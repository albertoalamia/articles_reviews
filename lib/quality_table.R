# Quality summary tables built from the registry (registry/issues.csv, protocol/taxonomy.csv,
# registry/papers.csv). Pure functions; loaded with source(here::here("lib/quality_table.R")).
# Tests: lib/tests/test_quality_table.R (run: Rscript lib/tests/run_tests.R)
#
# Rating rule (protocol v0.2, item H2), applied per protocol domain to the issue rows of a paper:
#   any critical issue  -> "conclusions at risk"
#   any major issue     -> "major concerns"
#   only minor issues   -> "minor concerns"
#   no issue            -> "no concern found"
# An override in a review is a stated decision with a reason, never a silent edit of the table.

domain_order <- c(design = "Design", measurement = "Measurement", model = "Model adequacy",
                  consistency = "Internal consistency", reporting = "Reporting", inference = "Inference")
severity_levels <- c("critical", "major", "minor")
evidence_levels <- c("confirmed", "inferred", "needs-data")
rating_levels   <- c("conclusions at risk", "major concerns", "minor concerns", "no concern found")

rate_domain <- function(severity) {
  if (any(severity == "critical")) return("conclusions at risk")
  if (any(severity == "major"))    return("major concerns")
  if (any(severity == "minor"))    return("minor concerns")
  "no concern found"
}

read_registry <- function(root = here::here()) {
  rd <- function(f) utils::read.csv(file.path(root, f), stringsAsFactors = FALSE, check.names = FALSE)
  list(issues = rd("registry/issues.csv"), taxonomy = rd("protocol/taxonomy.csv"), papers = rd("registry/papers.csv"))
}

#' Issue rows of one paper with domain and label attached; stops on an unknown code or tag.
paper_issues <- function(paper_id, issues, taxonomy) {
  x <- issues[issues$paper_id == paper_id, , drop = FALSE]
  x$domain <- taxonomy$domain[match(x$issue_code, taxonomy$code)]
  x$label  <- taxonomy$label[match(x$issue_code, taxonomy$code)]
  if (anyNA(x$domain)) stop("unknown issue code(s): ", paste(unique(x$issue_code[is.na(x$domain)]), collapse = ", "))
  if (!all(x$severity %in% severity_levels)) stop("unknown severity in ", paper_id)
  if (!all(x$evidence %in% evidence_levels)) stop("unknown evidence tag in ", paper_id)
  x[order(match(x$domain, names(domain_order)), match(x$severity, severity_levels),
          match(x$evidence, evidence_levels)), , drop = FALSE]
}

count_by <- function(x, column, levels) vapply(levels, function(l) sum(x[[column]] == l), integer(1))

#' One row per protocol domain: counts by severity and by evidence tag, rule-based rating, main point.
#' @param main_points optional named character vector (names = domain keys, e.g. "design") replacing
#'   the default main point (label and location of the most severe, best-evidenced issue).
quality_table <- function(paper_id, issues = NULL, taxonomy = NULL, main_points = NULL, root = here::here()) {
  if (is.null(issues) || is.null(taxonomy)) {
    reg <- read_registry(root); issues <- issues %||% reg$issues; taxonomy <- taxonomy %||% reg$taxonomy
  }
  x <- paper_issues(paper_id, issues, taxonomy)
  rows <- lapply(names(domain_order), function(d) {
    y <- x[x$domain == d, , drop = FALSE]
    main <- if (!is.null(main_points) && !is.na(main_points[d])) unname(main_points[d]) else
      if (nrow(y)) sprintf("%s (%s)", y$label[1], y$location[1]) else ""
    sev <- count_by(y, "severity", severity_levels); ev <- count_by(y, "evidence", evidence_levels)
    data.frame(Domain = unname(domain_order[d]), Critical = sev[["critical"]], Major = sev[["major"]],
               Minor = sev[["minor"]], Confirmed = ev[["confirmed"]], Inferred = ev[["inferred"]],
               `Needs data` = ev[["needs-data"]], Rating = rate_domain(y$severity), `Main point` = main,
               check.names = FALSE, stringsAsFactors = FALSE)
  })
  out <- do.call(rbind, rows); rownames(out) <- NULL; out
}

#' One row per paper for the site index and cross-paper counts. Only papers whose registry status
#' is in `status` are listed, so that nothing about an unpublished review reaches the index.
programme_table <- function(papers = NULL, issues = NULL, taxonomy = NULL, status = "published", root = here::here()) {
  if (is.null(papers) || is.null(issues) || is.null(taxonomy)) {
    reg <- read_registry(root)
    papers <- papers %||% reg$papers; issues <- issues %||% reg$issues; taxonomy <- taxonomy %||% reg$taxonomy
  }
  p <- papers[papers$status %in% status, , drop = FALSE]
  if (nrow(p) == 0) return(data.frame())
  rows <- lapply(seq_len(nrow(p)), function(i) {
    x <- paper_issues(p$id[i], issues, taxonomy)
    sev <- count_by(x, "severity", severity_levels); ev <- count_by(x, "evidence", evidence_levels)
    # the domain of the most severe (then best-evidenced) issue, not the first domain in protocol order
    xs <- x[order(match(x$severity, severity_levels), match(x$evidence, evidence_levels)), , drop = FALSE]
    worst <- if (nrow(xs)) unname(domain_order[xs$domain[1]]) else ""
    data.frame(Paper = sprintf("%s %s", p$first_author[i], p$year[i]), Journal = p$journal[i], Field = p$field[i],
               Track = p$track[i], Verdict = p$verdict[i], Critical = sev[["critical"]], Major = sev[["major"]],
               Minor = sev[["minor"]], Confirmed = ev[["confirmed"]], Inferred = ev[["inferred"]],
               `Needs data` = ev[["needs-data"]], `Worst domain` = worst, Published = p$date_review_published[i],
               check.names = FALSE, stringsAsFactors = FALSE)
  })
  out <- do.call(rbind, rows); rownames(out) <- NULL; out
}

`%||%` <- function(a, b) if (is.null(a)) b else a
