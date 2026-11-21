# 05_model1_age_confounding.R — Shi et al. 2026, Sci Rep (P002), stage 2
#
# Model 1 of Table 2 adjusts the CI hazard ratio for age, gender and education and moves it from
# 4.55 to 2.47 (ischaemic stroke), 3.99 to 2.28 (any stroke), 4.16 to 1.83 (death). The paper gives
# no age coefficient. This script asks: given the age and sex distributions of the two groups in
# Table 1, what effect of age (and sex) on the hazard makes an adjusted model reproduce the
# Model 1 estimate, once the unadjusted event counts are fixed? And what would stronger, textbook
# age effects imply for the adjusted hazard ratio?
# Method: ages per group from a shifted log-normal truncated at an upper age (90 years; 80 and 100
# as sensitivity), its two parameters fitted to the median and quartiles of Table 1, taken as
# deterministic quantiles (an untruncated log-normal with the Table 1 spread puts the oldest
# reconstructed participants above 200 years and lets a handful of them absorb the age effect);
# sex Bernoulli with the Table 1 shares; exponential hazard
#   h_i = lambda0 * exp(bCI * CI_i + bAge * (age_i - 50)/10 + bMale * male_i),
# follow-up 4.1 years. For each (bAge, bMale) on a grid, lambda0 and bCI are solved so that the
# expected events equal Table 2's counts in each group (66/15, 75/15, 71/15). exp(bCI) is then the
# covariate-adjusted hazard ratio an adjusted Cox model estimates in expectation (a correctly
# specified, rare-outcome setting; non-collapsibility is negligible here). A simulation at one
# grid point checks that and shows the spread of the fitted adjusted HR and its CI width.
# Everything here is conditional on the distributional assumptions; nothing is the authors' data.
# Outputs: output/tables/stage2_model1_age_grid.csv, stage2_model1_implied_age_hr.csv,
#          stage2_model1_implied_age_hr_shift.csv, stage2_model1_age_population.csv, stage2_model1_sim.csv,
#          stage2_model1_sim_summary.csv, output/figures/stage2_model1_age_grid.png

options(warn = 1)
suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(readr); library(purrr); library(survival); library(ggplot2)
})
here_art <- function(...) here::here("SciRep_cognitive_impairment_cerebrovascular_events_Shi_2026", ...)
out_t <- here_art("output/tables"); out_f <- here_art("output/figures")
t1 <- read_csv(here_art("data/raw/table1_baseline.csv"), show_col_types = FALSE)
t2 <- read_csv(here_art("data/raw/table2_cox.csv"), show_col_types = FALSE)
FU <- 4.1; SHIFT <- 39.5; AGE_MAX <- 90   # age >= 40 at enrolment; sensitivities below
N <- c(NCI = 3683L, CI = 192L)

# ---- age and sex per group from Table 1 -------------------------------------------------------
age_row <- t1 |> filter(variable == "Age")
male_row <- t1 |> filter(variable == "Male")
# shifted log-normal truncated above at age_max: quantile function and parameter fit to three quantiles
q_trunc <- function(p, mu, sigma, shift, age_max) {
  shift + qlnorm(p * plnorm(age_max - shift, mu, sigma), mu, sigma)
}
fit_trunc <- function(med, q1, q3, shift, age_max) {
  target <- c(q1, med, q3)
  loss <- function(par) sum((q_trunc(c(0.25, 0.5, 0.75), par[1], exp(par[2]), shift, age_max) - target)^2)
  start <- c(log(med - shift), log((log(q3 - shift) - log(q1 - shift)) / (2 * qnorm(0.75))))
  o <- optim(start, loss, method = "Nelder-Mead", control = list(reltol = 1e-12, maxit = 5000))
  c(mu = o$par[1], sigma = exp(o$par[2]), max_abs_dev = sqrt(max((q_trunc(c(0.25, 0.5, 0.75), o$par[1], exp(o$par[2]), shift, age_max) - target)^2)))
}
make_pop <- function(shift = SHIFT, age_max = AGE_MAX) {
  pn <- fit_trunc(age_row$nci_med, age_row$nci_q1, age_row$nci_q3, shift, age_max)
  pc <- fit_trunc(age_row$ci_med, age_row$ci_q1, age_row$ci_q3, shift, age_max)
  bind_rows(
    tibble(group = "NCI", ci = 0L, q = (seq_len(N[["NCI"]]) - 0.5) / N[["NCI"]]) |>
      mutate(age = q_trunc(q, pn[["mu"]], pn[["sigma"]], shift, age_max),
             male = as.integer(q <= male_row$nci_pct / 100)),
    tibble(group = "CI", ci = 1L, q = (seq_len(N[["CI"]]) - 0.5) / N[["CI"]]) |>
      mutate(age = q_trunc(q, pc[["mu"]], pc[["sigma"]], shift, age_max),
             male = as.integer(rev(q) <= male_row$ci_pct / 100))) |>   # rev: decorrelate sex from age within group
    mutate(age_c = (age - 50) / 10)
}
pop <- make_pop()
pop_check <- pop |> group_by(group) |>
  summarise(median_age = median(age), q1 = quantile(age, 0.25), q3 = quantile(age, 0.75),
            p90 = quantile(age, 0.9), max_age = max(age), male = mean(male), .groups = "drop") |>
  left_join(tibble(group = c("NCI", "CI"), t1_med = c(age_row$nci_med, age_row$ci_med),
                   t1_q1 = c(age_row$nci_q1, age_row$ci_q1), t1_q3 = c(age_row$nci_q3, age_row$ci_q3)), by = "group")
overall_check <- tibble(group = "overall", median_age = median(pop$age), q1 = quantile(pop$age, 0.25), q3 = quantile(pop$age, 0.75),
                        p90 = quantile(pop$age, 0.9), max_age = max(pop$age), male = mean(pop$male),
                        t1_med = age_row$overall_med, t1_q1 = age_row$overall_q1, t1_q3 = age_row$overall_q3)
write_csv(bind_rows(pop_check, overall_check), file.path(out_t, "stage2_model1_age_population.csv"))

# ---- calibration: lambda0 and bCI for given (bAge, bMale) ----------------------------------------
expected_events <- function(lambda0, bci, bage, bmale, d) sum(1 - exp(-lambda0 * exp(bci * d$ci + bage * d$age_c + bmale * d$male) * FU))
exp_pt <- function(h) (1 - exp(-h * FU)) / h   # expected time at risk under hazard h, censored at FU
calibrate <- function(ev_nci, ev_ci, bage, bmale, d = pop) {
  dn <- d[d$ci == 0, ]; dc <- d[d$ci == 1, ]
  lambda0 <- uniroot(\(l) expected_events(l, 0, bage, bmale, dn) - ev_nci, c(1e-6, 1), tol = 1e-10)$root
  bci <- uniroot(\(b) expected_events(lambda0, b, bage, bmale, dc) - ev_ci, c(-3, 5), tol = 1e-10)$root
  h_n <- lambda0 * exp(bage * dn$age_c + bmale * dn$male)
  h_c <- lambda0 * exp(bci + bage * dc$age_c + bmale * dc$male)
  tibble(lambda0 = lambda0, b_ci = bci, hr_adjusted = exp(bci),
         # unadjusted HR in expectation: crude rate ratio over expected person-time
         crude_rate_ratio = (ev_ci / sum(exp_pt(h_c))) / (ev_nci / sum(exp_pt(h_n))))
}
grid <- expand_grid(outcome = c("ischemic stroke", "any stroke", "all-cause mortality"),
                    hr_age_per_decade = c(1, 1.25, 1.5, 1.75, 2, 2.25, 2.5, 3),
                    hr_male = c(1, 1.3, 1.6)) |>
  left_join(t2 |> filter(group != "overall") |> select(outcome, group, events) |> pivot_wider(names_from = group, values_from = events), by = "outcome") |>
  left_join(t2 |> filter(group == "CI") |> select(outcome, hr_unadj, hr_m1, hr_m1_lo, hr_m1_hi, hr_m2), by = "outcome") |>
  mutate(cal = pmap(list(NCI, CI, log(hr_age_per_decade), log(hr_male)), \(n, c, a, m) calibrate(n, c, a, m))) |>
  unnest(cal) |>
  mutate(within_model1_ci = hr_adjusted >= hr_m1_lo & hr_adjusted <= hr_m1_hi)
write_csv(grid, file.path(out_t, "stage2_model1_age_grid.csv"))

# the age effect at which the adjusted HR equals Model 1, per outcome and sex effect
implied <- grid |> group_by(outcome, hr_male) |>
  group_modify(\(g, k) {
    f <- function(hr_age) { r <- calibrate(g$NCI[1], g$CI[1], log(hr_age), log(k$hr_male)); r$hr_adjusted - g$hr_m1[1] }
    root <- tryCatch(uniroot(f, c(1, 6), tol = 1e-6)$root, error = \(e) NA_real_)
    tibble(hr_m1 = g$hr_m1[1], hr_age_per_decade_implied = root,
           hr_adjusted_if_age_doubles_per_decade = calibrate(g$NCI[1], g$CI[1], log(2), log(k$hr_male))$hr_adjusted,
           hr_adjusted_if_age_1_5_per_decade = calibrate(g$NCI[1], g$CI[1], log(1.5), log(k$hr_male))$hr_adjusted)
  }) |> ungroup()
write_csv(implied, file.path(out_t, "stage2_model1_implied_age_hr.csv"))

# sensitivity of the implied age effect to the assumed age range (lower shift, upper truncation)
implied_shift <- pmap_dfr(list(shift = c(39.5, 39.5, 39.5, 30), age_max = c(80, 90, 100, 90)), \(shift, age_max) {
  d <- make_pop(shift, age_max)
  map_dfr(unique(grid$outcome), \(o) {
    g <- grid |> filter(outcome == o) |> slice(1)
    f <- function(hr_age) calibrate(g$NCI, g$CI, log(hr_age), log(1.3), d)$hr_adjusted - g$hr_m1
    tibble(shift = shift, age_max = age_max, outcome = o, hr_male = 1.3,
           hr_age_per_decade_implied = tryCatch(uniroot(f, c(1, 6), tol = 1e-6)$root, error = \(e) NA_real_),
           hr_adjusted_if_age_doubles_per_decade = calibrate(g$NCI, g$CI, log(2), log(1.3), d)$hr_adjusted)
  })
})
write_csv(implied_shift, file.path(out_t, "stage2_model1_implied_age_hr_shift.csv"))

# ---- simulation check at two points, ischaemic stroke, sex HR 1.3 ---------------------------------
# (i) age doubles per decade (textbook order of magnitude for stroke); (ii) the implied age effect
set.seed(20261121)
sim_one <- function(hr_age, label) {
  g0 <- grid |> filter(outcome == "ischemic stroke", hr_male == 1.3) |> slice(1)
  cal <- calibrate(g0$NCI, g0$CI, log(hr_age), log(1.3))
  map_dfr(seq_len(200), \(k) {
    d <- pop |> mutate(h = cal$lambda0 * exp(cal$b_ci * ci + log(hr_age) * age_c + log(1.3) * male),
                       t_ev = rexp(n(), h), t_c = runif(n(), 4.0, 4.2), time = pmin(t_ev, t_c), event = as.integer(t_ev <= t_c))
    un <- coxph(Surv(time, event) ~ ci, data = d); ad <- coxph(Surv(time, event) ~ ci + age_c + male, data = d)
    tibble(point = label, hr_age_assumed = hr_age, hr_adjusted_expected = cal$hr_adjusted, replicate = k,
           events = sum(d$event), events_ci = sum(d$event[d$ci == 1]),
           hr_unadj = exp(coef(un)[["ci"]]), hr_adj = exp(coef(ad)[["ci"]]), se_adj = sqrt(vcov(ad)["ci", "ci"]),
           hr_age_fitted = exp(coef(ad)[["age_c"]]))
  })
}
implied_isch <- implied |> filter(outcome == "ischemic stroke", hr_male == 1.3) |> pull(hr_age_per_decade_implied)
sim <- bind_rows(sim_one(2, "age HR 2 per decade"),
                 if (is.finite(implied_isch)) sim_one(implied_isch, "implied age HR"))
write_csv(sim, file.path(out_t, "stage2_model1_sim.csv"))
se_m1 <- t2 |> filter(outcome == "ischemic stroke", group == "CI") |> with((log(hr_m1_hi) - log(hr_m1_lo)) / (2 * qnorm(0.975)))
sim_summary <- sim |> group_by(point, hr_age_assumed, hr_adjusted_expected) |>
  summarise(events_mean = mean(events), events_ci_mean = mean(events_ci),
            hr_unadj_mean = exp(mean(log(hr_unadj))), hr_adj_mean = exp(mean(log(hr_adj))),
            hr_adj_q025 = quantile(hr_adj, 0.025), hr_adj_q975 = quantile(hr_adj, 0.975),
            se_adj_mean = mean(se_adj), se_model1_printed = se_m1,
            hr_age_fitted_mean = exp(mean(log(hr_age_fitted))), .groups = "drop")
write_csv(sim_summary, file.path(out_t, "stage2_model1_sim_summary.csv"))

# ---- figure ---------------------------------------------------------------------------------------
pg <- ggplot(grid |> filter(hr_male == 1.3), aes(hr_age_per_decade, hr_adjusted, colour = outcome)) +
  geom_line() + geom_point(size = 1.4) +
  geom_hline(data = distinct(grid, outcome, hr_m1), aes(yintercept = hr_m1, colour = outcome), linetype = 2) +
  scale_x_continuous(breaks = c(1, 1.5, 2, 2.5, 3)) +
  labs(x = "Assumed hazard ratio of age, per decade (sex HR 1.3)", y = "Adjusted HR for cognitive impairment implied",
       colour = NULL, caption = "Dashed: Model 1 of Table 2. Ages from the Table 1 medians and IQRs; event counts from Table 2.") +
  theme_minimal(base_size = 10) + theme(legend.position = "top")
ggsave(file.path(out_f, "stage2_model1_age_grid.png"), pg, width = 7, height = 4.2, dpi = 150, bg = "white")

print(bind_rows(pop_check, overall_check) |> mutate(across(where(is.numeric), \(x) round(x, 2))), width = 160)
print(implied |> mutate(across(where(is.numeric), \(x) round(x, 2))), n = 20, width = 140)
print(implied_shift |> mutate(across(where(is.numeric), \(x) round(x, 2))))
print(sim_summary |> mutate(across(where(is.numeric), \(x) round(x, 3))), width = 160)
