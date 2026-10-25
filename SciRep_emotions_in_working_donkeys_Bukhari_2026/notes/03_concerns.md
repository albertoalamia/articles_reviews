# Concerns — Bukhari 2026

Seeded 2026-10-25 from the first-pass critique (`00_first_pass_claude_ai_2026-10-25.md`).
**Every entry is provisional until re-verified against the PDF in Phase 1.** Evidence tags below
are what the first pass implied; confirm or downgrade them.

### Change scores appear to be absolute values
- Code: MEA-DERIVED / CON-SIGN — Severity: critical — Evidence: confirmed (to re-verify)
- Location: Methods (definition control − treatment); Table 2; Figs 3–4
- What: all Δ ≥ 0 although the definition implies negative values for positive-condition SBR, for
  ET in both arms, and for RMSSD in both arms. Mean Δ ≠ difference of means (RMSSD negative:
  10.09 vs 10.73; RMSSD positive: 32.97 vs 37.73), the pattern expected from mean(|Δ|).
- Why it matters: ΔRMSSD ~ ΔSBR and ΔRMSSD ~ ΔET then measure reactivity magnitude, not valence,
  which is what the Discussion interprets.
- How to check: `check_delta()` on every Table 2 pair; request raw data.

### HRV result contradicts the Discussion
- Code: INF-CONTRA — Severity: critical — Evidence: confirmed (to re-verify)
- Location: Table 2 / Fig 2C vs Discussion
- What: RMSSD rises under the negative condition (47.3 → 57.4 ms; Fig 2C marks p < 0.001 control
  vs negative, never reported in text). Discussion says HRV fell, "consistent with horses".

### Reported p-values implausible given descriptives
- Code: CON-STAT — Severity: critical — Evidence: confirmed (to re-verify)
- Location: Results, positive-condition SBR and RMSSD
- What: SBR change 19.0 ± 6.6, n = 34 → paired SE ≈ 1.1, t ≈ 17, yet p = 0.002. RMSSD 37.7 ± 16
  → t ≈ 14, yet p = 0.005. Either the model is not as described or the reporting is wrong.
- How to check: `t_from_summary()`; request full model output and code.

### Positive stimulus confounded with eating
- Code: DES-CONF — Severity: critical — Evidence: inferred
- Location: Methods (lucerne in 8-L bucket)
- What: head lowering, chewing, facial muscle activity and dust each affect blinking, periocular
  temperature and cardiorespiratory patterns. Unclear how blinks were filmed with head in bucket.
  No HR or respiration reported; no non-food positive stimulus.

### Arousal and valence not disentangled; no manipulation check
- Code: DES-MANIP / MEA-CONSTR — Severity: critical — Evidence: confirmed (to re-verify)
- What: no behavioural indices confirm induced states. "Absolute ET reflects arousal, ΔET reflects
  valence" is incoherent since ΔET is a linear function of absolute ET given a shared control.

### Carryover and time-of-day not modelled
- Code: DES-CARRY — Severity: major — Evidence: confirmed (to re-verify)
- What: all conditions in one session, 1-h washout, order as fixed effect only; order partially
  confounded with time of day (10:00–14:00); carryover after aversive clipper not assessed.

### Environmental covariates measured but unused
- Code: MEA-COVAR — Severity: major — Evidence: confirmed (to re-verify)
- What: ambient temperature (SD 4.5 °C), humidity, wind recorded but absent from ET models.

### Count outcome modelled as continuous; assumptions checked on raw data
- Code: MOD-FAMILY / MOD-ASSUMP — Severity: major — Evidence: confirmed (to re-verify)
- What: SBR is a count (Poisson / negative-binomial GLMM indicated); Shapiro–Wilk on raw data.
- Re-analysis target: NB GLMM with animal random effect and order, in Stan, on reconstructed data
  if obtainable, otherwise on summary statistics.

### Parallel slopes forced in Δ models
- Code: MOD-INTER — Severity: major — Evidence: inferred

### Shared-baseline artefact in Δ correlations
- Code: MEA-DERIVED — Severity: major — Evidence: inferred
- What: all Δs share the same control measurement; baseline variability and regression to the
  mean can induce correlation between ΔRMSSD and ΔSBR / ΔET.

### Power analysis mismatched to primary contrast
- Code: DES-POWER — Severity: major — Evidence: confirmed (to re-verify)
- What: based on a correlation test with ρ = 0.5; the primary contrasts are within-subject
  differences. Text says horse data "not used", then justifies ρ by comparability to horses.

### HRV processing underreported
- Code: REP-GUIDE — Severity: major — Evidence: confirmed (to re-verify)
- What: no artefact-correction percentages, HR or respiration; ultra-short 3-min RMSSD during
  eating is vulnerable to both.

### Habituation criterion is the outcome
- Code: DES-CTRL — Severity: minor — Evidence: confirmed (to re-verify)

### Blinding not reported
- Code: DES-BLIND — Severity: major — Evidence: confirmed (to re-verify)

### Comparative species claim without comparator
- Code: INF-COMPAR — Severity: major — Evidence: confirmed (to re-verify)
- What: "donkeys are not less sensitive than other animals" with no other species under protocol.

### SBR framed as field indicator without validity data
- Code: MEA-RELIAB — Severity: minor — Evidence: confirmed (to re-verify)

### Minor
- "Control group" for a within-subject condition; "Band-Altman" typo; Table 1 title mentions BCS
  absent from table; duplicated sentences (HRV paragraph, medial-canthus max-temperature
  sentence, future-research passage) [CON-DUP]; age 6.05 ± 0.31 y implausibly homogeneous
  [CON-GRIM candidate: check with `grim_consistent()` if ages are integers]; Ref. 19 DOI mismatch;
  data "on request" [REP-CODE].
