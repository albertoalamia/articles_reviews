# Reconstruction log — Shi et al. 2026 (P002), stage 2

Purpose: the paper reports hazard ratios, log-rank tests and Kaplan–Meier curves from individual
data that are not available. This log records the individual-level dataset rebuilt from what the
paper prints, every assumption that rebuilding needed, and what was refitted on it. Nothing here
is the authors' data. Code: `R/01_prepare_data.R` (reconstruction), `R/04_reproduce_cox_km.R`
(Cox, log-rank, curves, competing risks, interval rates), `R/05_model1_age_confounding.R`
(what Model 1 implies about the age effect). Seed 20261121.

## 1. What the paper fixes

| quantity | source | value |
|---|---|---|
| group sizes | Table 1 | NCI 3683, CI 192 |
| events per group | Table 2 | ischaemic 66 / 15, any stroke 75 / 15, death 71 / 15 |
| numbers at risk, years 0–4, three panels | Fig. 2 | `data/raw/fig2_at_risk.csv` |
| end of the time axis | Fig. 2 | 4.2 years (read, ±0.05) |
| median follow-up | Results | 4.1 years |

From the numbers at risk, removals per year interval and panel; with assumptions A1–A2 below they
split into deaths, ischaemic strokes and other strokes (`recon_counts.csv`). The split is exact
given the assumptions: for NCI the other-stroke removals sum to 9 = 75 − 66 without being forced
to, which is the one internal check the figure passes.

## 2. Assumptions

- **A1** Nobody is lost to follow-up before year 4: every removal from a risk set is an event. (If
  some were censored, fewer events fall before year 4 and more in the tail; A1 is the most
  favourable case for the paper's time course.)
- **A2** Deaths before year 4 occur in people without a prior stroke, so the ischaemic strokes in
  an interval are the panel-A removals minus the panel-C removals, and other strokes the panel-B
  minus panel-A removals. This is the minimum number of strokes before year 4; the alternative
  (deaths after strokes) would need more strokes before year 4 than Table 2 has in total for NCI
  (69 > 66), so it is excluded.
- **A3** Events that Table 2 counts beyond those fall after year 4 and before the end of the axis
  (4.0 to 4.2 years): NCI 27 ischaemic strokes, 0 other strokes, 41 deaths; CI 10, 0, 9.
- **A4** Survivors are censored at a time uniform between 4.0 and 4.2 years (all at risk at year
  4; median follow-up 4.1).
- **A5** No person has both a stroke and a death inside the window; the outcomes are carried by
  distinct people (fatal strokes would count as both; with 30 of 192 and 137 of 3683 affected the
  overlap would be small and does not change the unadjusted estimates).
- **A6** (Model 1 exploration only) Ages above the Table 1 quartiles follow the fitted
  log-normal up to 90 years and nobody is older; the implied age effect depends on this tail.
- **Timing within an interval**: `uniform` (random, 5 replicates), `early` (start of the interval),
  `late` (end). These bound anything that depends on exact times.

## 3. What was refitted

- Unadjusted Cox per outcome (Efron ties) with 95 % Wald CI; log-rank test; compared with Table 2
  and with the printed "p < 0.0001" / "P < 0.01".
- 1 − KM per group at the end of the axis and the number of steps, compared with the end values
  and four steps read from Fig. 2 (`data/raw/fig2_curve_features.csv`).
- Aalen–Johansen cumulative incidence of stroke with death as a competing event, which the paper
  does not report.
- Event rates per 100 person-years by year interval and in the tail, which the numbers at risk
  force.
- Model 1 (age, gender, education adjustment): ages per group from a shifted log-normal truncated
  above at 90 years, its two parameters fitted to the Table 1 median and quartiles (shift 39.5;
  sensitivity: truncation at 80 and 100, shift 30), sex from the Table 1 shares, exponential hazard
  calibrated to the Table 2 counts; the adjusted HR implied by each assumed age effect per decade
  (1 to 3) and sex effect (1, 1.3, 1.6); the age effect at which it equals Model 1; a
  200-replicate simulation at two points (age HR 2 per decade; the implied age HR). Education is
  not modelled (its distribution is tied to age and no joint distribution is given). A first run
  without truncation (2026-11-21) was discarded: with the Table 1 spread the log-normal tail put the
  oldest reconstructed participants above 200 years and the adjusted HR hardly moved with the age
  effect; the quantiles printed matched Table 1 while the hazard-weighted ages were absurd. The
  upper tail of the age distribution, which Table 1 does not give, is a stated assumption (A6).

## 4. Results

Run 2026-11-21 in the nix shell (R 4.4.3, survival); three runs, the first two discarded after
fixing (i) tail events drawn after their own censoring time and (ii) survivors censored before
the tail events in the deterministic scenarios (comments in `R/01_prepare_data.R`). Tables in
`output/tables/stage2_*.csv`, figures in `output/figures/`.

### 4.1 The reconstruction itself

- The 30 numbers at risk are reproduced exactly from the rebuilt persons in every scenario
  (`recon_check_at_risk.csv`), and every fit carries the Table 2 event counts (21 of 21).
- Timing forced by the numbers at risk (`recon_counts.csv`, A1–A3): NCI 0, 1, 15, 23 ischaemic
  strokes in years 1–4 and 27 after year 4; 6, 1, 4, 19 deaths and 41 after year 4. CI 1, 0, 2, 2
  ischaemic strokes and 10 after year 4; 0, 1, 2, 3 deaths and 9 after year 4. Two thirds of the
  exposed strokes and 60 % of the exposed deaths fall in the last 0.2 years of the axis.
- Rates per 100 person-years (`stage2_interval_rates.csv`, uniform replicate 1): ischaemic stroke
  CI 0.66 over years 0–4 against 56.3 in (4, 4.2], a ratio of 85; NCI 0.27 against 7.5, ratio 28.
  Death CI 0.79 against 48.2, ratio 61; NCI 0.20 against 11.3, ratio 55. No cohort has event rates
  that rise fifty-fold in its last ten weeks; either the event dates were set to the end of
  follow-up for events found through registries, or the numbers at risk and Table 2 describe
  different datasets (stage 1 concern, unchanged, `needs-data`).

### 4.2 Unadjusted Cox and log-rank (Table 2 and Fig. 2 p-values) — reproduce

| outcome | Table 2 | early = late | uniform, 5 replicates (mean; range) |
|---|---|---|---|
| ischaemic stroke | 4.55 (2.60–7.98) | 4.54 (2.59–7.95) | 4.42; 4.25–4.58 |
| any stroke | 3.99 (2.29–6.94) | 3.97 (2.28–6.91) | 3.88; 3.75–4.00 |
| all-cause mortality | 4.16 (2.38–7.26) | 4.17 (2.39–7.28) | 4.07; 3.96–4.29 |

The deterministic scenarios give the same fit (the risk sets at the interval level are identical)
and match Table 2 to within 0.02 on the HR and 0.03 on the CI bounds; the SE of the log HR is
0.286, 0.283, 0.284, the values 1/15 + 1/d gives. The uniform replicates scatter by ±4 % around
them. Log-rank chi-square 33.3, 27.5, 29.6 (p 8e-9, 2e-7, 5e-8): the "P < 0.0001" printed in
Fig. 2 holds, and so does the weaker "P < 0.01" of the text. Conclusion: the three unadjusted HRs,
their CIs and the log-rank tests are what the event counts and the numbers at risk give; they do
not depend on the figure's curves.

### 4.3 Curves (`stage2_curves_at_end.csv`, figure `stage2_km_reconstructed.png`)

| quantity | CI group | NCI group | Fig. 2 draws |
|---|---|---|---|
| 1 − KM at year 4 (A1–A2 only) | 0.026 stroke, 0.031 death | 0.011 / 0.013 / 0.008 | CI at 1.00 by 3.35 y |
| 1 − KM at 4.2 y, early | 0.080 / 0.080 / 0.078 | 0.018 / 0.020 / 0.019 | 1.00; 0.58 / 0.70 / 0.45 |
| Aalen–Johansen at 4.2 y, early | 0.078 (strokes) | 0.018 / 0.020 | — |
| distinct event times | 15 (uniform) | 66–75 | 4 equal steps of 0.25 |

The CI curves of Fig. 2 end 12.5 times above the reconstruction if read as proportions and at
one eighth of it if read as percent; the NCI curves 30 times above or at one third. No reading of
the axis makes Fig. 2 consistent with Table 2 and its own numbers at risk (stage 1 concern,
`confirmed`, now with the reconstructed curves to show against it). Death as a competing event
moves the stroke cumulative incidence in the CI group from 0.080 to 0.078: the direction the stage
1 concern names, and negligible at these rates. Under uniform timing 1 − KM at 4.2 years is 0.26
(CI) and 0.06 (NCI): events and censorings interleave in the last 0.2 years and the estimator
extrapolates past a shrinking risk set. That number is an artefact of A3–A4, but it has a
reading: if the authors' data did have 41 NCI deaths in the last ten weeks among people being
censored in the same weeks, their own Kaplan–Meier curves would show the same upturn, and Fig. 2
shows none.

### 4.4 What Model 1 implies about the age effect (`stage2_model1_*.csv`, figure `stage2_model1_age_grid.png`)

Reconstructed ages match Table 1 to within 0.6 years at the median and quartiles (CI 63.1,
53.3–74.6; NCI 50.7, 45.7–59.3; 90th percentiles 83 and 70; ceiling 90).

| outcome | Model 1 | age HR/decade that reproduces it (sex HR 1, 1.3, 1.6) | adjusted HR if age HR = 1.5 | if age HR = 2 |
|---|---|---|---|---|
| ischaemic stroke | 2.47 | 1.76, 1.56, 1.46 | 2.59 | 1.84 |
| any stroke | 2.28 | 1.67, 1.50, 1.41 | 2.27 | 1.61 |
| all-cause mortality | 1.83 | 2.24, 1.88, 1.71 | 2.40 | 1.70 |

Sensitivity (sex HR 1.3): the implied age HR for ischaemic stroke is 1.66, 1.56, 1.51 with the age
ceiling at 80, 90, 100 years and 1.52 with the shift at 30; the figure for death 2.08, 1.88, 1.80,
1.80. So, under the exponential model with age linear on the log hazard, Model 1 is consistent
with an age effect of about 1.5–1.7 per decade for stroke and 1.8–2.1 for death. The 200-replicate
simulation confirms the calibration (geometric mean of the fitted adjusted HR 2.41 against 2.47
expected at the implied age effect; 1.69 against 1.84 at age HR 2, the gap being small-sample
bias with 15 exposed events) and gives the spread: at the implied age effect the adjusted HR
ranges 1.08–4.70 across replicates with mean SE 0.38; at age HR 2, 0.63–3.93 with SE 0.43. The
printed Model 1 CI (1.31–4.68) corresponds to an SE of 0.325, between the unadjusted 0.286 and
the simulated 0.38–0.43. Reading: the headline adjusted HR survives only if a decade of age
multiplies the stroke hazard by about 1.5 in this cohort; with the doubling per decade that
population studies commonly report for stroke incidence after middle age, the same event counts
and age distributions give an adjusted HR of 1.6–1.8 with a CI that includes 1. The paper gives no
age coefficient, no functional form and no age-stratified counts, so this is `inferred` (A6 and
the model form) and settles only with the data. Education, correlated with age, is not in the
model and would move the adjusted HR further down.

### 4.5 What stage 3 inherits

Reconstructed persons (`recon_persons.csv`) are enough for the unadjusted contrast and for
competing-risk estimates by group; they carry no covariates. Stage 3–4 on these data can do:
cumulative incidence with death competing (done here), the sensitivity of the exposure HR to the
age effect (done here as a calibration; a Bayesian version puts a prior on the age effect), and
the added value of MMSE over age for screening only in the calibrated population. Anything on the
continuous MMSE, education-specific cut-offs or Model 2 needs the authors' data.

## 5. Inputs of stages 3 and 4 (S1, 2026-11-22)

Written by the S1 block at the end of `R/01_prepare_data.R`, after the seed-dependent part, so
`recon_counts.csv` and `recon_persons.csv` are unchanged (verified by `git diff` after the run).

- `pem_counts.csv`: the life table of plan §2, one row per scenario × replicate × model × group ×
  interval ((0, 1], (1, 2], (2, 3], (3, 4], (4, 4.2]): persons entering, person-years, events by
  cause, censorings. Model `isch` has causes {ischaemic stroke, death}; under A5 a person with
  another stroke stays at risk of both until censoring, so the `isch` risk set is one person larger
  than the `any` risk set in the NCI group after each other stroke. Model `any` has causes {any
  stroke, death}. Events per cell are the same in every scenario (they are fixed by
  `recon_counts.csv`) and sum to Table 2 (66/15, 75/15, 71/15); person-years depend on the timing
  scenario: uniform replicate 1 (`main = TRUE`) for the analysis, early and late as bounds. Under
  uniform timing the tail interval has about half the person-years of the deterministic scenarios
  (censoring is uniform on (4.0, 4.2] by A4), which is where the two bound it.
  Censoring in the life table follows A1 and A4 and nothing else: the paper reports no loss to
  follow-up and no censoring; the mortality panel's numbers at risk allow at most 30 (NCI) and 6
  (CI) departures of any kind before year 4, all taken as deaths (a censoring in their place would
  move one more death into the tail), so `n_cens` is 0 in intervals 1–4 and every event-free person
  is censored in (4.0, 4.2]. This also mirrors the paper's own design, which follows participants
  who missed the exams through records to 2015-12-31 without censoring them (Methods ll. 141–145;
  concern "Loss to follow-up not reported"). With the authors' data the real last-contact dates
  replace this.
- `calibrated_population.csv`: the A6 population from `R/lib_population.R` (the code of `R/05`,
  moved there without change): 3,875 rows with group, quantile, sex, and age at the three ceilings
  (90 main; 80 and 100 sensitivity), ages rounded to 3 decimals. Sex is independent of age within
  group by construction. No event is attached to a person.
- `stan_data/`: `pem_isch.json`, `pem_any.json` (and `_early`, `_late`), `exposure_age_isch.json`,
  `exposure_age_any.json`, `exposure_age_death.json`; keys documented in the S1 block header.
  Switch keys (`prior_only`, `beta_sd`, `prior`, `age_max`) are rewritten by `run_model.sh` into a
  copy of the file at run time; the committed files hold the defaults (0, 1, 2 = P2, 90).
