# 04_reproduce_cox_km.R — Shi et al. 2026, Sci Rep (P002), stage 2
#
# Refits, on the reconstructed persons (R/01_prepare_data.R), what the paper reports from the
# individual data: unadjusted Cox hazard ratios with 95 % CI (Table 2), log-rank tests and
# Kaplan-Meier "cumulative incidence" curves (Fig. 2); adds what the paper does not report: the
# cumulative incidence of stroke with death as a competing event (Aalen-Johansen), and the death
# and stroke rates per interval that the numbers at risk force.
# Inputs : data/derived/recon_persons.csv, data/raw/table2_cox.csv, data/raw/fig2_curve_features.csv
# Outputs: output/tables/stage2_cox_unadjusted.csv   HR, CI, log-rank per scenario/replicate/outcome vs Table 2
#          output/tables/stage2_curves_at_end.csv     1-KM and Aalen-Johansen at year 4 and at the axis end vs Fig. 2 features
#          output/tables/stage2_interval_rates.csv    events per 100 person-years by interval and group
#          output/figures/stage2_km_reconstructed.png the three panels as the reported numbers imply them
# Run    : Rscript SciRep_cognitive_impairment_cerebrovascular_events_Shi_2026/R/04_reproduce_cox_km.R

options(warn = 1)
suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(readr); library(purrr); library(survival); library(ggplot2)
})
here_art <- function(...) here::here("SciRep_cognitive_impairment_cerebrovascular_events_Shi_2026", ...)
out_t <- here_art("output/tables"); out_f <- here_art("output/figures")
dir.create(out_t, showWarnings = FALSE, recursive = TRUE); dir.create(out_f, showWarnings = FALSE, recursive = TRUE)

persons <- read_csv(here_art("data/derived/recon_persons.csv"), show_col_types = FALSE)
t2   <- read_csv(here_art("data/raw/table2_cox.csv"), show_col_types = FALSE)
curv <- read_csv(here_art("data/raw/fig2_curve_features.csv"), show_col_types = FALSE)
AXIS_END <- as.numeric(curv$value[curv$feature == "x_axis_end"][1])
OUTCOMES <- c("ischemic stroke", "any stroke", "all-cause mortality")

# one (time, status) pair per outcome; status 0 censored, 1 outcome event, 2 death before the outcome
outcome_frame <- function(d, outcome) {
  t_ev <- switch(outcome,
                 `ischemic stroke`     = d$t_isch,
                 `any stroke`          = pmin(d$t_isch, d$t_other, na.rm = TRUE),
                 `all-cause mortality` = d$t_death)
  t_ev[is.infinite(t_ev)] <- NA
  t_death <- if (outcome == "all-cause mortality") rep(NA_real_, nrow(d)) else d$t_death
  exit <- pmin(t_ev, t_death, d$t_cens, na.rm = TRUE)
  status <- case_when(!is.na(t_ev) & exit == t_ev ~ 1L, !is.na(t_death) & exit == t_death ~ 2L, TRUE ~ 0L)
  tibble(ci = d$ci, group = d$group, time = exit, status = status)
}

reported <- t2 |> filter(group == "CI") |> select(outcome, hr_unadj, hr_unadj_lo, hr_unadj_hi)

# ---- A. unadjusted Cox and log-rank -------------------------------------------------------------
fit_one <- function(d, outcome) {
  f <- outcome_frame(d, outcome) |> mutate(event = as.integer(status == 1))
  cx <- coxph(Surv(time, event) ~ ci, data = f, ties = "efron")
  lr <- survdiff(Surv(time, event) ~ ci, data = f)
  s <- summary(cx)
  tibble(outcome = outcome, events_nci = sum(f$event[f$ci == 0]), events_ci = sum(f$event[f$ci == 1]),
         py_nci = sum(f$time[f$ci == 0]), py_ci = sum(f$time[f$ci == 1]),
         hr = unname(s$conf.int[1, "exp(coef)"]), lo = unname(s$conf.int[1, "lower .95"]), hi = unname(s$conf.int[1, "upper .95"]),
         se_loghr = unname(s$coefficients[1, "se(coef)"]), logrank_chisq = lr$chisq,
         logrank_p = pchisq(lr$chisq, 1, lower.tail = FALSE))
}
cox <- persons |> group_by(scenario, replicate) |>
  group_modify(\(d, k) map_dfr(OUTCOMES, \(o) fit_one(d, o))) |> ungroup() |>
  left_join(reported, by = "outcome") |>
  left_join(t2 |> filter(group != "overall") |> select(outcome, group, events) |>
              pivot_wider(names_from = group, values_from = events, names_prefix = "t2_events_"), by = "outcome") |>
  mutate(events_match = events_nci == t2_events_NCI & events_ci == t2_events_CI,
         rate_ratio = (events_ci / py_ci) / (events_nci / py_nci),
         hr_diff = hr - hr_unadj, within_printed_ci = hr >= hr_unadj_lo & hr <= hr_unadj_hi,
         ci_lo_diff = lo - hr_unadj_lo, ci_hi_diff = hi - hr_unadj_hi)
write_csv(cox, file.path(out_t, "stage2_cox_unadjusted.csv"))
cat("Table 2 event counts reproduced in", sum(cox$events_match), "of", nrow(cox), "fits\n")
if (!all(cox$events_match)) warning("some fits lose events: check censoring in R/01_prepare_data.R")

cox_summary <- cox |> group_by(scenario, outcome) |>
  summarise(n_fits = n(), hr_mean = mean(hr), hr_min = min(hr), hr_max = max(hr),
            lo_mean = mean(lo), hi_mean = mean(hi), se_mean = mean(se_loghr),
            logrank_p_max = max(logrank_p), hr_reported = first(hr_unadj),
            lo_reported = first(hr_unadj_lo), hi_reported = first(hr_unadj_hi), .groups = "drop") |>
  mutate(abs_diff = abs(hr_mean - hr_reported), rel_diff = abs_diff / hr_reported)
write_csv(cox_summary, file.path(out_t, "stage2_cox_unadjusted_summary.csv"))

# ---- B. curves: 1 - KM (as the paper) and Aalen-Johansen at year 4 and at the axis end -----------
# At year 4 the value depends only on the numbers at risk (A1, A2). At the axis end it depends on
# where the tail events sit relative to the censoring times: under `early` the tail events precede
# every censoring and 1 - KM is the plain cumulative proportion; under `uniform` events and
# censorings interleave in the last 0.2 years and the KM estimate extrapolates beyond the data.
curve_at <- function(d, outcome, at) {
  f <- outcome_frame(d, outcome)
  km <- survfit(Surv(time, status == 1) ~ ci, data = f)
  s_km <- summary(km, times = at, extend = TRUE)
  strata_lab <- ifelse(grepl("ci=1", names(km$strata)), "CI", "NCI")
  steps <- tapply(km$n.event > 0, rep(strata_lab, km$strata), sum)   # distinct event times per group
  res <- tibble(outcome = outcome, time = at, group = ifelse(grepl("ci=1", s_km$strata), "CI", "NCI"),
                one_minus_km = 1 - s_km$surv) |>
    mutate(n_steps = as.integer(steps[group]))
  if (outcome != "all-cause mortality") {
    st <- factor(f$status, levels = 0:2, labels = c("censor", "event", "death"))
    aj <- survfit(Surv(time, st) ~ ci, data = f)
    s_aj <- summary(aj, times = at, extend = TRUE)
    res$aalen_johansen <- s_aj$pstate[, which(aj$states == "event")]
  } else res$aalen_johansen <- res$one_minus_km
  res
}
panel_of <- c(`ischemic stroke` = "A", `any stroke` = "B", `all-cause mortality` = "C")
ends <- persons |> filter(scenario %in% c("uniform", "early")) |> group_by(scenario, replicate) |>
  group_modify(\(d, k) map_dfr(OUTCOMES, \(o) bind_rows(curve_at(d, o, 4.0), curve_at(d, o, AXIS_END)))) |> ungroup() |>
  group_by(scenario, outcome, time, group) |>
  summarise(one_minus_km = mean(one_minus_km), aalen_johansen = mean(aalen_johansen), n_steps = first(n_steps), .groups = "drop") |>
  mutate(panel = panel_of[outcome]) |>
  left_join(t2 |> filter(group != "overall") |> select(outcome, group, events, n_group, pct_table2 = pct), by = c("outcome", "group")) |>
  left_join(curv |> filter(feature == "final_value") |> transmute(panel, group, fig2_final_value = as.numeric(value)), by = c("panel", "group")) |>
  left_join(curv |> filter(feature == "n_steps") |> transmute(panel, group, fig2_n_steps = as.integer(value)), by = c("panel", "group")) |>
  mutate(crude_proportion = events / n_group,
         ratio_fig2_to_recon_if_percent = ifelse(time == AXIS_END, fig2_final_value / (100 * one_minus_km), NA_real_),
         ratio_fig2_to_recon_if_proportion = ifelse(time == AXIS_END, fig2_final_value / one_minus_km, NA_real_)) |>
  select(scenario, panel, outcome, group, time, events, n_group, pct_table2, crude_proportion, one_minus_km, aalen_johansen, n_steps,
         fig2_final_value, fig2_n_steps, ratio_fig2_to_recon_if_percent, ratio_fig2_to_recon_if_proportion) |>
  arrange(panel, group, scenario, time)
write_csv(ends, file.path(out_t, "stage2_curves_at_end.csv"))

# ---- C. rates per interval forced by the numbers at risk --------------------------------------
rates <- persons |> filter(scenario == "uniform", replicate == 1) |>
  group_by(group) |> group_modify(\(d, k) {
    map_dfr(OUTCOMES, \(o) {
      f <- outcome_frame(d, o) |> mutate(ev = as.integer(status == 1)) |> select(time, ev, ci)
      cuts <- c(0, 1, 2, 3, 4, AXIS_END)
      sp <- survSplit(Surv(time, ev) ~ ., data = f, cut = cuts[-c(1, length(cuts))],
                      episode = "interval", start = "tstart", end = "tstop", event = "ev")
      sp |> group_by(interval) |> summarise(events = sum(ev), person_years = sum(tstop - tstart), .groups = "drop") |>
        mutate(outcome = o, interval = sprintf("(%s, %s]", cuts[interval], cuts[interval + 1]),
               rate_per_100py = 100 * events / person_years)
    })
  }, .keep = TRUE) |> ungroup() |> select(outcome, group, interval, events, person_years, rate_per_100py)
rates <- rates |> group_by(outcome, group) |>
  mutate(rate_ratio_vs_first_four_years = rate_per_100py / (sum(events[interval != sprintf("(4, %s]", AXIS_END)]) / sum(person_years[interval != sprintf("(4, %s]", AXIS_END)]) * 100)) |>
  ungroup()
write_csv(rates, file.path(out_t, "stage2_interval_rates.csv"))

# ---- D. figure: the three panels as the reported numbers imply them ----------------------------
# drawn from the `early` scenario: each interval's events at its start, the tail events at year 4.0,
# so the curves show what the numbers at risk and Table 2 fix and nothing drawn at random
d1 <- persons |> filter(scenario == "early")
km_df <- map_dfr(OUTCOMES, \(o) {
  f <- outcome_frame(d1, o)
  km <- survfit(Surv(time, status == 1) ~ ci, data = f)
  tibble(outcome = o, group = rep(c("NCI", "CI"), km$strata), time = km$time, cuminc = 100 * (1 - km$surv))
}) |> bind_rows(tibble(outcome = rep(OUTCOMES, each = 2), group = rep(c("NCI", "CI"), 3), time = 0, cuminc = 0)) |>
  mutate(outcome = factor(outcome, levels = OUTCOMES, labels = c("A  Ischaemic stroke", "B  Any stroke", "C  All-cause mortality")),
         group = factor(group, levels = c("NCI", "CI")))
risk_lab <- d1 |> group_by(group) |>
  group_modify(\(d, k) map_dfr(OUTCOMES, \(o) { f <- outcome_frame(d, o); tibble(outcome = o, year = 0:4, n = map_int(0:4, \(y) sum(f$time > y | y == 0))) }), .keep = TRUE) |>
  ungroup() |>
  mutate(outcome = factor(outcome, levels = OUTCOMES, labels = levels(km_df$outcome)), group = factor(group, levels = c("NCI", "CI")),
         y = ifelse(group == "NCI", -1.0, -1.9))
p <- ggplot(km_df, aes(time, cuminc, colour = group)) +
  geom_step(linewidth = 0.6) +
  geom_text(data = risk_lab, aes(x = year, y = y, label = n, colour = group), size = 2.6, show.legend = FALSE) +
  scale_colour_manual(values = c(NCI = "#1f4e9c", CI = "#c0392b"), name = NULL) +
  scale_x_continuous(breaks = 0:4, limits = c(0, AXIS_END)) +
  scale_y_continuous(breaks = seq(0, 10, 2), limits = c(-2.3, 10)) +
  facet_wrap(~ outcome, nrow = 1) +
  labs(x = "Time (years)", y = "Cumulative incidence, 1 − KM (%)",
       caption = paste0("Reconstructed from Table 2 and the numbers at risk under Fig. 2. Events are placed at the start of the year in which the",
                        " numbers at risk locate them;\nthe events Table 2 counts beyond year 4 are placed at year 4.0 (their timing in the last 0.2 years",
                        " is unknown). Fig. 2 of the paper draws the CI curve reaching 100 % in four steps.")) +
  theme_minimal(base_size = 10) + theme(legend.position = "top", panel.grid.minor = element_blank(), plot.caption = element_text(hjust = 0))
ggsave(file.path(out_f, "stage2_km_reconstructed.png"), p, width = 10, height = 4.2, dpi = 150, bg = "white")

# ---- console ------------------------------------------------------------------------------------
print(cox_summary |> select(scenario, outcome, hr_mean, hr_min, hr_max, hr_reported, lo_mean, lo_reported, hi_mean, hi_reported) |>
        mutate(across(where(is.numeric), \(x) round(x, 2))), n = 20, width = 140)
print(ends |> select(-fig2_n_steps, -ratio_fig2_to_recon_if_percent) |> mutate(across(where(is.numeric), \(x) round(x, 4))), n = 30, width = 160)
print(rates |> mutate(across(c(person_years, rate_per_100py, rate_ratio_vs_first_four_years), \(x) round(x, 2))), n = 40, width = 140)
