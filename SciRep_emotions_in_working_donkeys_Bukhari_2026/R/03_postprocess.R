# Stage 4 post-processing (plan §5, §8). Reads the CmdStan CSV draws that run_model.sh writes to
# $FITS_DIR/<article>/<model>/, computes diagnostics and summaries, and writes SMALL tables and figures to
# output/. Never copies draws into the project tree. R is for post-processing only, no fitting from R (CLAUDE.md).
# Usage (repo root, inside nix-shell):
#   Rscript <art>/R/03_postprocess.R --prior     S5: prior predictive of the seven models vs Table 2 / the example data
#   Rscript <art>/R/03_postprocess.R --example   S6: mapping check against the glmmTMB estimates of S2   (not yet written)
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
convergence <- function(run, exclude = c("y_rep", "log_lik")) {
  keep <- setdiff(variables(run$draws), grep(paste(exclude, collapse = "|"), variables(run$draws), value = TRUE))
  s <- summarise_draws(subset_draws(run$draws, variable = keep), "rhat", "ess_bulk", "ess_tail")
  div <- sum(as_draws_matrix(subset_draws(run$sampler, variable = "divergent__")))
  tibble(n_draws = ndraws(run$draws), max_rhat = max(s$rhat, na.rm = TRUE), min_ess_bulk = min(s$ess_bulk, na.rm = TRUE),
         min_ess_tail = min(s$ess_tail, na.rm = TRUE), divergences = div)
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

if (RUN_EXAMPLE) stop("--example (S6 mapping check) is not written yet")
