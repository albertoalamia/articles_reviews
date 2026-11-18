# Stage 4 post-processing (plan §5, §8). Reads the CmdStan CSV draws that run_model.sh writes to
# $FITS_DIR/<article>/<model>/, computes diagnostics and summaries, and writes SMALL tables and figures to
# output/. Never copies draws into the project tree. R is for post-processing only, no fitting from R (CLAUDE.md).
# Usage (repo root, inside nix-shell):
#   Rscript <art>/R/03_postprocess.R --prior     S5: prior predictive of the seven models vs Table 2 / the example data
#   Rscript <art>/R/03_postprocess.R --example   S6: mapping check of the posterior runs on the example replicate against glmmTMB (S2/S4 tables)
#   Rscript <art>/R/03_postprocess.R             S8: pooled posteriors over the 30 replicates, stage 3 vs 4   (not yet written)
suppressPackageStartupMessages({ library(tidyverse); library(posterior); library(jsonlite) })
here_art <- function(...) here::here("SciRep_emotions_in_working_donkeys_Bukhari_2026", ...)

args <- commandArgs(trailingOnly = TRUE)
allowed <- c("--prior", "--example")
if (!all(args %in% allowed)) stop("unknown argument(s): ", paste(setdiff(args, allowed), collapse = " "))
RUN_PRIOR   <- "--prior" %in% args
RUN_EXAMPLE <- "--example" %in% args
if (!any(RUN_PRIOR, RUN_EXAMPLE)) stop("nothing to do: use --prior or --example (S8 main run comes later)")

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
