# 02_consistency_checks.R — Shi et al. 2026, Sci Rep (P002)
#
# Recomputes everything that can be recomputed from the numbers reported in the paper.
# Inputs : data/raw/*.csv (transcribed from the PDF, see data/raw/EXTRACTION_LOG.md)
# Outputs: output/tables/consistency_*.csv (one file per block) and
#          output/tables/consistency_summary.csv (one row per check, read by review.qmd)
# Run    : from the nix shell, any working directory inside the repo:
#          Rscript SciRep_cognitive_impairment_cerebrovascular_events_Shi_2026/R/02_consistency_checks.R
#
# Assumptions used throughout (the paper states neither): complete covariate data, so every
# model uses all 3875 participants; chi-square tests are Pearson's without continuity
# correction, the SAS PROC FREQ default. Each block says which assumption it relies on.
#
# Blocks (protocol v0.1 item in brackets):
#   A  Table 1 counts: percentages and NCI + CI = overall                              [E3, E5]
#   B  Table 1 p-values for categorical rows recomputed from the counts                [E1]
#   C  Table 1 medians and quartiles: an overall quantile must lie between the groups' [E3]
#   D  Table 2: percentages, CI widths vs event counts, crude ratios, log-rank          [E1, E3]
#   E  Fig. 2: numbers at risk vs Table 2 events; step count and end value of CI curves [E4]
#   F  Timeline: MMSE visit, end of follow-up, median follow-up, at risk at 4 years     [E5]
#   G  What Table 2 implies for the screening claim; events per parameter              [G1, D1]
#   H  Supplementary Table S1: denominators behind the percentages, p-values, S1 vs Table 1 [C6, E1, E4]

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(purrr)
  library(readr)
  library(tibble)
})
source(here::here("lib/consistency.R"))
here_art <- function(...) here::here("SciRep_cognitive_impairment_cerebrovascular_events_Shi_2026", ...)
raw <- function(f) readr::read_csv(here_art("data/raw", f), show_col_types = FALSE)
out_dir <- here_art("output/tables")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
save <- function(x, name) { write_csv(x, file.path(out_dir, paste0("consistency_", name, ".csv"))); invisible(x) }

t1   <- raw("table1_baseline.csv")
t2   <- raw("table2_cox.csv")
ar   <- raw("fig2_at_risk.csv")
curv <- raw("fig2_curve_features.csv")
txt  <- raw("text_numbers.csv")

N_ALL <- 3875L; N_NCI <- 3683L; N_CI <- 192L   # Table 1 column headers
pct1  <- function(n, N) round(100 * n / N, 1)
near  <- function(a, b, tol) !is.na(a) & !is.na(b) & abs(a - b) <= tol + 1e-9
fmt_p <- function(p) ifelse(p < 1e-4, formatC(p, format = "e", digits = 1), formatC(p, format = "f", digits = 4))

summary_rows <- list()
add <- function(block, item, result, detail) {
  summary_rows[[length(summary_rows) + 1]] <<- tibble(block = block, item = item, result = result, detail = detail)
}

# --------------------------------------------------------------------------------------------
# A. Table 1 counts                                                                 [E3, E5]
# --------------------------------------------------------------------------------------------
cnt <- t1 |> filter(type == "count")
a <- cnt |>
  transmute(variable,
            overall_n, overall_pct, overall_pct_rec = pct1(overall_n, N_ALL),
            nci_n, nci_pct, nci_pct_rec = pct1(nci_n, N_NCI),
            ci_n, ci_pct, ci_pct_rec = pct1(ci_n, N_CI),
            sum_groups = nci_n + ci_n,
            pct_ok = near(overall_pct, overall_pct_rec, 0.05) & near(nci_pct, nci_pct_rec, 0.05) &
                     near(ci_pct, ci_pct_rec, 0.05),
            sum_ok = sum_groups == overall_n)
save(a, "A_table1_counts")
add("A", "Table 1 percentages from n / N", if (all(a$pct_ok)) "consistent" else "inconsistent",
    sprintf("%d of %d rows reproduce all three percentages to 0.1", sum(a$pct_ok), nrow(a)))
add("A", "Table 1 NCI + CI = overall", if (all(a$sum_ok)) "consistent" else "inconsistent",
    sprintf("%d of %d rows add up", sum(a$sum_ok), nrow(a)))
edu <- cnt |> filter(grepl("^Education", variable))
add("A", "Education levels sum to group sizes",
    if (sum(edu$overall_n) == N_ALL && sum(edu$nci_n) == N_NCI && sum(edu$ci_n) == N_CI) "consistent" else "inconsistent",
    sprintf("overall %d, NCI %d, CI %d", sum(edu$overall_n), sum(edu$nci_n), sum(edu$ci_n)))

# --------------------------------------------------------------------------------------------
# B. Table 1 p-values for the categorical rows                                          [E1]
# --------------------------------------------------------------------------------------------
# Pearson chi-square without continuity correction (SAS default); Fisher's exact test alongside
# because ECAS has 4 events in the CI group. The paper says "chi-square test".
chisq_2x2 <- function(n1, N1, n2, N2) {
  m <- matrix(c(n1, N1 - n1, n2, N2 - n2), nrow = 2)
  ct <- suppressWarnings(chisq.test(m, correct = FALSE))
  tibble(chisq = unname(ct$statistic), p_pearson = ct$p.value,
         p_fisher = fisher.test(m)$p.value, min_expected = min(ct$expected))
}
b_rows <- cnt |> filter(p_scope == "row") |>
  mutate(res = pmap(list(nci_n, N_NCI, ci_n, N_CI), chisq_2x2)) |>
  unnest(res) |>
  mutate(p_reported_ok = if_else(p_type == "less_than", p_pearson < p_reported,
                                 map2_lgl(p_reported, p_pearson, \(r, c) p_consistent(r, c, "exact", decimals = 4))),
         chisq_needed_for_reported = qchisq(1 - p_reported, df = 1)) |>
  select(variable, nci_n, nci_pct, ci_n, ci_pct, p_reported, p_type, chisq, p_pearson, p_fisher,
         min_expected, chisq_needed_for_reported, p_reported_ok)
# education: one 3 x 2 test
m_edu <- matrix(c(edu$nci_n, edu$ci_n), ncol = 2)
ct_edu <- chisq.test(m_edu, correct = FALSE)
b_edu <- tibble(variable = "Education (3 levels, one test)", nci_n = NA, nci_pct = NA, ci_n = NA, ci_pct = NA,
                p_reported = 0.0001, p_type = "less_than", chisq = unname(ct_edu$statistic),
                p_pearson = ct_edu$p.value, p_fisher = fisher.test(m_edu)$p.value,
                min_expected = min(ct_edu$expected), chisq_needed_for_reported = qchisq(1 - 0.0001, df = 2),
                p_reported_ok = ct_edu$p.value < 0.0001)
b <- bind_rows(b_rows, b_edu)
save(b, "B_table1_pvalues")
bad_b <- b |> filter(!p_reported_ok)
add("B", "Table 1 categorical p-values from the counts",
    if (nrow(bad_b) == 0) "consistent" else "inconsistent",
    if (nrow(bad_b) == 0) sprintf("all %d tests reproduce the reported p at 4 decimals (or the < bound)", nrow(b)) else
      paste(sprintf("%s: reported %s%s, recomputed %s (chi-square %.2f; %.1f needed for the reported p)",
                    bad_b$variable, ifelse(bad_b$p_type == "less_than", "< ", ""), bad_b$p_reported,
                    fmt_p(bad_b$p_pearson), bad_b$chisq, bad_b$chisq_needed_for_reported), collapse = "; "))
add("B", "Table 1 tests with a small expected count", if (any(b$min_expected < 5)) "note" else "consistent",
    paste(sprintf("%s: min expected %.1f, Pearson %s, Fisher %s", b$variable[b$min_expected < 5],
                  b$min_expected[b$min_expected < 5], fmt_p(b$p_pearson[b$min_expected < 5]),
                  fmt_p(b$p_fisher[b$min_expected < 5])), collapse = "; "))

# --------------------------------------------------------------------------------------------
# C. Table 1 medians and quartiles: mixture constraint                                  [E3]
# --------------------------------------------------------------------------------------------
# The overall sample is the union of NCI and CI, so each overall quantile must lie between the
# smaller and the larger of the two group quantiles (up to the printed rounding of 0.05).
med <- t1 |> filter(type == "median")
c_long <- med |>
  select(variable, starts_with("overall_"), starts_with("nci_"), starts_with("ci_")) |>
  select(variable, ends_with("_med"), ends_with("_q1"), ends_with("_q3")) |>
  pivot_longer(-variable, names_to = c("group", "stat"), names_sep = "_") |>
  pivot_wider(names_from = group, values_from = value) |>
  mutate(lower = pmin(nci, ci), upper = pmax(nci, ci),
         within = overall >= lower - 0.05 & overall <= upper + 0.05,
         distance = case_when(overall < lower ~ overall - lower, overall > upper ~ overall - upper, TRUE ~ 0))
save(c_long, "C_table1_quantiles")
bad_c <- c_long |> filter(!within)
add("C", "Overall quantiles between the group quantiles", if (nrow(bad_c) == 0) "consistent" else "inconsistent",
    if (nrow(bad_c) == 0) "all 24 overall quantiles lie between the NCI and CI values" else
      paste(sprintf("%s %s: overall %.1f, NCI %.1f, CI %.1f", bad_c$variable, bad_c$stat, bad_c$overall, bad_c$nci, bad_c$ci), collapse = "; "))

# --------------------------------------------------------------------------------------------
# D. Table 2                                                                        [E1, E3]
# --------------------------------------------------------------------------------------------
d_pct <- t2 |> mutate(pct_rec = pct1(events, n_group), pct_ok = near(pct, pct_rec, 0.05))
add("D", "Table 2 event percentages", if (all(d_pct$pct_ok)) "consistent" else "inconsistent",
    sprintf("%d of %d cells reproduce", sum(d_pct$pct_ok), nrow(d_pct)))

# For a two-group Cox model the SE of log HR is close to sqrt(1/d1 + 1/d2) (events only).
# The printed CI gives SE = (log hi - log lo) / (2 * 1.96). The ratio of the two is a check that
# the unadjusted HRs belong to these event counts; the crude risk ratio is where the HR should
# sit if person-time per head were equal in the two groups.
d_hr <- t2 |> filter(group == "CI") |>
  left_join(t2 |> filter(group == "NCI") |> select(outcome, nci_events = events, nci_n = n_group), by = "outcome") |>
  transmute(outcome, ci_events = events, ci_n = n_group, nci_events, nci_n,
            crude_risk_ratio = (ci_events / ci_n) / (nci_events / nci_n),
            hr_unadj, hr_unadj_lo, hr_unadj_hi,
            se_from_ci  = (log(hr_unadj_hi) - log(hr_unadj_lo)) / (2 * qnorm(0.975)),
            se_from_counts = sqrt(1 / ci_events + 1 / nci_events),
            se_ratio = se_from_ci / se_from_counts,
            ci_lo_rec = exp(log(hr_unadj) - qnorm(0.975) * se_from_counts),
            ci_hi_rec = exp(log(hr_unadj) + qnorm(0.975) * se_from_counts),
            ci_ok = near(ci_lo_rec, hr_unadj_lo, 0.02) & near(ci_hi_rec, hr_unadj_hi, 0.02),
            # score (log-rank) chi-square approximated by the Wald chi-square of the unadjusted log HR
            logrank_chisq_approx = (log(hr_unadj) / se_from_counts)^2,
            logrank_p_approx = pchisq(logrank_chisq_approx, 1, lower.tail = FALSE),
            se_m1 = (log(hr_m1_hi) - log(hr_m1_lo)) / (2 * qnorm(0.975)),
            se_m2 = (log(hr_m2_hi) - log(hr_m2_lo)) / (2 * qnorm(0.975)),
            attenuation_m1 = log(hr_m1) / log(hr_unadj),
            attenuation_m2 = log(hr_m2) / log(hr_unadj))
save(d_hr, "D_table2_hr")
add("D", "Unadjusted HR CIs vs event counts", if (all(d_hr$ci_ok)) "consistent" else "inconsistent",
    paste(sprintf("%s: printed [%.2f, %.2f], from 1/%d + 1/%d [%.2f, %.2f]; crude risk ratio %.2f vs HR %.2f",
                  d_hr$outcome, d_hr$hr_unadj_lo, d_hr$hr_unadj_hi, d_hr$ci_events, d_hr$nci_events,
                  d_hr$ci_lo_rec, d_hr$ci_hi_rec, d_hr$crude_risk_ratio, d_hr$hr_unadj), collapse = "; "))
add("D", "Log-rank p: text '< 0.01' vs figure '< 0.0001'", "approximate",
    paste(sprintf("%s: Wald chi-square of the unadjusted log HR %.1f, p %s", d_hr$outcome,
                  d_hr$logrank_chisq_approx, fmt_p(d_hr$logrank_p_approx)), collapse = "; "))
add("D", "Attenuation of log HR by adjustment", "note",
    paste(sprintf("%s: Model 1 keeps %.0f%% of the unadjusted log HR, Model 2 %.0f%%", d_hr$outcome,
                  100 * d_hr$attenuation_m1, 100 * d_hr$attenuation_m2), collapse = "; "))

# --------------------------------------------------------------------------------------------
# E. Fig. 2 numbers at risk vs Table 2; shape of the CI curves                          [E4]
# --------------------------------------------------------------------------------------------
# Removals from the risk set by year 4: for the mortality panel = deaths + censorings before
# year 4; for a stroke panel = strokes + deaths without prior stroke + censorings before year 4.
# Hence deaths before year 4 <= removals in panel C, and strokes before year 4 >= removals in the
# stroke panel minus removals in panel C. Events after year 4 follow from the Table 2 totals.
axis_end <- as.numeric(curv$value[curv$feature == "x_axis_end"][1])
removed <- ar |> filter(year %in% c(0, 4)) |>
  pivot_wider(names_from = year, values_from = n_at_risk, names_prefix = "y") |>
  mutate(removed_by_y4 = y0 - y4)
events <- t2 |> filter(group != "overall") |> select(outcome, group, events_total = events)
e <- removed |> left_join(events, by = c("outcome", "group")) |>
  left_join(removed |> filter(panel == "C") |> select(group, removed_C = removed_by_y4), by = "group") |>
  mutate(min_events_before_y4 = if_else(panel == "C", NA_real_, pmax(removed_by_y4 - removed_C, 0)),
         max_events_before_y4 = if_else(panel == "C", removed_C, pmin(removed_by_y4, events_total)),
         min_events_after_y4  = events_total - max_events_before_y4,
         share_after_y4_min   = min_events_after_y4 / events_total,
         axis_end_years       = axis_end,
         # crude rates per 100 person-years, before year 4 and in the tail of the axis
         rate_before_y4_max   = 100 * max_events_before_y4 / (4 * (y0 + y4) / 2),
         rate_after_y4_min    = 100 * min_events_after_y4 / ((axis_end_years - 4) * y4)) |>
  select(panel, outcome, group, y0, y4, removed_by_y4, events_total, min_events_before_y4,
         max_events_before_y4, min_events_after_y4, share_after_y4_min, rate_before_y4_max, rate_after_y4_min)
save(e, "E_fig2_at_risk")
e_dead <- e |> filter(panel == "C")
add("E", "Deaths after year 4 implied by the at-risk numbers", "inconsistent",
    paste(sprintf("%s: %d deaths in Table 2, at most %d before year 4 (%d -> %d at risk), so at least %d (%.0f%%) in the last %.1f years of the axis: %.1f vs at most %.2f per 100 person-years",
                  e_dead$group, e_dead$events_total, e_dead$max_events_before_y4, e_dead$y0, e_dead$y4, e_dead$min_events_after_y4,
                  100 * e_dead$share_after_y4_min, round(axis_end - 4, 1), e_dead$rate_after_y4_min, e_dead$rate_before_y4_max),
          collapse = "; "))

ci_curves <- curv |> filter(group == "CI", feature %in% c("n_steps", "final_value")) |>
  select(panel, feature, value) |> pivot_wider(names_from = feature, values_from = value) |>
  mutate(across(c(n_steps, final_value), as.numeric)) |>
  left_join(t2 |> filter(group == "CI") |> select(outcome, events, pct) |>
              mutate(panel = c("A", "B", "C")), by = "panel") |>
  left_join(ar |> filter(group == "CI", year == 4) |> select(panel, at_risk_y4 = n_at_risk), by = "panel") |>
  mutate(expected_final_if_percent = pct, expected_final_if_proportion = pct / 100,
         steps_vs_events = sprintf("%d steps drawn, %d events reported", as.integer(n_steps), events))
save(ci_curves, "E_fig2_ci_curves")
add("E", "CI curves: steps and end value vs Table 2 and numbers at risk", "inconsistent",
    paste(sprintf("panel %s (%s): %s; curve ends at %.2f on a 0-1 axis labelled %%, Table 2 gives %.1f%% (%.3f as a proportion); %d of 192 still at risk at year 4",
                  ci_curves$panel, ci_curves$outcome, ci_curves$steps_vs_events, ci_curves$final_value,
                  ci_curves$pct, ci_curves$pct / 100, ci_curves$at_risk_y4), collapse = "; "))
nci_end <- curv |> filter(group == "NCI", feature == "final_value") |> mutate(value = as.numeric(value)) |>
  left_join(t2 |> filter(group == "NCI") |> mutate(panel = c("A", "B", "C")) |> select(panel, pct), by = "panel")
add("E", "NCI curves: end value vs Table 2", "inconsistent",
    paste(sprintf("panel %s ends near %.2f, Table 2 %.1f%%: too small for percent, too large for a proportion", nci_end$panel, nci_end$value, nci_end$pct), collapse = "; "))
add("E", "Stroke panels: difference of NCI removals A vs B", "consistent",
    sprintf("3614 - 3605 = %d, the 75 - 66 = 9 non-ischaemic strokes in NCI; CI columns identical in A and B as 15 = 15",
            removed$y4[removed$panel == "A" & removed$group == "NCI"] - removed$y4[removed$panel == "B" & removed$group == "NCI"]))

# --------------------------------------------------------------------------------------------
# F. Timeline                                                                           [E5]
# --------------------------------------------------------------------------------------------
# Stated: MMSE at the first follow-up "from 2012 to 2013"; follow-up "until December 31, 2015";
# median follow-up 4.1 years; Fig. 2 at-risk at 4 years 3653 / 3683 and 186 / 192.
fu <- function(from, to) as.numeric(as.Date(to) - as.Date(from)) / 365.25
f <- tribble(
  ~time_origin,                 ~earliest,    ~latest,      ~end,
  "MMSE visit (2012-2013)",     "2012-01-01", "2013-12-31", "2015-12-31",
  "APAC baseline (2010-2011)",  "2010-01-01", "2011-12-31", "2015-12-31") |>
  mutate(max_follow_up = fu(earliest, end), min_follow_up = fu(latest, end),
         median_reported = 4.1,
         median_possible = median_reported <= max_follow_up & median_reported >= min_follow_up,
         share_at_risk_4y_nci = 3653 / 3683, share_at_risk_4y_ci = 186 / 192,
         four_years_possible_for_all = min_follow_up >= 4,
         deaths_in_first_year_possible = time_origin == "MMSE visit (2012-2013)")
save(f, "F_timeline")
add("F", "Median follow-up 4.1 years vs the stated dates", "inconsistent",
    paste(sprintf("origin %s: follow-up %.1f-%.1f years, median 4.1 %s, >= 4 years for everyone %s",
                  f$time_origin, f$min_follow_up, f$max_follow_up,
                  ifelse(f$median_possible, "possible", "impossible"),
                  ifelse(f$four_years_possible_for_all, "possible", "impossible")), collapse = "; "))
add("F", "Fig. 2 at risk at 4 years", "note",
    sprintf("NCI %.1f%% and CI %.1f%% of the groups are still under observation at 4 years; panel C shows NCI deaths from about %s years",
            100 * 3653 / 3683, 100 * 186 / 192, curv$value[curv$panel == "C" & curv$group == "NCI" & curv$feature == "first_step_time"]))

# --------------------------------------------------------------------------------------------
# G. Screening claim and events per parameter                                      [G1, D1]
# --------------------------------------------------------------------------------------------
g <- t2 |> filter(group != "overall") |>
  select(outcome, group, n_group, events) |>
  pivot_wider(names_from = group, values_from = c(n_group, events)) |>
  transmute(outcome,
            sensitivity = events_CI / (events_CI + events_NCI),
            specificity = (n_group_NCI - events_NCI) / ((n_group_NCI - events_NCI) + (n_group_CI - events_CI)),
            ppv = events_CI / n_group_CI, npv = (n_group_NCI - events_NCI) / n_group_NCI,
            lr_pos = sensitivity / (1 - specificity), lr_neg = (1 - sensitivity) / specificity,
            events_total = events_CI + events_NCI,
            params_model2 = 9L,   # CI, age, gender, education (2 dummies), homocysteine, ICAS, hypertension, occupation
            events_per_parameter = events_total / params_model2,
            exposed_events = events_CI)
save(g, "G_screening_epv")
add("G", "Screening performance implied by Table 2", "note",
    paste(sprintf("%s: sensitivity %.1f%%, specificity %.1f%%, PPV %.1f%%, LR+ %.1f", g$outcome,
                  100 * g$sensitivity, 100 * g$specificity, 100 * g$ppv, g$lr_pos), collapse = "; "))
add("G", "Events per parameter in Model 2", "note",
    paste(sprintf("%s: %d events / 9 parameters = %.1f; %d events in the exposed group", g$outcome, g$events_total,
                  g$events_per_parameter, g$exposed_events), collapse = "; "))

# --------------------------------------------------------------------------------------------
# H. Supplementary Table S1: excluded vs included; S1 "included" column vs Table 1 "overall"   [C6, E1, E4]
# --------------------------------------------------------------------------------------------
# S1 reports counts for excluded (1565) and included (3875). A printed percentage pins its
# denominator to an interval (rounding to one decimal); where that interval excludes the group
# size, the row was computed on participants with data for that variable, i.e. the variable has
# missing values the paper never mentions. The p-values are recomputed twice: with the full group
# sizes and with the midpoint of the implied denominators.
s1 <- raw("suppl_table_s1.csv")
N_EXC <- 1565L
den_range <- function(n, pct) {
  lo <- ceiling(n * 100 / (pct + 0.05)); hi <- floor(n * 100 / (pct - 0.05))
  tibble(den_lo = lo, den_hi = hi)
}
h_cnt <- s1 |> filter(type == "count") |>
  mutate(exc = pmap(list(excluded_n, excluded_pct), den_range), inc = pmap(list(included_n, included_pct), den_range)) |>
  unnest(exc, names_sep = "_") |> unnest(inc, names_sep = "_") |>
  mutate(exc_full_den_ok = exc_den_lo <= N_EXC & N_EXC <= exc_den_hi,
         inc_full_den_ok = inc_den_lo <= N_ALL & N_ALL <= inc_den_hi,
         exc_den_mid = round((exc_den_lo + exc_den_hi) / 2), inc_den_mid = round((inc_den_lo + inc_den_hi) / 2))
h_p <- h_cnt |> filter(p_scope == "row") |>
  mutate(full = pmap(list(excluded_n, N_EXC, included_n, N_ALL), chisq_2x2),
         impl = pmap(list(excluded_n, exc_den_mid, included_n, inc_den_mid), chisq_2x2)) |>
  unnest(full, names_sep = "_") |> unnest(impl, names_sep = "_") |>
  mutate(p_full_ok = if_else(p_type == "less_than", full_p_pearson < p_reported,
                             map2_lgl(p_reported, full_p_pearson, \(r, c) p_consistent(r, c, "exact", decimals = 4))),
         p_impl_ok = if_else(p_type == "less_than", impl_p_pearson < p_reported,
                             map2_lgl(p_reported, impl_p_pearson, \(r, c) p_consistent(r, c, "exact", decimals = 2)))) |>
  select(variable, excluded_n, excluded_pct, exc_den_lo, exc_den_hi, exc_full_den_ok,
         included_n, included_pct, inc_den_lo, inc_den_hi, inc_full_den_ok,
         p_reported, p_type, p_full = full_p_pearson, p_full_ok, p_impl = impl_p_pearson, p_impl_ok)
save(h_p, "H_s1_pvalues_denominators")
off <- h_p |> filter(!exc_full_den_ok | !inc_full_den_ok)
add("H", "S1 percentages whose denominators are not the group sizes", if (nrow(off) == 0) "consistent" else "inconsistent",
    paste(sprintf("%s: excluded %d (%.1f%%) needs a denominator in [%d, %d] not 1565; included %d (%.1f%%) needs [%d, %d] not 3875; p reported %s, %s with the group sizes, %s with the implied denominators",
                  off$variable, off$excluded_n, off$excluded_pct, off$exc_den_lo, off$exc_den_hi,
                  off$included_n, off$included_pct, off$inc_den_lo, off$inc_den_hi,
                  off$p_reported, fmt_p(off$p_full), fmt_p(off$p_impl)), collapse = "; "))
ok_rows <- h_p |> filter(exc_full_den_ok, inc_full_den_ok)
add("H", "S1 p-values recomputed with the group sizes", if (all(ok_rows$p_full_ok)) "consistent" else "inconsistent",
    sprintf("%d of %d rows with full denominators reproduce the printed p (%s)", sum(ok_rows$p_full_ok), nrow(ok_rows),
            paste(sprintf("%s %s", ok_rows$variable, fmt_p(ok_rows$p_full)), collapse = ", ")))
s1_edu <- s1 |> filter(grepl("^education", variable))
add("H", "S1 education rows sum to the group sizes",
    if (sum(s1_edu$excluded_n) == N_EXC && sum(s1_edu$included_n) == N_ALL) "consistent" else "inconsistent",
    sprintf("excluded %d + %d + %d = %d (1565); included %d + %d + %d = %d (3875); middle school 2394 is %.1f%% of 3875, printed 42.9%% = Table 1's 1662",
            s1_edu$excluded_n[1], s1_edu$excluded_n[2], s1_edu$excluded_n[3], sum(s1_edu$excluded_n),
            s1_edu$included_n[1], s1_edu$included_n[2], s1_edu$included_n[3], sum(s1_edu$included_n), 100 * 2394 / 3875))
# S1 "included" column against Table 1 "overall" column, cell by cell
h_x <- s1 |> select(table1_variable, included_n, included_pct, included_med, included_q1, included_q3) |>
  inner_join(t1 |> select(variable, overall_n, overall_pct, overall_med, overall_q1, overall_q3), by = c("table1_variable" = "variable")) |>
  pivot_longer(-table1_variable, names_to = c("source", "stat"), names_pattern = "(included|overall)_(.*)") |>
  pivot_wider(names_from = source, values_from = value) |>
  filter(!(is.na(included) & is.na(overall))) |>
  mutate(agree = near(included, overall, 0.001))
save(h_x, "H_s1_vs_table1")
bad_x <- h_x |> filter(!agree)
add("H", "S1 included column vs Table 1 overall column", if (nrow(bad_x) == 0) "consistent" else "inconsistent",
    sprintf("%d of %d shared cells agree; %s", sum(h_x$agree), nrow(h_x),
            paste(sprintf("%s %s: S1 %s, Table 1 %s", bad_x$table1_variable, bad_x$stat, bad_x$included, bad_x$overall), collapse = "; ")))
add("H", "Share excluded", "note",
    sprintf("1512 / 5440 = %.1f%% missing MMSE; 1565 / 5440 = %.1f%% excluded in all; the Discussion says 28.8%% for missing MMSE; the text calls S1's median age 54.6 a mean",
            100 * 1512 / 5440, 100 * 1565 / 5440))

# --------------------------------------------------------------------------------------------
summary_tbl <- bind_rows(summary_rows)
write_csv(summary_tbl, file.path(out_dir, "consistency_summary.csv"))
print(summary_tbl |> select(block, item, result), n = 50, width = 120)
cat("\nDetails in", out_dir, "\n")
