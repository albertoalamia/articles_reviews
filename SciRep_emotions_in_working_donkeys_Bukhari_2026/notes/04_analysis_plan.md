# Analysis plan — stages 3 (frequentist) and 4 (Bayesian), Bukhari 2026

**Version 1.0 — 2026-11-06.** Draft of the same day reviewed by Alberto (changes in section 7).
Any change after this line is logged in section 7 and bumps the version; the version in force
is quoted in `review.qmd`. Execution follows the step schedule in section 8: Claude prepares one
step, Alberto reviews and runs it, the output is checked against the step's criteria, then the
step is committed before the next is prepared.

Written 2026-11-06, before any model of stages 3–4 is fitted. One specification, two inference
engines: every row of section 3 maps one-to-one onto a Stan program in `stan/`. Changes after
fitting are logged in section 7 with the reason. Protocol v0.1.

Why re-analyse at all, given stage 2: the paper's condition analysis reports p-values only, pools
one residual variance across conditions (M15), never compares the two treatments (C4), and its
regressions relate unsigned changes (C1, M1, M2, M16). Stages 3–4 estimate, with uncertainty, the
quantities the paper's claims need, on data consistent with everything the paper reports, and on
the authors' data if they arrive.

## 1. Estimands

All contrasts are differences or ratios of expected values for a typical donkey (random effect
at zero) averaged over the three positions in the sequence with equal weights. Changes are
defined as **treatment − control** (the paper's "control minus treatment" reversed, so that an
increase is positive).

- **E1 — treatment vs control**, per outcome: positive − control and negative − control.
  SBR as a rate ratio (and the difference in blinks/min, derived); ET as a difference in °C;
  RMSSD as a ratio of means (and the difference in ms, derived). These are the six
  contrasts of Results 2.4, now with intervals.
- **E2 — positive vs negative**, per outcome, same scales as E1. This is the comparison the valence
  claims rest on and the paper never tests. Derived from E2: the sign pattern of E1, i.e. whether
  the two treatments move the outcome in opposite directions (valence-like) or in the same
  direction with different magnitude (arousal-like).
- **E3 — order and donkey**: the sequence-position effects (nuisance, reported because the paper
  says they were modelled and never reports them) and the between-donkey SD and ICC per outcome.
- **E4 — relation between responses**, replacing Tables 3–4: within each treatment, the slope of
  the signed change in RMSSD (ms) on the signed change in SBR (blinks/min) and on the signed change
  in ET (°C), with treatment-specific intercepts, slopes and residual SDs; the slope difference
  positive − negative; the within-treatment correlations as derived quantities. The shared-baseline
  caveat (M3) applies to any Δ-on-Δ regression and is stated, not solved; with the authors' data a
  level-on-level model with donkey effects replaces it (section 7 will record that switch).
- **E5 (optional, last)** — SBR as a single-reading indicator: the probability that one blink-rate
  reading from a donkey in the positive condition exceeds one from the negative condition (AUC),
  and likewise negative vs control and positive vs control. Derived from the SBR model's condition
  means and dispersion (NB2 predictive distributions), not a separate model; it is what the claim
  that SBR is a "simple and practical" field indicator requires. Done after E1–E4 and the write-up
  skeleton, if time allows; the review does not depend on it.

Not estimands: the paper's adjusted treatment terms of Tables 3–4 (M1, M16), and any
mediation-style "direct effect" of treatment through SBR or ET.

## 2. Data

- **Source A (default): reconstructed ensemble**, `R/lib_simulate_conditions.R` via
  `R/01_prepare_data.R`, documented in `data/derived/SIMULATION_LOG.md`. Each replicate is a
  complete dataset of 34 donkeys × 3 conditions matching exactly the 68 unsigned changes per
  outcome of Figures 3–4, the Table 2 condition means and SDs, the implied control–change
  correlations, and a uniformly drawn admissible sign pattern. K = 200 replicates per scenario of
  ρ_dd ∈ {−0.5, 0, 0.5} (the unidentified correlation between a donkey's two changes) for stage 3;
  stage 4 fits a fixed subset of 10 replicates per scenario, 30 runs per model (seeds recorded),
  after checking on the example dataset that the Stan and glmmTMB point estimates agree.
  Two generator options are added for stages 3–4 and logged in `SIMULATION_LOG.md`: control SBR
  drawn as integers (rounding the exact-moment normal draw; because ΔSBR are integers the
  treatment values stay integers and the Δ multisets stay exact), and control RMSSD redrawn until
  all values exceed 5 ms (normal control values with mean 47 and SD 17.5 would otherwise be
  negative in about 0.4 % of draws).
  For E4 the rows are the Figure 3 pairs (ΔSBR, ΔRMSSD) and the Figure 4 pairs (ΔET, ΔRMSSD), 68
  each, with signs inherited by value from the replicate's sign patterns (the same ΔRMSSD value
  carries the same sign in both files).
- **Source B: authors' data** if they arrive (request 2026-10-25; follow-up 2026-11-15). Same
  models, source A then becomes a sensitivity analysis. Additional terms become possible: previous
  condition (carryover), ambient temperature for ET, body condition and age as covariates.
- Unit: donkey (34); rows per donkey: 3 (one per condition) for E1–E3, E5; 2 (one per treatment)
  for E4.
- Outcomes: SBR, integer blinks/min (count; Fig. 1 shows integer coder differences); ET, °C
  (continuous, 33–38); RMSSD, ms (positive continuous, SD proportional to the mean: CV 0.34–0.37
  in all three conditions, Table 2 — both a Gamma and a log-normal model have this property;
  Gamma is primary because its contrasts are ratios of arithmetic means, which is what Table 2
  reports, and log-normal is the family sensitivity).
- Covariates: condition (control = reference, positive, negative); order = position in the
  sequence (1 = reference, 2, 3), as a factor; treatment (negative = reference) in E4. No centring
  for factors; ΔSBR and ΔET enter E4 uncentred, intercepts are reported but not interpreted.
- Exclusions and missing data: none known (the paper reports none, m7). In source A every cell is
  complete by construction. In source B, missing cells are left missing (likelihood-based
  handling under MAR); any exclusion is reported.
- Ensemble inference: estimates are pooled across the K replicates of a scenario with Rubin's
  rules (within-replicate variance plus (1 + 1/K) × between-replicate variance) in stage 3, and by
  pooling posterior draws across replicates in stage 4. ρ_dd = 0 is the headline scenario; the
  other two are reported as sensitivity rows, which matters for E2 only.

## 3. Model, shared by both stages

Three condition models (one per outcome) and two response-relation models. Index i = donkey,
j = row; c(j) = condition, o(j) = order position, t(j) = treatment.

| element | specification | glmmTMB | Stan |
|---|---|---|---|
| **SBR** family and link | y ~ NegBinomial2(μ, φ), log μ = η; Poisson is the limit φ → ∞ and is reported if φ is not identified | `family = nbinom2(link = "log")` | `y ~ neg_binomial_2_log(eta, phi)` |
| **ET** family and link | y ~ Normal(η, σ_c), identity, residual SD by condition | `family = gaussian`, `dispformula = ~ condition` | `y ~ normal(eta, sigma[c])` |
| **RMSSD** family and link | y ~ Gamma(shape α_c, rate α_c/μ), log μ = η: mean modelled directly, condition-specific shape (variance μ²/α_c) | `family = Gamma(link = "log")`, `dispformula = ~ condition` | `y ~ gamma(alpha[c], alpha[c] / exp(eta))` |
| fixed effects (all three) | η = β₀ + β_cond[c(j)] + β_order[o(j)], β_cond[control] = β_order[1] = 0 | `~ condition + order` | design vector with 2 + 2 dummies |
| random effects | u_i ~ Normal(0, τ), one intercept per donkey | `+ (1 \| donkey)` | `u[i] ~ normal(0, tau)`, non-centred |
| dispersion / variance | SBR: one φ; ET: σ_c; RMSSD: α_c, c = 1..3 | as above | as above |
| contrasts E1, E2 | on the link scale: β_pos, β_neg, β_pos − β_neg; response scale at u = 0 averaged over order: SBR differences in blinks/min, RMSSD differences in ms via exp(η) | `emmeans(…, ~ condition, type = "response")` and the link-scale contrasts | `generated quantities` |
| E3 | β_order[2], β_order[3]; τ; ICC = τ² / (τ² + σ²) with σ² the mean residual variance over conditions (ET), the log-scale variance of a Gamma with shape α_c, i.e. trigamma(α_c) averaged over conditions (RMSSD), or the NB2 variance at the control mean (SBR) | `VarCorr`, `sigma` | `generated quantities` |
| E5 | AUC_ab = P(Y_a > Y_b) for independent draws from the NB2 predictive distributions of two conditions at u = 0, order-averaged, computed by summation over the support | computed from the fitted parameters in `R/02_fit_frequentist.R` | `generated quantities` by the same summation |
| **E4** model (×2: x = ΔSBR, x = ΔET) | Δ_RMSSD_j ~ Normal(a_t + b_t x_j, s_t), t ∈ {neg, pos}; no donkey term (one row per donkey; the random intercept was ≈ 0 on 2 rows per donkey, M3) | `lm(dRMSSD ~ treatment * x)` + `gls(weights = varIdent(~1\|treatment))` or `glmmTMB(dispformula = ~ treatment)` | `dRMSSD ~ normal(a[t] + b[t] * x, s[t])` |
| E4 derived | b_pos − b_neg; r_t = b_t · sd(x_t)/sd(Δ_RMSSD_t) | `emtrends` | `generated quantities` |

Everything in the table is identical between engines; the only differences are the priors
(section 5) and, in stage 3, Wald intervals vs posterior intervals.

## 4. Stage 3 specifics (frequentist)

- Software: R 4.4.3, glmmTMB 1.1.10 (all five models, so that dispersion formulas and the NB2
  family share one implementation), lme4 1.1 / lmerTest only for the reproduction of the paper's
  model (stage 2); emmeans for contrasts. Estimation: ML throughout (glmmTMB default), so that
  models within an outcome are comparable; REML variants reported for the Gaussian ET model as
  a check on τ.
- Intervals: Wald 95 % on the link scale, back-transformed; z reference. For one replicate per
  outcome, a parametric bootstrap (1000 refits) of E1–E2 as a check on the Wald intervals at
  n = 34. Ensemble pooling by Rubin's rules (section 2).
- Diagnostics per model and replicate: dispersion ratio (Pearson χ²/df); DHARMa scaled quantile
  residuals (250 simulations; uniformity, dispersion and outlier tests; residuals by condition and
  by order) overall and by condition; residual SD by condition against the pooled fit (M15); random-effect normality;
  Cook's-type influence by leaving each donkey out for E1–E2 on one replicate. Pass/fail is
  summarised across replicates (share of replicates with dispersion ratio outside 0.8–1.2, etc.).
- Model comparison within an outcome, by AICc on one replicate and by the share of replicates
  preferring each: pooled vs condition-specific dispersion; Poisson vs NB2; for RMSSD,
  Gamma(log) vs log-normal (Gaussian on log y; AICc with the Jacobian term so the two are on the
  same scale).
- Multiplicity: no adjustment; results are estimates with intervals and are read as such; the
  number of contrasts (9 primary) is stated.

## 5. Stage 4 specifics (Bayesian)

- Priors, weakly informative on the outcome scale, same for every replicate:
  - SBR: β₀ ~ Normal(log 20, 1); β_cond, β_order ~ Normal(0, 1) (95 % of prior rate ratios within
    e^±2 ≈ 0.14–7.4); τ ~ Normal⁺(0, 1); 1/√φ ~ Normal⁺(0, 1).
  - ET: β₀ ~ Normal(35, 2); β_cond, β_order ~ Normal(0, 2); σ_c ~ Normal⁺(0, 2); τ ~ Normal⁺(0, 2).
  - RMSSD (log link): β₀ ~ Normal(log 50, 1); β_cond, β_order ~ Normal(0, 1); shape α_c ~
    Gamma(2, 0.1) (prior median ≈ 17, i.e. CV ≈ 0.24, with 95 % mass between CV 0.13 and 0.92);
    τ ~ Normal⁺(0, 1).
  - E4: a_t ~ Normal(0, 50) ms; b_t ~ Normal(0, 10) ms per blink/min, Normal(0, 50) ms per °C;
    s_t ~ Normal⁺(0, 50).
  Prior predictive checks (`R/03_postprocess.R`, section "prior"): simulated condition means and
  SDs must cover the Table 2 ranges without concentrating on them.
- Sampler: CmdStan 2.36 via `run_model.sh`; 4 chains, 1000 warmup, 1000 sampling, seed 20261025
  + replicate index; `adapt_delta` 0.95 for the hierarchical models. `run_model.sh` gains an
  optional data-file argument and output suffix so one compiled model runs over the replicate JSON
  files (`data/derived/stan/<model>_rep<k>_rho<s>.json`).
- Diagnostics: R-hat < 1.01, bulk and tail ESS > 400, no divergences, E-BFMI > 0.3, reported per
  run and summarised across replicates; posterior predictive checks of condition means, SDs and
  the 68 unsigned changes per outcome (the reconstruction's own inputs must be recovered), plus
  the SBR integer distribution and the RMSSD upper tail (Fig. 2C whisker at 132 ms).
- Sensitivity, all run, E1–E2 re-reported under each: (i) prior SDs doubled and (i′) prior SDs
  halved, for every model, so that the prior's contribution to the stage 3 vs stage 4 difference is
  bracketed; (ii) RMSSD log-normal instead of Gamma; (iii) SBR Poisson instead of NB2; (iv) pooled
  dispersion instead of condition-specific, to show what M15 costs; (v) ρ_dd scenarios.

## 6. Comparison table planned for `review.qmd`

Rows: E1 (6 contrasts), E2 (3), E4 (2 slopes × 2 treatments, 2 slope differences), E3 (τ, ICC
per outcome); E5 (3 AUC) only if done. Columns: authors' reported value (p-value, or Table 3–4 coefficient,
or "not reported"); stage 2 reproduction (exact paired t and CI from `contrasts_exact.csv`;
simulated refit of the described model from `sim_contrasts_summary.csv`); stage 3 estimate with
95 % Wald interval pooled over the ensemble; stage 4 posterior median with 95 % interval pooled
over draws. One row block per ρ_dd scenario for E2.

Attribution of differences: stages 3 and 4 share likelihood, structure and estimands, so any
difference between their columns is due to the priors (and Wald vs posterior intervals at
n = 34); the halved- and doubled-prior sensitivity rows bracket it. Differences between stage 2 and stage 3
are due to the model (condition-specific vs pooled dispersion, NB2 vs Gaussian, Gamma vs Gaussian)
and are the point
of the exercise.

## 7. Deviations from this plan

| date | what changed | why |
|---|---|---|
| 2026-11-06 (before fitting) | RMSSD family: Gamma(log) primary, log-normal as sensitivity (draft had the reverse); E5 made optional and last; prior sensitivity both halved and doubled; DHARMa adopted | Alberto's review of the draft plan |

## 8. Execution schedule

One step per round: Claude writes the code, Alberto reads it and runs it from nvim (or the
command given), the output is checked against the criteria, the step is committed. No step
starts before the previous one is committed. Estimated run times are on Alberto's machine.

| step | Claude prepares | Alberto runs | check before committing |
|---|---|---|---|
| S0 | `shell.nix` + DHARMa (done 2026-11-06) | re-enter the shell; `Rscript -e 'library(DHARMa); library(glmmTMB)'` | both load |
| S1 | `R/lib_simulate_conditions.R`: options `integer_control`, `control_floor`; `R/01_prepare_data.R`: ensemble (200 × 3 scenarios), E4 pair files, Stan JSON for the 10-replicate subset, seed table; addendum to `SIMULATION_LOG.md` | `Rscript <art>/R/01_prepare_data.R` (≈ 1 min) | SBR integer in every cell; min RMSSD > 5; Δ multisets per replicate identical to `deltas_fig3/4.csv`; condition means/SDs within 0.1 of Table 2 (printed table); file list and sizes as announced |
| S2 | `R/02_fit_frequentist.R` section A: the three condition models and the two E4 models on the example replicate; DHARMa plots; emmeans contrasts | `Rscript <art>/R/02_fit_frequentist.R --example` (seconds) | models converge; dispersion ratio 0.8–1.2 or explained; contrasts on the response scale reproduce the Table 2 differences of the example data; E4 slopes match `gof_by_group.csv` signs |
| S3 | section B: ensemble fits for E1–E3 (600 replicates × 3 outcomes), Rubin pooling, diagnostics summary, model comparison (pooled vs condition-specific, Poisson vs NB2, Gamma vs log-normal) | `Rscript <art>/R/02_fit_frequentist.R --ensemble` (≈ 10–20 min) | share of non-converged fits < 1 %; pooled E1 medians within rounding of `contrasts_exact.csv` means; between-replicate variance small relative to within for E1, larger for E2 as expected |
| S4 | section C: E4 on the ensemble; parametric bootstrap of E1–E2 on one replicate | `Rscript <art>/R/02_fit_frequentist.R --e4 --bootstrap` (≈ 5 min) | bootstrap and Wald intervals agree to ±10 % of width; E4 slopes per treatment with intervals |
| S5 | `stan/sbr_nb2.stan`, `stan/et_normal.stan`, `stan/rmssd_gamma.stan`, `stan/delta_slopes.stan`; `run_model.sh` data-file argument; prior predictive section of `R/03_postprocess.R` | `./<art>/run_model.sh <model> --prior-only` per model; `Rscript <art>/R/03_postprocess.R --prior` | all four compile; prior predictive means and SDs cover Table 2 ranges without concentrating on them |
| S6 | mapping check: fit the example replicate with each Stan model | `./<art>/run_model.sh <model> data/derived/stan/<model>_example.json` ×4; `Rscript <art>/R/03_postprocess.R --example` | posterior medians within 1 SE of the glmmTMB estimates of S2; no divergences, R-hat < 1.01 |
| S7 | loop script over the 30 replicates per model, plus sensitivities (i, i′, ii, iii, iv) on the same replicates; diagnostics collector | `./<art>/run_all.sh` (≈ 1–2 h, background) | every run passes R-hat/ESS/divergence thresholds or is listed; disk usage on `$FITS_DIR` as announced |
| S8 | `R/03_postprocess.R` main: pooled draws, `stage4_*.csv`, posterior predictive checks, side-by-side table with stage 3 | `Rscript <art>/R/03_postprocess.R` (≈ 5 min) | PPC recovers the 68 unsigned changes per outcome and the Table 2 moments; stage 3 vs stage 4 columns differ by less than the prior-sensitivity spread |
| S9 (optional) | E5 from the SBR fits | `Rscript <art>/R/03_postprocess.R --e5` | AUCs with intervals |
| S10 | STATUS entry, registry, section 7 of this plan | commit | — |

## Implementation notes (not part of the specification)

- `R/01_prepare_data.R`: build the ensemble (both sources' formats identical: long CSV
  `donkey, condition, order, sbr, et, rmssd` plus the E4 files), write stage 3 CSVs and stage 4
  JSON for the fixed subset; record seeds. Prerequisites in `R/lib_simulate_conditions.R`:
  `integer_control` and `control_floor` options.
- `R/02_fit_frequentist.R` (new; `02_consistency_checks.R` keeps its name): fits, diagnostics,
  Rubin pooling, tables in `output/tables/stage3_*.csv`.
- `stan/sbr_nb2.stan`, `stan/et_normal.stan`, `stan/rmssd_gamma.stan` (+ `rmssd_lognormal.stan`
  for sensitivity ii), `stan/delta_slopes.stan`;
  `R/03_postprocess.R` reads `$FITS_DIR`, pools draws, writes `output/tables/stage4_*.csv` and the
  side-by-side table.
- `shell.nix`: add `DHARMa` (nixpkgs `rPackages.DHARMa`); glmmTMB, emmeans, lme4, lmerTest
  already present.
