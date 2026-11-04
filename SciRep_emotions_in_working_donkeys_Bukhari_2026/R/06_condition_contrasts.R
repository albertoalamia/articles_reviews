# 06_condition_contrasts.R — Bukhari 2026, stage 2: the six treatment-vs-control contrasts of Table 2
#
# Inputs : data/raw/table2_conditions.csv, data/raw/table2_changes.csv, data/raw/text_contrast_pvalues.csv
#          data/derived/deltas_fig3.csv (ΔSBR, ΔRMSSD), deltas_fig4.csv (ΔET)   — the 34 unsigned changes per treatment
#          R/lib_simulate_conditions.R
# Outputs: output/tables/contrasts_exact.csv            signed-difference SD, paired t, implied correlation, reversed sum — no simulation
#          output/tables/contrasts_reversed_counts.csv  how many donkeys moved against the group direction: admissible counts
#          output/tables/contrasts_pos_vs_neg_bounds.csv the untested positive-vs-negative contrast, bounds over the unknown pairing
#          output/tables/sim_contrasts_summary.csv      authors' mixed model on simulated complete data: distribution over replicates
#          output/tables/sim_moment_check.csv           simulated condition means/SDs vs Table 2
#          data/derived/simulated_conditions_example.csv one replicate per outcome (scenario rho_dd = 0, seed 1) for stages 3–4
# Run    : Rscript SciRep_emotions_in_working_donkeys_Bukhari_2026/R/06_condition_contrasts.R   (≈ 2–4 min for the simulation)
#
# Part 1 needs no assumption beyond n = 34 per condition and Δ = control − treatment per donkey:
# the mean of the signed differences is fixed by Table 2, their sum of squares by the figures, so
# SD, paired t and control–treatment correlation follow exactly (see lib_simulate_conditions.R).
# Part 2 simulates complete per-donkey data consistent with all of that and refits the model the
# paper describes (lmer: condition + order fixed, donkey random; lmerTest p-values).

suppressPackageStartupMessages({ library(tidyverse); library(lme4); library(lmerTest) })
here_art <- function(...) here::here("SciRep_emotions_in_working_donkeys_Bukhari_2026", ...)
source(here_art("R/lib_simulate_conditions.R"))
out_tab <- here_art("output/tables"); dir.create(out_tab, showWarnings = FALSE, recursive = TRUE)

N      <- 34L
N_REP  <- 200L                              # replicates per scenario and outcome
RHO_DD <- c(-0.5, 0, 0.5)                   # assumed correlation between a donkey's two changes (unknown)
SEED   <- 1L

cond  <- read_csv(here_art("data/raw/table2_conditions.csv"), show_col_types = FALSE)
t2chg <- read_csv(here_art("data/raw/table2_changes.csv"), show_col_types = FALSE)
pvals <- read_csv(here_art("data/raw/text_contrast_pvalues.csv"), show_col_types = FALSE) |>
  mutate(treatment = str_remove(contrast, "_vs_control"))
f3 <- read_csv(here_art("data/derived/deltas_fig3.csv"), show_col_types = FALSE)
f4 <- read_csv(here_art("data/derived/deltas_fig4.csv"), show_col_types = FALSE)

# data grid and plotting-rounding allowance on a sum of 34 values (2 SD of the rounding error sum)
grid_info <- tibble(outcome = c("SBR", "RMSSD", "ET"), step = c(1, 1, 0.1), exact = c(TRUE, FALSE, FALSE)) |>
  mutate(tol_plot = if_else(exact, 0, 2 * step * sqrt(N / 12)))
absd <- list(SBR   = list(positive = f3$dSBR[f3$series == "positive"],   negative = f3$dSBR[f3$series == "negative"]),
             RMSSD = list(positive = f3$dRMSSD[f3$series == "positive"], negative = f3$dRMSSD[f3$series == "negative"]),
             ET    = list(positive = f4$dET[f4$series == "positive"],    negative = f4$dET[f4$series == "negative"]))
stopifnot(all(lengths(unlist(absd, recursive = FALSE)) == N))

# ---- Part 1a. exact results for each contrast ----------------------------------------------
exact <- map_dfr(names(absd), function(o) map_dfr(c("positive", "negative"), function(tn) {
  a <- absd[[o]][[tn]]; gi <- grid_info[grid_info$outcome == o, ]
  mc <- cond$mean[cond$outcome == o & cond$condition == "control"]; sc <- cond$sd[cond$outcome == o & cond$condition == "control"]
  mt <- cond$mean[cond$outcome == o & cond$condition == tn];        st <- cond$sd[cond$outcome == o & cond$condition == tn]
  mu_d <- mc - mt; S1 <- sum(a); S2 <- sum(a^2)
  sd_d <- sqrt((S2 - N * mu_d^2) / (N - 1))
  sd_d_lo <- sqrt((S2 - N * (abs(mu_d) + 0.01)^2) / (N - 1)); sd_d_hi <- sqrt((S2 - N * (abs(mu_d) - 0.01)^2) / (N - 1))
  t_val <- abs(mu_d) / (sd_d / sqrt(N)); R <- reversed_sum_interval(S1, N, mu_d, gi$tol_plot)
  tbl2 <- t2chg[t2chg$outcome == o & t2chg$treatment == tn, ]
  tibble(outcome = o, treatment = tn, n = N,
         mean_control = mc, mean_treatment = mt, mean_d = mu_d,
         sum_absd = S1, sum_absd_sq = S2, mean_absd = S1 / N, sd_absd = sd(a),
         table2_delta_mean = tbl2$delta_mean, table2_delta_sd = tbl2$delta_sd,
         sd_d_signed = sd_d, sd_d_signed_lo = sd_d_lo, sd_d_signed_hi = sd_d_hi,
         t_paired_signed = t_val, p_paired_signed = 2 * pt(-t_val, N - 1),
         ci_low_d = mu_d - qt(0.975, N - 1) * sd_d / sqrt(N), ci_high_d = mu_d + qt(0.975, N - 1) * sd_d / sqrt(N),
         t_paired_if_no_reversal = (S1 / N) / (sd(a) / sqrt(N)),           # what 02_consistency_checks.R block A used
         t_needed_for_reported_p = NA_real_, p_reported = NA_real_, p_type = NA_character_,
         rho_control_treatment = (sc^2 + st^2 - sd_d^2) / (2 * sc * st),
         reversed_sum = (S1 - N * abs(mu_d)) / 2, reversed_sum_lo = R[["lo"]], reversed_sum_hi = R[["hi"]],
         step = gi$step, tol_plot = gi$tol_plot, min_absd = min(a), max_absd = max(a))
})) |>
  select(-t_needed_for_reported_p, -p_reported, -p_type) |>
  left_join(pvals |> select(outcome, treatment, p_reported, p_type), by = c("outcome", "treatment")) |>
  mutate(t_needed_for_reported_p = qt(1 - p_reported / 2, N - 1),
         p_consistent = if_else(p_type == "exact", abs(p_paired_signed - p_reported) < 0.0005 * 2, p_paired_signed < p_reported))
cat("== Part 1a: contrasts from the signed differences (exact up to plotting rounding) ==\n")
print(exact |> select(outcome, treatment, mean_d, sd_absd, sd_d_signed, t_paired_if_no_reversal, t_paired_signed,
                      p_paired_signed, p_reported, p_type, t_needed_for_reported_p, p_consistent, rho_control_treatment,
                      reversed_sum, reversed_sum_lo, reversed_sum_hi) |>
        mutate(across(where(is.numeric), ~ signif(.x, 3))), width = 220)
write_csv(exact, file.path(out_tab, "contrasts_exact.csv"))

# ---- Part 1b. how many donkeys moved against the group direction --------------------------
dp_cache <- list()
rev_counts <- map_dfr(names(absd), function(o) map_dfr(c("positive", "negative"), function(tn) {
  a <- absd[[o]][[tn]]; gi <- grid_info[grid_info$outcome == o, ]; e <- exact[exact$outcome == o & exact$treatment == tn, ]
  v <- round(a[a > 0] / gi$step); Tm <- subset_dp(v); dp_cache[[o]][[tn]] <<- Tm
  cnt <- subset_counts_by_size(Tm, e$reversed_sum_lo / gi$step, e$reversed_sum_hi / gi$step)
  tibble(outcome = o, treatment = tn, n_reversed = as.integer(names(cnt)), n_sign_patterns = cnt,
         n_zero_values = sum(a == 0)) |> filter(n_sign_patterns > 0) |>
    mutate(share = n_sign_patterns / sum(n_sign_patterns))
}))
rev_summary <- rev_counts |> group_by(outcome, treatment) |>
  summarise(patterns = sum(n_sign_patterns), min_reversed = min(n_reversed), max_reversed = max(n_reversed),
            mode_reversed = n_reversed[which.max(n_sign_patterns)], .groups = "drop")
cat("\n== Part 1b: admissible numbers of donkeys moving against the group direction ==\n"); print(rev_summary)
write_csv(rev_counts, file.path(out_tab, "contrasts_reversed_counts.csv"))

# ---- Part 1c. positive vs negative: never tested in the paper --------------------------------
# d_pn = positive − negative = d_negative − d_positive per donkey. Its mean is known; its SD depends on
# the unknown within-donkey correlation of the two changes: bounds over the whole range, plus independence.
pn <- exact |> select(outcome, treatment, mean_treatment, sd_d_signed) |>
  pivot_wider(names_from = treatment, values_from = c(mean_treatment, sd_d_signed)) |>
  mutate(mean_pos_minus_neg = mean_treatment_positive - mean_treatment_negative,
         sd_min = abs(sd_d_signed_positive - sd_d_signed_negative),
         sd_indep = sqrt(sd_d_signed_positive^2 + sd_d_signed_negative^2),
         sd_max = sd_d_signed_positive + sd_d_signed_negative,
         t_best = abs(mean_pos_minus_neg) / (sd_min / sqrt(N)), t_indep = abs(mean_pos_minus_neg) / (sd_indep / sqrt(N)),
         t_worst = abs(mean_pos_minus_neg) / (sd_max / sqrt(N)),
         p_indep = 2 * pt(-t_indep, N - 1), p_worst = 2 * pt(-t_worst, N - 1),
         rho_dd_for_p_0.05 = {                      # correlation between the two changes at which p would reach 0.05
           need_sd <- abs(mean_pos_minus_neg) * sqrt(N) / qt(0.975, N - 1)
           (sd_d_signed_positive^2 + sd_d_signed_negative^2 - need_sd^2) / (2 * sd_d_signed_positive * sd_d_signed_negative)
         })
cat("\n== Part 1c: positive vs negative (untested in the paper), bounds over the unknown pairing ==\n")
print(pn |> mutate(across(where(is.numeric), ~ signif(.x, 3))), width = 220)
write_csv(pn, file.path(out_tab, "contrasts_pos_vs_neg_bounds.csv"))

# ---- Part 2. simulate complete data and refit the authors' model ----------------------------
fit_authors <- function(dat) {
  m <- suppressMessages(lmer(y ~ condition + order + (1 | donkey), data = dat, REML = TRUE))
  cf <- summary(m)$coefficients
  L <- c(0, -1, 1, 0, 0); names(L) <- rownames(cf)              # negative − positive on the coefficient scale
  pn <- lmerTest::contest1D(m, L, ddf = "Satterthwaite")
  vc <- as.data.frame(VarCorr(m))
  tibble(contrast = c("positive_vs_control", "negative_vs_control", "negative_vs_positive"),
         estimate = c(cf["conditionpositive", 1], cf["conditionnegative", 1], pn$Estimate),
         se = c(cf["conditionpositive", 2], cf["conditionnegative", 2], pn$`Std. Error`),
         df = c(cf["conditionpositive", 3], cf["conditionnegative", 3], pn$df),
         t = c(cf["conditionpositive", 4], cf["conditionnegative", 4], pn$`t value`),
         p = c(cf["conditionpositive", 5], cf["conditionnegative", 5], pn$`Pr(>|t|)`),
         sd_donkey = vc$sdcor[vc$grp == "donkey"], sd_resid = vc$sdcor[vc$grp == "Residual"],
         singular = isSingular(m))
}

set.seed(SEED)
sims <- list(); moments <- list(); example <- list()
for (o in names(absd)) {
  gi <- grid_info[grid_info$outcome == o, ]; co <- cond[cond$outcome == o, ]
  for (rho in RHO_DD) {
    cat(sprintf("simulating %-5s rho_dd = %+.1f ", o, rho))
    for (r in seq_len(N_REP)) {
      dat <- simulate_conditions(absd[[o]], co, rho_dd = rho, step = gi$step, tol_plot = gi$tol_plot, dp = dp_cache[[o]])
      tg <- attr(dat, "targets")
      sims[[length(sims) + 1]] <- fit_authors(dat) |>
        mutate(outcome = o, rho_dd = rho, rep = r, n_reversed_pos = tg$n_reversed[["positive"]],
               n_reversed_neg = tg$n_reversed[["negative"]], rho_dd_achieved = tg$rho_dd_achieved, pd_fixed = tg$pd_fixed)
      moments[[length(moments) + 1]] <- attr(dat, "check") |> mutate(outcome = o, rho_dd = rho, rep = r,
                                                                   r_cd_target_pos = tg$r_cd[["positive"]], r_cd_achieved_pos = tg$r_cd_achieved[["positive"]],
                                                                   r_cd_target_neg = tg$r_cd[["negative"]], r_cd_achieved_neg = tg$r_cd_achieved[["negative"]])
      if (rho == 0 && r == 1) example[[o]] <- dat |> mutate(outcome = o, .before = 1)
      if (r %% 50 == 0) cat(".")
    }
    cat("\n")
  }
}
sims <- list_rbind(sims); moments <- list_rbind(moments)

q <- function(x, p) unname(quantile(x, p))
sim_summary <- sims |> group_by(outcome, rho_dd, contrast) |>
  summarise(n_rep = n(), estimate_med = median(estimate), se_med = median(se), se_lo = q(se, .025), se_hi = q(se, .975),
            df_med = median(df), t_med = median(t), t_lo = q(t, .025), t_hi = q(t, .975),
            p_med = median(p), p_max = max(p), share_p_below_0.001 = mean(p < 0.001), share_p_below_0.05 = mean(p < 0.05),
            sd_donkey_med = median(sd_donkey), sd_resid_med = median(sd_resid), share_singular = mean(singular),
            rho_dd_achieved_med = median(rho_dd_achieved), share_pd_fixed = mean(pd_fixed), .groups = "drop") |>
  left_join(pvals |> transmute(outcome, contrast, p_reported, p_type), by = c("outcome", "contrast"))
cat("\n== Part 2: authors' model (lmer, condition + order, donkey intercept) on simulated complete data ==\n")
print(sim_summary |> select(outcome, rho_dd, contrast, estimate_med, se_med, df_med, t_med, t_lo, t_hi, p_med, p_max,
                            share_p_below_0.05, sd_donkey_med, sd_resid_med, share_singular, p_reported, p_type) |>
        mutate(across(where(is.numeric), ~ signif(.x, 3))), n = 30, width = 220)
write_csv(sim_summary, file.path(out_tab, "sim_contrasts_summary.csv"))

moment_check <- moments |> group_by(outcome, rho_dd, condition) |>
  summarise(mean_target = first(mean_target), mean_sim_med = median(mean_sim), sd_target = first(sd_target),
            sd_sim_med = median(sd_sim), sd_sim_lo = q(sd_sim, .025), sd_sim_hi = q(sd_sim, .975),
            r_cd_target_pos = median(r_cd_target_pos), r_cd_achieved_pos = median(r_cd_achieved_pos),
            r_cd_target_neg = median(r_cd_target_neg), r_cd_achieved_neg = median(r_cd_achieved_neg), .groups = "drop")
cat("\n== simulated condition moments vs Table 2 (medians over replicates) ==\n")
print(moment_check |> filter(rho_dd == 0) |> mutate(across(where(is.numeric), ~ signif(.x, 4))), width = 220)
write_csv(moment_check, file.path(out_tab, "sim_moment_check.csv"))

write_csv(list_rbind(example), here_art("data/derived/simulated_conditions_example.csv"))
cat("\nWritten: output/tables/contrasts_*.csv, sim_*.csv; data/derived/simulated_conditions_example.csv\n")
