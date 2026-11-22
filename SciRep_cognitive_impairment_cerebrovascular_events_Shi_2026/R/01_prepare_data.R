# 01_prepare_data.R — Shi et al. 2026, Sci Rep (P002), stage 2
#
# Reconstructs individual-level time-to-event data consistent with everything the paper prints:
# group sizes (Table 1), events per group and outcome (Table 2), numbers at risk at years 0-4 in
# the three panels of Fig. 2, a 4.2-year axis and a median follow-up of 4.1 years.
# Inputs : data/raw/table2_cox.csv, data/raw/fig2_at_risk.csv
# Outputs: data/derived/recon_counts.csv    events and censorings per group and year interval
#          data/derived/recon_persons.csv   one row per person, scenario and replicate
#          (S1, stages 3-4; plan §2, §8) data/derived/pem_counts.csv  life-table cells per scenario and model
#          data/derived/calibrated_population.csv  ages and sex per person (A6; three ceilings)
#          data/derived/stan_data/pem_{isch,any}[_early|_late].json, exposure_age_{isch,any,death}.json
# Log    : data/derived/RECONSTRUCTION_LOG.md
# Run    : from the nix shell:  Rscript SciRep_cognitive_impairment_cerebrovascular_events_Shi_2026/R/01_prepare_data.R
#
# How the counts are derived (per group g, year interval j = 1..4):
#   rC_j = removals from the mortality risk set      = deaths_j + censored_j
#   rA_j = removals from the ischaemic-stroke risk set = isch_j + deaths without prior stroke_j + censored_j
#   rB_j = removals from the any-stroke risk set       = anystroke_j + deaths without prior stroke_j + censored_j
# Assumptions of the main scenario (each one is a choice, logged):
#   A1 nobody is lost to follow-up before year 4 (censored_j = 0): every removal is an event;
#   A2 deaths before year 4 happen to people without a prior stroke, so isch_j = rA_j - rC_j and
#      other-stroke_j = (rB_j - rA_j); this is the minimum number of strokes before year 4;
#   A3 the events Table 2 counts beyond those fall between year 4.0 and the end of the axis (4.2);
#   A4 survivors are censored at a time uniform between 4.0 and 4.2 (median follow-up 4.1, all at
#      risk at year 4);
#   A5 no person has both a stroke and a death inside the window (no fatal strokes recorded as
#      both); the three outcomes are carried by distinct people.
# Timing scenarios: "uniform" (event times uniform inside their interval; 5 replicates),
# "early" (at the start of the interval), "late" (at the end). Nothing here is the authors' data.

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(readr); library(purrr)
})
here_art <- function(...) here::here("SciRep_cognitive_impairment_cerebrovascular_events_Shi_2026", ...)
raw <- function(f) read_csv(here_art("data/raw", f), show_col_types = FALSE)
dir.create(here_art("data/derived"), showWarnings = FALSE)

t2 <- raw("table2_cox.csv")
ar <- raw("fig2_at_risk.csv")
AXIS_END <- 4.2; CENS_LO <- 4.0
N_REP <- 5L; SEED <- 20261121L

# ---- removals per interval and panel ---------------------------------------------------------
rem <- ar |> arrange(panel, group, year) |> group_by(panel, group) |>
  mutate(removed = lag(n_at_risk) - n_at_risk) |> ungroup() |> filter(year >= 1) |>
  select(panel, group, year, removed) |>
  pivot_wider(names_from = panel, values_from = removed, names_prefix = "r")

totals <- t2 |> filter(group != "overall") |>
  select(outcome, group, events) |>
  pivot_wider(names_from = outcome, values_from = events) |>
  rename(isch_total = `ischemic stroke`, any_total = `any stroke`, death_total = `all-cause mortality`) |>
  mutate(other_total = any_total - isch_total)

counts <- rem |>
  mutate(deaths = rC, isch = rA - rC, other = rB - rA) |>
  select(group, year, deaths, isch, other)
stopifnot(all(counts$isch >= 0), all(counts$other >= 0), all(counts$deaths >= 0))

tail_counts <- counts |> group_by(group) |>
  summarise(deaths_by4 = sum(deaths), isch_by4 = sum(isch), other_by4 = sum(other), .groups = "drop") |>
  left_join(totals, by = "group") |>
  transmute(group, year = 5L,   # "interval 5" = (4.0, 4.2]
            deaths = death_total - deaths_by4, isch = isch_total - isch_by4, other = other_total - other_by4)
stopifnot(all(tail_counts$deaths >= 0), all(tail_counts$isch >= 0), all(tail_counts$other >= 0))

recon_counts <- bind_rows(counts, tail_counts) |> arrange(group, year) |>
  mutate(interval = ifelse(year <= 4, sprintf("(%d, %d]", year - 1L, year), sprintf("(4, %.1f]", AXIS_END)))
write_csv(recon_counts, here_art("data/derived/recon_counts.csv"))

# ---- persons ------------------------------------------------------------------------------------
n_group <- c(NCI = 3683L, CI = 192L)
interval_time <- function(year, n, scenario) {
  lo <- ifelse(year <= 4, year - 1, CENS_LO); hi <- ifelse(year <= 4, year, AXIS_END)
  switch(scenario,
         uniform = runif(n, lo, hi),
         early   = rep(lo + 1e-3, n),
         late    = rep(hi - 1e-3, n))
}
build_group <- function(g, scenario) {
  N <- n_group[[g]]
  cnt <- recon_counts |> filter(group == g)
  ids <- sample.int(N)            # random assignment of roles to ids
  take <- function(k) { out <- ids[seq_len(k)]; ids <<- ids[-seq_len(k)]; out }
  person <- tibble(id = seq_len(N), group = g, ci = as.integer(g == "CI"),
                   t_isch = NA_real_, t_other = NA_real_, t_death = NA_real_)
  for (r in seq_len(nrow(cnt))) {
    y <- cnt$year[r]
    if (cnt$deaths[r] > 0) person$t_death[take(cnt$deaths[r])] <- interval_time(y, cnt$deaths[r], scenario)
    if (cnt$isch[r]   > 0) person$t_isch[take(cnt$isch[r])]    <- interval_time(y, cnt$isch[r], scenario)
    if (cnt$other[r]  > 0) person$t_other[take(cnt$other[r])]  <- interval_time(y, cnt$other[r], scenario)
  }
  # administrative censoring: uniform on (4.0, 4.2] under `uniform` (median follow-up 4.1 as the
  # paper); at the axis end under `early` and `late`, so that every survivor is at risk when the
  # tail events occur. Censoring applies to survivors: a person with an event in the tail is
  # followed at least to that event (without this, tail events drawn after the censoring time were
  # lost: first run, 2026-11-21).
  t_last <- pmax(person$t_isch, person$t_other, person$t_death, na.rm = TRUE)
  t_last[is.infinite(t_last)] <- NA_real_
  base <- if (scenario == "uniform") runif(N, CENS_LO, AXIS_END) else rep(AXIS_END, N)
  person$t_cens <- pmax(base, t_last, na.rm = TRUE)
  person
}
set.seed(SEED)
persons <- bind_rows(
  map_dfr(seq_len(N_REP), \(k) bind_rows(build_group("NCI", "uniform"), build_group("CI", "uniform")) |>
            mutate(scenario = "uniform", replicate = k)),
  bind_rows(build_group("NCI", "early"), build_group("CI", "early")) |> mutate(scenario = "early", replicate = 1L),
  bind_rows(build_group("NCI", "late"),  build_group("CI", "late"))  |> mutate(scenario = "late",  replicate = 1L)) |>
  select(scenario, replicate, id, group, ci, t_isch, t_other, t_death, t_cens)
write_csv(persons, here_art("data/derived/recon_persons.csv"))

# ---- checks: numbers at risk reproduced exactly -------------------------------------------------
at_risk <- function(d, outcome) {
  t_event <- switch(outcome,
                    `ischemic stroke`    = d$t_isch,
                    `any stroke`         = pmin(d$t_isch, d$t_other, na.rm = TRUE),
                    `all-cause mortality` = d$t_death)
  t_event[is.infinite(t_event)] <- NA
  exit <- pmin(t_event, d$t_death, d$t_cens, na.rm = TRUE)
  map_dfr(0:4, \(y) tibble(year = y, n_at_risk = sum(exit > y | (y == 0))))
}
chk <- persons |> filter(scenario == "uniform", replicate == 1) |>
  group_by(group) |> group_modify(\(d, k) map_dfr(set_names(unique(t2$outcome)), \(o) at_risk(d, o), .id = "outcome")) |>
  ungroup() |>
  left_join(ar |> select(outcome, group, year, n_at_risk_fig = n_at_risk), by = c("outcome", "group", "year")) |>
  mutate(ok = n_at_risk == n_at_risk_fig)
write_csv(chk, here_art("data/derived/recon_check_at_risk.csv"))
cat(sprintf("numbers at risk reproduced in %d of %d cells\n", sum(chk$ok), nrow(chk)))
print(recon_counts, n = 20)
cat("persons:", nrow(persons), "rows;", "median follow-up (uniform, rep 1):",
    round(median(with(persons |> filter(scenario == "uniform", replicate == 1), pmin(t_isch, t_other, t_death, t_cens, na.rm = TRUE))), 2), "\n")

# ================================================================================================
# S1 — inputs of stages 3 and 4 (plan §2 and §8), added 2026-11-22. Everything above is unchanged:
# the seed-dependent part has finished, so recon_counts.csv and recon_persons.csv are byte-identical
# to the stage 2 run (check: git diff --stat data/derived after running).
# (a) pem_counts.csv: the life table the piecewise-exponential model (E1) is fitted to, one row per
#     scenario × model × group × interval: persons entering, person-years, events by cause,
#     censorings. Model "isch" has causes {ischaemic stroke, death}: under A5 a person with another
#     stroke stays at risk of both until censoring. Model "any" has causes {any stroke, death}.
#     Events per cell do not depend on the timing scenario (they are fixed by recon_counts.csv);
#     person-years do, so uniform replicate 1 is the main analysis and early / late bound it.
#     Censoring: the paper reports no loss to follow-up and no censoring; the numbers at risk allow
#     at most 30 (NCI) and 6 (CI) departures of any kind before year 4, and A1 takes them all as
#     events (the reading most favourable to the paper: a censoring in their place pushes one more
#     event into the tail). Hence n_cens is 0 in intervals 1-4 and every event-free person is
#     censored in (4.0, 4.2] (A4: uniform, median 4.1; early/late: at 4.2). Nothing is known past 4.2.
# (b) calibrated_population.csv: the A6 population (R/lib_population.R, the code of R/05), ages at
#     three ceilings, for E2–E3.
# (c) Stan data (JSON) in data/derived/stan_data/, with the switches run_model.sh rewrites:
#     prior_only (1 skips the likelihood), beta_sd (E1: prior SD of the group effects, 1; 2 = wide),
#     prior (E2: 1 P1, 2 P2, 3 P3 of plan §5), age_max (E2: 90; 80, 100).
# ================================================================================================
source(here_art("R/lib_population.R"))            # jsonlite is called with ::
dir_stan <- here_art("data/derived/stan_data"); dir.create(dir_stan, showWarnings = FALSE)
BREAKS <- c(0, 1, 2, 3, 4, AXIS_END)
INTERVALS <- sprintf("(%s, %s]", BREAKS[-length(BREAKS)], BREAKS[-1])   # the labels of recon_counts.csv
stopifnot(setequal(INTERVALS, recon_counts$interval))
FU <- 4.1                                                              # median follow-up, E2 horizon (plan §3)

# ---- (a) life-table cells -----------------------------------------------------------------------
life_table <- function(d, model) {
  t_stroke <- if (model == "isch") d$t_isch else pmin(d$t_isch, d$t_other, na.rm = TRUE)
  t_stroke[is.infinite(t_stroke)] <- NA_real_
  exit <- pmin(t_stroke, d$t_death, d$t_cens, na.rm = TRUE)
  cause <- case_when(!is.na(t_stroke) & t_stroke == exit ~ "stroke",
                     !is.na(d$t_death) & d$t_death == exit ~ "death",
                     TRUE ~ "censored")
  map_dfr(seq_along(INTERVALS), \(j) {
    lo <- BREAKS[j]; hi <- BREAKS[j + 1]
    in_j <- exit > lo & exit <= hi
    tibble(model = model, ci = d$ci[1], j = j, interval = INTERVALS[j], t_lo = lo, t_hi = hi,
           n_enter = sum(exit > lo), py = sum(pmax(0, pmin(exit, hi) - lo)),
           d_stroke = sum(in_j & cause == "stroke"), d_death = sum(in_j & cause == "death"),
           n_cens = sum(in_j & cause == "censored"))
  })
}
pem_counts <- persons |>
  group_by(scenario, replicate, group) |>
  group_modify(\(d, k) bind_rows(life_table(d, "isch"), life_table(d, "any")), .keep = TRUE) |>   # group_modify: the key `group` is added back, not returned
  ungroup() |>
  mutate(main = scenario == "uniform" & replicate == 1L) |>
  select(scenario, replicate, main, model, group, ci, j, interval, t_lo, t_hi, n_enter, py, d_stroke, d_death, n_cens) |>
  arrange(scenario, replicate, model, ci, j)
write_csv(pem_counts, here_art("data/derived/pem_counts.csv"))

# events per cell sum to Table 2 in every scenario and replicate; survivors leave only by censoring
ev_check <- pem_counts |> group_by(scenario, replicate, model, group) |>
  summarise(stroke = sum(d_stroke), death = sum(d_death), n = first(n_enter), left = sum(d_stroke + d_death + n_cens), .groups = "drop") |>
  left_join(totals |> select(group, isch_total, any_total, death_total), by = "group") |>
  mutate(stroke_expected = ifelse(model == "isch", isch_total, any_total),
         ok = stroke == stroke_expected & death == death_total & left == n)
stopifnot(all(ev_check$ok), all(pem_counts$n_enter[pem_counts$j == 1] == n_group[pem_counts$group[pem_counts$j == 1]]))
cat(sprintf("life-table cells: events match Table 2 in %d of %d scenario x model x group blocks\n", sum(ev_check$ok), nrow(ev_check)))
py_summary <- pem_counts |> filter(replicate == 1L) |> group_by(scenario, model, group) |>
  summarise(py_total = sum(py), py_tail = py[j == 5], .groups = "drop") |>
  pivot_wider(names_from = scenario, values_from = c(py_total, py_tail))
print(py_summary |> mutate(across(where(is.numeric), \(x) round(x, 1))), width = 140)

# ---- (b) calibrated population (A6), three ceilings -------------------------------------------------
t1 <- raw("table1_baseline.csv")
age_row <- t1 |> filter(variable == "Age"); male_row <- t1 |> filter(variable == "Male")
pops <- map(POP_AGE_MAX, \(am) make_population(age_row, male_row, n_group, POP_SHIFT, am))
stopifnot(identical(pops$main$male, pops$low$male), identical(pops$main$male, pops$high$male),
          identical(pops$main$group, pops$low$group))
calibrated <- pops$main |> select(group, ci, q, male) |>
  mutate(age_90 = round(pops$main$age, 3), age_80 = round(pops$low$age, 3), age_100 = round(pops$high$age, 3))
write_csv(calibrated, here_art("data/derived/calibrated_population.csv"))
pop_summary <- calibrated |> group_by(group) |>
  summarise(n = n(), male = round(mean(male), 3),
            across(c(age_90, age_80, age_100), list(med = \(x) round(median(x), 1), q1 = \(x) round(quantile(x, .25), 1),
                                                  q3 = \(x) round(quantile(x, .75), 1), max = \(x) round(max(x), 1))),
            .groups = "drop")
print(pop_summary, width = 200)

# ---- (c) Stan data -------------------------------------------------------------------------------------
# E1: D[g, j, k] events (k = 1 stroke, k = 2 death), PY[g, j] person-years, CI[g]; g = 1 NCI, g = 2 CI.
stan_pem <- function(lt) {
  lt <- lt |> arrange(ci, j)
  g_rows <- function(g) lt[lt$ci == g - 1L, ]
  list(G = 2L, J = 5L, K = 2L,
       D = lapply(1:2, \(g) lapply(seq_len(5), \(j) { r <- g_rows(g)[j, ]; c(r$d_stroke, r$d_death) })),
       PY = lapply(1:2, \(g) g_rows(g)$py),
       CI = c(0L, 1L),
       width = diff(BREAKS), t_end = BREAKS[-1],
       prior_only = 0L, beta_sd = 1)
}
n_json <- 0L
for (m in c("isch", "any")) for (sc in c("uniform", "early", "late")) {
  lt <- pem_counts |> filter(model == m, scenario == sc, replicate == 1L)
  f <- sprintf("pem_%s%s.json", m, ifelse(sc == "uniform", "", paste0("_", sc)))
  jsonlite::write_json(stan_pem(lt), file.path(dir_stan, f), auto_unbox = TRUE, digits = NA)
  n_json <- n_json + 1L
}
# E2–E3: one file per outcome; the population is the same, the two counts differ. Ages at the three
# ceilings travel together and `age_max` selects one in the program's transformed data.
stan_exposure <- function(outcome_events) {
  list(N = nrow(calibrated), CI = calibrated$ci, male = calibrated$male,
       age_90 = calibrated$age_90, age_80 = calibrated$age_80, age_100 = calibrated$age_100,
       age_max = 90L, age_ref = 50, age_flag = 65,
       D = c(outcome_events[["NCI"]], outcome_events[["CI"]]),
       tau = FU, t_pred = AXIS_END,
       prior = 2L, prior_only = 0L)
}
outcomes <- c(isch = "ischemic stroke", any = "any stroke", death = "all-cause mortality")
for (nm in names(outcomes)) {
  e <- t2 |> filter(outcome == outcomes[[nm]], group != "overall")
  jsonlite::write_json(stan_exposure(set_names(e$events, e$group)), file.path(dir_stan, sprintf("exposure_age_%s.json", nm)),
                       auto_unbox = TRUE, digits = NA)
  n_json <- n_json + 1L
}
cat(sprintf("Stan data: %d JSON files in %s\n", n_json, dir_stan))
