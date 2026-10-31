# 02_consistency_checks.R — Bukhari et al. 2026, Sci Rep (P001)
#
# Recomputes everything that can be recomputed from the numbers reported in the paper.
# Inputs : data/raw/*.csv (transcribed from the PDF, see data/raw/EXTRACTION_LOG.md)
# Outputs: output/tables/consistency_*.csv  (one file per block) and
#          output/tables/consistency_summary.csv (one row per check, read by review.qmd)
# Run    : from the nix shell, any working directory inside the repo:
#          Rscript SciRep_emotions_in_working_donkeys_Bukhari_2026/R/02_consistency_checks.R
#
# Assumption used throughout: n = 34 donkeys in every cell. The paper never states n per
# analysis; every check that depends on it says so in its `assumption` column.
#
# Blocks (protocol v0.1 item in brackets):
#   A  condition contrasts: paired t and p from the Δ rows vs reported p        [E1]
#   B  Δ rows vs difference of condition means, sign and magnitude               [E3]
#   C  GRIM on integer-valued summaries (SBR means, Fig. 1 biases, age, BCS)     [E2]
#   D  Tables 3–4: internal arithmetic and cross-check against Table 2 Δ means   [E1, E3]
#   E  implied within-donkey correlations from the paired SDs                    [E3]
#   F  power analysis: which test gives n = 34 for ρ = 0.5, α = .05, 1−β = .95   [B7]

suppressPackageStartupMessages({
  library(tidyverse)
})
source(here::here("lib/consistency.R"))
here_art <- function(...) here::here("SciRep_emotions_in_working_donkeys_Bukhari_2026", ...)
raw <- function(f) readr::read_csv(here_art("data/raw", f), show_col_types = FALSE)
out_dir <- here_art("output/tables")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

N <- 34L   # stated sample size; see header

cond   <- raw("table2_conditions.csv")
chg    <- raw("table2_changes.csv")
pvals  <- raw("text_contrast_pvalues.csv")
regs   <- raw("tables3_4_regressions.csv")
ba     <- raw("fig1_bland_altman.csv")
meth   <- raw("methods_numbers.csv")

num <- function(q) as.numeric(meth$value[meth$quantity == q])

# --------------------------------------------------------------------------------------------
# A. Condition contrasts: what the Δ rows imply vs the p-values reported                 [E1]
# --------------------------------------------------------------------------------------------
# A paired t on the Δ row is the simplest model consistent with "LMM with donkey random
# intercept". Adding an order fixed effect (2–5 df) cannot move p by orders of magnitude.
# As a worst case we also compute the *unpaired* Welch t between the two condition columns,
# which ignores the pairing entirely and is the weakest test anyone could run.

contrasts <- chg |>
  left_join(cond |> filter(condition == "control") |>
              select(outcome, ctrl_mean = mean, ctrl_sd = sd), by = "outcome") |>
  left_join(cond |> filter(condition != "control") |>
              select(outcome, treatment = condition, trt_mean = mean, trt_sd = sd),
            by = c("outcome", "treatment")) |>
  left_join(pvals |> mutate(treatment = sub("_vs_control", "", contrast)) |>
              select(outcome, treatment, p_reported, p_type, p_source = source),
            by = c("outcome", "treatment"))

paired   <- pmap_dfr(list(contrasts$delta_mean, contrasts$delta_sd),
                     \(m, s) t_from_summary(m, s, N))
unpaired <- pmap_dfr(list(contrasts$trt_mean, contrasts$trt_sd, contrasts$ctrl_mean, contrasts$ctrl_sd),
                     \(m1, s1, m2, s2) t_welch_from_summary(m1, s1, N, m2, s2, N))

block_A <- contrasts |>
  mutate(n_assumed        = N,
         t_paired         = paired$t,
         df_paired        = paired$df,
         p_paired         = paired$p_two_sided,
         t_unpaired_welch = unpaired$t,
         p_unpaired_welch = unpaired$p_two_sided,
         # |t| that the reported p would require at df = 33 (paired) and df = 60 (≈ LMM df)
         t_needed_df33    = t_needed_for_p(p_reported, 33),
         t_needed_df60    = t_needed_for_p(p_reported, 60),
         p_consistent     = pmap_lgl(list(p_reported, p_paired, p_type),
                                     \(pr, pc, ty) p_consistent(pr, pc, reported_as = ty)),
         consistent_even_unpaired = pmap_lgl(list(p_reported, p_unpaired_welch, p_type),
                                     \(pr, pc, ty) p_consistent(pr, pc, reported_as = ty))) |>
  select(outcome, treatment, delta_mean, delta_sd, n_assumed,
         t_paired, df_paired, p_paired, t_unpaired_welch, p_unpaired_welch,
         p_reported, p_type, p_source, t_needed_df33, t_needed_df60,
         p_consistent, consistent_even_unpaired)

# Ordering check (df-free): within an outcome, the contrast with the larger |t| must have the
# smaller p. A reported *exact* p larger than a reported "< 0.001" on a bigger t is impossible
# for two models of the same structure.
block_A_order <- block_A |>
  group_by(outcome) |>
  summarise(
    larger_t_treatment    = treatment[which.max(abs(t_paired))],
    larger_t_p_reported   = p_reported[which.max(abs(t_paired))],
    larger_t_p_type       = p_type[which.max(abs(t_paired))],
    smaller_t_treatment   = treatment[which.min(abs(t_paired))],
    smaller_t_p_reported  = p_reported[which.min(abs(t_paired))],
    smaller_t_p_type      = p_type[which.min(abs(t_paired))],
    .groups = "drop") |>
  mutate(ordering_violated = larger_t_p_type == "exact" & smaller_t_p_type == "less_than" &
                             larger_t_p_reported > smaller_t_p_reported)

write_csv(block_A,       file.path(out_dir, "consistency_contrasts.csv"))
write_csv(block_A_order, file.path(out_dir, "consistency_contrasts_ordering.csv"))

# --------------------------------------------------------------------------------------------
# B. Δ rows vs condition means: sign and magnitude                                        [E3]
# --------------------------------------------------------------------------------------------
# Definition as printed (Methods and Table 2 caption): Δ = control − treatment.
# With complete pairs, mean(Δ) = mean(control) − mean(treatment) exactly. Both means are
# printed to 2 dp, so the difference is known to ±0.01 (± half a unit of the reported Δ's own
# precision is added for the comparison).

# The printed precision of each Δ matters (19.0 vs 6.79): read the column as text once.
delta_decimals <- readr::read_csv(here_art("data/raw/table2_changes.csv"),
                                  col_types = cols(.default = col_character())) |>
  transmute(outcome, treatment,
            delta_decimals = nchar(sub("^[^.]*\\.?", "", delta_mean)))

block_B <- chg |>
  left_join(delta_decimals, by = c("outcome", "treatment")) |>
  left_join(cond |> filter(condition == "control") |> select(outcome, ctrl_mean = mean), by = "outcome") |>
  left_join(cond |> select(outcome, treatment = condition, trt_mean = mean), by = c("outcome", "treatment")) |>
  mutate(expected_signed   = ctrl_mean - trt_mean,
         feasible_low      = abs(expected_signed) - 0.01,
         feasible_high     = abs(expected_signed) + 0.01,
         delta_precision   = 0.5 * 10^(-delta_decimals),
         sign_as_defined   = sign(expected_signed),
         sign_reported     = sign(delta_mean),
         sign_consistent   = sign_as_defined == sign_reported,
         magnitude_in_range = abs(delta_mean) >= feasible_low - delta_precision &
                              abs(delta_mean) <= feasible_high + delta_precision,
         excess_over_abs_diff = abs(delta_mean) - abs(expected_signed),
         # under Δ_reported = mean|control − treatment|, the excess equals
         # 2 × |sum of wrong-direction changes| / n
         implied_wrong_direction_sum = -excess_over_abs_diff * N / 2)

toolkit_B <- pmap_dfr(list(block_B$ctrl_mean, block_B$trt_mean, block_B$delta_mean),
                      \(a, b, d) check_delta(a, b, d, "a_minus_b", tol = 0.02)) |>
  select(toolkit_matches_signed = matches_signed,
         toolkit_matches_absolute = matches_absolute,
         toolkit_sign_lost = sign_lost)
block_B <- bind_cols(block_B, toolkit_B)

write_csv(block_B, file.path(out_dir, "consistency_deltas.csv"))

# --------------------------------------------------------------------------------------------
# C. GRIM                                                                                   [E2]
# --------------------------------------------------------------------------------------------
# SBR is an integer count per donkey per condition (Fig. 1: all coder differences on integers,
# all means on half-integers). The Δ SBR of a donkey is then also an integer. Coder differences
# in Fig. 1 are integers, so their mean (the bias) is GRIM-testable too.
# Age: GRIM-testable if ages are whole years (items = 1) or half-years (items = 2).
# BCS: 1–5 scale in half points → items = 2.

sbr_means <- bind_rows(
  cond |> filter(outcome == "SBR") |> transmute(what = paste("SBR mean,", condition), value = mean, decimals = 2L, items = 1L),
  chg  |> filter(outcome == "SBR") |> transmute(what = paste("Δ SBR mean,", treatment), value = delta_mean,
                                               decimals = if_else(treatment == "positive", 1L, 2L), items = 1L))
grim_in <- bind_rows(
  sbr_means,
  ba |> transmute(what = paste("Fig. 1 bias (C1−C2),", condition), value = bias, decimals = 2L, items = 1L),
  tibble(what = c("age (whole years)", "age (half years)", "BCS (half points)"),
         value = c(num("age_mean"), num("age_mean"), num("bcs_mean")),
         decimals = 2L, items = c(1L, 2L, 2L)))

block_C <- grim_in |>
  mutate(n = N,
         grim_consistent = pmap_lgl(list(value, n, decimals, items),
                                    \(m, n, d, k) grim_consistent(m, n, d, k)),
         nearest_below = floor(value * n * items) / (n * items),
         nearest_above = ceiling(value * n * items) / (n * items),
         assumption = case_when(
           str_detect(what, "SBR")  ~ "integer blinks/min per donkey (Fig. 1); n = 34",
           str_detect(what, "bias") ~ "integer coder differences (Fig. 1); n = 34 points",
           str_detect(what, "age")  ~ "age resolution as stated in `what`; n = 34",
           TRUE                     ~ "half-point BCS; n = 34"))

write_csv(block_C, file.path(out_dir, "consistency_grim.csv"))

# --------------------------------------------------------------------------------------------
# D. Tables 3–4: internal arithmetic and cross-check with Table 2                     [E1, E3]
# --------------------------------------------------------------------------------------------
# Internal: estimate/SE ≈ t; t² ≈ F (1-df term); CI half-width / SE ≈ t_{.975, df}. The last
# ratio identifies the df the software used (1.96 → large df; 2.03 → df ≈ 35).
# Cross-check: for OLS of y on x + treatment (negative = reference) with balanced groups,
#   intercept  = ȳ_neg − b·x̄_neg
#   treatment  = (ȳ_pos − ȳ_neg) − b·(x̄_pos − x̄_neg)
# With a near-zero random intercept the LMM reduces to this. Agreement shows which Δ values
# entered the regressions.

df_from_ratio <- function(r) {            # solve qt(.975, df) = r for df; NA if r <= 1.96
  if (!is.finite(r) || r <= qnorm(.975) + 1e-6) return(Inf)
  uniroot(\(d) qt(.975, d) - r, c(1, 1e5))$root
}

block_D_internal <- regs |>
  mutate(ci_halfwidth   = (ci_high - ci_low) / 2,
         ci_centre      = (ci_high + ci_low) / 2,
         est_over_se    = estimate / se,
         t_minus_ratio  = t - est_over_se,
         # SE is printed to 2 dp, so est/SE is only known to within est/(SE ± 0.005)
         t_range_low    = pmin(estimate / (se + 0.005), estimate / (se - 0.005)),
         t_range_high   = pmax(estimate / (se + 0.005), estimate / (se - 0.005)),
         t_within_rounding = t >= t_range_low - 0.005 & t <= t_range_high + 0.005,
         t_squared      = t^2,
         F_minus_t2     = F - t_squared,
         halfwidth_over_se = ci_halfwidth / se,
         implied_df     = map_dbl(halfwidth_over_se, df_from_ratio),
         p_at_df60      = 2 * pt(-abs(t), 60),
         p_at_df33      = 2 * pt(-abs(t), 33),
         p_reported_num = suppressWarnings(as.numeric(sub("<", "", p_reported))),
         p_reported_type = if_else(str_detect(p_reported, "<"), "less_than", "exact"),
         p_consistent_df60 = pmap_lgl(list(p_reported_num, p_at_df60, p_reported_type),
                                      \(pr, pc, ty) p_consistent(pr, pc, reported_as = ty)))

d_means <- chg |> select(outcome, treatment, delta_mean) |>
  pivot_wider(names_from = c(outcome, treatment), values_from = delta_mean)

block_D_cross <- tibble(
  table     = c(3L, 3L, 4L, 4L),
  term      = c("Intercept", "treatment_positive", "Intercept", "treatment_positive"),
  covariate = c("dSBR", "dSBR", "dET", "dET")) |>
  left_join(regs |> select(table, term, estimate), by = c("table", "term")) |>
  mutate(b     = map_dbl(table, \(tb) regs$estimate[regs$table == tb & regs$term %in% c("dSBR", "dET")]),
         x_pos = if_else(covariate == "dSBR", d_means$SBR_positive, d_means$ET_positive),
         x_neg = if_else(covariate == "dSBR", d_means$SBR_negative, d_means$ET_negative),
         y_pos = d_means$RMSSD_positive,
         y_neg = d_means$RMSSD_negative,
         implied_from_table2 = if_else(term == "Intercept",
                                       y_neg - b * x_neg,
                                       (y_pos - y_neg) - b * (x_pos - x_neg)),
         difference = estimate - implied_from_table2,
         raw_treatment_difference = y_pos - y_neg,
         assumption = "OLS identities; exact only if the donkey random-intercept variance is 0 and groups balanced")

write_csv(block_D_internal, file.path(out_dir, "consistency_regressions_internal.csv"))
write_csv(block_D_cross,    file.path(out_dir, "consistency_regressions_vs_table2.csv"))

# --------------------------------------------------------------------------------------------
# E. Implied within-donkey correlations from the paired SDs                               [E3]
# --------------------------------------------------------------------------------------------
# SD_Δ² = SD_c² + SD_t² − 2 r SD_c SD_t  →  r = (SD_c² + SD_t² − SD_Δ²) / (2 SD_c SD_t).
# Feasible if −1 ≤ r ≤ 1. Also the ingredient for simulating paired data later (stage 2).
block_E <- chg |>
  left_join(cond |> filter(condition == "control") |> select(outcome, ctrl_sd = sd), by = "outcome") |>
  left_join(cond |> select(outcome, treatment = condition, trt_sd = sd), by = c("outcome", "treatment")) |>
  mutate(implied_r = (ctrl_sd^2 + trt_sd^2 - delta_sd^2) / (2 * ctrl_sd * trt_sd),
         feasible  = abs(implied_r) <= 1,
         note      = "assumes Δ SD is the SD of signed differences; if Δ are absolute values this is not the correlation") |>
  select(outcome, treatment, ctrl_sd, trt_sd, delta_sd, implied_r, feasible, note)

write_csv(block_E, file.path(out_dir, "consistency_implied_correlations.csv"))

# --------------------------------------------------------------------------------------------
# F. Power analysis: which test gives n = 34?                                             [B7]
# --------------------------------------------------------------------------------------------
# Inputs as stated: α = 0.05, power = 0.95, "effect size (ρ = 0.5)", G*Power 3.1.
# Candidates, all in base R (no pwr dependency):
#   1. Correlation, point-biserial model (G*Power t-family): noncentral t, df = n − 2,
#      ncp = ρ √n / √(1 − ρ²).  Exact.
#   2. Correlation, bivariate normal model: Fisher-z approximation,
#      n = ((z_α + z_β) / atanh(ρ))² + 3.  G*Power's exact version differs by ≈ 1.
#   3. Paired t with d_z = 0.5 (reading "0.5" as Cohen's d): power.t.test(type = "paired").
#   4. Paired t with the d_z the paper's own Δ rows imply (for perspective).
alpha <- num("power_alpha"); pw <- num("power_target"); rho <- num("power_effect_rho")

power_pb <- function(n, r, alpha, sides) {
  ncp <- r * sqrt(n) / sqrt(1 - r^2); df <- n - 2
  if (sides == 2) { tc <- qt(1 - alpha / 2, df); pt(tc, df, ncp, lower.tail = FALSE) + pt(-tc, df, ncp) }
  else            { tc <- qt(1 - alpha, df);     pt(tc, df, ncp, lower.tail = FALSE) }
}
n_for <- function(f, target) { n <- 4; while (f(n) < target && n < 1e4) n <- n + 1; n }
n_fisher <- function(r, alpha, pw, sides) ceiling(((qnorm(1 - alpha / sides) + qnorm(pw)) / atanh(r))^2 + 3)

dz_paper <- chg |> transmute(label = paste0("Δ ", outcome, " ", treatment), dz = delta_mean / delta_sd)

block_F <- bind_rows(
  tibble(test = "correlation, point-biserial model, two-sided", effect = rho,
         n_required = n_for(\(n) power_pb(n, rho, alpha, 2), pw),
         power_at_34 = power_pb(N, rho, alpha, 2)),
  tibble(test = "correlation, point-biserial model, one-sided", effect = rho,
         n_required = n_for(\(n) power_pb(n, rho, alpha, 1), pw),
         power_at_34 = power_pb(N, rho, alpha, 1)),
  tibble(test = "correlation, bivariate normal (Fisher z approx.), two-sided", effect = rho,
         n_required = n_fisher(rho, alpha, pw, 2),
         power_at_34 = pnorm(atanh(rho) * sqrt(N - 3) - qnorm(1 - alpha / 2))),
  tibble(test = "correlation, bivariate normal (Fisher z approx.), one-sided", effect = rho,
         n_required = n_fisher(rho, alpha, pw, 1),
         power_at_34 = pnorm(atanh(rho) * sqrt(N - 3) - qnorm(1 - alpha))),
  tibble(test = "paired t, d_z = 0.5, two-sided", effect = 0.5,
         n_required = ceiling(power.t.test(delta = 0.5, sd = 1, sig.level = alpha, power = pw, type = "paired")$n),
         power_at_34 = power.t.test(n = N, delta = 0.5, sd = 1, sig.level = alpha, type = "paired")$power),
  tibble(test = "paired t, d_z = 0.5, one-sided", effect = 0.5,
         n_required = ceiling(power.t.test(delta = 0.5, sd = 1, sig.level = alpha, power = pw, type = "paired",
                                           alternative = "one.sided")$n),
         power_at_34 = power.t.test(n = N, delta = 0.5, sd = 1, sig.level = alpha, type = "paired",
                                    alternative = "one.sided")$power),
  dz_paper |> transmute(test = paste0("paired t at the paper's own d_z (", label, "), two-sided"),
                        effect = dz,
                        n_required = map_dbl(dz, \(d) ceiling(power.t.test(delta = d, sd = 1, sig.level = alpha,
                                                                          power = pw, type = "paired")$n)),
                        power_at_34 = map_dbl(dz, \(d) power.t.test(n = N, delta = d, sd = 1, sig.level = alpha,
                                                                   type = "paired")$power))) |>
  mutate(alpha = alpha, power_target = pw, n_stated = num("power_n_result"),
         gives_34 = n_required == 34)

write_csv(block_F, file.path(out_dir, "consistency_power.csv"))

# --------------------------------------------------------------------------------------------
# Summary: one row per check, for review.qmd
# --------------------------------------------------------------------------------------------
summary_tbl <- bind_rows(
  block_A |> transmute(block = "A contrasts", check = paste("p reported vs Δ row:", outcome, treatment),
                       value = sprintf("t = %.1f, p_paired = %.1e, reported %s%s", t_paired, p_paired,
                                       if_else(p_type == "less_than", "< ", "= "), format(p_reported)),
                       verdict = if_else(p_consistent, "consistent", "inconsistent")),
  block_A_order |> transmute(block = "A contrasts", check = paste("p ordering:", outcome),
                             value = sprintf("larger t (%s) p %s vs smaller t (%s) p %s", larger_t_treatment,
                                             larger_t_p_reported, smaller_t_treatment, smaller_t_p_reported),
                             verdict = if_else(ordering_violated, "inconsistent", "consistent")),
  block_B |> transmute(block = "B deltas", check = paste("Δ sign:", outcome, treatment),
                       value = sprintf("defined %+.2f, printed %+.2f", expected_signed, delta_mean),
                       verdict = if_else(sign_consistent, "consistent", "inconsistent")),
  block_B |> transmute(block = "B deltas", check = paste("Δ magnitude:", outcome, treatment),
                       value = sprintf("|diff of means| %.2f (range %.2f–%.2f), printed %.2f",
                                       abs(expected_signed), feasible_low, feasible_high, abs(delta_mean)),
                       verdict = if_else(magnitude_in_range, "consistent", "inconsistent")),
  block_C |> transmute(block = "C GRIM", check = what,
                       value = sprintf("%.2f with n = %d (nearest attainable %.3f / %.3f)", value, n,
                                       nearest_below, nearest_above),
                       verdict = if_else(grim_consistent, "attainable", "not attainable")),
  block_D_internal |> transmute(block = "D regressions", check = paste0("Table ", table, " ", term, ": est/SE vs t, t² vs F"),
                                value = sprintf("est/SE = %.2f (t %.2f); t² = %.2f (F %s); CI/SE = %.2f → df ≈ %s",
                                                est_over_se, t, t_squared, format(F), halfwidth_over_se,
                                                if_else(is.finite(implied_df), sprintf("%.0f", implied_df), ">1000")),
                                verdict = if_else(t_within_rounding & (is.na(F) | abs(F_minus_t2) <= 0.05),
                                                  "consistent", "inconsistent")),
  block_D_cross |> transmute(block = "D regressions", check = paste0("Table ", table, " ", term, " vs Table 2 Δ means"),
                             value = sprintf("reported %.2f, implied %.2f", estimate, implied_from_table2),
                             verdict = if_else(abs(difference) <= 0.15, "consistent (regressions ran on the printed Δ)",
                                               "inconsistent")),
  block_E |> transmute(block = "E implied r", check = paste("within-donkey r:", outcome, treatment),
                       value = sprintf("%.2f", implied_r), verdict = if_else(feasible, "feasible", "infeasible")),
  block_F |> transmute(block = "F power", check = test,
                       value = sprintf("n required %d, power at n = 34: %.3f", n_required, power_at_34),
                       verdict = if_else(gives_34, "gives n = 34", "does not give n = 34")))

write_csv(summary_tbl, file.path(out_dir, "consistency_summary.csv"))

cat("\n==== Consistency checks, Bukhari 2026 (n assumed = 34) ====\n\n")
print(summary_tbl |> select(block, check, value, verdict), n = Inf, width = 200)
cat("\nWritten to", out_dir, ":\n", paste(" ", list.files(out_dir, pattern = "^consistency_"), collapse = "\n"), "\n")
