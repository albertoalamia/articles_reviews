# 01_prepare_data.R — Bukhari 2026, stage 3–4 step S1: the reconstructed ensemble and the Stan data files
#
# Plan   : notes/04_analysis_plan.md v1.0, sections 2 and 8 (S1)
# Inputs : data/raw/table2_conditions.csv                 condition means and SDs (Table 2)
#          data/derived/deltas_fig3.csv, deltas_fig4.csv   the 68 unsigned changes per figure (DIGITISATION_LOG.md)
#          R/lib_simulate_conditions.R                     generator (SIMULATION_LOG.md)
# Outputs: data/derived/stage3/ensemble_conditions.csv.gz  long: rho_dd, rep, outcome, donkey, condition, order, y
#          data/derived/stage3/ensemble_e4_pairs.csv.gz    long: rho_dd, rep, figure, treatment, x_name, x, dRMSSD  (signed, treatment − control)
#          data/derived/stage3/ensemble_checks.csv         per replicate: Δ-multiset identity, integer SBR, min value, moments, redraws
#          data/derived/stage3/seeds.csv                   scenario, rep, seed
#          data/derived/stan_data/cond_<outcome>_<scenario>_rep<k>.json, delta_<x>_<scenario>_rep<k>.json  for k = 1..K_STAN
# Run    : Rscript SciRep_emotions_in_working_donkeys_Bukhari_2026/R/01_prepare_data.R     (≈ 1–2 min)
#
# Scenarios: rho_dd ∈ {−0.5, 0, 0.5} (correlation between a donkey's two changes; unidentified).
# N_REP replicates per scenario; the first K_STAN of each scenario are also written as Stan JSON.
# The example replicate of the plan is scenario rho0, rep 1.
#
# What is exact in every replicate: the 34 + 34 unsigned changes per outcome (as multisets), the
# control mean and SD (SBR: up to integer rounding), the mean of the signed changes (Table 2
# differences, ±0.01). What is matched approximately: treatment SDs (±0.1), control–change
# correlations (±0.01). Every SBR value is a count ≥ 0 and every RMSSD value exceeds 5 ms: sign
# pattern, control draw and pairing are redrawn together until this holds (SIMULATION_LOG.md, S1).
# What is assumed: normal control values, Gaussian-copula pairing, rho_dd.
# The three outcomes are generated independently: donkey k of the SBR data is not donkey k of
# the RMSSD data (the paper gives no cross-outcome information at donkey level). They share the
# session order so that the order factor is one design. E4 uses the Figure 3–4 pairs, not these rows.

suppressPackageStartupMessages({ library(tidyverse); library(jsonlite) })
here_art <- function(...) here::here("SciRep_emotions_in_working_donkeys_Bukhari_2026", ...)
source(here_art("R/lib_simulate_conditions.R"))
dir_s3 <- here_art("data/derived/stage3"); dir_stan <- here_art("data/derived/stan_data")
dir.create(dir_s3, showWarnings = FALSE, recursive = TRUE); dir.create(dir_stan, showWarnings = FALSE, recursive = TRUE)

N       <- 34L
N_REP   <- 200L
K_STAN  <- 10L
RHO_DD  <- c(-0.5, 0, 0.5)
SEED0   <- 20261106L
scen_lab <- function(rho) c("-0.5" = "rhom05", "0" = "rho0", "0.5" = "rhop05")[[as.character(rho)]]

cond <- read_csv(here_art("data/raw/table2_conditions.csv"), show_col_types = FALSE)
f3   <- read_csv(here_art("data/derived/deltas_fig3.csv"), show_col_types = FALSE)
f4   <- read_csv(here_art("data/derived/deltas_fig4.csv"), show_col_types = FALSE)

# unsigned changes per outcome, in the row order of the figure files (kept: E4 maps signs back by index)
absd <- list(SBR   = list(positive = f3$dSBR[f3$series == "positive"],   negative = f3$dSBR[f3$series == "negative"]),
             RMSSD = list(positive = f3$dRMSSD[f3$series == "positive"], negative = f3$dRMSSD[f3$series == "negative"]),
             ET    = list(positive = f4$dET[f4$series == "positive"],    negative = f4$dET[f4$series == "negative"]))
stopifnot(all(lengths(unlist(absd, recursive = FALSE)) == N))
grid <- tibble(outcome = c("SBR", "RMSSD", "ET"), step = c(1, 1, 0.1), exact = c(TRUE, FALSE, FALSE),
               integer_control = c(TRUE, FALSE, FALSE), floor = c(-0.5, 5, -Inf)) |>      # SBR counts ≥ 0; RMSSD > 5 ms
  mutate(tol_plot = if_else(exact, 0, 2 * step * sqrt(N / 12)))

# ---- helpers ---------------------------------------------------------------------------------
# signs of the Figure 3–4 pairs, inherited from the replicate's sign patterns.
# ΔSBR (fig3) and ΔET (fig4) map by index (absd was built from those files); ΔRMSSD maps by index
# for fig3 and by value for fig4 (its absd vector came from fig3).
sign_by_value <- function(values, ref_values, ref_reversed) {
  rev <- logical(length(values))
  for (v in unique(ref_values[ref_reversed])) {
    k <- sum(ref_values == v & ref_reversed); idx <- which(values == v)
    stopifnot(length(idx) >= k); rev[idx[seq_len(k)]] <- TRUE
  }
  rev
}
signed <- function(a, reversed, mu_d) { d <- sign(mu_d) * a; d[reversed] <- -d[reversed]; -d }   # treatment − control

stan_cond <- function(dat) list(N = nrow(dat), J = N, donkey = as.integer(dat$donkey),
                                cond = as.integer(dat$condition), ord = as.integer(dat$order), y = dat$y)
stan_delta <- function(pairs) list(N = nrow(pairs), trt = as.integer(factor(pairs$treatment, levels = c("negative", "positive"))),
                                   x = pairs$x, y = pairs$dRMSSD)

# ---- main loop -------------------------------------------------------------------------------
dp_cache <- list(); ens <- list(); e4 <- list(); checks <- list(); seeds <- list(); n_json <- 0L
t0 <- Sys.time()
for (rho in RHO_DD) {
  sl <- scen_lab(rho); cat(sprintf("scenario %s ", sl))
  for (r in seq_len(N_REP)) {
    seed <- SEED0 + 1000L * match(rho, RHO_DD) + r; set.seed(seed)
    seeds[[length(seeds) + 1]] <- tibble(scenario = sl, rho_dd = rho, rep = r, seed = seed)
    ord <- t(replicate(N, sample(3)))                                   # one session order per donkey, shared by the outcomes
    sim <- list(); sg <- list()
    for (o in names(absd)) {
      gi <- grid[grid$outcome == o, ]
      dat <- simulate_conditions(absd[[o]], cond[cond$outcome == o, ], rho_dd = rho, step = gi$step, tol_plot = gi$tol_plot,
                                 dp = dp_cache[[o]], integer_control = gi$integer_control, floor = gi$floor, order = ord)
      if (is.null(dp_cache[[o]])) dp_cache[[o]] <- attr(dat, "dp")
      sim[[o]] <- dat; sg[[o]] <- attr(dat, "signed")
      ens[[length(ens) + 1]] <- tibble(rho_dd = rho, rep = r, outcome = o, donkey = dat$donkey,
                                       condition = as.character(dat$condition), order = as.integer(as.character(dat$order)), y = dat$y)
      # -- integrity checks: Δ multisets, integers, floor, moments
      w <- dat |> pivot_wider(id_cols = donkey, names_from = condition, values_from = y)
      ok_pos <- isTRUE(all.equal(sort(abs(w$control - w$positive)), sort(absd[[o]]$positive), tolerance = 1e-9))
      ok_neg <- isTRUE(all.equal(sort(abs(w$control - w$negative)), sort(absd[[o]]$negative), tolerance = 1e-9))
      ck <- attr(dat, "check"); tg <- attr(dat, "targets")
      checks[[length(checks) + 1]] <- tibble(
        rho_dd = rho, rep = r, outcome = o, delta_multisets_exact = ok_pos && ok_neg,
        all_integer = all(dat$y == round(dat$y)), min_y = min(dat$y),
        mean_control = ck$mean_sim[1], mean_positive = ck$mean_sim[2], mean_negative = ck$mean_sim[3],
        sd_control = ck$sd_sim[1], sd_positive = ck$sd_sim[2], sd_negative = ck$sd_sim[3],
        n_reversed_positive = tg$n_reversed[["positive"]], n_reversed_negative = tg$n_reversed[["negative"]],
        r_cd_err_max = max(abs(tg$r_cd_achieved - tg$r_cd)), rho_dd_achieved = tg$rho_dd_achieved, pd_fixed = tg$pd_fixed,
        attempts = tg$attempts)
    }
    # -- E4 pairs with inherited signs (treatment − control)
    mu_d <- function(o, tn) cond$mean[cond$outcome == o & cond$condition == "control"] - cond$mean[cond$outcome == o & cond$condition == tn]
    for (tn in c("positive", "negative")) {
      rv <- sg$RMSSD[[paste0("reversed_", tn)]]; a_r3 <- absd$RMSSD[[tn]]
      a_s <- absd$SBR[[tn]]; a_e <- absd$ET[[tn]]; a_r4 <- f4$dRMSSD[f4$series == tn]
      e4[[length(e4) + 1]] <- bind_rows(
        tibble(figure = 3L, x_name = "dSBR", x = signed(a_s, sg$SBR[[paste0("reversed_", tn)]], mu_d("SBR", tn)),
               dRMSSD = signed(a_r3, rv, mu_d("RMSSD", tn))),
        tibble(figure = 4L, x_name = "dET", x = signed(a_e, sg$ET[[paste0("reversed_", tn)]], mu_d("ET", tn)),
               dRMSSD = signed(a_r4, sign_by_value(a_r4, a_r3, rv), mu_d("RMSSD", tn)))) |>
        mutate(rho_dd = rho, rep = r, treatment = tn, .before = 1)
    }
    # -- Stan JSON for the first K_STAN replicates
    if (r <= K_STAN) {
      sfx <- sprintf("%s_rep%02d", sl, r)
      for (o in names(absd)) {
        write_json(stan_cond(sim[[o]]), file.path(dir_stan, sprintf("cond_%s_%s.json", tolower(o), sfx)), auto_unbox = TRUE, digits = NA)
        n_json <- n_json + 1L
      }
      pr <- bind_rows(tail(e4, 2))
      for (fx in c("dSBR", "dET")) {
        write_json(stan_delta(pr[pr$x_name == fx, ]), file.path(dir_stan, sprintf("delta_%s_%s.json", tolower(sub("^d", "", fx)), sfx)),
                   auto_unbox = TRUE, digits = NA)
        n_json <- n_json + 1L
      }
    }
    if (r %% 50 == 0) cat(".")
  }
  cat("\n")
}
cat(sprintf("generated %d replicates in %s\n", N_REP * length(RHO_DD), format(round(Sys.time() - t0, 1))))

ens <- list_rbind(ens); e4 <- list_rbind(e4); checks <- list_rbind(checks); seeds <- list_rbind(seeds)
write_csv(ens, file.path(dir_s3, "ensemble_conditions.csv.gz"))
write_csv(e4, file.path(dir_s3, "ensemble_e4_pairs.csv.gz"))
write_csv(checks, file.path(dir_s3, "ensemble_checks.csv"))
write_csv(seeds, file.path(dir_s3, "seeds.csv"))

# ---- report ----------------------------------------------------------------------------------
cat("\n== integrity, all replicates ==\n")
print(checks |> group_by(outcome) |>
        summarise(n = n(), delta_multisets_exact = mean(delta_multisets_exact), all_integer = mean(all_integer),
                  min_y = min(min_y), r_cd_err_max = max(r_cd_err_max), any_pd_fixed = any(pd_fixed),
                  attempts_mean = mean(attempts), attempts_max = max(attempts), .groups = "drop"))
cat("\n== condition moments vs Table 2 (median [min, max] over replicates; SBR control is integer-rounded) ==\n")
mom <- checks |> pivot_longer(c(starts_with("mean_"), starts_with("sd_")), names_to = c("stat", "condition"), names_sep = "_") |>
  group_by(outcome, condition, stat) |>
  summarise(med = median(value), lo = min(value), hi = max(value), .groups = "drop") |>
  left_join(cond |> select(outcome, condition, mean, sd) |> pivot_longer(c(mean, sd), names_to = "stat", values_to = "target"),
            by = c("outcome", "condition", "stat")) |>
  mutate(across(c(med, lo, hi), ~ round(.x, 3))) |> arrange(outcome, stat, condition)
print(mom, n = 20)
cat("\n== reversed-direction donkeys per treatment (range over replicates) ==\n")
print(checks |> group_by(outcome) |> summarise(pos = paste(range(n_reversed_positive), collapse = "–"),
                                              neg = paste(range(n_reversed_negative), collapse = "–"), .groups = "drop"))
cat("\n== E4 pairs: signed means vs Table 2 differences (treatment − control) ==\n")
print(e4 |> group_by(x_name, treatment) |> summarise(mean_x = mean(x), mean_dRMSSD = mean(dRMSSD), n_rows = n(), .groups = "drop"))
sz <- function(f) sprintf("%s (%.1f MB)", basename(f), file.size(f) / 1e6)
cat("\nWritten:", sz(file.path(dir_s3, "ensemble_conditions.csv.gz")), sz(file.path(dir_s3, "ensemble_e4_pairs.csv.gz")),
    "ensemble_checks.csv, seeds.csv;", n_json, "JSON files in data/derived/stan_data/\n")
