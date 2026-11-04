# Concerns — Bukhari 2026

Seeded 2026-10-25 from the first-pass critique; **re-verified 2026-10-29** against the full text
(`paper/Bukhari_2026_fulltext.txt`, "FT l."), the rendered PDF pages, `notes/01_reading_notes.md`
("RN") and `notes/02_methods_inventory.md`. Codes from `protocol/taxonomy.csv`. Severity:
critical = undermines a main conclusion; major = invalidates or weakens an analysis; minor =
reporting. Evidence: confirmed / inferred / needs-data, with the reason for any change from the
seed. Arithmetic to be reproduced in `R/02_consistency_checks.R` (hand values from
`scratchpad/results_arith.py`, 2026-10-29).

Changes from the seeded list: 16 → 27 entries. Merged "arousal/valence" into the construct and
manipulation-check entries; split "p-values" from "Δ signs"; added the untested positive-vs-
negative contrast, post-treatment adjustment, ARRIVE, missing n/df, Fig. 1 integer evidence and
the SBR GRIM failure, pre-registration, overgeneralisation. Downgraded none; upgraded MOD-INTER
(inferred → confirmed: Methods lists no interaction term and Figs 3–4 draw parallel lines).

**Stage 2 update (2026-11-04).** Figures 3–4 digitised (all 68 + 68 change scores recovered,
`data/derived/DIGITISATION_LOG.md`), Tables 2–4 reproduced from them, goodness of fit of the
Tables 3–4 models tested (`R/05_gof_authors_models.R`), and the condition contrasts recomputed
exactly from the signed-difference identity plus a simulated refit of the described mixed model
(`data/derived/SIMULATION_LOG.md`). Entries C1, C2, C4, M1–M4, M13, m2 carry a "Stage 2" bullet;
M15 added. 27 → 28 entries. Tags from stage 2 are `inferred` where they rest on the
reconstruction (n = 34 complete pairs; plotting rounding of ΔRMSSD and ΔET), `confirmed` where
the paper's own numbers suffice.

## Critical

### C1. Change scores reported without sign; magnitudes inconsistent with the condition means
- Code: CON-SIGN (facts) + MEA-DERIVED (consequence) — Severity: critical — Evidence: confirmed; the
  absolute-value explanation is inferred; resolution needs-data
- Location: Table 2 (p. 6), caption; Methods FT l. 771–772; Tables 3–4; Figs 3–4
- What: Δ is defined twice as "control minus positive and control minus negative". Five of the six
  treatment means exceed control, so five Δ must be negative; all six are printed positive. With
  complete pairs mean Δ must equal the difference of means to ±0.02; it does for SBR-positive only
  (19.0) and is above the feasible range for the other five (SBR-neg 6.79 vs 6.74; ET-pos 0.81 vs
  0.78; ET-neg 1.22 vs 1.20; RMSSD-pos 37.73 vs 32.97; RMSSD-neg 10.73 vs 10.09). Tables 3–4
  reproduce from the Δ as printed (intercepts and treatment terms within ±0.13), so the regressions
  and Figs 3–4 used these values. All 68 points in each of Figs 3–4 are ≥ 0.
- Why it matters: if Δ = |control − treatment|, the Δ regressions relate magnitudes of reactivity
  with direction removed, and the claim that changes "make the direction more obvious" (FT l. 431)
  is the opposite of what was done. Several donkeys appear to have had *lower* RMSSD under lucerne
  (hidden sum ≈ −81 ms).
- How to check: `check_delta()` on all six pairs; digitise Figs 3–4 and compare SD(|Δ|) with the SD
  implied by the paired SDs; ask the authors for the signed per-donkey Δ.
- Stage 2: the 68 plotted values per figure reproduce every Δ mean and SD of Table 2 to the printed
  digit (ΔSBR sums exactly 646 and 231) and Table 3 to the second decimal by OLS. The Δ rows are
  therefore the means and SDs of the plotted unsigned values (confirmed). Because the mean of the
  signed differences is fixed by the condition means, the values of donkeys that moved against the
  group direction must add up to (Σ|Δ| − 34·|Δ of means|)/2: 0 for SBR-positive, exactly one donkey
  (ΔSBR = 1) for SBR-negative, 81 ms for RMSSD-positive (2–4 donkeys), 11 ms for RMSSD-negative
  (1–6), 0.5 °C for ET-positive (1–5) and ET-negative (0–2) (`output/tables/contrasts_reversed_counts.csv`).
  The absolute-value reading stays `inferred` only because it assumes 34 complete pairs and Δ taken
  on the same values that enter the condition means; no other reading fits all three tables.

### C2. Exact p-values inconsistent with the reported summaries
- Code: CON-STAT — Severity: critical — Evidence: confirmed
- Location: Results 2.4 FT l. 314–320; Fig. 2 brackets
- What: from the Δ rows (n = 34) the paired t are 16.7 (SBR-pos) and 13.8 (RMSSD-pos), p < 10⁻¹⁴;
  reported p = 0.002 and p = 0.005. The unpaired worst case still gives t ≈ 11. The four contrasts
  reported as "< 0.001" are consistent. df-free version: for both outcomes the contrast with the
  larger t has the larger p (SBR 16.7 → 0.002 vs 12.5 → < 0.001; RMSSD 13.8 → 0.005 vs 8.9 →
  < 0.001), impossible for two models of the same structure.
- Why it matters: the only two exact p-values in the condition analysis cannot come from the
  described models on the described data; either the models, the data or the reporting differ
  from what is written.
- How to check: `t_from_summary()`, `p_consistent()`; request model output and code.
- Stage 2: with the sign reversals accounted for (SD of the signed differences from Σ|Δ|², exact up
  to plotting rounding) the paired t are 16.7 (SBR-pos) and 7.8 (RMSSD-pos) against t needed of
  3.4 and 3.0 (`output/tables/contrasts_exact.csv`); still inconsistent. The described mixed model
  (condition + order fixed, donkey intercept, Satterthwaite df ≈ 64) refitted on 600 simulated
  datasets consistent with Table 2 and the figures gives p ≈ 1e-12 for RMSSD-positive in every
  replicate and p between 0.004 and 0.065 for RMSSD-negative, i.e. the reverse ordering of the
  reported 0.005 and < 0.001; no replicate gives 0.002 for SBR-positive (`sim_contrasts_summary.csv`).
  Neither a paired test nor the described model reproduces the reported pair of values
  (`inferred`, since it rests on the reconstruction).

### C3. Discussion states that RMSSD fell under the negative treatment; Results show an increase
- Code: INF-CONTRA — Severity: critical — Evidence: confirmed
- Location: Discussion FT l. 545–546 vs Table 2 and Fig. 2C
- What: "We found an increase in RMSSD in response to positive treatment and a reduction in HRV in
  response to negative treatment (stressful situation), which is consistent with previous studies
  in horses". Table 2: RMSSD control 47.26 → negative 57.35 ms; Δ = 10.73 ± 7.04; Fig. 2C marks
  control–negative "P < 0.001" with the negative box above control.
- Why it matters: this is the HRV valence claim; the data show the same direction under both
  treatments.

### C4. The valence conclusions rest on a positive-vs-negative comparison that is never tested
- Code: INF-FOLLOW — Severity: critical — Evidence: confirmed
- Location: Discussion ¶1 (FT l. 429–441), ¶4 (l. 520–523), Conclusion (l. 613–615)
- What: no model compares positive with negative for any outcome. ET rises under both (0.81 vs
  1.22 °C), RMSSD rises under both (37.7 vs 10.7 ms); the only between-treatment estimates are the
  treatment terms of Tables 3–4, obtained after adjusting for a co-outcome (C6). The Conclusion
  itself says "numerically greater". Derived claims without support: "change in ET is the measure
  of positive and negative emotions" (an untested 0.41 °C difference in the same direction,
  contradicted at l. 579–580); "assess donkey emotions using the change" (a change still needs a
  within-animal control, and carries no information beyond the pairing); SBR as a "simple and
  practical" field indicator (group-level d ≈ 1.15 negative vs control; individual-level accuracy
  never evaluated).
- How to check: stage 3 — fit the three-level model and report positive − negative with CI;
  compute AUC for SBR as a single-reading classifier from the summary data.
- Stage 2: the positive − negative difference can be bounded without the pairing of a donkey's two
  changes (`output/tables/contrasts_pos_vs_neg_bounds.csv`): SBR 25.7 blinks/min, t ≥ 15 under any
  pairing; RMSSD 22.9 ms, t ≥ 4.1; ET −0.42 °C, t = 2.8 (p 0.009) if the changes are independent and
  1.96 (p 0.059) in the worst case, significant unless the two changes correlate at −0.85 or below.
  So the two treatments do differ on all three outcomes; what remains untested in the paper is
  exactly the comparison its valence claims need, and for ET and RMSSD the difference is one of
  magnitude in the same direction, not of direction (`inferred`).

### C5. No manipulation check: nothing independent shows that the stimuli induced the intended states
- Code: DES-MANIP + MEA-CONSTR — Severity: critical — Evidence: confirmed
- Location: Methods 5.4; Discussion FT l. 607–608
- What: no behaviour other than blinking, no HR, no latency, no approach/avoidance. The authors:
  the study "lacked a comprehensive behavioral investigation during treatments". The hypotheses
  (FT l. 214–218) concern magnitudes of change only; the Introduction presents SBR and ET as
  *stress* markers and the Discussion reads them as *valence* markers. The only evidence that the
  clipper was negative and the lucerne positive is the outcomes themselves.
- Why it matters: without it, "positive" and "negative" are labels for two stimuli, not for two
  emotional states, and arousal cannot be separated from valence.

### C6. Positive stimulus confounded with eating
- Code: DES-CONF — Severity: critical — Evidence: inferred
- Location: Methods 5.4–5.7 (lucerne in an 8-L bucket); Discussion FT l. 569–570
- What: chewing, swallowing, head-down posture and altered respiration change RR intervals and
  therefore ultra-short RMSSD; head in a bucket changes eye visibility and camera angle for both
  the GoPro (blinks) and the FLIR at 1 m/90° (ET). Methods say nothing about how the eye was imaged
  during feeding; no HR, respiration or artefact % reported. The Introduction itself lists HR,
  respiration and activity as RMSSD confounders (FT l. 199–200).
- Why it matters: every positive-treatment effect, including the largest ones (SBR +19, RMSSD +33
  ms), is compatible with a motor/feeding effect.
- How to check: ask the authors for HR per condition, artefact %, and the filming protocol during
  feeding.

## Major

### M1. Treatment effect on ΔRMSSD estimated after adjusting for a co-outcome
- Code: MOD-STRUCT — Severity: major — Evidence: confirmed
- Location: Tables 3–4; Methods FT l. 773–782
- What: ΔSBR and ΔET are themselves outcomes of the treatment. Raw ΔRMSSD difference positive −
  negative = 27.0 ms; after adjusting for ΔSBR 10.82 ms, after ΔET 21.66 ms. The adjusted term is
  not the treatment effect.
- Stage 2: on the reconstructed data the treatment dummy alone gives R² = 0.55 of the models' 0.69
  and 0.70; ΔSBR separates the treatments by 2.35 SD (VIF 2.4), so covariate and treatment carry the
  same contrast (`output/tables/gof_fit_summary.csv`; `inferred`).

### M2. Parallel slopes forced in the Δ regressions
- Code: MOD-INTER — Severity: major — Evidence: confirmed (was inferred; Methods list only main
  effects and Figs 3–4 draw parallel lines)
- Location: Tables 3–4, Figs 3–4
- What: no ΔSBR × treatment or ΔET × treatment term. With unsigned Δ a single slope of 1.32 pools
  "larger increase in SBR ↔ larger increase in RMSSD" (positive) with "larger decrease in SBR ↔
  larger increase in RMSSD" (negative).
- Stage 2: within-treatment slopes on the unsigned values are 1.21 and 1.36 for ΔSBR (interaction
  F-test p = 0.81) and −8.5 and −16.6 for ΔET (p = 0.061) (`output/tables/gof_by_group.csv`). For
  ΔSBR the parallel-slope fit is adequate; the objection is to what a common slope on unsigned
  changes means, not to its fit. For ΔET the common slope averages two slopes that differ twofold.

### M3. Shared-baseline artefact in the Δ regressions
- Code: MEA-DERIVED — Severity: major — Evidence: inferred
- What: both Δ per donkey, and both regressors, subtract the same control value; control
  variability and regression to the mean induce correlation between ΔRMSSD and ΔSBR / ΔET
  independent of any physiological link. Not acknowledged. CI widths imply ≈ 60 df, i.e. the donkey
  random intercept is near zero and the model is OLS on 68 rows.
- Stage 2: OLS on the 68 reconstructed rows reproduces Table 3 to the second decimal (1.33 vs 1.32,
  10.80 vs 10.82) and Table 4 within plotting rounding, so the near-zero random intercept is now
  confirmed; the shared-baseline artefact itself still needs the signed per-donkey data.

### M4. Count outcome and skewed RMSSD modelled as Gaussian; normality checked on raw data
- Code: MOD-FAMILY + MOD-ASSUMP — Severity: major — Evidence: confirmed
- Location: Methods FT l. 748–760; Fig. 1 (integer counts); Fig. 2C (upper whisker 132 ms)
- What: Fig. 1 shows all coder differences on integers and means on half-integers: SBR is an
  integer count per donkey per condition. Shapiro–Wilk "on the data" (p > 0.05) was the basis for
  "raw, untransformed data … for all analyses"; residuals were not examined.
- Re-analysis target (stage 3/4): Poisson or NB GLMM for SBR with donkey and order; log-normal or
  Gamma for RMSSD; same structure in Stan.
- Stage 2 (Tables 3–4 models on the reconstructed data, `output/tables/gof_residual_tests.csv`,
  `gof_model_comparison.csv`; `inferred`): residual SD 5.9 vs 13.2 ms (ΔSBR model) and 5.6 vs 13.1
  (ΔET model) between treatments, variance-ratio p < 1e-5, Breusch–Pagan p 0.0009 and 0.011,
  Shapiro–Wilk p 0.009 and 0.0001, residual spread rising with the fitted value (Spearman 0.54,
  0.52). The ΔET model predicts negative ΔRMSSD for two donkeys (fitted −3.8 ms at ΔET 2.4 °C) for
  a response that cannot be negative. A treatment-specific variance (GLS) or a Gamma log-link
  model improves AICc by 17 and 28 units with the same leave-one-out error: the mean structure is
  adequate, the error model is not, so the SEs, CIs and p-values of Tables 3–4 are not calibrated.

### M5. Carryover, order and randomisation unreported
- Code: DES-CARRY — Severity: major — Evidence: confirmed as unreported; allocation needs-data
- Location: Methods FT l. 657–713
- What: one session, 1-h washout after a food reward or an aversive sound; order is a fixed effect
  but its estimate is never reported; carryover not assessed; randomisation described as "random
  numbers between one to three" in Excel, not a permutation; donkeys per sequence never given; order
  co-varies with time of day and ambient temperature.

### M6. Measured covariates unused; BCS promised and absent
- Code: MEA-COVAR — Severity: major — Evidence: confirmed
- Location: Methods 5.6; Table 1 (p. 5)
- What: ambient temperature (SD 4.55 °C), humidity and wind were measured "as they may affect
  thermography" and enter no model, nor are they reported per condition. Table 1 title promises
  BCS; the table has no BCS row.

### M7. Power analysis does not match the primary contrast
- Code: DES-POWER — Severity: major — Evidence: confirmed
- Location: Methods FT l. 632–641
- What: G*Power with "effect size (ρ = 0.5)", α 0.05, power 0.95 → 34. ρ is a correlation; the
  primary analyses are paired contrasts. Horse data "not [used] to derive the effect size", then ρ
  justified by comparability with horses. Recomputed (script block F, 2026-10-31): n = 34 is
  reproduced exactly by G*Power's point-biserial correlation model, one-sided (power 0.950 at 34);
  two-sided it needs 42, the bivariate-normal model 47 (two-sided) or 39 (one-sided), a paired t at
  d_z = 0.5 needs 54. So the figure is reproducible but rests on a one-sided correlation test
  unrelated to the paired contrasts analysed; at the paper's own d_z (1.4–2.9) 4–9 donkeys suffice.
- How to check: done, `output/tables/consistency_power.csv`.

### M8. Blink-rate mean for the negative condition fails GRIM
- Code: CON-GRIM — Severity: major — Evidence: inferred (assumes integer SBR, supported by Fig. 1,
  and n = 34); needs-data
- Location: Table 2, SBR negative 12.20
- What: with 34 integer counts the mean can only be 414/34 = 12.18 or 415/34 = 12.21; 12.20 is not
  attainable. The other SBR means (18.94, 37.94, 19.0, 6.79) are attainable. Fig. 1C bias −0.17 is
  likewise unattainable for 34 integer differences (−5/34 = −0.15, −6/34 = −0.18), while −0.09 and
  −0.15 are attainable.
- Why it matters: either n ≠ 34 for that cell (missing data, never mentioned) or SBR is not what
  Fig. 1 shows.
- How to check: `grim_consistent(12.20, 34)`; `grim_consistent(-0.17, 34)`; request data.

### M9. HRV processing and condition-model output underreported
- Code: REP-GUIDE — Severity: major — Evidence: confirmed
- Location: Methods 5.7; Results 2.4
- What: no artefact-correction %, HR, respiration or movement; ultra-short 3-min RMSSD during eating
  is the worst case. For the six condition contrasts: no estimates, CIs, df, n, order effects or
  random-effect variances, p-values only; RMSSD-negative p appears only as a figure bracket.

### M10. ARRIVE compliance claimed but four Essential-10 items unmet
- Code: REP-GUIDE — Severity: major — Evidence: confirmed
- Location: Declarations FT l. 1024; whole paper
- What: items 3 (exclusions/missing data), 4 (randomisation method and concealment), 5 (blinding),
  10b (effect sizes with CI) absent; no checklist supplied.

### M11. Blinding not reported
- Code: DES-BLIND — Severity: major — Evidence: confirmed as unreported
- What: coders could see the condition on video (bucket, clipper); thermography reading and
  analysis not blinded; nothing stated.

### M12. Comparative claims about other species and about pain without a comparator
- Code: INF-COMPAR — Severity: major — Evidence: confirmed
- Location: Discussion FT l. 467; Conclusion l. 618–620
- What: "donkeys are not less sensitive than other animals"; "challenges the notion that donkeys …
  experience less pain or stress than horses"; "respond … in a similar way to horses, goats, dogs,
  and cattle". No other species and no pain were studied.

### M13. No effect sizes with uncertainty for the condition contrasts
- Code: REP-EFFECT — Severity: major — Evidence: confirmed
- Location: Results 2.4
- What: p-values only; no mean differences with CI, no df, no n per analysis. Tables 3–4 do give
  CIs.
- Stage 2: Tables 3–4 also report no fit statistic; on the reconstructed data R² is 0.69 and 0.70,
  of which 0.55 is the treatment dummy (M1).

### M15. Condition models pool the residual variance across conditions
- Code: MOD-ASSUMP — Severity: major — Evidence: inferred (simulation on data reconstructed to match
  Table 2 and Figures 3–4; `data/derived/SIMULATION_LOG.md`)
- Location: Methods FT l. 748–760 (model description); Results 2.4; Fig. 2
- What: a linear mixed model with a donkey intercept and one residual variance gives every contrast
  of an outcome the same SE. The reconstructed RMSSD data have signed-difference SDs of 24.5 ms
  (positive) and 8.0 ms (negative); the pooled model SE is 3.4–3.9 ms for both contrasts against
  paired SEs of 4.2 and 1.4. The model therefore overstates the precision of the positive contrast
  and understates that of the negative one by a factor of 2.5–2.9; under it the negative RMSSD
  contrast has p between 0.004 and 0.065, not < 0.001 as the Fig. 2C bracket states. SBR and ET show
  the same pattern to a smaller degree (condition SDs 5.8–8.4 and 0.93–1.02).
- Why it matters: the HRV result for the negative treatment, which the Discussion misreports in
  direction (C3), is also the one whose evidence depends most on the variance assumption.
- How to check: stage 3 model with condition-specific residual variance (or unstructured
  within-donkey covariance); compare contrast SEs with the pooled model.

### M14. Data on request only; no code
- Code: REP-CODE — Severity: major — Evidence: confirmed
- Location: Declarations FT l. 1029; Methods l. 785
- What: no repository, no supplement, no code statement. Request sent 2026-10-25.

## Minor

### m1. Multiplicity unaddressed
- Code: MOD-MULT — Severity: minor — Evidence: confirmed
- What: 6 condition contrasts + 4 regression terms, no adjustment or framing.

### m2. Model structure ambiguities
- Code: MOD-STRUCT — Severity: minor — Evidence: inferred
- What: "individually compare … positive or negative … with the control" suggests six two-condition
  models rather than one three-level model per outcome; not stated. Δ regressions: 2 rows per
  donkey, random intercept weakly identified (M3).
- Stage 2: the three-level model with order as a factor gives Satterthwaite df ≈ 64 on simulated
  complete data, consistent with the ≈ 60 inferred from Tables 3–4; the six-vs-one question stays
  open.

### m3. Overgeneralisation from one stimulus, one exposure, one window
- Code: INF-GENER — Severity: minor — Evidence: confirmed
- Location: Discussion FT l. 489–506
- What: "SBR decreases in response to a stressful or startling situation"; the horse-style SBR
  rebound "was not observed in our study" although no time course was examined; "quicker
  mobilization" of ET under threat asserted without time data.

### m4. No pre-registration; valence/arousal framing is post hoc
- Code: DES-PREREG — Severity: minor — Evidence: confirmed
- What: hypotheses are about magnitudes; the valence vs arousal partition of the measures
  appears first in the Discussion.

### m5. Habituation criterion is the primary outcome
- Code: DES-CTRL — Severity: minor — Evidence: confirmed
- Location: Methods FT l. 663–666
- What: habituation judged by SBR "staying constant", no numeric criterion.

### m6. Reliability incompletely reported
- Code: MEA-RELIAB — Severity: minor — Evidence: confirmed
- What: Bland–Altman bias and LoA are printed on Fig. 1 only (control −1.85/1.67, positive
  −2.51/2.22, negative −1.94/1.59), not in text; no ICC; coder 1 used alone; no reliability for ET or
  RMSSD.

### m7. Missing data and n per analysis never stated
- Code: MEA-MISSING — Severity: minor — Evidence: confirmed as unreported; needs-data
- What: no exclusions, no artefact-based losses, no n per cell; relevant to C1 and M8.

### m8. Age summary not attainable with integer ages
- Code: CON-GRIM — Severity: minor — Evidence: needs-data
- What: 6.05 × 34 = 205.7; not attainable with whole-year ages, nor with half-year ages (411.4);
  quarter-year resolution would attain it. SD 0.31 y in 34 working donkeys is unusually homogeneous.
- How to check: done, `output/tables/consistency_grim.csv` (both resolutions FALSE); ask the
  authors how age was estimated.

### m9. Text–table–figure disagreements
- Code: CON-XREF — Severity: minor — Evidence: confirmed
- What: wind 0.21 m/s (text) vs 0.78 km/h (table; 0.21 m/s = 0.76 km/h); BCS in Table 1 title only;
  RMSSD-negative p in Fig. 2C only; ΔET proposed as valence measure (l. 522) and warned against
  (l. 579); abstract gives no direction for any RMSSD contrast; "control group" for a within-subject
  condition; Ref. 19 pairs a WOAH web page with a 1998 journal DOI (10.1016/S0168-1591(98)00117-8).

### m10. Duplicated text
- Code: CON-DUP — Severity: minor — Evidence: confirmed
- What: medial-canthus sentence twice in Methods (FT l. 725–730); "sensitive measure of both
  physical and emotional stress …" twice in Discussion (l. 548–552); near-duplicate future-work
  passage (l. 592–600); "Band-Altman" typo (l. 754).
