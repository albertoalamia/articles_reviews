# Analysis plan — stages 3 (frequentist) and 4 (Bayesian), Bukhari 2026

**Version 1.1 — 2026-11-09.** v1.0 of 2026-11-06 was the draft of the same day as reviewed by Alberto;
v1.1 changes the donkey random structure of the ET and RMSSD models and the RMSSD family after
step S2 (section 7, entries of 2026-11-09).
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

All contrasts are differences or ratios of expected values averaged over the three positions in
the sequence with equal weights, for a typical donkey (random effect at zero); for RMSSD, whose
model is on the log scale, the primary contrast is the ratio of arithmetic means averaged over
donkeys, and the typical-donkey (median) ratio is reported alongside (section 3). Changes are
defined as **treatment − control** (the paper's "control minus treatment" reversed, so that an
increase is positive).

- **E1 — treatment vs control**, per outcome: positive − control and negative − control.
  SBR as a rate ratio (and the difference in blinks/min, derived); ET as a difference in °C;
  RMSSD as a ratio of arithmetic means (and the difference in ms, derived), with the median-donkey
  ratio alongside. These are the six
  contrasts of Results 2.4, now with intervals.
- **E2 — positive vs negative**, per outcome, same scales as E1. This is the comparison the valence
  claims rest on and the paper never tests. Derived from E2: the sign pattern of E1, i.e. whether
  the two treatments move the outcome in opposite directions (valence-like) or in the same
  direction with different magnitude (arousal-like).
- **E3 — order and donkey**: the sequence-position effects (nuisance, reported because the paper
  says they were modelled and never reports them); for SBR the between-donkey SD and ICC; for ET
  and RMSSD the per-condition donkey-level SDs and the three within-donkey correlations between
  conditions, which take the place of τ and the ICC (section 3).
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
  in all three conditions, Table 2 — both a Gamma and a log-normal model have this property.
  v1.0 made Gamma primary because its contrasts are ratios of arithmetic means, which is what
  Table 2 reports; v1.1 makes the log-normal primary, with an unstructured donkey covariance,
  because the reported numbers imply a within-donkey covariance that a shared intercept cannot
  represent (section 7, 2026-11-09), and recovers the ratio of arithmetic means as
  exp(Δβ + (σ_c² − σ_control²)/2); Gamma with a shared intercept is the family sensitivity).
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
j = row; c(j) = condition, o(j) = order position, t(j) = treatment. SBR keeps a shared donkey
intercept; ET and RMSSD model the three condition values of a donkey as one multivariate normal
vector with an unstructured covariance (v1.1, section 7), so that each donkey has its own
effect in each condition and the within-donkey correlations between conditions are free.

| element | specification | glmmTMB | Stan |
|---|---|---|---|
| **SBR** family and link | y ~ NegBinomial2(μ, φ), log μ = η; Poisson is the limit φ → ∞ and is reported if φ is not identified | `family = nbinom2(link = "log")` | `y ~ neg_binomial_2_log(eta, phi)` |
| **ET** family and link | (y_i1, y_i2, y_i3) ~ MVN(η_i, Σ_ET): the three condition values of a donkey jointly normal, identity link, Σ unstructured 3 × 3 (three SDs σ_c in °C, three correlations) | `family = gaussian`, `~ … + us(0 + condition \| donkey)`, `dispformula = ~ 0` | `y[i] ~ multi_normal_cholesky(eta[i], L_Sigma)` |
| **RMSSD** family and link | (log y_i1, log y_i2, log y_i3) ~ MVN(η_i, Σ_RMSSD): the same on the log scale (σ_c = SD of log RMSSD per condition); arithmetic means exp(η_c + σ_c²/2) | `log(y) ~ … + us(0 + condition \| donkey)`, `dispformula = ~ 0` | `log_y[i] ~ multi_normal_cholesky(eta[i], L_Sigma)`, `log_y` built in `transformed data` |
| fixed effects (all three) | η = β₀ + β_cond[c(j)] + β_order[o(j)], β_cond[control] = β_order[1] = 0 | `~ condition + order` | design vector with 2 + 2 dummies |
| random effects | SBR: u_i ~ Normal(0, τ), one intercept per donkey. ET, RMSSD: the donkey effect is the vector (u_i1, u_i2, u_i3) ~ MVN(0, Σ), Σ = diag(σ_c) Ω diag(σ_c) unstructured; with three observations per donkey it absorbs the residual, so there is no separate residual term (residual variance fixed at 0) | `+ (1 \| donkey)`; `+ us(0 + condition \| donkey)` with `dispformula = ~ 0` | `u[i] ~ normal(0, tau)`, non-centred; `u[i] = diag_pre_multiply(sigma, L_Omega) * z[i]`, `z[i] ~ std_normal()`; the v1.1 programs integrate u_i out and sample Σ only (section 7, 2026-11-18) |
| dispersion / variance | SBR: one φ; ET: σ_c (°C) and Ω; RMSSD: σ_c (log scale) and Ω, c = 1..3 | `sigma`; `VarCorr` | `phi`; `sigma[3]`, `L_Omega` |
| contrasts E1, E2 | link scale: β_pos, β_neg, β_pos − β_neg (ET: the °C differences; RMSSD: the median-donkey log ratios). Response scale averaged over order: SBR rate ratios at u = 0 and differences in blinks/min; RMSSD ratios of arithmetic means exp(Δβ + (σ_c² − σ_ref²)/2), averaged over donkeys, and the differences in ms from exp(η_c + σ_c²/2); the median-donkey ratio exp(Δβ) alongside | SBR: `emmeans(…, ~ condition, type = "response")` and the link-scale contrasts; ET, RMSSD: delta method on (β, θ) with the Hessian covariance `fit$sdr$cov.fixed` | `generated quantities` |
| E3 | β_order[2], β_order[3]. SBR: τ and ICC = τ² / (τ² + σ²_latent), σ²_latent = trigamma(φ) + 1/μ_control, the log-scale variance of the NB2 at the control mean (1/μ_control for Poisson). ET, RMSSD: σ_c (c = 1..3) and the three correlations ρ_cc′ of Σ, which are the within-donkey correlations between conditions (a shared-intercept model is the special case of equal ρ_cc′, and then ρ is the ICC) | `VarCorr`, delta method (Fisher z for ρ) | `generated quantities` |
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
  a check on Σ. Optimiser: glmmTMB's default (nlminb) first; if it stops at a non-positive-definite
  Hessian, BFGS (`optim`) from the same start, and the optimiser used is recorded per fit (the v1.0
  ET model stopped at a boundary, σ_control → 0, on the example replicate). A fit counts as converged when
  the optimiser reports code 0, the Hessian is positive definite, and the log-likelihood is finite and below
  20 per observation; the last clause rejects degenerate BFGS solutions (S4: 5/200 replicates of the Gamma α_c
  sensitivity at ρ_dd = 0.5 with log-likelihood ≈ 10^56 from density overflow, code 0 and a positive-definite
  Hessian). A fit that is not converged has no AICc and is excluded from the model comparison.
- Intervals: Wald 95 % on the link scale, back-transformed; z reference. For one replicate per
  outcome, a parametric bootstrap (1000 refits) of E1–E2 as a check on the Wald intervals at
  n = 34. Ensemble pooling by Rubin's rules (section 2).
- Diagnostics per model and replicate: dispersion ratio (Pearson χ²/df; SBR only, it is undefined
  for the MVN models, whose covariance is saturated); DHARMa scaled quantile
  residuals (250 simulations; uniformity, dispersion and outlier tests; residuals by condition and
  by order) overall and by condition; residual SD by condition against the pooled fit (M15); random-effect normality;
  Cook's-type influence by leaving each donkey out for E1–E2 on one replicate. Pass/fail is
  summarised across replicates (share of replicates with dispersion ratio outside 0.8–1.2, etc.).
- Model comparison within an outcome, by AICc on one replicate and by the share of replicates
  preferring each: SBR, Poisson vs NB2, plus (S4) a Conway–Maxwell–Poisson with dispersion by
  condition and a Gaussian MVN on the counts as check row; ET and RMSSD, unstructured donkey covariance vs shared
  intercept with condition-specific and with pooled dispersion; RMSSD additionally Gamma(log) with
  shared intercept (AICc of the log-normal fits with the Jacobian term 2 Σ log y, so that all RMSSD
  models are on the scale of y). The E1 estimates of every compared model are tabulated next to
  the AICc, so that what a structure costs in the estimand is visible; the sample within-donkey
  covariance of the condition values is tabulated against the model-implied one. A Gaussian MVN on
  raw RMSSD is included as a check row: on source A it wins any family comparison because the
  generator draws the control values as normal on the raw scale, so the log-normal vs Gaussian
  comparison for RMSSD is informative on the authors' data only (S2, 2026-11-09: AICc 862 vs 899,
  ratios 1.695/1.207 vs 1.659/1.175 against 1.701/1.213 in the example data).
- Multiplicity: no adjustment; results are estimates with intervals and are read as such; the
  number of contrasts (9 primary) is stated.

## 5. Stage 4 specifics (Bayesian)

- Priors, weakly informative on the outcome scale, same for every replicate:
  - SBR: β₀ ~ Normal(log 20, 1); β_cond, β_order ~ Normal(0, 1) (95 % of prior rate ratios within
    e^±2 ≈ 0.14–7.4); τ ~ Normal⁺(0, 1); 1/√φ ~ Normal⁺(0, 1).
  - ET: β₀ ~ Normal(35, 2); β_cond, β_order ~ Normal(0, 2); σ_c ~ Normal⁺(0, 2) for the three
    donkey-level SDs (°C); Ω ~ LKJ(2) for the 3 × 3 correlation matrix. (v1.0: σ_c residual SDs and
    τ ~ Normal⁺(0, 2) for a shared intercept; kept for sensitivity ii′.)
  - RMSSD (log scale): β₀ ~ Normal(log 50, 1); β_cond, β_order ~ Normal(0, 1); σ_c ~ Normal⁺(0, 1)
    for the three donkey-level SDs of log RMSSD (prior median 0.67; the Table 2 CVs imply ≈ 0.35);
    Ω ~ LKJ(2). (v1.0 Gamma model: shape α_c ~ Gamma(2, 0.1), prior median ≈ 17, i.e. CV ≈ 0.24,
    95 % mass between CV 0.13 and 0.92; τ ~ Normal⁺(0, 1); kept for sensitivity ii.)
  - E4: a_t ~ Normal(0, 50) ms; b_t ~ Normal(0, 3) ms per blink/min, Normal(0, 40) ms per °C (one
    prior SD at the slope where the implied within-treatment correlation reaches 1, from the
    Table 2 SDs of the changes; v1.0: 10 and 50, changed after the prior predictive check,
    section 7, 2026-11-18); s_t ~ Normal⁺(0, 50).
  Prior predictive checks (`R/03_postprocess.R`, section "prior"): simulated condition means and
  SDs must cover the Table 2 ranges without concentrating on them.
- Sampler: CmdStan 2.36 via `run_model.sh`; 4 chains, 1000 warmup, 1000 sampling, seed 20261025
  + replicate index + 1000 × scenario index (so that no two data files share a seed); `adapt_delta`
  0.95 for the condition models, CmdStan's default for E4. `run_model.sh` takes an optional data-file
  argument (`data/derived/stan_data/cond_<outcome>_<scenario>_rep<k>.json`,
  `delta_<x>_<scenario>_rep<k>.json`; default the example replicate `rho0_rep01`) and the switches
  `--prior-only`, `--prior-scale X`, `--pooled`, which it writes into a copy of the data file (keys
  `prior_only`, `prior_scale`, `pooled`, set to their defaults by `R/01_prepare_data.R`); the draws go
  to `$FITS_DIR/<article>/<model>/<model>_<suffix>_<chain>.csv`. In the MVN programs the donkey
  vectors are integrated out analytically (the model has no residual term, so the likelihood is the
  multivariate normal of the three observed values, section 7, 2026-11-18); divergences, if any, are
  reported per run.
- Diagnostics: R-hat < 1.01, bulk and tail ESS > 400, no divergences, E-BFMI > 0.3, reported per
  run and summarised across replicates; posterior predictive checks of condition means, SDs and
  the 68 unsigned changes per outcome (the reconstruction's own inputs must be recovered), plus
  the SBR integer distribution and the RMSSD upper tail (Fig. 2C whisker at 132 ms).
- Sensitivity, all run, E1–E2 re-reported under each: (i) prior SDs doubled and (i′) prior SDs
  halved, for every model, so that the prior's contribution to the stage 3 vs stage 4 difference is
  bracketed; (ii) RMSSD Gamma(log) with shared donkey intercept and α_c by condition (the v1.0
  primary) instead of the log-normal MVN, and (ii′) ET with shared intercept and σ_c by condition
  (the v1.0 primary); (iii) SBR Poisson instead of NB2 (moot where φ is not identified, as on the
  example replicate); (iv) a single σ for the three conditions in the MVN models (correlations
  still free) and pooled dispersion in (ii)/(ii′), to show what M15 costs; (v) ρ_dd scenarios.

## 6. Comparison table planned for `review.qmd`

Rows: E1 (6 contrasts), E2 (3), E4 (2 slopes × 2 treatments, 2 slope differences), E3 (τ and ICC
for SBR; σ_c and the three within-donkey correlations for ET and RMSSD); E5 (3 AUC) only if done. Columns: authors' reported value (p-value, or Table 3–4 coefficient,
or "not reported"); stage 2 reproduction (exact paired t and CI from `contrasts_exact.csv`;
simulated refit of the described model from `sim_contrasts_summary.csv`); stage 3 estimate with
95 % Wald interval pooled over the ensemble; stage 4 posterior median with 95 % interval pooled
over draws. One row block per ρ_dd scenario for E2.

Attribution of differences: stages 3 and 4 share likelihood, structure and estimands, so any
difference between their columns is due to the priors (and Wald vs posterior intervals at
n = 34); the halved- and doubled-prior sensitivity rows bracket it. Differences between stage 2 and stage 3
are due to the model (unstructured donkey covariance vs shared intercept, condition-specific vs
pooled variance, Poisson/NB2 vs Gaussian for SBR, log-normal vs Gaussian for RMSSD) and are the
point of the exercise.

## 7. Deviations from this plan

| date | what changed | why |
|---|---|---|
| 2026-11-06 (before fitting) | RMSSD family: Gamma(log) primary, log-normal as sensitivity (draft had the reverse); E5 made optional and last; prior sensitivity both halved and doubled; DHARMa adopted | Alberto's review of the draft plan |
| 2026-11-18 (S5, prior check) | E4 slope prior SD 3 ms per blink/min and 40 ms per °C instead of 10 and 50 (§5), decided before any posterior was seen | prior predictive run of `delta_slopes` on the example replicate: the SD of ΔRMSSD in the negative treatment (7.97 ms) fell at the 2.0 percentile of the prior predictive, below the 2.5–97.5 % band, because the predictive SD is at least \|b\| × sd(ΔSBR) ≈ 3.6 \|b\| and Normal(0, 10) rarely gives an SD under 9 ms. The slope at which the implied correlation r = b · sd(x)/sd(ΔRMSSD) reaches 1 is ≈ 2.7 ms per blink/min and ≈ 40 ms per °C (positive treatment), so most of the v1.0 prior mass implied \|r\| > 1. All other rows covered (`stage4_prior_predictive.csv`, run with the v1.0 values; rerun after the change) |
| 2026-11-18 (S5) | Stan programs: (a) `et_mvn.stan` and `rmssd_lognormal_mvn.stan` integrate the donkey vector out, y_i ~ MVN(μ_i, Σ) directly, instead of sampling u_i = diag(σ) L_Ω z_i; same likelihood (no residual term, so y_i − μ_i = u_i), 102 fewer parameters. (b) Sensitivities (i, i′) and (iv) are data switches (`prior_scale`, `pooled`) of the same programs, and the prior predictive is `prior_only`, all set by `run_model.sh` in a copy of the data file; (iii) is a seventh program, `sbr_poisson.stan`. Under `prior_scale` the LKJ(2) prior is unchanged and the Gamma(2, 0.1) prior on α_c has its rate divided (mean and SD of the prior scale together). (c) Seed offset by scenario (1000 × index) in addition to the replicate index. (d) SBR programs mark a predictive cell −1 instead of drawing when η ≥ 20 (μ ≥ 4.9 × 10⁸, reachable only under widened priors without data), and `R/03_postprocess.R` reports the share. (e) The RMSSD log-likelihood includes the Jacobian −Σ log y so that it is comparable with the stage 3 AICc. (f) S6 uses `cond_<outcome>_rho0_rep01.json` (the example replicate) rather than a separate `_example.json` | one-to-one mapping with the glmmTMB models is unchanged; the switches avoid six near-identical copies of each program |
| 2026-11-11 (S4) | Convergence test gains a log-likelihood sanity clause (§4): finite and below 20 per observation | S3/S4 ensemble: the BFGS retry of the Gamma α_c sensitivity fit (ii) reached a degenerate region on 5/200 replicates at ρ_dd = 0.5 (β ≈ 70–100 on the log scale, log α_c ≈ 40–85, log-likelihood ≈ +10^56 from density overflow) while reporting code 0 and a positive-definite Hessian, so it took the best AICc in those replicates (mean Δ AICc ≈ 10^59 for every other RMSSD model at ρ_dd = 0.5 in `stage3_ensemble_model_comparison.csv` of the S3 commit; medians unaffected). The same model hits the boundary α_negative → ∞ (nlminb code 1) in 57/200 replicates at ρ_dd = 0.5, the shared-intercept analogue of Cov(control, negative) > Var(control). A standalone refit of one affected replicate gave a sane BFGS solution, so the retry's outcome is numerically fragile for this model; the guard removes the absurd solutions whichever way they arise. Planned fits, bootstrap and E4 are unaffected (no such fit among them) |
| 2026-11-09 (S2) | SBR ICC: σ²_latent = trigamma(φ) + 1/μ_control, the log-scale variance of the NB2 at the control mean (1/μ_control for Poisson), instead of the count-scale NB2 variance | τ is on the log scale, so both variances in τ²/(τ² + σ²) have to be on the log scale |
| 2026-11-09 (S2 → v1.1) | ET and RMSSD: unstructured 3 × 3 donkey covariance (the three condition values of a donkey as one multivariate normal vector, no separate residual) instead of a shared donkey intercept plus condition-specific residual SD. RMSSD family: log-normal (the MVN on log y) primary; Gamma with shared intercept and α_c demoted to sensitivity (ii), the v1.0 ET model to sensitivity (ii′). RMSSD E1/E2: ratio of arithmetic means exp(Δβ + (σ_c² − σ_ref²)/2) with the median-donkey ratio alongside. E3 for ET/RMSSD: σ_c and the three correlations instead of τ and ICC. Stan: `et_mvn.stan`, `rmssd_lognormal_mvn.stan` replace `et_normal.stan`, `rmssd_gamma.stan` as primary (both kept for the sensitivities). Script: delta method on (β, θ) for the MVN estimands; `optimizer` column; `stage3_example_random_structure.csv` and E1 columns in the model-comparison table | S2 on the example replicate (ρ_dd = 0, rep 1): the v1.0 Gamma model gave a positive/control RMSSD ratio of 1.83 (37.2 ms) against 1.70 (33.1 ms) in the example data and 1.698 in Table 2, with α_negative = 212 and DHARMa dispersion p = 0.008 (`stage3_example_model_comparison.csv`, E1 columns, after the v1.1 run). Cause: the reconstructed data have Cov(control, negative) > Var(control) for RMSSD (`stage3_example_random_structure.csv`; it follows from the Table 2 SDs and the SD of the signed changes, so it holds in every replicate — S3 tabulates the share); a shared intercept forces equal covariances for all condition pairs, each below both variances, and the Gamma fit absorbs the misfit into β_pos and α_negative. The v1.0 ET model stopped at a boundary (σ_control → 0) under nlminb; its ML solution has the same E1/E2 as the MVN. SBR unchanged: the unstructured Poisson model is singular (correlations → 1) and the shared-intercept Poisson reproduces the example (ratios 2.04/0.66 vs 2.005/0.644). A one-factor loading model (`rr(0 + condition \| donkey, d = 1)`) was tried in a session diagnostic and rejected (boundary solutions in most scenarios) |
| 2026-11-09 (S4) | SBR comparison set gains a Conway–Maxwell–Poisson (glmmTMB `compois`, mean-parameterised, log link, `dispformula = ~ condition`) and a Gaussian MVN on the counts (raw-scale check row); planned SBR model unchanged, Bayesian sensitivity list unchanged. Leave-one-donkey-out influence (§4) run at S4 together with the bootstrap, on the example replicate, since §8 had not assigned it to a step | S3: under the shared-intercept Poisson the positive condition is underdispersed and the negative overdispersed (implied SDs 10.7 and 4.5 vs 8.4 and 5.9 observed): DHARMa dispersion ratio outside 0.8–1.2 in 19 / 52 / 88 % of replicates by scenario, homogeneity by condition rejected in 37–42 %, Wald SEs 1.3–1.75 × the paired-t SEs, and the E2 interval identical across ρ_dd scenarios because one τ cannot represent the pair correlations. NB2 cannot be underdispersed; the CMP can, per condition (`stage3_ensemble_diagnostics.csv`, `stage3_ensemble_check_vs_exact.csv`) |
| 2026-11-07 (S1) | generator option `floor` applied to every cell of every condition (SBR ≥ 0, RMSSD > 5 ms), sign pattern and pairing redrawn until feasible, instead of a floor on the control values only; ensemble file long with an `outcome` column instead of one row per donkey with three outcome columns | first S1 run produced negative counts / RMSSD in 35–40 % of replicates (treatment cells); outcomes are generated independently, so donkey k is not the same unit across outcomes |

## 8. Execution schedule

One step per round: Claude writes the code, Alberto reads it and runs it from nvim (or the
command given), the output is checked against the criteria, the step is committed. No step
starts before the previous one is committed. Estimated run times are on Alberto's machine.

| step | Claude prepares | Alberto runs | check before committing |
|---|---|---|---|
| S0 | `shell.nix` + DHARMa (done 2026-11-06) | re-enter the shell; `Rscript -e 'library(DHARMa); library(glmmTMB)'` | both load |
| S1 | `R/lib_simulate_conditions.R`: options `integer_control`, `floor`, `order`; `R/01_prepare_data.R`: ensemble (200 × 3 scenarios), E4 pair files, Stan JSON for the 10-replicate subset, seed table; addendum to `SIMULATION_LOG.md` | `Rscript <art>/R/01_prepare_data.R` (≈ 1 min) | SBR integer in every cell; min RMSSD > 5; Δ multisets per replicate identical to `deltas_fig3/4.csv`; condition means/SDs within 0.1 of Table 2 (printed table); file list and sizes as announced |
| S2 | `R/02_fit_frequentist.R` section A: the three condition models and the two E4 models on the example replicate; DHARMa plots; emmeans contrasts | `Rscript <art>/R/02_fit_frequentist.R --example` (seconds) | models converge; dispersion ratio 0.8–1.2 or explained; contrasts on the response scale reproduce the Table 2 differences of the example data; E4 slopes match `gof_by_group.csv` signs |
| S3 | section B: ensemble fits for E1–E3 (600 replicates × 3 outcomes), Rubin pooling, diagnostics summary, model comparison (MVN vs shared intercept, pooled vs condition-specific, Poisson vs NB2, Gamma vs log-normal), share of replicates with Cov(c, c′) > Var(c) per outcome | `Rscript <art>/R/02_fit_frequentist.R --ensemble` (≈ 10–20 min) | share of non-converged fits < 1 %; pooled E1 medians within rounding of `contrasts_exact.csv` means; between-replicate variance small relative to within for E1, larger for E2 as expected |
| S4 | section C: E4 on the ensemble; parametric bootstrap of E1–E2 on one replicate; leave-one-donkey-out influence; SBR comparison fits (CMP, Gaussian MVN) | `Rscript <art>/R/02_fit_frequentist.R --e4 --bootstrap` (≈ 5 min); `--example` again for the new SBR rows; `--ensemble` again after the convergence guard of 2026-11-11 | bootstrap and Wald intervals agree to ±10 % of width, or the discrepancy is attributed; no donkey shifts E1–E2 by more than one SE; E4 slopes per treatment with intervals |
| S5 | `stan/sbr_nb2.stan`, `stan/et_mvn.stan`, `stan/rmssd_lognormal_mvn.stan`, `stan/delta_slopes.stan` (primary); `stan/et_normal.stan`, `stan/rmssd_gamma.stan`, `stan/sbr_poisson.stan` (sensitivities ii′, ii, iii); `run_model.sh` data-file argument and switches; data switches in `R/01_prepare_data.R`; prior predictive section of `R/03_postprocess.R` | `Rscript <art>/R/01_prepare_data.R` (JSON switches; ensemble CSVs must come out identical); `./<art>/run_model.sh <model> --prior-only` per model; `Rscript <art>/R/03_postprocess.R --prior` | all seven compile; prior predictive means and SDs cover Table 2 ranges without concentrating on them |
| S6 | mapping check: fit the example replicate with each Stan model | `./<art>/run_model.sh <model>` ×4 (primary models; the default data file is the example replicate `cond_<outcome>_rho0_rep01.json`, `delta_sbr_rho0_rep01.json`), plus `delta_slopes delta_et_rho0_rep01.json`; `Rscript <art>/R/03_postprocess.R --example` | posterior medians within 1 SE of the glmmTMB estimates of S2; no divergences, R-hat < 1.01 |
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
- `stan/sbr_nb2.stan`, `stan/et_mvn.stan`, `stan/rmssd_lognormal_mvn.stan`, `stan/delta_slopes.stan`
  (+ `stan/et_normal.stan`, `stan/rmssd_gamma.stan`, `stan/sbr_poisson.stan` for sensitivities ii′, ii, iii;
  prior scale and pooled-variance sensitivities and the prior predictive are data switches, section 5);
  `R/03_postprocess.R` reads `$FITS_DIR`, pools draws, writes `output/tables/stage4_*.csv` and the
  side-by-side table.
- `shell.nix`: add `DHARMa` (nixpkgs `rPackages.DHARMa`); glmmTMB, emmeans, lme4, lmerTest
  already present.
