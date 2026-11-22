#!/usr/bin/env Rscript
# stan_to_dag.R — read a Stan program and print the skeleton of its model graph (protocol H4e)
# as R code for lib/model_dag.R: one node per declared quantity, one prior-constant node per
# `~` statement on a parameter, edges from every variable used on the right of a `~` or `=`.
#
#   Rscript tools/stan_to_dag.R <article>/stan/<model>.stan      # prints R code to stdout
#
# The output is a proposal to be laid out and checked by hand (x, y are left NA; labels are
# guesses): Stan is parsed with regular expressions, not a grammar. Things it does not see:
# `target +=` statements (listed for reading), functions blocks, declarations inside loops.
# Base R only, no packages.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1) stop("usage: Rscript tools/stan_to_dag.R <file.stan>")
src <- paste(readLines(args[1], warn = FALSE), collapse = "\n")

# ---- strip comments -------------------------------------------------------------------------
src <- gsub("/\\*.*?\\*/", " ", src, perl = TRUE)
src <- gsub("//[^\n]*", "", src, perl = TRUE)

# ---- split into top-level blocks by brace matching --------------------------------------------
block_names <- c("functions", "data", "transformed data", "parameters", "transformed parameters",
                 "model", "generated quantities")
blocks <- list()
chars <- strsplit(src, "")[[1]]
for (bn in block_names) {
  m <- regexpr(paste0("(^|\n)\\s*", bn, "\\s*\\{"), src, perl = TRUE)
  if (m < 0) next
  open <- m + attr(m, "match.length") - 1          # index of the "{"
  depth <- 0; close <- NA
  for (k in open:length(chars)) {
    if (chars[k] == "{") depth <- depth + 1
    if (chars[k] == "}") { depth <- depth - 1; if (depth == 0) { close <- k; break } }
  }
  blocks[[bn]] <- substr(src, open + 1, close - 1)
}

# ---- top-level statements of a block (depth 0 only; loop bodies are skipped) -------------------
top_statements <- function(txt) {
  if (is.null(txt)) return(character())
  out <- character(); buf <- ""; depth <- 0; pdepth <- 0
  for (ch in strsplit(txt, "")[[1]]) {
    if (ch == "{") depth <- depth + 1
    if (ch == "}") depth <- depth - 1
    if (depth > 0) next
    if (ch == "(") pdepth <- pdepth + 1
    if (ch == ")") pdepth <- pdepth - 1
    if (ch == ";" && pdepth == 0) { out <- c(out, trimws(gsub("\\s+", " ", buf))); buf <- ""; next }
    buf <- paste0(buf, ch)
  }
  out[nzchar(out)]
}
# statements at any depth (for the model block, where likelihoods often sit inside loops)
all_statements <- function(txt) {
  if (is.null(txt)) return(character())
  txt <- gsub("\\bfor\\s*\\([^)]*\\)", "", txt, perl = TRUE)   # drop loop heads
  txt <- gsub("\\bif\\s*\\([^)]*\\)", "", txt, perl = TRUE)    # and if-conditions (prior_only switch)
  txt <- gsub("[{}]", "", txt)
  out <- trimws(gsub("\\s+", " ", strsplit(txt, ";", fixed = TRUE)[[1]]))
  out[nzchar(out)]
}

types <- "int|real|complex|vector|row_vector|matrix|array|simplex|unit_vector|ordered|positive_ordered|cholesky_factor_corr|cholesky_factor_cov|corr_matrix|cov_matrix"
parse_decl <- function(st) {
  if (!grepl(paste0("^(", types, ")\\b"), st, perl = TRUE)) return(NULL)
  # drop <constraints> and [dimensions] (both may contain "=" or names) before splitting at "="
  bare <- gsub("<[^>]*>", "", st, perl = TRUE)
  bare <- gsub("\\[[^]]*\\]", "", bare, perl = TRUE)
  lhs <- sub("=.*$", "", bare); rhs <- if (grepl("=", bare, fixed = TRUE)) sub("^[^=]*=", "", bare) else NA
  toks <- regmatches(lhs, gregexpr("[A-Za-z_][A-Za-z0-9_]*", lhs))[[1]]
  name <- toks[length(toks)]
  scalar <- grepl(paste0("^(int|real)\\b"), st, perl = TRUE) && !grepl("^array", st)
  lower0 <- grepl("lower\\s*=\\s*0", sub("=.*$", "", gsub("<lower\\s*=\\s*0", "<LOWER0", st)), perl = TRUE) ||
            grepl("<LOWER0", gsub("<lower\\s*=\\s*0", "<LOWER0", st), fixed = TRUE)
  list(name = name, rhs = trimws(rhs), scalar = scalar, lower0 = lower0, decl = st)
}
decls <- function(bn) Filter(Negate(is.null), lapply(top_statements(blocks[[bn]]), parse_decl))

d_data  <- decls("data");  d_tdata <- decls("transformed data")
d_par   <- decls("parameters"); d_tpar <- decls("transformed parameters"); d_gq <- decls("generated quantities")
nm <- function(d) vapply(d, `[[`, "", "name")

# ---- `~` statements ---------------------------------------------------------------------------
model_sts <- all_statements(blocks[["model"]])
tilde <- grep("~", model_sts, fixed = TRUE, value = TRUE)
target <- grep("target\\s*\\+=", model_sts, perl = TRUE, value = TRUE)
parse_tilde <- function(st) {
  lhs <- trimws(sub("~.*$", "", st)); rhs <- trimws(sub("^[^~]*~", "", st))
  lhs_name <- sub("\\[.*$", "", lhs)
  dist <- sub("\\(.*$", "", rhs)
  inner <- sub("^[^(]*\\((.*)\\)\\s*$", "\\1", rhs, perl = TRUE)
  list(lhs = lhs_name, dist = dist, args = inner)
}
tl <- lapply(tilde, parse_tilde)

# ---- classify ---------------------------------------------------------------------------------
observed <- unique(vapply(tl, `[[`, "", "lhs"))
observed <- observed[observed %in% c(nm(d_data), nm(d_tdata))]
sizes <- nm(Filter(function(d) d$scalar, d_data))
covariates <- setdiff(c(nm(d_data), nm(d_tdata)), c(observed, sizes))
params <- nm(d_par)
derived <- c(nm(d_tpar), nm(d_gq))
skip_gq <- derived[grepl("_rep$|^log_lik$|^lp__$", derived)]
known <- c(observed, covariates, params, derived)

vars_in <- function(expr) {
  toks <- unique(regmatches(expr, gregexpr("[A-Za-z_][A-Za-z0-9_]*", expr))[[1]])
  toks[toks %in% known]
}

# ---- prior labels (plotmath string literals, lib/model_dag.R convention) ----------------------
clean_args <- function(a) {
  a <- gsub("\\s*\\*\\s*prior_scale", "", a, perl = TRUE)
  a <- gsub("prior_scale\\s*\\*\\s*", "", a, perl = TRUE)
  a <- gsub("log\\(([^()]+)\\)", "log \\1", a, perl = TRUE)
  a <- gsub("\\s+", " ", a); trimws(a)
}
prior_label <- function(t, lower0) {
  a <- clean_args(t$args)
  switch(t$dist,
    normal       = sprintf(if (lower0) "N^'+'*'(%s)'" else "N*'(%s)'", a),
    std_normal   = "N*'(0, 1)'",
    lognormal    = sprintf("LogN*'(%s)'", a),
    exponential  = sprintf("Exp*'(%s)'", a),
    gamma        = sprintf("Gamma*'(%s)'", a),
    beta         = sprintf("Beta*'(%s)'", a),
    cauchy       = sprintf(if (lower0) "Cauchy^'+'*'(%s)'" else "Cauchy*'(%s)'", a),
    student_t    = sprintf("t*'(%s)'", a),
    lkj_corr_cholesky = sprintf("LKJ*'(%s)'", a),
    lkj_corr     = sprintf("LKJ*'(%s)'", a),
    sprintf("%s*'(%s)'", t$dist, a))
}
guess_label <- function(x) {            # b_cond -> b[cond]; names that are Greek letters render as such
  if (grepl("_", x) && !grepl("^inv_|_rep$|^log_", x)) sub("^([^_]+)_(.+)$", "\\1[\\2]", x) else x
}

# ---- nodes and edges --------------------------------------------------------------------------
nodes <- data.frame(name = character(), label = character(), group = character(), stringsAsFactors = FALSE)
add_node <- function(name, label, group) nodes <<- rbind(nodes, data.frame(name = name, label = label, group = group))
edges <- data.frame(from = character(), to = character(), stringsAsFactors = FALSE)
add_edges <- function(from, to) for (f in setdiff(from, to)) edges <<- rbind(edges, data.frame(from = f, to = to))

lower0_of <- setNames(vapply(d_par, `[[`, NA, "lower0"), params)
mixed <- character()
for (t in tl) {
  if (t$lhs %in% params) {
    used <- vars_in(t$args)
    add_edges(used, t$lhs)
    if (length(used) == 0) {
      # fixed constants only: one prior-constant node
      hn <- paste0("h_", t$lhs)
      add_node(hn, prior_label(t, isTRUE(lower0_of[[t$lhs]])), "hyperparameter")
      add_edges(hn, t$lhs)
    } else if (grepl("[1-9]", t$args)) {
      mixed <- c(mixed, sprintf("%s ~ %s(%s)", t$lhs, t$dist, t$args))
    }
  } else if (t$lhs %in% observed) {
    add_edges(vars_in(t$args), t$lhs)
  }
}
for (p in params) add_node(p, guess_label(p), "parameter")
for (d in c(d_tpar, d_gq)) {
  if (d$name %in% skip_gq) next
  add_node(d$name, guess_label(d$name), "derived")
  if (!is.na(d$rhs)) add_edges(vars_in(d$rhs), d$name)
}
# assignments to already-declared derived quantities (e.g. `x = ...;` after `vector[N] x;`)
for (bn in c("transformed parameters", "generated quantities"))
  for (st in all_statements(blocks[[bn]])) {
    if (grepl(paste0("^(", types, ")\\b"), st, perl = TRUE) || !grepl("=", st, fixed = TRUE)) next
    lhs <- sub("\\[.*$", "", trimws(sub("=.*$", "", st))); rhs <- sub("^[^=]*=", "", st)
    if (lhs %in% derived && !(lhs %in% skip_gq)) add_edges(vars_in(rhs), lhs)
  }
for (cv in covariates) add_node(cv, guess_label(cv), "covariate")
for (ob in observed) add_node(ob, guess_label(ob), "observed")
edges <- unique(edges)
# order nodes: prior constants, parameters, derived, covariates, data (the left-to-right columns)
ord <- c("hyperparameter", "parameter", "derived", "covariate", "observed")
nodes <- nodes[order(match(nodes$group, ord)), ]
rownames(nodes) <- NULL

# ---- print ------------------------------------------------------------------------------------
q <- function(x) paste0('"', x, '"')
cat("# model graph skeleton from", basename(args[1]), "—", nrow(nodes), "nodes,", nrow(edges), "edges\n")
cat("# sizes / switches (not drawn):", if (length(sizes)) paste(sizes, collapse = ", ") else "none", "\n")
if (length(skip_gq)) cat("# generated quantities left out (predictive draws, log-lik):", paste(skip_gq, collapse = ", "), "\n")
if (length(target)) cat("# target += statements, read by hand:\n#  ", paste(target, collapse = "\n#   "), "\n")
if (length(mixed)) cat("# priors with both a parameter and a non-zero constant (edge drawn, constant not):\n#  ", paste(mixed, collapse = "\n#   "), "\n")
if (length(d_gq)) cat("# generated quantities (keep only those the review reports):", paste(setdiff(nm(d_gq), skip_gq), collapse = ", "), "\n")
cat("# TODO: set x, y (columns: constants 0, parameters 1, derived 2–3, covariates between, data right);\n")
cat("#       check every label against the program; drop derived quantities the review does not need.\n")
cat("nodes <- data.frame(\n")
cat("  name  = c(", paste(q(nodes$name), collapse = ", "), "),\n", sep = "")
cat("  label = c(", paste(q(nodes$label), collapse = ", "), "),\n", sep = "")
cat("  group = c(", paste(q(nodes$group), collapse = ", "), "),\n", sep = "")
cat("  x = NA_real_, y = NA_real_)\n")
cat("edges <- data.frame(\n")
cat("  from = c(", paste(q(edges$from), collapse = ", "), "),\n", sep = "")
cat("  to   = c(", paste(q(edges$to), collapse = ", "), "))\n", sep = "")
cat("# model_dag(nodes, edges, title = ", q(basename(args[1])), ")\n", sep = "")
