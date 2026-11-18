# Stage 4 post-processing (plan §5, §8). Reads the CmdStan CSV draws that run_model.sh writes to
# $FITS_DIR/<article>/<model>/, computes diagnostics and summaries, and writes SMALL tables and figures to
# output/. Never copies draws into the project tree. R is for post-processing only, no fitting from R (CLAUDE.md).
# Usage (repo root, inside nix-shell):
#   Rscript <art>/R/03_postprocess.R --prior     S5: prior predictive of the seven models vs Table 2 / the example data
#   Rscript <art>/R/03_postprocess.R --example   S6: mapping check of the posterior runs on the example replicate against glmmTMB (S2/S4 tables)
#   Rscript <art>/R/03_postprocess.R --collect   S7: sampler diagnostics of every run on the archive disk, plan §5 thresholds
#   Rscript <art>/R/03_postprocess.R             S8: pooled posteriors over the 30 replicates, posterior predictive checks, LOO, stage 3 vs 4
suppressPackageStartupMessages({ library(tidyverse); library(posterior); library(jsonlite) })
here_art <- function(...) here::here("SciRep_emotions_in_working_donkeys_Bukhari_2026", ...)

args <- commandArgs(trailingOnly = TRUE)
allowed <- c("--prior", "--example", "--collect", "--cores")
opt_cores <- match("--cores", args); if (!is.na(opt_cores)) allowed <- c(allowed, args[opt_cores + 1])
if (!all(args %in% allowed)) stop("unknown argument(s): ", paste(setdiff(args, allowed), collapse = " "))
RUN_PRIOR   <- "--prior" %in% args
RUN_EXAMPLE <- "--example" %in% args
RUN_COLLECT <- "--collect" %in% args
RUN_MAIN    <- !any(RUN_PRIOR, RUN_EXAMPLE, RUN_COLLECT)
N_CORES <- if (is.na(opt_cores)) max(1L, parallel::detectCores() - 2L) else as.integer(args[opt_cores + 1])

stopifnot("FITS_DIR not set: run inside nix-shell" = nzchar(Sys.getenv("FITS_DIR")))
fits_dir <- file.path(Sys.getenv("FITS_DIR"), "SciRep_emotions_in_working_donkeys_Bukhari_2026")
stopifnot("archive disk not mounted" = dir.exists(fits_dir))
out_tab <- here_art("output/tables"); out_fig <- here_art("output/figures")
stan_data <- here_art("data/derived/stan_data")

COND_NAMES <- c("control", "positive", "negative")      # cond 1, 2, 3 (R/01_prepare_data.R)
TRT_NAMES  <- c("negative", "positive")                 # trt 1, 2
MODELS <- tribble(
  ~model,                 ~outcome, ~role,                          ~default_data,
  "sbr_nb2",              "SBR",    "planned",                      "cond_sbr_rho0_rep01",
  "sbr_poisson",          "SBR",    "sensitivity iii",              "cond_sbr_rho0_rep01",
  "et_mvn",               "ET",     "planned",                      "cond_et_rho0_rep01",
  "et_normal",            "ET",     "sensitivity ii'",              "cond_et_rho0_rep01",
  "rmssd_lognormal_mvn",  "RMSSD",  "planned",                      "cond_rmssd_rho0_rep01",
  "rmssd_gamma",          "RMSSD",  "sensitivity ii",               "cond_rmssd_rho0_rep01",
  "delta_slopes",         "E4",     "planned (x = dSBR by default)", "delta_sbr_rho0_rep01")
suffix_of <- function(data_name) sub("^cond_(sbr|et|rmssd)_|^delta_", "", data_name)
table2 <- read_csv(here_art("data/raw/table2_conditions.csv"), show_col_types = FALSE)
table2_changes <- read_csv(here_art("data/raw/table2_changes.csv"), show_col_types = FALSE)   # unsigned changes, mean and SD per treatment

# ---- reading draws (cmdstanr::read_cmdstan_csv reads the files; nothing is fitted from R) --------
read_run <- function(model, suffix) {
  dir <- file.path(fits_dir, model)
  files <- list.files(dir, pattern = sprintf("^%s_%s_[0-9]+\\.csv$", model, suffix), full.names = TRUE)
  if (length(files) == 0) stop("no draws for ", model, " [", suffix, "] in ", dir, ": run run_model.sh first")
  cs <- cmdstanr::read_cmdstan_csv(files, format = "draws_df")
  list(draws = cs$post_warmup_draws, sampler = cs$post_warmup_sampler_diagnostics, n_chains = length(files))
}
# plan §5 thresholds: R-hat < 1.01, bulk and tail ESS > 400, no divergences, E-BFMI > 0.3 (per chain: mean squared
# energy increment over the energy variance); treedepth saturations are counted as well
convergence <- function(run, exclude = c("y_rep", "log_lik")) {
  keep <- setdiff(variables(run$draws), grep(paste(exclude, collapse = "|"), variables(run$draws), value = TRUE))
  s <- summarise_draws(subset_draws(run$draws, variable = keep), "rhat", "ess_bulk", "ess_tail")
  sd_df <- as_draws_df(run$sampler)
  ebfmi <- sd_df |> group_by(.chain) |> summarise(e = mean(diff(energy__)^2) / var(energy__), .groups = "drop")
  tibble(n_draws = ndraws(run$draws), max_rhat = max(s$rhat, na.rm = TRUE), min_ess_bulk = min(s$ess_bulk, na.rm = TRUE),
         min_ess_tail = min(s$ess_tail, na.rm = TRUE), divergences = sum(sd_df$divergent__),
         max_treedepth_hits = sum(sd_df$treedepth__ >= 10), min_ebfmi = min(ebfmi$e),
         passes = max_rhat < 1.01 & min_ess_bulk > 400 & min_ess_tail > 400 & divergences == 0 & min_ebfmi > 0.3)
}
yrep_matrix <- function(run, guarded = FALSE) {
  m <- as_draws_matrix(subset_draws(run$draws, variable = "y_rep"))
  m <- m[, order(as.integer(sub("^y_rep\\[(\\d+)\\]$", "\\1", colnames(m))))]
  share_guarded <- if (guarded) mean(m < 0) else 0
  if (guarded) m[m < 0] <- NA                       # SBR programs mark cells whose rng would overflow with -1
  list(m = m, share_guarded = share_guarded)
}
qtab <- function(x) tibble(q025 = quantile(x, 0.025, na.rm = TRUE), q25 = quantile(x, 0.25, na.rm = TRUE),
                           q50 = median(x, na.rm = TRUE), q75 = quantile(x, 0.75, na.rm = TRUE), q975 = quantile(x, 0.975, na.rm = TRUE))

# ---- S5: prior predictive (plan §5: condition means and SDs must cover the Table 2 ranges without concentrating on them)
prior_predictive_condition <- function(model, outcome, data_name) {
  run <- read_run(model, paste0(suffix_of(data_name), "_prior"))
  dat <- read_json(file.path(stan_data, paste0(data_name, ".json")), simplifyVector = TRUE)
  yr  <- yrep_matrix(run, guarded = outcome == "SBR")
  ref <- table2 |> filter(outcome == .env$outcome) |> select(condition, mean, sd)
  stats <- map_dfr(1:3, function(c) {
    sub <- yr$m[, dat$cond == c, drop = FALSE]
    bind_rows(tibble(statistic = "mean", value = rowMeans(sub, na.rm = TRUE)),
              tibble(statistic = "sd",   value = apply(sub, 1, sd, na.rm = TRUE))) |>
      mutate(condition = COND_NAMES[c], .before = 1)
  })
  summ <- stats |> group_by(condition, statistic) |> summarise(qtab(value), .groups = "drop") |>
    left_join(ref |> pivot_longer(c(mean, sd), names_to = "statistic", values_to = "reference"), by = c("condition", "statistic")) |>
    rowwise() |>
    mutate(percentile = mean(stats$value[stats$condition == condition & stats$statistic == statistic] < reference, na.rm = TRUE)) |>
    ungroup() |>
    group_by(statistic) |> mutate(reference_range = max(reference) - min(reference)) |> ungroup() |>
    mutate(model = model, outcome = outcome, reference_source = "Table 2", share_guarded = yr$share_guarded,
           iqr = q75 - q25, iqr_over_reference_range = iqr / reference_range,
           covers = percentile >= 0.025 & percentile <= 0.975)
  list(summary = summ, draws = stats |> mutate(model = model, outcome = outcome), convergence = convergence(run) |> mutate(model = model))
}
prior_predictive_e4 <- function(model, data_name) {
  run <- read_run(model, paste0(suffix_of(data_name), "_prior"))
  dat <- read_json(file.path(stan_data, paste0(data_name, ".json")), simplifyVector = TRUE)
  x_name <- if (grepl("^delta_sbr", data_name)) "dSBR" else "dET"
  yr <- yrep_matrix(run)$m
  b  <- as_draws_matrix(subset_draws(run$draws, variable = "b"))
  stats <- map_dfr(1:2, function(t) {
    sel <- dat$trt == t
    bind_rows(tibble(statistic = "sd of dRMSSD", value = apply(yr[, sel, drop = FALSE], 1, sd)),
              tibble(statistic = "slope b",      value = as.numeric(b[, t])),
              tibble(statistic = "mean dRMSSD",  value = rowMeans(yr[, sel, drop = FALSE]))) |>
      mutate(condition = TRT_NAMES[t], .before = 1)
  })
  ref <- map_dfr(1:2, function(t) {
    sel <- dat$trt == t
    tibble(condition = TRT_NAMES[t], statistic = c("sd of dRMSSD", "slope b", "mean dRMSSD"),
           reference = c(sd(dat$y[sel]), cov(dat$x[sel], dat$y[sel]) / var(dat$x[sel]), mean(dat$y[sel])))
  })
  summ <- stats |> group_by(condition, statistic) |> summarise(qtab(value), .groups = "drop") |>
    left_join(ref, by = c("condition", "statistic")) |>
    rowwise() |>
    mutate(percentile = mean(stats$value[stats$condition == condition & stats$statistic == statistic] < reference)) |>
    ungroup() |>
    group_by(statistic) |> mutate(reference_range = max(abs(reference))) |> ungroup() |>   # one x only: scale by the larger |reference|
    mutate(model = model, outcome = paste0("E4 (x = ", x_name, ")"), reference_source = "example replicate (OLS, sample SD)",
           share_guarded = 0, iqr = q75 - q25, iqr_over_reference_range = iqr / reference_range,
           covers = percentile >= 0.025 & percentile <= 0.975)
  list(summary = summ, draws = stats |> mutate(model = model, outcome = paste0("E4 (x = ", x_name, ")")),
       convergence = convergence(run) |> mutate(model = model))
}
plot_prior_predictive <- function(draws, summ, file) {
  trimmed <- draws |> group_by(model, condition, statistic) |>
    filter(value > quantile(value, 0.005, na.rm = TRUE), value < quantile(value, 0.995, na.rm = TRUE)) |> ungroup()
  g <- ggplot(trimmed, aes(value, colour = condition)) +
    geom_density(na.rm = TRUE) +
    geom_vline(data = summ, aes(xintercept = reference, colour = condition), linetype = 2) +
    facet_wrap(~ model + statistic, scales = "free", ncol = 4) +
    labs(x = NULL, y = "prior predictive density", colour = NULL,
         title = "Prior predictive condition means and SDs (densities trimmed to the central 99 %)",
         subtitle = "Dashed: Table 2 values (condition models) or the example replicate (E4)") +
    theme_minimal(base_size = 9) + theme(legend.position = "bottom")
  ggsave(file, g, width = 12, height = 9, dpi = 150)
}

if (RUN_PRIOR) {
  cat("== S5 prior predictive\n")
  res <- pmap(MODELS, function(model, outcome, role, default_data) {
    if (model == "delta_slopes") prior_predictive_e4(model, default_data) else prior_predictive_condition(model, outcome, default_data)
  })
  summ <- map_dfr(res, "summary") |> left_join(MODELS |> select(model, role), by = "model") |>
    select(model, role, outcome, condition, statistic, reference, reference_source, q025, q25, q50, q75, q975,
           percentile, covers, iqr, iqr_over_reference_range, share_guarded)
  conv <- map_dfr(res, "convergence") |> select(model, everything())
  write_csv(summ, file.path(out_tab, "stage4_prior_predictive.csv"))
  write_csv(conv, file.path(out_tab, "stage4_prior_convergence.csv"))
  plot_prior_predictive(map_dfr(res, "draws"), summ, file.path(out_fig, "stage4_prior_predictive.png"))
  options(width = 200)
  cat("\n-- sampler (prior runs)\n"); print(conv)
  cat("\n-- prior predictive vs reference (percentile = share of prior draws below the reference; covers = within 2.5-97.5 %)\n")
  print(summ |> mutate(across(c(reference, q025, q50, q975, percentile, iqr_over_reference_range), ~ signif(.x, 3))) |>
          select(model, outcome, condition, statistic, reference, q025, q50, q975, percentile, covers, iqr_over_reference_range, share_guarded), n = Inf)
  cat("\nwritten: output/tables/stage4_prior_predictive.csv, stage4_prior_convergence.csv; output/figures/stage4_prior_predictive.png\n")
}

# ---- S6: mapping check on the example replicate (plan §8: posterior medians within 1 SE of the glmmTMB estimates of
# S2/S4, no divergences, R-hat < 1.01). One row per stage 3 quantity, matched by the exact term/scale strings of
# stage3_example_estimands.csv and stage3_example_e4.csv. The stage 3 SBR fit on the example is the Poisson (phi not
# identified), so both sbr_nb2 and sbr_poisson are compared with it. The sensitivity models et_normal and rmssd_gamma
# are compared on E1 only, with the corresponding rows of stage3_example_model_comparison.csv.
MAP_COND <- tribble(
  ~outcome, ~term,                                         ~scale,                               ~stan_var,
  "SBR",   "positive - control",                           "link",                               "b_cond[1]",
  "SBR",   "negative - control",                           "link",                               "b_cond[2]",
  "SBR",   "positive - negative",                          "link",                               "lr_pos_neg",
  "SBR",   "order 2 - 1",                                  "link",                               "b_ord[1]",
  "SBR",   "order 3 - 1",                                  "link",                               "b_ord[2]",
  "SBR",   "positive / control",                           "ratio",                              "rr_pos",
  "SBR",   "negative / control",                           "ratio",                              "rr_neg",
  "SBR",   "positive / negative",                          "ratio",                              "rr_pos_neg",
  "SBR",   "positive - control",                           "difference (blinks/min)",            "diff_pos",
  "SBR",   "negative - control",                           "difference (blinks/min)",            "diff_neg",
  "SBR",   "positive - negative",                          "difference (blinks/min)",            "diff_pos_neg",
  "SBR",   "mean control",                                 "response, u = 0",                    "mu_c[1]",
  "SBR",   "mean positive",                                "response, u = 0",                    "mu_c[2]",
  "SBR",   "mean negative",                                "response, u = 0",                    "mu_c[3]",
  "SBR",   "tau (donkey SD, link scale)",                  "link",                               "tau",
  "SBR",   "sigma_latent (residual SD, link scale)",       "link",                               "sigma_latent",
  "SBR",   "ICC (latent)",                                 "link",                               "icc",
  "ET",    "positive - control",                           "link",                               "b_cond[1]",
  "ET",    "negative - control",                           "link",                               "b_cond[2]",
  "ET",    "positive - negative",                          "link",                               "diff_pos_neg",
  "ET",    "order 2 - 1",                                  "link",                               "b_ord[1]",
  "ET",    "order 3 - 1",                                  "link",                               "b_ord[2]",
  "ET",    "mean control",                                 "response",                           "eta_c[1]",
  "ET",    "mean positive",                                "response",                           "eta_c[2]",
  "ET",    "mean negative",                                "response",                           "eta_c[3]",
  "ET",    "sigma control (donkey-level SD, link scale)",  "link",                               "sigma[1]",
  "ET",    "sigma positive (donkey-level SD, link scale)", "link",                               "sigma[2]",
  "ET",    "sigma negative (donkey-level SD, link scale)", "link",                               "sigma[3]",
  "ET",    "corr(control, positive)",                      "link",                               "rho_cp",
  "ET",    "corr(control, negative)",                      "link",                               "rho_cn",
  "ET",    "corr(positive, negative)",                     "link",                               "rho_pn",
  "ET",    "positive - control",                           "difference (degC)",                  "diff_pos",
  "ET",    "negative - control",                           "difference (degC)",                  "diff_neg",
  "ET",    "positive - negative",                          "difference (degC)",                  "diff_pos_neg",
  "RMSSD", "positive - control",                           "link",                               "lr_pos",
  "RMSSD", "negative - control",                           "link",                               "lr_neg",
  "RMSSD", "positive - negative",                          "link",                               "lr_pos_neg",
  "RMSSD", "order 2 - 1",                                  "link",                               "b_ord[1]",
  "RMSSD", "order 3 - 1",                                  "link",                               "b_ord[2]",
  "RMSSD", "mean control",                                 "response, u = 0 (median donkey)",    "med_c[1]",
  "RMSSD", "mean positive",                                "response, u = 0 (median donkey)",    "med_c[2]",
  "RMSSD", "mean negative",                                "response, u = 0 (median donkey)",    "med_c[3]",
  "RMSSD", "sigma control (donkey-level SD, link scale)",  "link",                               "sigma[1]",
  "RMSSD", "sigma positive (donkey-level SD, link scale)", "link",                               "sigma[2]",
  "RMSSD", "sigma negative (donkey-level SD, link scale)", "link",                               "sigma[3]",
  "RMSSD", "corr(control, positive)",                      "link",                               "rho_cp",
  "RMSSD", "corr(control, negative)",                      "link",                               "rho_cn",
  "RMSSD", "corr(positive, negative)",                     "link",                               "rho_pn",
  "RMSSD", "positive - control",                           "ratio (marginal, arithmetic means)", "ratio_pos",
  "RMSSD", "negative - control",                           "ratio (marginal, arithmetic means)", "ratio_neg",
  "RMSSD", "positive - negative",                          "ratio (marginal, arithmetic means)", "ratio_pos_neg",
  "RMSSD", "positive - control",                           "difference (ms, marginal)",          "diff_pos",
  "RMSSD", "negative - control",                           "difference (ms, marginal)",          "diff_neg",
  "RMSSD", "positive - negative",                          "difference (ms, marginal)",          "diff_pos_neg",
  "RMSSD", "mean control",                                 "response, marginal",                 "m_c[1]",
  "RMSSD", "mean positive",                                "response, marginal",                 "m_c[2]",
  "RMSSD", "mean negative",                                "response, marginal",                 "m_c[3]",
  "RMSSD", "positive - control",                           "ratio (conditional, median donkey)", "ratio_med_pos",
  "RMSSD", "negative - control",                           "ratio (conditional, median donkey)", "ratio_med_neg",
  "RMSSD", "positive - negative",                          "ratio (conditional, median donkey)", "ratio_med_pos_neg")
MAP_E4 <- tribble(
  ~quantity,                          ~treatment,            ~stan_var,
  "a (intercept at x = 0)",           "negative",            "a[1]",
  "a (intercept at x = 0)",           "positive",            "a[2]",
  "b (slope)",                        "negative",            "b[1]",
  "b (slope)",                        "positive",            "b[2]",
  "b positive - b negative",          "positive - negative", "b_diff",
  "s (residual SD)",                  "negative",            "s[1]",
  "s (residual SD)",                  "positive",            "s[2]",
  "r (within-treatment correlation)", "negative",            "r[1]",
  "r (within-treatment correlation)", "positive",            "r[2]")
# E1 columns of the model-comparison table for the sensitivity models (ET: degC differences; RMSSD, SBR: ratios)
MAP_SENS <- tribble(
  ~model,         ~outcome, ~cmp_model,                                                            ~var_pos,    ~var_neg,
  "et_normal",    "ET",     "Gaussian, donkey intercept, sigma by condition (v1.0)",               "diff_pos",  "diff_neg",
  "rmssd_gamma",  "RMSSD",  "Gamma(log), donkey intercept, alpha by condition (v1.0; sens. ii)",   "ratio_pos", "ratio_neg")

post_summary <- function(draws, vars)
  summarise_draws(subset_draws(draws, variable = vars), median, sd, ~ quantile2(.x, probs = c(0.025, 0.975))) |>
  rename(stan_var = variable, post_median = median, post_sd = sd, post_q025 = q2.5, post_q975 = q97.5)
finish_map <- function(tb) tb |>
  mutate(diff = post_median - glmmtmb, diff_in_se = diff / se, within_1se = abs(diff_in_se) <= 1,
         width_ratio = (post_q975 - post_q025) / (s3_ci_high - s3_ci_low)) |>
  select(model, outcome, term, scale, stan_var, glmmtmb, se, s3_ci_low, s3_ci_high, post_median, post_sd, post_q025, post_q975,
         diff, diff_in_se, within_1se, width_ratio)
mapping_condition <- function(model, outcome, stage3, suffix = "rho0_rep01") {
  run <- read_run(model, suffix)
  d <- run$draws
  if (outcome == "SBR") d <- mutate_variables(d, lr_pos_neg = `b_cond[1]` - `b_cond[2]`, sigma_latent = sqrt(sigma2_latent))
  map <- MAP_COND |> filter(outcome == .env$outcome)
  s3  <- stage3 |> filter(outcome == .env$outcome) |> select(outcome, term, scale, glmmtmb = estimate, se, s3_ci_low = ci_low, s3_ci_high = ci_high)
  tb <- map |> left_join(s3, by = c("outcome", "term", "scale")) |> left_join(post_summary(d, map$stan_var), by = "stan_var") |>
    mutate(model = model)
  list(map = finish_map(tb), convergence = convergence(run) |> mutate(model = model, run = suffix, .before = 1))
}
mapping_e4 <- function(x_name, stage3_e4) {
  suffix <- paste0(tolower(sub("^d", "", x_name)), "_rho0_rep01")
  run <- read_run("delta_slopes", suffix)
  s3  <- stage3_e4 |> filter(x_name == .env$x_name) |> select(quantity, treatment, glmmtmb = estimate, se, s3_ci_low = ci_low, s3_ci_high = ci_high)
  tb <- MAP_E4 |> left_join(s3, by = c("quantity", "treatment")) |> left_join(post_summary(run$draws, MAP_E4$stan_var), by = "stan_var") |>
    mutate(model = "delta_slopes", outcome = paste0("E4 (x = ", x_name, ")"), term = paste(quantity, treatment, sep = ", "), scale = "response")
  list(map = finish_map(tb), convergence = convergence(run) |> mutate(model = "delta_slopes", run = suffix, .before = 1))
}
mapping_sensitivity <- function(model, outcome, cmp_model, var_pos, var_neg, stage3_cmp, suffix = "rho0_rep01") {
  run <- read_run(model, suffix)
  cmp <- stage3_cmp |> filter(outcome == .env$outcome, model == cmp_model)
  stopifnot(nrow(cmp) == 1)
  tb <- tibble(model = model, outcome = outcome, term = c("positive - control", "negative - control"),
               scale = "E1 of stage3_example_model_comparison.csv", stan_var = c(var_pos, var_neg),
               glmmtmb = c(cmp$e1_positive, cmp$e1_negative), se = NA_real_, s3_ci_low = NA_real_, s3_ci_high = NA_real_) |>
    left_join(post_summary(run$draws, c(var_pos, var_neg)), by = "stan_var")
  list(map = finish_map(tb), convergence = convergence(run) |> mutate(model = model, run = suffix, .before = 1))
}

if (RUN_EXAMPLE) {
  cat("== S6 mapping check on the example replicate (rho_dd = 0, rep 1)\n")
  stage3     <- read_csv(here_art("output/tables/stage3_example_estimands.csv"), show_col_types = FALSE)
  stage3_e4  <- read_csv(here_art("output/tables/stage3_example_e4.csv"), show_col_types = FALSE)
  stage3_cmp <- read_csv(here_art("output/tables/stage3_example_model_comparison.csv"), show_col_types = FALSE)
  res <- c(list(mapping_condition("sbr_nb2", "SBR", stage3), mapping_condition("sbr_poisson", "SBR", stage3),
                mapping_condition("et_mvn", "ET", stage3), mapping_condition("rmssd_lognormal_mvn", "RMSSD", stage3),
                mapping_e4("dSBR", stage3_e4), mapping_e4("dET", stage3_e4)),
           pmap(MAP_SENS, mapping_sensitivity, stage3_cmp = stage3_cmp))
  map  <- map_dfr(res, "map")
  conv <- map_dfr(res, "convergence")
  write_csv(map,  file.path(out_tab, "stage4_example_mapping.csv"))
  write_csv(conv, file.path(out_tab, "stage4_example_convergence.csv"))
  options(width = 220)
  cat("\n-- sampler diagnostics (plan §5 thresholds; passes = all met)\n"); print(conv, n = Inf)
  cat("\n-- posterior median vs glmmTMB (diff_in_se = difference / glmmTMB SE; width_ratio = posterior 95 % / Wald 95 %)\n")
  print(map |> mutate(across(c(glmmtmb, post_median, diff, diff_in_se, width_ratio), ~ signif(.x, 3))) |>
          select(model, outcome, term, scale, glmmtmb, post_median, diff, diff_in_se, within_1se, width_ratio), n = Inf)
  cat("\n-- summary per model\n")
  print(map |> group_by(model, outcome) |> summarise(n = n(), n_with_se = sum(!is.na(se)), n_within_1se = sum(within_1se, na.rm = TRUE),
                                                     max_abs_diff_in_se = if (any(!is.na(diff_in_se))) max(abs(diff_in_se), na.rm = TRUE) else NA_real_,
                                                     median_width_ratio = median(width_ratio, na.rm = TRUE), .groups = "drop"))
  cat("\nwritten: output/tables/stage4_example_mapping.csv, stage4_example_convergence.csv\n")
}

# ---- S7: sampler diagnostics of every run (plan §8: every run passes the §5 thresholds or is listed) -----------
# A run is a set of chain files <model>_<suffix>_<chain>.csv next to a <model>_<suffix>_diagnose.txt. The suffix encodes
# the data file and the switches: [sbr_|et_]<scenario>_rep<k>[_prior][_ps<scale>][_pooled].
list_runs <- function() {
  map_dfr(list.dirs(fits_dir, recursive = FALSE), function(dir) {
    model <- basename(dir)
    dg <- list.files(dir, pattern = paste0("^", model, "_.*_diagnose\\.txt$"))
    if (length(dg) == 0) return(NULL)
    tibble(model = model, suffix = sub(paste0("^", model, "_(.*)_diagnose\\.txt$"), "\\1", dg))
  }) |>
    filter(!grepl("_prior($|_)", suffix)) |>
    mutate(x_name     = if_else(model == "delta_slopes", paste0("d", toupper(sub("_.*$", "", suffix))), NA_character_),
           scenario   = str_extract(suffix, "rhom05|rho0|rhop05"),
           rho_dd     = c(rhom05 = -0.5, rho0 = 0, rhop05 = 0.5)[scenario],
           rep        = as.integer(str_extract(suffix, "(?<=_rep)\\d+")),
           prior_scale = coalesce(as.numeric(str_extract(suffix, "(?<=_ps)[0-9.]+")), 1),
           pooled     = grepl("_pooled", suffix))
}
if (RUN_COLLECT) {
  cat("== S7 sampler diagnostics of every run in", fits_dir, "\n")
  runs <- list_runs()
  cat(nrow(runs), "runs found\n")
  conv <- parallel::mclapply(seq_len(nrow(runs)), function(i) {
    r <- runs[i, ]
    tryCatch(convergence(read_run(r$model, r$suffix)) |> mutate(model = r$model, suffix = r$suffix, .before = 1),
             error = function(e) tibble(model = r$model, suffix = r$suffix, error = conditionMessage(e)))
  }, mc.cores = N_CORES) |> list_rbind()
  out <- runs |> left_join(conv, by = c("model", "suffix")) |>
    arrange(model, prior_scale, pooled, rho_dd, rep)
  write_csv(out, file.path(out_tab, "stage4_runs_convergence.csv"))
  options(width = 220)
  cat("\n-- runs per model and setting; share passing the plan §5 thresholds\n")
  print(out |> group_by(model, x_name, prior_scale, pooled) |>
          summarise(n = n(), share_passes = mean(passes, na.rm = TRUE), max_rhat = max(max_rhat, na.rm = TRUE),
                    min_ess_bulk = min(min_ess_bulk, na.rm = TRUE), min_ess_tail = min(min_ess_tail, na.rm = TRUE),
                    runs_with_divergences = sum(divergences > 0, na.rm = TRUE), total_divergences = sum(divergences, na.rm = TRUE),
                    min_ebfmi = min(min_ebfmi, na.rm = TRUE), .groups = "drop"), n = Inf)
  fails <- out |> filter(is.na(passes) | !passes)
  cat("\n-- runs not passing:", nrow(fails), "\n")
  if (nrow(fails) > 0) print(fails |> select(model, suffix, max_rhat, min_ess_bulk, min_ess_tail, divergences, min_ebfmi, any_of("error")), n = Inf)
  cat("\nwritten: output/tables/stage4_runs_convergence.csv\n")
}

# ---- S8: pooled posteriors over the 30 replicates, posterior predictive checks, LOO, side by side with stage 3 ----
# One pass over the runs on the archive disk (prior-only runs excluded), grouped by model × setting × scenario, 10
# replicates per group. Per run: the quantities of MAP_COND / MAP_E4 (the stage 3 term/scale strings, so the join with
# the stage 3 tables is exact), the posterior predictive statistics against the run's own data and Table 2, and the
# leave-one-donkey-out elpd (loo). Pooling over the replicates of a scenario stacks the draws of the 10 runs: the
# posterior under a mixture of reconstructions, the Bayesian analogue of the Rubin pooling of stage 3; the median and
# 2.5–97.5 % of the stack are reported with the within-replicate posterior SD and the between-replicate SD of the medians.
# Sensitivity settings (prior scale, pooled sigma, programs ii/ii'/iii) are summarised for E1, E2 and the means only
# (plan §5: "E1–E2 re-reported under each"); E3 labels of MAP_COND do not apply to the shared-intercept programs.
K_STAN <- 10L
FIG2_RMSSD_POSITIVE_WHISKER <- 132   # ms, Fig. 2C upper whisker of the positive condition, rough read (notes/01_reading_notes.md, Fig. 2 entry)
PRIMARY_SCALE <- c(SBR = "ratio", ET = "difference (degC)", RMSSD = "ratio (marginal, arithmetic means)")
estimand_of <- function(term) case_when(grepl("^mean ", term) ~ "mean",
                                        grepl("^order|^corr|^sigma|^tau|^ICC", term) ~ "E3",
                                        grepl("positive [-/] negative", term) ~ "E2",   # §1: E2 whatever the stage 3 label says
                                        TRUE ~ "E1")
is_full_setting <- function(model, prior_scale, pooled) grepl("^planned", MODELS$role[match(model, MODELS$model)]) & prior_scale == 1 & !pooled
data_name_of <- function(model, suffix) {
  base <- sub("_ps[0-9.]+|_pooled", "", suffix)
  if (model == "delta_slopes") paste0("delta_", base) else paste0("cond_", tolower(MODELS$outcome[match(model, MODELS$model)]), "_", base)
}
row_sd <- function(X) { J <- ncol(X); sqrt(rowSums((X - rowMeans(X))^2) / (J - 1)) }
pctl <- function(pred, obs) mean(pred < obs) + 0.5 * mean(pred == obs)   # percentile of the observed statistic in the predictive

# statistics of the three condition vectors (list of D × J matrices, D = 1 for the observed data); dir = sign of the observed
# mean change per treatment, for the count of donkeys that move against the group direction (stage 2 pinned these)
cond_stats <- function(L, outcome, dir) {
  out <- list()
  for (c in 1:3) {
    X <- L[[c]]; nm <- COND_NAMES[c]
    out[[length(out) + 1]] <- bind_rows(tibble(statistic = "mean", value = rowMeans(X)), tibble(statistic = "sd", value = row_sd(X)),
                                        tibble(statistic = "min", value = apply(X, 1, min)), tibble(statistic = "max", value = apply(X, 1, max)),
                                        if (outcome == "SBR") tibble(statistic = "var / mean", value = row_sd(X)^2 / rowMeans(X))) |>
      mutate(condition = nm)
  }
  for (t in 2:3) {
    D <- L[[t]] - L[[1]]; nm <- COND_NAMES[t]
    out[[length(out) + 1]] <- bind_rows(tibble(statistic = "mean |delta|", value = rowMeans(abs(D))), tibble(statistic = "sd |delta|", value = row_sd(abs(D))),
                                        tibble(statistic = "max |delta|", value = apply(abs(D), 1, max)),
                                        tibble(statistic = "donkeys against the group direction", value = rowSums(sign(D) == -dir[t])),
                                        if (outcome == "SBR") tibble(statistic = "donkeys with delta = 0", value = rowSums(D == 0))) |>
      mutate(condition = nm)
  }
  bind_rows(out)
}
ppc_condition <- function(yr, dat, outcome, keep_draws = FALSE) {
  idx <- sapply(1:3, function(c) { w <- which(dat$cond == c); w[order(dat$donkey[w])] })   # J × 3, rows in donkey order
  Lobs <- lapply(1:3, function(c) matrix(dat$y[idx[, c]], nrow = 1))
  dir  <- c(NA, sign(mean(Lobs[[2]] - Lobs[[1]])), sign(mean(Lobs[[3]] - Lobs[[1]])))
  ok   <- if (anyNA(yr$m)) !apply(is.na(yr$m), 1, any) else rep(TRUE, nrow(yr$m))     # SBR guard: drop draws with an overflow cell
  Lpred <- lapply(1:3, function(c) yr$m[ok, idx[, c], drop = FALSE])
  obs  <- cond_stats(Lobs, outcome, dir) |> rename(observed = value)
  pred <- cond_stats(Lpred, outcome, dir)
  ref  <- bind_rows(table2 |> filter(outcome == .env$outcome) |> select(condition, mean, sd) |> pivot_longer(c(mean, sd), names_to = "statistic", values_to = "reference"),
                    table2_changes |> filter(outcome == .env$outcome) |> transmute(condition = treatment, `mean |delta|` = delta_mean, `sd |delta|` = delta_sd) |>
                      pivot_longer(-condition, names_to = "statistic", values_to = "reference")) |>
    mutate(reference_source = "Table 2")
  if (outcome == "RMSSD") ref <- bind_rows(ref, tibble(statistic = "max", condition = "positive", reference = FIG2_RMSSD_POSITIVE_WHISKER, reference_source = "Fig. 2C whisker (rough read)"))
  summ <- pred |> group_by(statistic, condition) |> summarise(qtab(value), .groups = "drop") |>
    left_join(obs, by = c("statistic", "condition")) |>
    rowwise() |> mutate(percentile = pctl(pred$value[pred$statistic == statistic & pred$condition == condition], observed)) |> ungroup() |>
    left_join(ref, by = c("statistic", "condition")) |>
    mutate(share_guarded = yr$share_guarded)
  list(summary = summ, draws = if (keep_draws) pred else NULL,
       counts = if (outcome == "SBR") map_dfr(1:3, function(c) tibble(condition = COND_NAMES[c], count = 0:70,
                                                                     pred_share = tabulate(pmin(Lpred[[c]], 70) + 1, nbins = 71) / length(Lpred[[c]]),
                                                                     obs_share = tabulate(pmin(Lobs[[c]], 70) + 1, nbins = 71) / length(Lobs[[c]]))) else NULL)
}
e4_stats <- function(Y, x, trt) map_dfr(1:2, function(t) {
  sel <- trt == t; X <- Y[, sel, drop = FALSE]; xs <- x[sel]
  slope <- as.numeric((X - rowMeans(X)) %*% (xs - mean(xs))) / sum((xs - mean(xs))^2)
  bind_rows(tibble(statistic = "mean dRMSSD", value = rowMeans(X)), tibble(statistic = "sd dRMSSD", value = row_sd(X)),
            tibble(statistic = "OLS slope", value = slope), tibble(statistic = "max |dRMSSD|", value = apply(abs(X), 1, max))) |>
    mutate(condition = TRT_NAMES[t])
})
ppc_e4 <- function(m, dat, keep_draws = FALSE) {
  obs  <- e4_stats(matrix(dat$y, nrow = 1), dat$x, dat$trt) |> rename(observed = value)
  pred <- e4_stats(m, dat$x, dat$trt)
  summ <- pred |> group_by(statistic, condition) |> summarise(qtab(value), .groups = "drop") |>
    left_join(obs, by = c("statistic", "condition")) |>
    rowwise() |> mutate(percentile = pctl(pred$value[pred$statistic == statistic & pred$condition == condition], observed)) |> ungroup() |>
    mutate(reference = NA_real_, reference_source = NA_character_, share_guarded = 0)
  list(summary = summ, draws = if (keep_draws) pred else NULL, counts = NULL)
}

process_run <- function(model, suffix, outcome, x_name, prior_scale, pooled, keep_draws = FALSE) {
  run <- read_run(model, suffix)
  d <- run$draws
  dat <- read_json(file.path(stan_data, paste0(data_name_of(model, suffix), ".json")), simplifyVector = TRUE)
  if (model == "delta_slopes") {
    map <- MAP_E4 |> transmute(outcome = paste0("E4 (x = ", x_name, ")"), term = paste(quantity, treatment, sep = ", "), scale = "response", stan_var)
  } else {
    if (outcome == "SBR") d <- mutate_variables(d, lr_pos_neg = `b_cond[1]` - `b_cond[2]`, sigma_latent = sqrt(sigma2_latent))
    map <- MAP_COND |> filter(outcome == .env$outcome, stan_var %in% variables(d))
    if (!is_full_setting(model, prior_scale, pooled)) map <- map |> filter(estimand_of(term) != "E3")
  }
  sub <- as_draws_matrix(subset_draws(d, variable = map$stan_var))[, map$stan_var, drop = FALSE]
  per_rep <- map |> mutate(post_median = apply(sub, 2, median), post_sd = apply(sub, 2, sd),
                           post_q025 = apply(sub, 2, quantile, 0.025), post_q975 = apply(sub, 2, quantile, 0.975))
  ppc <- if (model == "delta_slopes") ppc_e4(yrep_matrix(run)$m, dat, keep_draws) else
    ppc_condition(yrep_matrix(run, guarded = outcome == "SBR"), dat, outcome, keep_draws)
  ll <- as_draws_matrix(subset_draws(d, variable = "log_lik"))
  ll <- ll[, order(as.integer(sub("^log_lik\\[(\\d+)\\]$", "\\1", colnames(ll)))), drop = FALSE]
  unit <- "donkey"
  if (model == "delta_slopes") unit <- "observation" else if (ncol(ll) == dat$N) ll <- t(rowsum(t(ll), dat$donkey))   # per-observation programs: sum per donkey
  lo <- loo::loo(ll, r_eff = loo::relative_eff(exp(ll), chain_id = as.integer(d$.chain)))
  loo_row <- tibble(loo_unit = unit, n_units = ncol(ll), elpd_loo = lo$estimates["elpd_loo", "Estimate"], se_elpd_loo = lo$estimates["elpd_loo", "SE"],
                    p_loo = lo$estimates["p_loo", "Estimate"], max_pareto_k = max(lo$diagnostics$pareto_k), n_pareto_k_gt_0.7 = sum(lo$diagnostics$pareto_k > 0.7))
  list(map = map, sub = sub, per_rep = per_rep, ppc = ppc$summary, ppc_draws = ppc$draws, counts = ppc$counts, loo = loo_row,
       pointwise = tibble(unit = seq_len(ncol(ll)), elpd = lo$pointwise[, "elpd_loo"]))
}
process_group <- function(g) {
  res <- lapply(seq_len(nrow(g)), function(i) process_run(g$model[i], g$suffix[i], g$outcome[i], g$x_name[i], g$prior_scale[i], g$pooled[i],
                                                           keep_draws = g$scenario[i] == "rho0" & g$rep[i] == 1 & is_full_setting(g$model[i], g$prior_scale[i], g$pooled[i])))
  key <- g |> select(model, role, x_name, prior_scale, pooled, scenario, rho_dd) |> distinct()
  stopifnot(nrow(key) == 1)
  stack <- do.call(rbind, lapply(res, `[[`, "sub"))
  per_rep <- map2_dfr(res, g$rep, ~ .x$per_rep |> mutate(rep = .y))
  pooled <- res[[1]]$map |>
    mutate(K = nrow(g), estimate = apply(stack, 2, median), ci_low = apply(stack, 2, quantile, 0.025), ci_high = apply(stack, 2, quantile, 0.975),
           post_sd = apply(stack, 2, sd)) |>
    left_join(per_rep |> group_by(stan_var) |> summarise(within_sd = sqrt(mean(post_sd^2)), between_sd_estimate = sd(post_median),
                                                        q025_estimate = quantile(post_median, 0.025), q975_estimate = quantile(post_median, 0.975), .groups = "drop"),
              by = "stan_var") |>
    mutate(between_within_ratio = between_sd_estimate^2 / within_sd^2)
  list(pooled = bind_cols(key, pooled), per_rep = bind_cols(key, per_rep),
       ppc = map2_dfr(res, g$rep, ~ .x$ppc |> mutate(rep = .y)) |> bind_cols(key),
       ppc_draws = map_dfr(res, "ppc_draws") |> (\(x) if (nrow(x) > 0) bind_cols(key, x) else x)(),
       counts = map2_dfr(res, g$rep, ~ if (is.null(.x$counts)) NULL else .x$counts |> mutate(rep = .y)) |> (\(x) if (nrow(x) > 0) bind_cols(key, x) else x)(),
       loo = map2_dfr(res, g$rep, ~ .x$loo |> mutate(rep = .y)) |> bind_cols(key),
       pointwise = map2_dfr(res, g$rep, ~ .x$pointwise |> mutate(rep = .y)) |> bind_cols(key))
}

# stage 3 pooled over the same 10 replicates (Rubin's rules as in R/02_fit_frequentist.R, on the per-replicate tables)
back <- function(x, transform) case_when(transform == "exp" ~ exp(x), transform == "tanh" ~ tanh(x), TRUE ~ x)
pool_rubin_s3 <- function(per_rep) per_rep |>
  group_by(rho_dd, outcome, estimand, term, scale, transform) |>
  summarise(K = n(), qbar = mean(est_raw), W = mean(se_raw^2), B = var(est_raw), .groups = "drop") |>
  mutate(T = W + (1 + 1 / K) * B, estimate = back(qbar, transform), ci_low = back(qbar - 1.96 * sqrt(T), transform), ci_high = back(qbar + 1.96 * sqrt(T), transform)) |>
  select(rho_dd, outcome, estimand, term, scale, K, estimate, ci_low, ci_high)
pool_identity_s3 <- function(per_rep) per_rep |>
  group_by(rho_dd, x_name, quantity, treatment) |>
  summarise(K = n(), qbar = mean(estimate), W = mean(se^2), B = var(estimate), .groups = "drop") |>
  mutate(T = W + (1 + 1 / K) * B, estimate = qbar, ci_low = qbar - 1.96 * sqrt(T), ci_high = qbar + 1.96 * sqrt(T)) |>
  transmute(rho_dd, outcome = paste0("E4 (x = ", x_name, ")"), estimand = "E4", term = paste(quantity, treatment, sep = ", "), scale = "response", K, estimate, ci_low, ci_high)
fmt_int <- function(e, l, h) if_else(is.na(e), NA_character_, if_else(is.na(l), as.character(signif(e, 3)), sprintf("%s [%s, %s]", signif(e, 3), signif(l, 3), signif(h, 3))))

if (RUN_MAIN) {
  t_start <- Sys.time()
  cat("== S8 pooled posteriors, posterior predictive checks and LOO over the runs in", fits_dir, "\n")
  runs <- list_runs() |> left_join(MODELS |> select(model, outcome, role), by = "model") |>
    mutate(outcome = if_else(model == "delta_slopes", paste0("E4 (x = ", x_name, ")"), outcome),
           role = sub(" \\(.*$", "", role)) |>                                    # "planned (x = ...)" -> "planned"
    arrange(model, x_name, prior_scale, pooled, rho_dd, rep)
  groups <- runs |> group_by(model, x_name, prior_scale, pooled, scenario) |> group_split()
  cat(nrow(runs), "runs in", length(groups), "groups of", K_STAN, "replicates;", N_CORES, "cores\n")
  stopifnot(all(map_int(groups, nrow) == K_STAN))
  res <- parallel::mclapply(groups, function(g) tryCatch(process_group(g), error = function(e) structure(conditionMessage(e), class = "s8_error")), mc.cores = N_CORES)
  err <- map_lgl(res, inherits, c("s8_error", "try-error")) | map_lgl(res, is.null)
  if (any(err)) stop("groups failed:\n", paste(map2_chr(groups[err], res[err], ~ paste0("  ", .x$model[1], " ", .x$suffix[1], ": ", paste(.y, collapse = " "))), collapse = "\n"))

  # -- 1. pooled estimands and per-replicate summaries
  pooled <- map_dfr(res, "pooled") |> mutate(estimand = if_else(grepl("^E4", outcome), "E4", estimand_of(term))) |>
    select(model, role, x_name, prior_scale, pooled, scenario, rho_dd, outcome, estimand, term, scale, stan_var, K, estimate, ci_low, ci_high,
           post_sd, within_sd, between_sd_estimate, between_within_ratio, q025_estimate, q975_estimate)
  per_rep <- map_dfr(res, "per_rep") |> mutate(estimand = if_else(grepl("^E4", outcome), "E4", estimand_of(term))) |>
    select(model, role, x_name, prior_scale, pooled, scenario, rho_dd, rep, outcome, estimand, term, scale, stan_var, post_median, post_sd, post_q025, post_q975)
  write_csv(pooled, file.path(out_tab, "stage4_ensemble_estimands.csv"))
  write_csv(per_rep, file.path(out_tab, "stage4_per_replicate_estimands.csv.gz"))

  # -- 2. side by side: authors, stage 2, stage 3 (K = 200 and the same 10 replicates), stage 4 and its sensitivities
  s3_all <- read_csv(here_art("output/tables/stage3_ensemble_estimands.csv"), show_col_types = FALSE)
  s3_rep <- read_csv(here_art("output/tables/stage3_ensemble_per_replicate_estimands.csv.gz"), show_col_types = FALSE) |> filter(rep <= K_STAN)
  s3_e4  <- read_csv(here_art("output/tables/stage3_e4_ensemble.csv"), show_col_types = FALSE)
  s3_e4_rep <- read_csv(here_art("output/tables/stage3_e4_per_replicate.csv.gz"), show_col_types = FALSE) |> filter(rep <= K_STAN, converged)
  exact  <- read_csv(here_art("output/tables/contrasts_exact.csv"), show_col_types = FALSE)
  simref <- read_csv(here_art("output/tables/sim_contrasts_summary.csv"), show_col_types = FALSE)
  pvals  <- read_csv(here_art("data/raw/text_contrast_pvalues.csv"), show_col_types = FALSE)
  t34    <- read_csv(here_art("data/raw/tables3_4_regressions.csv"), show_col_types = FALSE)
  diff_scale <- c(SBR = "difference (blinks/min)", ET = "difference (degC)", RMSSD = "difference (ms, marginal)")
  keys <- bind_rows(s3_all |> distinct(outcome, term, scale), s3_e4 |> distinct(x_name, quantity, treatment) |>
                      transmute(outcome = paste0("E4 (x = ", x_name, ")"), term = paste(quantity, treatment, sep = ", "), scale = "response")) |>
    mutate(estimand = if_else(grepl("^E4", outcome), "E4", estimand_of(term)))
  src_s3 <- bind_rows(s3_all |> select(rho_dd, outcome, term, scale, estimate, ci_low, ci_high),
                      s3_e4 |> transmute(rho_dd, outcome = paste0("E4 (x = ", x_name, ")"), term = paste(quantity, treatment, sep = ", "), scale = "response", estimate, ci_low, ci_high)) |>
    mutate(source = "stage 3 (K = 200)")
  src_s3_10 <- bind_rows(pool_rubin_s3(s3_rep) |> select(-estimand, -K), pool_identity_s3(s3_e4_rep) |> select(-estimand, -K)) |> mutate(source = "stage 3 (same 10 replicates)")
  s4_src <- function(filter_expr, label) pooled |> filter({{ filter_expr }}) |> select(rho_dd, outcome, term, scale, estimate, ci_low, ci_high, post_sd) |> mutate(source = label)
  src_s4 <- bind_rows(s4_src(role == "planned" & prior_scale == 1 & !pooled, "stage 4"),
                      s4_src(role == "planned" & prior_scale == 2 & !pooled, "stage 4, prior SDs x2 (i)"),
                      s4_src(role == "planned" & prior_scale == 0.5 & !pooled, "stage 4, prior SDs x0.5 (i')"),
                      s4_src(role == "planned" & prior_scale == 1 & pooled, "stage 4, pooled sigma (iv)"),
                      s4_src(role != "planned" & !pooled, "stage 4, alternative program (ii/ii'/iii)"),
                      s4_src(role != "planned" & pooled, "stage 4, alternative program, pooled dispersion (iv)"))
  src_exact <- exact |> transmute(outcome, term = paste(treatment, "- control"), scale = diff_scale[outcome], estimate = -mean_d, ci_low = -ci_high_d, ci_high = -ci_low_d,
                                  source = "stage 2 exact paired t (treatment - control)") |>
    crossing(rho_dd = unique(s3_all$rho_dd))
  src_sim <- simref |> mutate(sgn = if_else(contrast == "negative_vs_positive", -1, 1),
                              term = recode(contrast, positive_vs_control = "positive - control", negative_vs_control = "negative - control", negative_vs_positive = "positive - negative")) |>
    transmute(rho_dd, outcome, term, scale = diff_scale[outcome], estimate = sgn * estimate_med, ci_low = sgn * estimate_med - 1.96 * se_med, ci_high = sgn * estimate_med + 1.96 * se_med,
              source = "stage 2 described model, simulated (median over 200)")
  authors <- bind_rows(
    table2_changes |> left_join(pvals |> mutate(treatment = sub("_vs_control", "", contrast)), by = c("outcome", "treatment")) |>
      transmute(outcome, term = paste(treatment, "- control"), scale = diff_scale[outcome],
                authors_reported = sprintf("|delta| %s (SD %s), %s %s", delta_mean, delta_sd, if_else(p_type == "exact", "P =", "P <"), p_reported)),
    table2 |> transmute(outcome, term = paste("mean", condition), scale = if_else(outcome == "RMSSD", "response, marginal", if_else(outcome == "SBR", "response, u = 0", "response")),
                        authors_reported = sprintf("%s (SD %s)", mean, sd)),
    t34 |> filter(term %in% c("dSBR", "dET")) |> transmute(outcome = paste0("E4 (x = ", term, ")"), term = "b (slope), positive", scale = "response",
                                                           authors_reported = sprintf("common slope %s [%s, %s], P %s (Table %s)", estimate, ci_low, ci_high, p_reported, table)),
    t34 |> filter(term %in% c("dSBR", "dET")) |> transmute(outcome = paste0("E4 (x = ", term, ")"), term = "b (slope), negative", scale = "response",
                                                           authors_reported = sprintf("common slope %s [%s, %s], P %s (Table %s)", estimate, ci_low, ci_high, p_reported, table)))
  long <- bind_rows(src_exact, src_sim, src_s3, src_s3_10, src_s4) |> inner_join(keys, by = c("outcome", "term", "scale")) |>
    select(rho_dd, outcome, estimand, term, scale, source, estimate, ci_low, ci_high, post_sd) |> arrange(outcome, estimand, term, scale, rho_dd, source)
  write_csv(long, file.path(out_tab, "stage4_comparison_long.csv"))
  wide_num <- function(label, col) long |> filter(source == label) |> select(rho_dd, outcome, term, scale, !!col := estimate)
  wide <- keys |> crossing(rho_dd = unique(s3_all$rho_dd)) |>
    left_join(authors, by = c("outcome", "term", "scale")) |>
    left_join(long |> filter(source == "stage 2 exact paired t (treatment - control)") |> transmute(rho_dd, outcome, term, scale, stage2_exact = fmt_int(estimate, ci_low, ci_high)), by = c("rho_dd", "outcome", "term", "scale")) |>
    left_join(long |> filter(source == "stage 3 (K = 200)") |> transmute(rho_dd, outcome, term, scale, stage3 = fmt_int(estimate, ci_low, ci_high), s3_estimate = estimate, s3_low = ci_low, s3_high = ci_high), by = c("rho_dd", "outcome", "term", "scale")) |>
    left_join(long |> filter(source == "stage 3 (same 10 replicates)") |> transmute(rho_dd, outcome, term, scale, stage3_same10 = fmt_int(estimate, ci_low, ci_high), s3_10_estimate = estimate), by = c("rho_dd", "outcome", "term", "scale")) |>
    left_join(long |> filter(source == "stage 4") |> transmute(rho_dd, outcome, term, scale, stage4 = fmt_int(estimate, ci_low, ci_high), s4_estimate = estimate, s4_low = ci_low, s4_high = ci_high, s4_post_sd = post_sd), by = c("rho_dd", "outcome", "term", "scale")) |>
    left_join(wide_num("stage 4, prior SDs x2 (i)", "s4_ps2"), by = c("rho_dd", "outcome", "term", "scale")) |>
    left_join(wide_num("stage 4, prior SDs x0.5 (i')", "s4_ps05"), by = c("rho_dd", "outcome", "term", "scale")) |>
    left_join(wide_num("stage 4, pooled sigma (iv)", "s4_pooled"), by = c("rho_dd", "outcome", "term", "scale")) |>
    left_join(wide_num("stage 4, alternative program (ii/ii'/iii)", "s4_alt_program"), by = c("rho_dd", "outcome", "term", "scale")) |>
    mutate(s3_s4_diff = s4_estimate - s3_estimate, s3_s4_diff_in_sd = s3_s4_diff / s4_post_sd, s3_10_s4_diff_in_sd = (s4_estimate - s3_10_estimate) / s4_post_sd,
           prior_spread = abs(s4_ps2 - s4_ps05), diff_within_prior_spread = abs(s4_estimate - s3_10_estimate) <= prior_spread,
           width_ratio = (s4_high - s4_low) / (s3_high - s3_low)) |>
    arrange(outcome, estimand, term, scale, rho_dd)
  write_csv(wide, file.path(out_tab, "stage4_side_by_side.csv"))

  # -- 3. posterior predictive checks
  ppc <- map_dfr(res, "ppc") |> select(model, role, x_name, prior_scale, pooled, scenario, rho_dd, rep, statistic, condition, observed, reference, reference_source,
                                       q025, q25, q50, q75, q975, percentile, share_guarded)
  write_csv(ppc, file.path(out_tab, "stage4_per_replicate_ppc.csv.gz"))
  ppc_summary <- ppc |> group_by(model, role, x_name, prior_scale, pooled, scenario, rho_dd, statistic, condition) |>
    summarise(K = n(), observed_mean = mean(observed), reference = first(reference), reference_source = first(reference_source),
              pred_q50_median = median(q50), pred_q025_median = median(q025), pred_q975_median = median(q975),
              percentile_median = median(percentile), percentile_min = min(percentile), percentile_max = max(percentile),
              share_outside_95 = mean(percentile < 0.025 | percentile > 0.975), max_share_guarded = max(share_guarded), .groups = "drop")
  write_csv(ppc_summary, file.path(out_tab, "stage4_ppc_summary.csv"))
  counts <- map_dfr(res, "counts")
  counts_summary <- counts |> group_by(model, prior_scale, pooled, scenario, rho_dd, condition, count) |>
    summarise(obs_share = mean(obs_share), pred_share = mean(pred_share), .groups = "drop")
  write_csv(counts_summary, file.path(out_tab, "stage4_ppc_sbr_counts.csv"))

  # -- 4. LOO: per run, and every setting against the planned model on the same replicate (paired on the pointwise elpd)
  loo_runs <- map_dfr(res, "loo") |> select(model, role, x_name, prior_scale, pooled, scenario, rho_dd, rep, loo_unit, n_units, elpd_loo, se_elpd_loo, p_loo, max_pareto_k, n_pareto_k_gt_0.7)
  write_csv(loo_runs, file.path(out_tab, "stage4_loo.csv"))
  pw <- map_dfr(res, "pointwise") |> left_join(MODELS |> select(model, outcome), by = "model") |>
    mutate(outcome = if_else(model == "delta_slopes", paste0("E4 (x = ", x_name, ")"), outcome))
  ref <- pw |> filter(role == "planned", prior_scale == 1, !pooled) |> select(outcome, scenario, rep, unit, elpd_ref = elpd)
  loo_cmp <- pw |> inner_join(ref, by = c("outcome", "scenario", "rep", "unit")) |>
    group_by(model, role, x_name, prior_scale, pooled, outcome, scenario, rho_dd, rep) |>
    summarise(elpd_diff = sum(elpd - elpd_ref), se_diff = sqrt(n()) * sd(elpd - elpd_ref), .groups = "drop") |>
    group_by(model, role, x_name, prior_scale, pooled, outcome, scenario, rho_dd) |>
    summarise(K = n(), mean_elpd_diff = mean(elpd_diff), sd_elpd_diff_across_reps = sd(elpd_diff), mean_se_diff = mean(se_diff),
              share_planned_better = mean(elpd_diff < 0), share_diff_beyond_2se = mean(abs(elpd_diff) > 2 * se_diff), .groups = "drop") |>
    filter(!(role == "planned" & prior_scale == 1 & !pooled))
  write_csv(loo_cmp, file.path(out_tab, "stage4_loo_comparison.csv"))

  # -- 5. figures
  forest <- long |> filter(estimand %in% c("E1", "E2"), scale == PRIMARY_SCALE[outcome], grepl("^stage 3|^stage 4", source), !grepl("alternative|pooled", source)) |>
    mutate(source = factor(source, levels = c("stage 3 (K = 200)", "stage 3 (same 10 replicates)", "stage 4", "stage 4, prior SDs x2 (i)", "stage 4, prior SDs x0.5 (i')")),
           panel = paste0(outcome, " (", scale, ")"), rho_lab = paste("rho_dd =", rho_dd))
  g <- ggplot(forest, aes(x = estimate, y = term, colour = source)) +
    geom_vline(data = distinct(forest, panel) |> mutate(x0 = if_else(grepl("ratio", panel), 1, 0)), aes(xintercept = x0), colour = "grey70") +
    geom_pointrange(aes(xmin = ci_low, xmax = ci_high), position = position_dodge(width = 0.7), size = 0.3) +
    facet_grid(rho_lab ~ panel, scales = "free_x") +
    labs(x = "estimate with 95 % interval (Wald, Rubin-pooled; posterior, pooled draws)", y = NULL, colour = NULL,
         title = "E1 and E2 on the reconstructed ensemble: stage 3 (glmmTMB) and stage 4 (Stan)") +
    theme_minimal(base_size = 9) + theme(legend.position = "bottom") + guides(colour = guide_legend(nrow = 2))
  ggsave(file.path(out_fig, "stage4_forest_e1_e2.png"), g, width = 11, height = 7, dpi = 150)
  ppc_draws <- map_dfr(res, "ppc_draws")
  ex <- ppc |> filter(scenario == "rho0", rep == 1, role == "planned", prior_scale == 1, !pooled) |>
    mutate(outcome = if_else(model == "delta_slopes", x_name, MODELS$outcome[match(model, MODELS$model)]))
  pd <- ppc_draws |> mutate(outcome = if_else(model == "delta_slopes", x_name, MODELS$outcome[match(model, MODELS$model)])) |>
    filter(statistic %in% c("mean", "sd", "mean |delta|", "sd |delta|", "max", "donkeys against the group direction", "sd dRMSSD", "OLS slope")) |>
    group_by(outcome, statistic, condition) |> filter(value > quantile(value, 0.002), value < quantile(value, 0.998)) |> ungroup()
  g2 <- ggplot(pd, aes(value, colour = condition)) + geom_density(adjust = 1.5) +
    geom_vline(data = ex |> semi_join(pd, by = c("outcome", "statistic", "condition")), aes(xintercept = observed, colour = condition), linetype = 2) +
    geom_vline(data = ex |> semi_join(pd, by = c("outcome", "statistic", "condition")) |> filter(!is.na(reference)), aes(xintercept = reference, colour = condition), linetype = 3) +
    facet_wrap(~ outcome + statistic, scales = "free", ncol = 5) +
    labs(x = NULL, y = "posterior predictive density", colour = NULL, title = "Posterior predictive statistics, example replicate (rho_dd = 0, rep 1), planned models",
         subtitle = "Dashed: observed in the replicate; dotted: Table 2 / Fig. 2C reference where one exists") +
    theme_minimal(base_size = 8) + theme(legend.position = "bottom")
  ggsave(file.path(out_fig, "stage4_ppc_example.png"), g2, width = 13, height = 10, dpi = 150)
  cs <- counts_summary |> filter(prior_scale == 1, !pooled, count <= 65) |> mutate(rho_lab = paste("rho_dd =", rho_dd), condition = factor(condition, levels = COND_NAMES))
  g3 <- ggplot(cs, aes(count)) + geom_col(data = cs |> distinct(rho_lab, condition, count, obs_share), aes(y = obs_share), fill = "grey80", width = 1) +
    geom_line(aes(y = pred_share, colour = model)) +
    facet_grid(rho_lab ~ condition) +
    labs(x = "blinks/min", y = "share of cells", colour = NULL, title = "SBR: observed counts (bars, 10 replicates per scenario) and posterior predictive frequencies (lines)") +
    theme_minimal(base_size = 9) + theme(legend.position = "bottom")
  ggsave(file.path(out_fig, "stage4_ppc_sbr_counts.png"), g3, width = 10, height = 7, dpi = 150)

  # -- 6. console
  options(width = 230)
  cat("\n-- E1/E2 on the primary scales: stage 3 (K = 200 / same 10) vs stage 4 and the prior-scale bracket\n")
  print(wide |> filter(estimand %in% c("E1", "E2"), scale == PRIMARY_SCALE[outcome]) |>
          mutate(across(c(s3_estimate, s3_10_estimate, s4_estimate, s4_ps2, s4_ps05, s3_10_s4_diff_in_sd, width_ratio), ~ signif(.x, 3))) |>
          select(rho_dd, outcome, term, s3_estimate, s3_10_estimate, s4_estimate, s4_ps05, s4_ps2, s3_10_s4_diff_in_sd, diff_within_prior_spread, width_ratio), n = Inf)
  cat("\n-- all mapped quantities: |stage 4 - stage 3 (same 10)| in posterior SDs, by estimand\n")
  print(wide |> filter(!is.na(s3_10_s4_diff_in_sd)) |> group_by(estimand) |>
          summarise(n = n(), median_abs = median(abs(s3_10_s4_diff_in_sd)), max_abs = max(abs(s3_10_s4_diff_in_sd)),
                    n_beyond_1sd = sum(abs(s3_10_s4_diff_in_sd) > 1), median_width_ratio = median(width_ratio, na.rm = TRUE), .groups = "drop"))
  cat("\n-- worst agreements (|diff| > 0.5 SD)\n")
  print(wide |> filter(abs(s3_10_s4_diff_in_sd) > 0.5) |> select(rho_dd, outcome, term, scale, s3_10_estimate, s4_estimate, s4_ps05, s4_ps2, s3_10_s4_diff_in_sd) |>
          mutate(across(where(is.numeric), ~ signif(.x, 3))), n = Inf)
  cat("\n-- posterior predictive checks: share of replicates with the observed statistic outside the central 95 % (planned models, prior scale 1)\n")
  print(ppc_summary |> filter(role == "planned", prior_scale == 1, !pooled) |>
          mutate(outcome = if_else(model == "delta_slopes", x_name, MODELS$outcome[match(model, MODELS$model)])) |>
          group_by(outcome, statistic, condition) |>
          summarise(observed = signif(mean(observed_mean), 3), reference = first(reference), pred_q50 = signif(median(pred_q50_median), 3),
                    pctl_min = signif(min(percentile_min), 2), pctl_median = signif(median(percentile_median), 2), pctl_max = signif(max(percentile_max), 2),
                    share_outside_95 = mean(share_outside_95), .groups = "drop"), n = Inf)
  cat("\n-- posterior predictive checks, sensitivity settings: statistics with share_outside_95 > 0.1 in any scenario\n")
  print(ppc_summary |> filter(!(role == "planned" & prior_scale == 1 & !pooled), share_outside_95 > 0.1) |>
          select(model, prior_scale, pooled, scenario, statistic, condition, observed_mean, pred_q50_median, percentile_median, share_outside_95) |>
          mutate(across(where(is.numeric), ~ signif(.x, 3))), n = Inf)
  cat("\n-- LOO: elpd difference to the planned model on the same replicates (negative = planned model predicts better)\n")
  print(loo_cmp |> mutate(across(c(mean_elpd_diff, sd_elpd_diff_across_reps, mean_se_diff), ~ signif(.x, 3))) |>
          select(outcome, model, prior_scale, pooled, rho_dd, mean_elpd_diff, mean_se_diff, sd_elpd_diff_across_reps, share_planned_better, share_diff_beyond_2se), n = Inf)
  cat("\n-- LOO diagnostics: runs with any Pareto k > 0.7\n")
  print(loo_runs |> group_by(model, prior_scale, pooled) |> summarise(runs = n(), runs_with_k_gt_0.7 = sum(n_pareto_k_gt_0.7 > 0), max_k = signif(max(max_pareto_k), 2), .groups = "drop"), n = Inf)
  cat(sprintf("\nwritten: output/tables/stage4_ensemble_estimands.csv, stage4_per_replicate_estimands.csv.gz, stage4_comparison_long.csv, stage4_side_by_side.csv,\n  stage4_per_replicate_ppc.csv.gz, stage4_ppc_summary.csv, stage4_ppc_sbr_counts.csv, stage4_loo.csv, stage4_loo_comparison.csv;\n  output/figures/stage4_forest_e1_e2.png, stage4_ppc_example.png, stage4_ppc_sbr_counts.png  (%.1f min)\n",
              as.numeric(difftime(Sys.time(), t_start, units = "mins"))))
}
