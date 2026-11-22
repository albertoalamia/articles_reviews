# lib_population.R — the calibrated population of Shi et al. 2026 (P002): ages and sex per group from
# Table 1, assumption A6 of data/derived/RECONSTRUCTION_LOG.md.
# Shared by R/05_model1_age_confounding.R (stage 2, Model 1 calibration), R/01_prepare_data.R (S1:
# calibrated_population.csv and the exposure_age JSON) and R/06_fit_frequentist.R (stage 3, E2–E3).
# Moved verbatim from R/05 on 2026-11-22 (plan §8, S1); R/05 sources this file and its outputs must
# not change (checked by diff after the run).
#
# q_trunc(p, mu, sigma, shift, age_max)
#     quantile function of a shifted log-normal (age = shift + X, X ~ LogN(mu, sigma)) truncated above
#     at age_max.
# fit_trunc(med, q1, q3, shift, age_max)
#     (mu, sigma) fitted by least squares to a median and quartiles taken as deterministic quantiles;
#     max_abs_dev is the largest deviation of the three fitted quantiles from the targets.
# make_population(age_row, male_row, n_group, shift, age_max)
#     one row per person: group, ci, q (the person's quantile), age, male, age_c = (age - 50)/10.
#     age_row, male_row: the "Age" and "Male" rows of data/raw/table1_baseline.csv (columns nci_med,
#     nci_q1, nci_q3, ci_med, ci_q1, ci_q3; nci_pct, ci_pct); n_group: c(NCI = ..., CI = ...).
#     Sex is independent of age within group by construction (the quantile order is reversed for the
#     CI group so that sex is not aligned with age in the same direction in both groups).
# Nothing here is the authors' data: the shape above the Table 1 quartiles is an assumption, and the
# ceiling age_max is varied (80, 90, 100) as a sensitivity analysis.

POP_SHIFT <- 39.5                                   # age >= 40 at enrolment
POP_AGE_MAX <- c(main = 90, low = 80, high = 100)   # ceiling of the age distribution and its sensitivities

q_trunc <- function(p, mu, sigma, shift, age_max) {
  shift + qlnorm(p * plnorm(age_max - shift, mu, sigma), mu, sigma)
}

fit_trunc <- function(med, q1, q3, shift, age_max) {
  target <- c(q1, med, q3)
  loss <- function(par) sum((q_trunc(c(0.25, 0.5, 0.75), par[1], exp(par[2]), shift, age_max) - target)^2)
  start <- c(log(med - shift), log((log(q3 - shift) - log(q1 - shift)) / (2 * qnorm(0.75))))
  o <- optim(start, loss, method = "Nelder-Mead", control = list(reltol = 1e-12, maxit = 5000))
  c(mu = o$par[1], sigma = exp(o$par[2]),
    max_abs_dev = sqrt(max((q_trunc(c(0.25, 0.5, 0.75), o$par[1], exp(o$par[2]), shift, age_max) - target)^2)))
}

make_population <- function(age_row, male_row, n_group, shift = POP_SHIFT, age_max = POP_AGE_MAX[["main"]]) {
  pn <- fit_trunc(age_row$nci_med, age_row$nci_q1, age_row$nci_q3, shift, age_max)
  pc <- fit_trunc(age_row$ci_med, age_row$ci_q1, age_row$ci_q3, shift, age_max)
  dplyr::bind_rows(
    dplyr::tibble(group = "NCI", ci = 0L, q = (seq_len(n_group[["NCI"]]) - 0.5) / n_group[["NCI"]]) |>
      dplyr::mutate(age = q_trunc(q, pn[["mu"]], pn[["sigma"]], shift, age_max),
                    male = as.integer(q <= male_row$nci_pct / 100)),
    dplyr::tibble(group = "CI", ci = 1L, q = (seq_len(n_group[["CI"]]) - 0.5) / n_group[["CI"]]) |>
      dplyr::mutate(age = q_trunc(q, pc[["mu"]], pc[["sigma"]], shift, age_max),
                    male = as.integer(rev(q) <= male_row$ci_pct / 100))) |>   # rev: decorrelate sex from age within group
    dplyr::mutate(age_c = (age - 50) / 10)
}
