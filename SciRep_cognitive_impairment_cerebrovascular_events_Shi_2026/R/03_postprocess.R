# 03_postprocess.R — Shi et al. 2026, Sci Rep (P002), stage 4 post-processing (plan notes/04_analysis_plan.md §5, §8)
#
# Reads the CmdStan CSV draws that run_model.sh writes to $FITS_DIR/<article>/<model>/, computes diagnostics and
# summaries, and writes SMALL tables and figures to output/. Never copies draws into the project tree. R is for
# post-processing only: nothing is fitted from R (cmdstanr::read_cmdstan_csv reads the files).
# Usage (repo root, inside nix-shell):
#   Rscript <art>/R/03_postprocess.R --prior    S3: prior predictive of the two programs against the life table and Table 2,
#                                               sampler diagnostics of the prior runs, and the mapping checks (the generated
#                                               quantities of each program recomputed in R from its parameter draws)
#   Rscript <art>/R/03_postprocess.R            S4: posteriors, diagnostics, posterior predictive, stage 3 vs 4 (not written yet)
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
suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(readr); library(purrr); library(stringr); library(ggplot2); library(posterior)
})
ART <- "SciRep_cognitive_impairment_cerebrovascular_events_Shi_2026"
here_art <- function(...) here::here(ART, ...)

args <- commandArgs(trailingOnly = TRUE)
if (!all(args %in% c("--prior"))) stop("unknown argument(s): ", paste(setdiff(args, "--prior"), collapse = " "))
RUN_PRIOR <- "--prior" %in% args
if (!RUN_PRIOR) stop("only --prior is written so far (S3); the main section is S4 of plan §8")

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
