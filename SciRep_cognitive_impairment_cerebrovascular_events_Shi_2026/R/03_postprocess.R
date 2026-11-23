# 03_postprocess.R — Shi et al. 2026, Sci Rep (P002), stage 4 post-processing (plan notes/04_analysis_plan.md §5, §8)
#
# Reads the CmdStan CSV draws that run_model.sh writes to $FITS_DIR/<article>/<model>/, computes diagnostics and
# summaries, and writes SMALL tables and figures to output/. Never copies draws into the project tree. R is for
# post-processing only: nothing is fitted from R (cmdstanr::read_cmdstan_csv reads the files).
# Usage (repo root, in the project environment):
#   Rscript <art>/R/03_postprocess.R --prior    S3: prior predictive of the two programs against the life table and Table 2,
#                                               sampler diagnostics of the prior runs, and the mapping checks (the generated
#                                               quantities of each program recomputed in R from its parameter draws)
#   Rscript <art>/R/03_postprocess.R            S4: the 29 posterior runs of run_all.sh: sampler diagnostics, posterior predictive
#                                               counts, every estimand of plan §1, and stage 3 next to stage 4
#
# --prior needs these five runs (S3 of plan §8):
#   ./<art>/run_model.sh pem_competing pem_isch --prior-only
#   ./<art>/run_model.sh pem_competing pem_any  --prior-only
#   ./<art>/run_model.sh exposure_age exposure_age_isch --prior P1 --prior-only      (and P2, P3)
# The prior of exposure_age does not depend on the outcome, so the same three runs are compared with the two counts of
# each of the three outcomes.
# Outputs: output/tables/stage4_prior_predictive.csv   one row per quantity: prior quantiles, reference, percentile, covers
#          output/tables/stage4_prior_convergence.csv  sampler diagnostics of the prior runs (plan §5 thresholds)
#          output/tables/stage4_mapping_checks.csv     max |Stan generated quantity - R recomputation| per run and quantity
#          output/figures/stage4_prior_predictive_pem.png, stage4_prior_predictive_exposure.png
# Outputs of the main section (S4):
#          output/tables/stage4_convergence.csv        sampler diagnostics per run (plan §5 thresholds)
#          output/tables/stage4_ppc.csv                posterior predictive counts against the life table and Table 2
#          output/tables/stage4_estimates.csv          every estimand of every run: posterior median, 95 % interval, P(> 1) for ratios
#          output/tables/stage4_side_by_side.csv       the same rows with the paper's value, stage 2 and stage 3 beside them (plan §6)
#          output/figures/stage4_ppc_pem.png, stage4_hr_by_prior.png
suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(readr); library(purrr); library(stringr); library(ggplot2); library(posterior)
})
ART <- "SciRep_cognitive_impairment_cerebrovascular_events_Shi_2026"
here_art <- function(...) here::here(ART, ...)

args <- commandArgs(trailingOnly = TRUE)
if (!all(args %in% c("--prior"))) stop("unknown argument(s): ", paste(setdiff(args, "--prior"), collapse = " "))
RUN_PRIOR <- "--prior" %in% args

stopifnot("FITS_DIR not set: run inside nix-shell" = nzchar(Sys.getenv("FITS_DIR")))
fits_dir <- file.path(Sys.getenv("FITS_DIR"), ART)
stopifnot("archive disk not mounted, or no run yet" = dir.exists(fits_dir))
out_tab <- here_art("output/tables"); out_fig <- here_art("output/figures")
rd <- function(f) read_csv(here_art(f), show_col_types = FALSE)

t2  <- rd("data/raw/table2_cox.csv")
GROUPS <- c("NCI", "CI"); CAUSES <- c("stroke", "death")
N_GROUP <- setNames(t2$n_group[t2$outcome == "ischemic stroke" & t2$group %in% GROUPS], t2$group[t2$outcome == "ischemic stroke" & t2$group %in% GROUPS])[GROUPS]
OUTCOME_OF <- c(isch = "ischemic stroke", any = "any stroke", death = "all-cause mortality")
PRIOR_LABEL <- c(`1` = "P1, as Model 1 implies", `2` = "P2, as population studies report", `3` = "P3, unknown between 1 and 3")
N_MAP <- 25L                                   # draws used by the mapping checks
TOL_MAP <- 1e-4                                # CmdStan writes 6 significant digits

# ---- reading draws ------------------------------------------------------------------------------------------
read_run <- function(model, suffix) {
  dir <- file.path(fits_dir, model)
  files <- list.files(dir, pattern = sprintf("^%s_%s_[0-9]+\\.csv$", model, suffix), full.names = TRUE)
  if (length(files) == 0) stop("no draws for ", model, " [", suffix, "] in ", dir, ": run run_model.sh first (see the header)")
  cs <- cmdstanr::read_cmdstan_csv(files, format = "draws_df")
  data_copy <- file.path(dir, "data", sprintf("%s_%s.json", model, suffix))   # the data the run read, switches included
  list(model = model, suffix = suffix, draws = cs$post_warmup_draws, sampler = cs$post_warmup_sampler_diagnostics,
       n_chains = length(files), data = jsonlite::read_json(data_copy, simplifyVector = TRUE))
}
# plan §5 thresholds: R-hat < 1.01, bulk and tail ESS > 400, no divergences, E-BFMI > 0.3 (per chain); the predictive
# draws, the pointwise log-likelihood and the per-person vector mu are left out of the R-hat and ESS scan
convergence <- function(run, exclude = c("^D_rep", "^log_lik", "^mu\\[")) {
  keep <- variables(run$draws); keep <- keep[!grepl(paste(exclude, collapse = "|"), keep)]
  s <- summarise_draws(subset_draws(run$draws, variable = keep), "rhat", "ess_bulk", "ess_tail")
  sd_df <- as_draws_df(run$sampler)
  ebfmi <- sd_df |> group_by(.chain) |> summarise(e = mean(diff(energy__)^2) / var(energy__), .groups = "drop")
  n_draws <- ndraws(run$draws)       # before tibble(): inside it, the column `run` masks the list `run`
  tibble(model = run$model, run = run$suffix, n_draws = n_draws, max_rhat = max(s$rhat, na.rm = TRUE),
         min_ess_bulk = min(s$ess_bulk, na.rm = TRUE), min_ess_tail = min(s$ess_tail, na.rm = TRUE),
         divergences = sum(sd_df$divergent__), max_treedepth_hits = sum(sd_df$treedepth__ >= 10), min_ebfmi = min(ebfmi$e),
         passes = max_rhat < 1.01 & min_ess_bulk > 400 & min_ess_tail > 400 & divergences == 0 & min_ebfmi > 0.3)
}
# all elements of one Stan variable as a plain draws x elements matrix, with the indices parsed from the names
var_matrix <- function(run, v) {
  m <- unclass(as_draws_matrix(subset_draws(run$draws, variable = v)))
  br <- str_extract(colnames(m), "\\[[0-9,]+\\]$")                      # NA for a scalar
  idx <- if (anyNA(br)) NULL else do.call(rbind, lapply(str_extract_all(br, "[0-9]+"), as.integer))
  list(m = m, idx = idx)
}
# prior quantiles of each column, the reference, its percentile in the prior (mid-p, counts have ties) and coverage
quant_rows <- function(m, reference) {
  stopifnot(ncol(m) == length(reference))
  map_dfr(seq_len(ncol(m)), \(c) {
    x <- m[, c]; ref <- reference[c]
    tibble(q025 = quantile(x, .025, na.rm = TRUE), q25 = quantile(x, .25, na.rm = TRUE), q50 = median(x, na.rm = TRUE),
           q75 = quantile(x, .75, na.rm = TRUE), q975 = quantile(x, .975, na.rm = TRUE), reference = ref,
           percentile = if (is.na(ref)) NA_real_ else mean(x < ref, na.rm = TRUE) + 0.5 * mean(x == ref, na.rm = TRUE),
           share_guarded = mean(x == -1))
  }) |> mutate(covers = percentile >= 0.025 & percentile <= 0.975)
}

# ---- pem_competing ----------------------------------------------------------------------------------------
# cumulative incidence at the interval ends from a J x K hazard matrix (cif_ends() of R/06_fit_frequentist.R)
cif_ends <- function(h, width) {
  S <- 1; Fk <- rep(0, ncol(h)); out <- matrix(NA_real_, nrow(h), ncol(h))
  for (j in seq_len(nrow(h))) {
    hd <- sum(h[j, ]); Fk <- Fk + S * h[j, ] / hd * (1 - exp(-hd * width[j])); S <- S * exp(-hd * width[j]); out[j, ] <- Fk
  }
  out
}
prior_pem <- function(suffix) {
  run <- read_run("pem_competing", suffix); dat <- run$data
  J <- dat$J; K <- dat$K; G <- dat$G
  outcome <- OUTCOME_OF[[sub("_.*$", "", suffix)]]
  cause_label <- function(k) ifelse(k == 1, outcome, "all-cause mortality")
  interval <- sprintf("(%s, %s]", c(0, dat$t_end[-J]), dat$t_end)
  # (a) cell counts
  dr <- var_matrix(run, "D_rep")
  obs <- dat$D[cbind(dr$idx[, 1], dr$idx[, 2], dr$idx[, 3])]
  mcell <- dr$m; mcell[mcell < 0] <- NA
  cells <- quant_rows(mcell, obs) |> mutate(share_guarded = colMeans(dr$m < 0)) |>
    mutate(quantity = "events per cell", group = GROUPS[dr$idx[, 1]], interval = interval[dr$idx[, 2]], cause = cause_label(dr$idx[, 3]),
           reference_source = "life table (pem_counts.csv)", .before = 1)
  # (b) cumulative incidence at year 4 and at the end, against the crude proportions of the life table
  f <- var_matrix(run, "F"); keep <- f$idx[, 2] %in% c(J - 1, J)
  crude <- map_dbl(which(keep), \(c) { g <- f$idx[c, 1]; j <- f$idx[c, 2]; k <- f$idx[c, 3]; sum(dat$D[g, 1:j, k]) / N_GROUP[[g]] })
  cif <- quant_rows(f$m[, keep, drop = FALSE], crude) |>
    mutate(quantity = sprintf("cumulative incidence at %s y", dat$t_end[f$idx[keep, 2]]), group = GROUPS[f$idx[keep, 1]], interval = NA_character_,
           cause = cause_label(f$idx[keep, 3]), reference_source = "events to that time / n (crude)", .before = 1)
  # (c) hazard ratios against Table 2 (unadjusted)
  h <- var_matrix(run, "hr")
  hr_ref <- map_dbl(h$idx[, 2], \(k) t2$hr_unadj[t2$outcome == cause_label(k) & t2$group == "CI"])
  hr <- quant_rows(h$m, hr_ref) |>
    mutate(quantity = if (dat$split == 1) c("HR CI vs NCI, (0, 4]", "HR CI vs NCI, (4, 4.2]")[h$idx[, 1]] else "HR CI vs NCI", group = NA_character_,
           interval = NA_character_, cause = cause_label(h$idx[, 2]), reference_source = "Table 2, unadjusted", .before = 1)
  # (d) tail ratio against the crude one
  tr <- var_matrix(run, "tail_ratio")
  tr_ref <- map_dbl(seq_len(nrow(tr$idx)), \(c) { g <- tr$idx[c, 1]; k <- tr$idx[c, 2]
    (dat$D[g, J, k] / dat$PY[g, J]) / (sum(dat$D[g, 1:(J - 1), k]) / sum(dat$PY[g, 1:(J - 1)])) })
  tail <- quant_rows(tr$m, tr_ref) |>
    mutate(quantity = "rate in the last interval / rate before", group = GROUPS[tr$idx[, 1]], interval = NA_character_, cause = cause_label(tr$idx[, 2]),
           reference_source = "life table (crude)", .before = 1)
  # mapping check: F and tail_ratio recomputed in R from alpha and beta
  al <- var_matrix(run, "alpha"); be <- var_matrix(run, "beta")
  period <- if (dat$split == 1) c(rep(1L, J - 1), 2L) else rep(1L, J)
  dd <- seq_len(min(N_MAP, nrow(al$m)))
  diffs <- map_dfr(dd, \(d) {
    alpha <- matrix(NA_real_, J, K); alpha[al$idx] <- al$m[d, ]
    beta <- matrix(NA_real_, max(period), K); beta[be$idx] <- be$m[d, ]
    map_dfr(seq_len(G), \(g) {
      hmat <- exp(alpha + beta[period, , drop = FALSE] * dat$CI[g])
      Fr <- cif_ends(hmat, dat$width)
      sel <- f$idx[, 1] == g
      Fs <- matrix(NA_real_, J, K); Fs[f$idx[sel, 2:3, drop = FALSE]] <- f$m[d, sel]
      trr <- hmat[J, ] / (colSums(hmat[1:(J - 1), , drop = FALSE] * dat$PY[g, 1:(J - 1)]) / sum(dat$PY[g, 1:(J - 1)]))
      trs <- tr$m[d, tr$idx[, 1] == g][order(tr$idx[tr$idx[, 1] == g, 2])]
      tibble(quantity = c("F", "tail_ratio"), diff = c(max(abs(Fr - Fs)), max(abs(trr / trs - 1))))
    })
  }) |> group_by(quantity) |> summarise(max_diff = max(diff), .groups = "drop") |>
    mutate(model = "pem_competing", run = suffix, scale = ifelse(quantity == "F", "absolute", "relative"), n_draws = length(dd), .before = 1)
  list(summary = bind_rows(cells, cif, hr, tail) |> mutate(model = "pem_competing", run = suffix, .before = 1),
       convergence = convergence(run), mapping = diffs)
}

# ---- exposure_age -----------------------------------------------------------------------------------------
# expected concordance and screening metrics as in R/06_fit_frequentist.R
c_expected <- function(score, risk) {
  o <- order(score); s <- score[o]; r <- risk[o]; qn <- 1 - r
  grp <- cumsum(c(TRUE, diff(s) != 0))
  q_grp <- as.vector(rowsum(qn, grp)); before <- c(0, cumsum(q_grp))[grp]; tie_other <- q_grp[grp] - qn
  (sum(r * (before + 0.5 * tie_other))) / (sum(r) * sum(qn) - sum(r * qn))
}
screen <- function(flag, risk) c(sens = sum(risk[flag]) / sum(risk), spec = sum(1 - risk[!flag]) / sum(1 - risk),
                                 ppv = mean(risk[flag]), npv = mean(1 - risk[!flag]))
events_of <- function(nm) { d <- jsonlite::read_json(here_art("data/derived/stan_data", sprintf("exposure_age_%s.json", nm)), simplifyVector = TRUE)$D; setNames(d, GROUPS) }
prior_exposure <- function(suffix) {
  run <- read_run("exposure_age", suffix); dat <- run$data
  prior <- PRIOR_LABEL[[as.character(dat$prior)]]
  # (a) the two group counts, against the counts of each outcome (the prior is the same for the three)
  dr <- var_matrix(run, "D_rep"); mrep <- dr$m; mrep[mrep < 0] <- NA
  counts <- map_dfr(names(OUTCOME_OF), \(nm) {
    quant_rows(mrep, events_of(nm)[dr$idx[, 1]]) |> mutate(share_guarded = colMeans(dr$m < 0)) |>
      mutate(quantity = "events per group", group = GROUPS[dr$idx[, 1]], interval = NA_character_, cause = OUTCOME_OF[[nm]],
             reference_source = "Table 2 counts", .before = 1)
  })
  # (b) parameters and derived quantities; reference where the paper or stage 3 gives one
  one <- function(v, label, ref = NA_real_, src = NA_character_, cause = NA_character_) {
    quant_rows(var_matrix(run, v)$m[, 1, drop = FALSE], ref) |>
      mutate(quantity = label, group = NA_character_, interval = NA_character_, cause = cause, reference_source = src, .before = 1)
  }
  m1 <- \(o) t2$hr_m1[t2$outcome == o & t2$group == "CI"]
  pars <- bind_rows(
    map_dfr(unname(OUTCOME_OF), \(o) one("hr_ci", "HR for MMSE < 24 at given age and sex", m1(o), "Table 2, Model 1", o)),
    one("theta_age", "hazard multiplier per decade of age"),
    one("theta_male", "hazard multiplier, male"),
    one("lambda0", "hazard per person-year at the reference (woman, 50, MMSE >= 24)"),
    one("age_equiv_years", "age-equivalent of MMSE < 24, years"),
    one("c_age_sex", "c-index, age and sex"), one("c_gain", "c-index gain from MMSE status"),
    one("sens[1]", "sensitivity of MMSE < 24"), one("sens[2]", "sensitivity of age >= 65"))
  # mapping check: E, c-index and screening metrics recomputed in R from the four parameters
  age <- dat[[sprintf("age_%d", dat$age_max)]]; a <- (age - dat$age_ref) / 10
  flags <- list(dat$CI == 1, age >= dat$age_flag, dat$CI == 1 | age >= dat$age_flag)
  v <- c("lambda0", "b_ci", "b_age", "b_male", "E[1]", "E[2]", "c_age_sex", "c_with_mmse",
         sprintf("%s[%d]", rep(c("sens", "spec", "ppv", "npv"), each = 3), 1:3))
  dm <- unclass(as_draws_matrix(subset_draws(run$draws, variable = v)))[, v, drop = FALSE]
  dd <- seq_len(min(N_MAP, nrow(dm)))
  diffs <- map_dfr(dd, \(d) {
    p <- dm[d, ]; lp0 <- p[["b_age"]] * a + p[["b_male"]] * dat$male
    mu <- 1 - exp(-dat$tau * p[["lambda0"]] * exp(p[["b_ci"]] * dat$CI + lp0))
    risk <- 1 - exp(-dat$t_pred * p[["lambda0"]] * exp(p[["b_ci"]] * dat$CI + lp0))
    E <- c(sum(mu[dat$CI == 0]), sum(mu[dat$CI == 1]))
    scr <- sapply(flags, \(fl) screen(fl, risk))                     # 4 metrics x 3 rules
    tibble(quantity = c("E", "c_age_sex", "c_with_mmse", "sens, spec, ppv, npv"),
           diff = c(max(abs(E / p[c("E[1]", "E[2]")] - 1)), abs(c_expected(lp0, risk) - p[["c_age_sex"]]),
                    abs(c_expected(p[["b_ci"]] * dat$CI + lp0, risk) - p[["c_with_mmse"]]),
                    max(abs(as.vector(t(scr)) - p[sprintf("%s[%d]", rep(c("sens", "spec", "ppv", "npv"), each = 3), 1:3)]))))
  }) |> group_by(quantity) |> summarise(max_diff = max(diff), .groups = "drop") |>
    mutate(model = "exposure_age", run = suffix, scale = ifelse(quantity == "E", "relative", "absolute"), n_draws = length(dd), .before = 1)
  hr_draws <- tibble(prior = prior, hr_ci = as.vector(var_matrix(run, "hr_ci")$m), theta_age = as.vector(var_matrix(run, "theta_age")$m))
  list(summary = bind_rows(counts, pars) |> mutate(model = "exposure_age", run = suffix, prior = prior, .before = 1),
       convergence = convergence(run), mapping = diffs, hr_draws = hr_draws)
}

# ---- S3: prior predictive ---------------------------------------------------------------------------------------
if (RUN_PRIOR) {
  cat("== S3 prior predictive\n")
  pem <- map(c("isch_prior", "any_prior"), prior_pem)
  expo <- map(sprintf("isch_P%d_prior", 1:3), prior_exposure)
  summ <- bind_rows(map_dfr(pem, "summary"), map_dfr(expo, "summary")) |>
    mutate(width_ratio = q975 / q025) |>
    select(model, run, prior, quantity, group, interval, cause, reference, reference_source, q025, q25, q50, q75, q975,
           percentile, covers, width_ratio, share_guarded)
  conv <- bind_rows(map_dfr(pem, "convergence"), map_dfr(expo, "convergence"))
  mapping <- bind_rows(map_dfr(pem, "mapping"), map_dfr(expo, "mapping")) |> mutate(tolerance = TOL_MAP, pass = max_diff < TOL_MAP)
  write_csv(summ, file.path(out_tab, "stage4_prior_predictive.csv"))
  write_csv(conv, file.path(out_tab, "stage4_prior_convergence.csv"))
  write_csv(mapping, file.path(out_tab, "stage4_mapping_checks.csv"))

  # figures: prior 95 % (thin) and 50 % (thick) intervals with the observed value
  cells <- summ |> filter(quantity == "events per cell") |>
    mutate(group = factor(group, GROUPS), interval = factor(interval, unique(interval)),
           panel = sprintf("%s: %s", sub("_prior$", "", run), cause))
  g1 <- ggplot(cells, aes(interval)) +
    geom_linerange(aes(ymin = q025, ymax = q975), colour = "grey55") +
    geom_linerange(aes(ymin = q25, ymax = q75), linewidth = 1.6, colour = "grey35") +
    geom_point(aes(y = reference, colour = covers), size = 2) +
    scale_colour_manual(values = c(`TRUE` = "#1b7837", `FALSE` = "#b2182b"), name = "observed within the prior 95 %") +
    scale_y_continuous(trans = scales::pseudo_log_trans(base = 10), breaks = c(0, 1, 3, 10, 30, 100, 300, 1000, 10000)) +
    facet_grid(group ~ panel) +
    labs(x = "interval, years", y = "events in the cell", title = "pem_competing: prior predictive cell counts",
         subtitle = "Bars: prior 50 % and 95 % intervals; points: the life table") +
    theme_minimal(base_size = 9) + theme(legend.position = "bottom")
  ggsave(file.path(out_fig, "stage4_prior_predictive_pem.png"), g1, width = 10, height = 5.5, dpi = 150, bg = "white")

  hr_draws <- map_dfr(expo, "hr_draws") |> pivot_longer(c(hr_ci, theta_age), names_to = "quantity") |>
    mutate(quantity = c(hr_ci = "HR for MMSE < 24 at given age and sex", theta_age = "hazard multiplier per decade of age")[quantity])
  refs <- t2 |> filter(group == "CI") |> transmute(quantity = "HR for MMSE < 24 at given age and sex", outcome, value = hr_m1)
  g2 <- ggplot(hr_draws, aes(value, colour = prior)) +
    geom_density(na.rm = TRUE) +
    geom_vline(data = refs, aes(xintercept = value), linetype = 2, colour = "grey40") +
    scale_x_log10(limits = c(0.1, 10)) +
    facet_wrap(~ quantity, ncol = 2) +
    labs(x = NULL, y = "prior density", colour = NULL, title = "exposure_age: priors of the exposure and age effects",
         subtitle = "Dashed: the three Model 1 hazard ratios of Table 2") +
    theme_minimal(base_size = 9) + theme(legend.position = "bottom")
  ggsave(file.path(out_fig, "stage4_prior_predictive_exposure.png"), g2, width = 9, height = 4, dpi = 150, bg = "white")

  options(width = 220)
  sg <- \(d) d |> mutate(across(where(is.numeric), \(x) signif(x, 3)))
  cat("\n-- sampler (prior runs; plan §5 thresholds)\n"); print(conv |> sg(), n = Inf)
  cat("\n-- mapping checks: Stan generated quantities against the R recomputation from the parameter draws\n"); print(mapping |> sg(), n = Inf)
  cat("\n-- prior predictive against the reference (percentile = share of prior draws below the reference; covers = within 2.5-97.5 %)\n")
  print(summ |> sg() |> select(model, run, quantity, group, interval, cause, reference, q025, q50, q975, percentile, covers, width_ratio), n = Inf)
  cat(sprintf("\ncells or counts outside the prior 95 %%: %d of %d; mapping checks passed: %d of %d; prior runs passing the sampler thresholds: %d of %d\n",
              sum(!summ$covers[summ$quantity %in% c("events per cell", "events per group")]), sum(summ$quantity %in% c("events per cell", "events per group")),
              sum(mapping$pass), nrow(mapping), sum(conv$passes), nrow(conv)))
  cat("written: output/tables/stage4_prior_predictive.csv, stage4_prior_convergence.csv, stage4_mapping_checks.csv;",
      "output/figures/stage4_prior_predictive_pem.png, stage4_prior_predictive_exposure.png\n")
}

# ================================================================================================================
# S4: posterior runs (plan §5, §6, §8)
# ================================================================================================================
RULES <- c("MMSE < 24", "age >= 65", "MMSE < 24 or age >= 65")
METRICS <- c(sens = "sensitivity", spec = "specificity", ppv = "ppv", npv = "npv")
# posterior median, central 95 % interval and, for ratios, the posterior probability of a value above 1
est_rows <- function(m, ratio = FALSE) {
  tibble(stage4_median = apply(m, 2, median), stage4_lo = apply(m, 2, quantile, .025), stage4_hi = apply(m, 2, quantile, .975),
         pr_gt_1 = if (ratio) colMeans(m > 1) else NA_real_)
}
with_meta <- function(rows, meta) bind_cols(meta[rep(1, nrow(rows)), ], rows)

post_pem <- function(suffix) {
  run <- read_run("pem_competing", suffix); dat <- run$data; J <- dat$J
  tok <- str_split(suffix, "_")[[1]]; split <- dat$split == 1
  meta <- tibble(program = "pem_competing", run = suffix, model = tok[1],
                 scenario = if ("early" %in% tok) "early" else if ("late" %in% tok) "late" else "uniform",
                 structure = if (split) "split at year 4" else "proportional", beta_sd = dat$beta_sd,
                 prior = NA_character_, age_max = NA_integer_)
  outcome_of_cause <- c(stroke = OUTCOME_OF[[tok[1]]], death = "all-cause mortality")
  h <- var_matrix(run, "hr")
  hr <- est_rows(h$m, ratio = TRUE) |>
    mutate(estimand = if (split) "E1c" else "E1b", quantity = "HR", cause = CAUSES[h$idx[, 2]],
           period = if (split) c("(0, 4]", "(4, 4.2]")[h$idx[, 1]] else NA_character_)
  f <- var_matrix(run, "F"); keep <- f$idx[, 2] %in% c(J - 1, J)
  cif <- est_rows(f$m[, keep, drop = FALSE]) |>
    mutate(estimand = "E1", quantity = "F", cause = CAUSES[f$idx[keep, 3]], group = GROUPS[f$idx[keep, 1]],
           time = as.character(dat$t_end[f$idx[keep, 2]]))
  contrasts <- map_dfr(c("RD_pre", "RR_pre", "RD_end", "RR_end"), \(v) {
    x <- var_matrix(run, v)
    est_rows(x$m, ratio = startsWith(v, "RR")) |>
      mutate(estimand = "E1", quantity = substr(v, 1, 2), cause = CAUSES[x$idx[, 1]],
             time = as.character(dat$t_end[if (endsWith(v, "pre")) J - 1 else J]))
  })
  tr <- var_matrix(run, "tail_ratio")
  tail <- est_rows(tr$m, ratio = TRUE) |>
    mutate(estimand = "E1c", quantity = "tail ratio", cause = CAUSES[tr$idx[, 2]], group = GROUPS[tr$idx[, 1]])
  est <- bind_rows(hr, cif, contrasts, tail) |> mutate(outcome = unname(outcome_of_cause[cause])) |> with_meta(meta)
  # posterior predictive cell counts
  dr <- var_matrix(run, "D_rep"); mcell <- dr$m; mcell[mcell < 0] <- NA
  interval <- sprintf("(%s, %s]", c(0, dat$t_end[-J]), dat$t_end)
  ppc <- quant_rows(mcell, dat$D[cbind(dr$idx[, 1], dr$idx[, 2], dr$idx[, 3])]) |> mutate(share_guarded = colMeans(dr$m < 0)) |>
    mutate(quantity = "events per cell", group = GROUPS[dr$idx[, 1]], interval = interval[dr$idx[, 2]],
           outcome = unname(outcome_of_cause[CAUSES[dr$idx[, 3]]]), .before = 1) |> with_meta(meta)
  list(est = est, ppc = ppc, convergence = convergence(run))
}

post_exposure <- function(suffix) {
  run <- read_run("exposure_age", suffix); dat <- run$data
  tok <- str_split(suffix, "_")[[1]]
  meta <- tibble(program = "exposure_age", run = suffix, model = tok[1], scenario = NA_character_, structure = NA_character_,
                 beta_sd = NA_real_, prior = paste0("P", dat$prior), age_max = as.integer(dat$age_max))
  one <- function(v, estimand, quantity, ratio = FALSE) est_rows(var_matrix(run, v)$m[, 1, drop = FALSE], ratio) |>
    mutate(estimand = estimand, quantity = quantity)
  scr <- map_dfr(names(METRICS), \(mt) { x <- var_matrix(run, mt)
    est_rows(x$m) |> mutate(estimand = "E3c", quantity = METRICS[[mt]], rule = RULES[x$idx[, 1]]) })
  est <- bind_rows(
    one("hr_ci", "E2", "HR at given age and sex", ratio = TRUE),
    one("theta_age", "E2", "hazard multiplier per decade of age", ratio = TRUE),
    one("theta_male", "E2", "hazard multiplier, male", ratio = TRUE),
    one("lambda0", "E2", "hazard per person-year at the reference"),
    one("age_equiv_years", "E3a", "age-equivalent, years"),
    one("c_age_sex", "E3b", "c_age_sex"), one("c_with_mmse", "E3b", "c_with_mmse"), one("c_gain", "E3b", "c_gain"),
    scr) |> mutate(outcome = OUTCOME_OF[[tok[1]]]) |> with_meta(meta)
  dr <- var_matrix(run, "D_rep"); mrep <- dr$m; mrep[mrep < 0] <- NA
  ppc <- quant_rows(mrep, dat$D[dr$idx[, 1]]) |> mutate(share_guarded = colMeans(dr$m < 0)) |>
    mutate(quantity = "events per group", group = GROUPS[dr$idx[, 1]], interval = NA_character_, outcome = OUTCOME_OF[[tok[1]]], .before = 1) |>
    with_meta(meta)
  list(est = est, ppc = ppc, convergence = convergence(run))
}

# stage 3 estimates in the layout of the stage 4 rows (keys: model, scenario, structure, prior, age_max, quantity, cause,
# group, time, period, rule). E2 and E3 have no one-to-one counterpart: stage 3 conditions on theta_age, stage 4 integrates
# over a prior, so P1 is set beside the profile at the theta_age nearest its centre and P2 beside theta_age = 2; P3 has none.
stage3_rows <- function() {
  s3 <- \(f) rd(file.path("output/tables", f))
  key_model <- setNames(names(OUTCOME_OF), OUTCOME_OF)
  hr <- s3("stage3_e1_hr.csv") |>
    transmute(model, scenario, structure = "proportional", quantity = "HR", cause, stage2 = hr_cox_stage2,
              stage3 = hr, stage3_lo = lo, stage3_hi = hi, stage3_source = "PEM by glm, Wald")
  per <- s3("stage3_e1_hr_by_period.csv") |>
    transmute(model, scenario, structure = "split at year 4", quantity = "HR", cause, period,
              stage3 = hr, stage3_lo = lo, stage3_hi = hi, stage3_source = "PEM by glm, Wald")
  cif <- s3("stage3_e1_cif.csv")
  cif_long <- bind_rows(
    cif |> transmute(model, scenario, structure = group_effect, quantity = "F", cause, group = "NCI", time = as.character(time),
                     stage3 = F_NCI, stage3_lo = F_NCI_lo, stage3_hi = F_NCI_hi),
    cif |> transmute(model, scenario, structure = group_effect, quantity = "F", cause, group = "CI", time = as.character(time),
                     stage3 = F_CI, stage3_lo = F_CI_lo, stage3_hi = F_CI_hi),
    cif |> transmute(model, scenario, structure = group_effect, quantity = "RD", cause, time = as.character(time),
                     stage3 = RD, stage3_lo = RD_lo, stage3_hi = RD_hi),
    cif |> transmute(model, scenario, structure = group_effect, quantity = "RR", cause, time = as.character(time),
                     stage3 = RR, stage3_lo = RR_lo, stage3_hi = RR_hi)) |>
    mutate(stage3_source = "PEM by glm, parametric bootstrap")
  tail <- s3("stage3_e1_tail.csv") |>
    transmute(model, scenario, quantity = "tail ratio", cause, group, stage3 = ratio, stage3_lo = ratio_lo, stage3_hi = ratio_hi,
              stage3_source = "crude rates of the life table") |>
    tidyr::crossing(structure = c("proportional", "split at year 4"))
  # P1 is centred at 1.55 for every outcome. Model 1 implies 1.56 and 1.50 for the two stroke outcomes but 1.88 for death, so
  # the P1 counterpart is the stage 3 theta_age nearest to 1.55 within the outcome (and ceiling): the implied value for the
  # strokes, the grid point 1.5 for death. Rows without theta_age (observed counts) are dropped.
  link <- function(d) bind_rows(d |> filter(!is.na(theta_age)) |> group_by(outcome, across(any_of("age_max"))) |>
                                  filter(abs(theta_age - 1.55) == min(abs(theta_age - 1.55))) |> ungroup() |>
                                  mutate(prior = "P1", at = if_else(is_implied, "the theta_age Model 1 implies", "the grid point nearest the P1 centre 1.55")),
                                d |> filter(!is_implied, theta_age == 2) |> mutate(prior = "P2", at = "theta_age = 2")) |>
    mutate(stage3_source = sprintf("fixed age effect, %s (%.2f)", at, theta_age), model = unname(key_model[outcome]))
  e2 <- s3("stage3_e2_profile.csv") |> link() |>
    transmute(model, prior, age_max = as.integer(age_max), quantity = "HR at given age and sex",
              stage3 = hr_ci, stage3_lo = hr_prof_lo, stage3_hi = hr_prof_hi, stage3_source = paste0(stage3_source, ", profile likelihood"))
  e3a <- s3("stage3_e3_age_equivalent.csv") |> link() |>
    transmute(model, prior, age_max = 90L, quantity = "age-equivalent, years", stage3 = estimate, stage3_lo = lo, stage3_hi = hi, stage3_source)
  e3b <- s3("stage3_e3_cindex.csv") |> link() |>
    transmute(model, prior, age_max = 90L, quantity, stage3 = estimate, stage3_lo = lo, stage3_hi = hi, stage3_source)
  e3c <- s3("stage3_e3_screening.csv") |> filter(source == "model, calibrated population", metric %in% METRICS) |> link() |>
    transmute(model, prior, age_max = 90L, quantity = metric, rule, stage3 = estimate, stage3_lo = lo, stage3_hi = hi, stage3_source)
  bind_rows(hr, per, cif_long, tail, e2, e3a, e3b, e3c)
}
JOIN_KEYS <- c("model", "scenario", "structure", "prior", "age_max", "quantity", "cause", "group", "time", "period", "rule")

if (!RUN_PRIOR) {
  cat("== S4 posterior runs\n")
  pem_suffix <- as.vector(outer(c("", "_early", "_late", "_bsd2", "_split", "_early_split", "_split_bsd2"), c("isch", "any"), \(v, o) paste0(o, v)))
  exp_suffix <- as.vector(outer(c("_P1", "_P2", "_P3", "_P2_amax80", "_P2_amax100"), names(OUTCOME_OF), \(v, o) paste0(o, v)))
  have <- function(model, suffix) length(list.files(file.path(fits_dir, model), pattern = sprintf("^%s_%s_[0-9]+\\.csv$", model, suffix))) > 0
  missing <- c(paste("pem_competing", pem_suffix)[!map_lgl(pem_suffix, \(s) have("pem_competing", s))],
               paste("exposure_age", exp_suffix)[!map_lgl(exp_suffix, \(s) have("exposure_age", s))])
  if (length(missing)) stop("runs missing on the archive disk (run_all.sh): ", paste(missing, collapse = "; "))
  res <- c(map(pem_suffix, post_pem), map(exp_suffix, post_exposure))
  conv <- map_dfr(res, "convergence")
  ppc <- map_dfr(res, "ppc") |>
    select(program, run, model, scenario, structure, beta_sd, prior, age_max, quantity, outcome, group, interval,
           observed = reference, q025, q25, q50, q75, q975, percentile, covers, share_guarded)
  est <- map_dfr(res, "est")
  for (k in setdiff(JOIN_KEYS, names(est))) est[[k]] <- NA_character_
  est <- est |> mutate(role = ifelse((program == "pem_competing" & scenario == "uniform" & beta_sd == 1) |
                                       (program == "exposure_age" & age_max == 90L), "planned", "sensitivity")) |>
    select(estimand, program, run, role, model, outcome, scenario, structure, beta_sd, prior, age_max, quantity, cause, group, time, period, rule,
           stage4_median, stage4_lo, stage4_hi, pr_gt_1) |>
    arrange(program != "pem_competing", estimand, model, run, quantity, cause, group, time, period, rule)
  # the paper's values: Table 2 unadjusted beside the proportional HR, Model 1 beside the HR at given age and sex
  paper <- bind_rows(
    t2 |> filter(group == "CI") |> transmute(outcome, quantity = "HR", structure = "proportional", paper = hr_unadj, paper_lo = hr_unadj_lo,
                                             paper_hi = hr_unadj_hi, paper_source = "Table 2, unadjusted Cox"),
    t2 |> filter(group == "CI") |> transmute(outcome, quantity = "HR at given age and sex", structure = NA_character_, paper = hr_m1,
                                             paper_lo = hr_m1_lo, paper_hi = hr_m1_hi, paper_source = "Table 2, Model 1 (age, gender, education)"))
  side <- est |>
    left_join(paper, by = c("outcome", "quantity", "structure")) |>
    left_join(stage3_rows(), by = JOIN_KEYS) |>
    mutate(ratio_4_over_3 = ifelse(quantity %in% c("RD", "age-equivalent, years", "c_gain"), NA_real_, stage4_median / stage3),
           diff_4_minus_3 = stage4_median - stage3) |>
    select(estimand, program, run, role, model, outcome, scenario, structure, beta_sd, prior, age_max, quantity, group, time, period, rule,
           paper, paper_lo, paper_hi, paper_source, stage2, stage3, stage3_lo, stage3_hi, stage3_source,
           stage4_median, stage4_lo, stage4_hi, pr_gt_1, ratio_4_over_3, diff_4_minus_3)
  stopifnot(nrow(side) == nrow(est))                       # the joins add columns, never rows
  write_csv(conv, file.path(out_tab, "stage4_convergence.csv"))
  write_csv(ppc, file.path(out_tab, "stage4_ppc.csv"))
  write_csv(est |> select(-cause), file.path(out_tab, "stage4_estimates.csv"))
  write_csv(side, file.path(out_tab, "stage4_side_by_side.csv"))

  # figure 1: posterior predictive cell counts of the planned runs, both structures
  cells <- ppc |> filter(program == "pem_competing", scenario == "uniform", beta_sd == 1) |>
    mutate(group = factor(group, GROUPS), interval = factor(interval, unique(interval)), panel = sprintf("%s\n%s", outcome, structure),
           row = sprintf("%s: %s", model, group))
  g1 <- ggplot(cells, aes(interval)) +
    geom_linerange(aes(ymin = q025, ymax = q975), colour = "grey55") +
    geom_linerange(aes(ymin = q25, ymax = q75), linewidth = 1.6, colour = "grey35") +
    geom_point(aes(y = observed, colour = covers), size = 2) +
    scale_colour_manual(values = c(`TRUE` = "#1b7837", `FALSE` = "#b2182b"), name = "observed within the posterior predictive 95 %") +
    scale_y_continuous(trans = scales::pseudo_log_trans(base = 10), breaks = c(0, 1, 3, 10, 30, 100)) +
    facet_grid(group ~ model + panel) +
    labs(x = "interval, years", y = "events in the cell", title = "pem_competing: posterior predictive cell counts",
         subtitle = "Bars: posterior predictive 50 % and 95 % intervals; points: the life table (uniform person-years)") +
    theme_minimal(base_size = 9) + theme(legend.position = "bottom", axis.text.x = element_text(angle = 30, hjust = 1))
  ggsave(file.path(out_fig, "stage4_ppc_pem.png"), g1, width = 13, height = 5.5, dpi = 150, bg = "white")

  # figure 2: the exposure HR at given age and sex under the three priors, with the stage 3 value it is set beside
  e2 <- side |> filter(quantity == "HR at given age and sex", age_max == 90L) |>
    mutate(outcome = factor(outcome, unname(OUTCOME_OF)))
  e2_long <- bind_rows(
    e2 |> transmute(outcome, prior, source = "stage 4, posterior median and 95 %", y = stage4_median, lo = stage4_lo, hi = stage4_hi),
    e2 |> filter(!is.na(stage3)) |> transmute(outcome, prior, source = "stage 3, age effect fixed, profile 95 %", y = stage3, lo = stage3_lo, hi = stage3_hi))
  g2 <- ggplot(e2_long, aes(prior, y, colour = source)) +
    geom_hline(yintercept = 1, colour = "grey40") +
    geom_hline(data = e2 |> distinct(outcome, paper), aes(yintercept = paper), linetype = 2, colour = "grey40") +
    geom_pointrange(aes(ymin = lo, ymax = hi), position = position_dodge(width = 0.4)) +
    scale_y_log10(breaks = c(0.5, 0.75, 1, 1.5, 2, 3, 4, 6)) +
    scale_colour_manual(values = c("stage 4, posterior median and 95 %" = "#2166ac", "stage 3, age effect fixed, profile 95 %" = "grey45"), name = NULL) +
    facet_wrap(~ outcome) +
    labs(x = "prior on the age effect (P1 as Model 1 implies, P2 doubling per decade, P3 unknown between 1 and 3)",
         y = "hazard ratio, MMSE < 24, at given age and sex",
         title = "exposure_age: the adjusted hazard ratio under three priors on the age effect",
         subtitle = "Dashed: the paper's Model 1 hazard ratio; solid: no association") +
    theme_minimal(base_size = 9) + theme(legend.position = "bottom")
  ggsave(file.path(out_fig, "stage4_hr_by_prior.png"), g2, width = 9, height = 4.5, dpi = 150, bg = "white")

  options(width = 230)
  sg <- \(d) d |> mutate(across(where(is.numeric), \(x) signif(x, 3)))
  cat("\n-- sampler (plan §5 thresholds)\n"); print(conv |> sg(), n = Inf)
  cat("\n-- posterior predictive counts outside the 95 % interval\n")
  print(ppc |> filter(!covers) |> sg() |> select(program, run, outcome, group, interval, observed, q025, q50, q975, percentile), n = Inf)
  show <- function(d) print(d |> sg() |> select(run, outcome, quantity, group, time, period, rule, paper, stage2, stage3, stage3_lo, stage3_hi,
                                                 stage4_median, stage4_lo, stage4_hi, pr_gt_1, ratio_4_over_3), n = Inf)
  cat("\n-- E1b, E1c: hazard ratios, all pem runs\n"); show(side |> filter(quantity == "HR"))
  cat("\n-- E1: cumulative incidence, RD, RR (planned runs and the early scenario)\n")
  show(side |> filter(estimand == "E1", scenario %in% c("uniform", "early"), beta_sd == 1))
  cat("\n-- E1c: tail ratios (planned runs)\n"); show(side |> filter(quantity == "tail ratio", role == "planned"))
  cat("\n-- E2: the exposure HR and the age effect, all exposure runs\n")
  show(side |> filter(estimand == "E2", quantity %in% c("HR at given age and sex", "hazard multiplier per decade of age")))
  cat("\n-- E3: age-equivalent, c-index, screening metrics (ceiling 90)\n"); show(side |> filter(estimand %in% c("E3a", "E3b", "E3c"), age_max == 90L))
  cat(sprintf("\nruns passing the sampler thresholds: %d of %d; posterior predictive counts within the 95 %%: %d of %d; rows with a stage 3 counterpart: %d of %d\n",
              sum(conv$passes), nrow(conv), sum(ppc$covers), nrow(ppc), sum(!is.na(side$stage3)), nrow(side)))
  cat("written: output/tables/stage4_convergence.csv, stage4_ppc.csv, stage4_estimates.csv, stage4_side_by_side.csv;",
      "output/figures/stage4_ppc_pem.png, stage4_hr_by_prior.png\n")
}
