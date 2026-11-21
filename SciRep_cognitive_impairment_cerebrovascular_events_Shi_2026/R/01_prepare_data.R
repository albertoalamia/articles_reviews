# 01_prepare_data.R — Shi et al. 2026, Sci Rep (P002), stage 2
#
# Reconstructs individual-level time-to-event data consistent with everything the paper prints:
# group sizes (Table 1), events per group and outcome (Table 2), numbers at risk at years 0-4 in
# the three panels of Fig. 2, a 4.2-year axis and a median follow-up of 4.1 years.
# Inputs : data/raw/table2_cox.csv, data/raw/fig2_at_risk.csv
# Outputs: data/derived/recon_counts.csv    events and censorings per group and year interval
#          data/derived/recon_persons.csv   one row per person, scenario and replicate
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
