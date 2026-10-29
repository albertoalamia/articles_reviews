# Methods inventory — protocol v0.1

Paper: Bukhari et al. 2026, Sci Rep, doi 10.1038/s41598-026-62753-3 (accepted manuscript).
Filled 2026-10-29 from `notes/01_reading_notes.md` (line refs "RN l.") and the full text ("FT l.").
Codes are from `protocol/taxonomy.csv`. The reading notes use some ad hoc codes (CON-PVAL,
CON-MEANS, INF-CLAIM, REP-INCOMPLETE …); they are mapped to taxonomy codes here, and the
taxonomy codes are the ones that go into `03_concerns.md` and `registry/issues.csv`.
Evidence tags: confirmed / inferred / needs-data.

## A. Selection and provenance
- A1 Track / source: `selected`; own interest (donkey-assisted therapy). Not part of the
  systematic sample.
- A2 Version, DOI, dates: unedited accepted manuscript, "Article in Press"; doi
  10.1038/s41598-026-62753-3; received 16 Dec 2025, accepted 14 Jul 2026, online 22 Jul 2026.
  Publisher's note that errors may be present. Every number to be re-verified against the version
  of record before publication.
- A3 Peer-review status: peer reviewed (Sci Rep). Reports not yet available; may appear with the
  version of record under Transparent Peer Review. Check before publication.
- A4 Data and code availability: data "available from the corresponding author on reasonable
  request" (FT l. 1029); no repository, no supplement. No code statement. Software: R 4.2.3,
  tidyverse, lme4, lmerTest. Request sent 2026-10-25, follow-up due 2026-11-15. Figures 3–4 show
  all 68 Δ points → partial data recoverable by digitisation (RN l. 350–375). [REP-CODE, confirmed]

## B. Design
- B1 Question / pre-registration: three hypotheses stated (FT ll. 214–218), all about the
  *magnitude* of change ("greater change in SBR … ET … HRV") between treatments, none about
  direction or valence. No pre-registration anywhere. The valence/arousal interpretation in the
  Discussion is post hoc. [DES-PREREG, confirmed]
- B2 Design type: within-subject randomised crossover, 3 conditions (control, positive = lucerne in
  an 8-L bucket, negative = clipper sound at the right ear), 3-min recording per condition, 1-h
  washout, single session 10:00–14:00, n = 34 Pakistani working donkeys (brick-kiln setting).
- B3 Unit of analysis vs sampling unit: donkey is the sampling unit, 3 observations per donkey.
  Condition models include a donkey random intercept (adequate). Δ regressions have 2 rows per
  donkey with a random intercept; CI widths imply ≈ 60 df, i.e. the random-effect variance is
  near zero and the model is effectively OLS on 68 rows (RN l. 300–315). [MOD-STRUCT, inferred]
- B4 Control condition: standing in the usual environment, no interaction. Appropriate as a
  baseline. But the comparison the conclusion needs (positive vs negative) is never tested for any
  outcome; only each treatment vs control. [DES-CTRL, confirmed]
- B5 Confounding of manipulation: positive stimulus = eating (chewing, swallowing, head-down into
  a bucket) → affects RR intervals/respiration (RMSSD), periocular temperature and camera angle
  (ET), eye visibility and blinking (SBR). Negative stimulus = novel sound at the ear →
  orienting/attention response indistinguishable from negative valence without behaviour.
  Methods silent on how the eye was imaged while the head was in the bucket. Time of day and
  ambient temperature (SD 4.55 °C) co-vary with order. [DES-CONF, inferred]
- B6 Order / carryover / washout: 1-h washout within one session after a food reward or a
  sustained aversive sound. Order included as a fixed effect in condition models; its estimate is
  never reported; carryover (treatment × preceding treatment) not assessed. Randomisation
  described as "random numbers between one to three" in Excel (FT l. 667–670), which is not a
  permutation; number of donkeys per sequence never reported. [DES-CARRY, confirmed as
  unreported; actual allocation needs-data]
- B7 Sample size justification: G*Power, α = 0.05, power 0.95, "effect size (ρ = 0.5)" → n = 34.
  ρ is a correlation effect size; the primary analyses are paired condition contrasts. Text says
  horse data were "not [used] to derive the effect size", then justifies ρ by comparability with
  horses. Which test gives 34 is unclear (bivariate correlation two-sided ≈ 46, one-sided ≈ 38).
  → recompute with `pwr`. [DES-POWER, confirmed]
- B8 Blinding: none stated for coders (condition visible on video), thermography reading, or
  analysis. [DES-BLIND, confirmed as unreported]
- B9 Manipulation check: none. No behaviour other than blinking, no HR, no latency, no approach/
  avoidance. Authors: the study "lacked a comprehensive behavioral investigation during
  treatments" (FT l. 607–608). The only evidence that the stimuli had the intended valence is the
  outcomes themselves. [DES-MANIP, confirmed]

## C. Measurement
- C1 Operationalisation: SBR = blinks per minute counted from GoPro video (coder 1 used for
  analysis). ET = maximum temperature at the medial canthus, left eye, FLIR T530 at 1 m/90°, under
  shade (frame selection not stated). HRV = RMSSD from Polar Equine V800 via Kubios 3.5.0, 3-min
  ultra-short window, 0.35-s artefact threshold. Introduction frames SBR and ET as *stress*
  markers; Discussion uses them as *valence* markers. [MEA-CONSTR, confirmed]
- C2 Reliability: SBR inter-coder Bland–Altman per condition, bias −0.09 to −0.17 blinks/min,
  limits of agreement "narrow (less than the SBR standard deviations)" — not given numerically;
  no ICC. ET and RMSSD: no reliability (single reading, single device). [MEA-RELIAB, confirmed as
  incompletely reported]
- C3 Validity: all three measures validated by citation in horses, dogs, goats, cattle; no
  donkey-specific validation and this is the first donkey study by the authors' own claim.
  [MEA-CONSTR]
- C4 Scale type: SBR is a count over 3 min (whether mean of three 1-min counts or 3-min count/3 is
  not stated), modelled as Gaussian. RMSSD is positive and right-skewed by nature (Fig. 2C upper
  whisker to 132 ms), modelled as Gaussian on the raw scale. [MEA-SCALE / MOD-FAMILY, confirmed]
- C5 Derived scores: Δ defined as "control minus positive and control minus negative" (FT l. 771–772,
  Table 2 caption). All six reported Δ are positive although five treatment means exceed control;
  five of six Δ magnitudes fall outside the rounding-feasible range of the difference of means
  (RMSSD positive: 37.73 vs 32.97). Everything fits Δ = |control − treatment| (RN l. 219–248).
  Both Δ per donkey share one control value (shared-baseline correlation, regression to the
  mean), not acknowledged. [MEA-DERIVED, confirmed for the sign/magnitude facts; absolute-value
  cause inferred; needs-data]
- C6 Missing data: no statement anywhere; no n per cell; HRV artefact/exclusion counts not
  reported. [MEA-MISSING, confirmed as unreported]
- C7 Measurement conditions / covariates: ambient temperature 25.65 ± 4.55 °C, humidity
  34.64 ± 5.79 %, wind 0.78 ± 0.31 km/h (text: 0.21 m/s) measured "as they may affect
  thermography", then used in no model and not reported per condition. BCS promised in Table 1
  title, absent. Time of day within 10:00–14:00 not used. [MEA-COVAR, confirmed]

## D. Model adequacy
- D1 Model vs design: condition models = LMM with donkey random intercept and order fixed effect,
  fitted "to individually compare" each treatment with control → probably six two-condition
  models (not explicit). Adequate structure for the pairing; order estimate unreported;
  carryover not modelled. Δ regressions: ΔRMSSD ~ ΔSBR + treatment and ΔRMSSD ~ ΔET + treatment,
  donkey random intercept, 68 rows. [MOD-STRUCT, inferred]
- D2 Distributional family: Gaussian for a count (SBR) and for a positive skewed quantity (RMSSD).
  [MOD-FAMILY, confirmed]
- D3 Assumption checks: Shapiro–Wilk "on the data" (raw outcomes), p > 0.05 → "raw, untransformed
  data were used for all analyses". No residual check, no variance homogeneity. [MOD-ASSUMP,
  confirmed]
- D4 Interactions: Δ regressions force parallel slopes across treatments; no ΔSBR × treatment or
  ΔET × treatment term. Under unsigned Δ a single slope pools a larger-increase (positive) with a
  larger-decrease (negative) relation. [MOD-INTER, confirmed]
- D5 Covariates: treatment adjusted for ΔSBR/ΔET, which are themselves outcomes of the treatment
  (post-treatment adjustment; raw ΔRMSSD difference 27.0 ms shrinks to 10.8). Measured
  confounders (ambient, time, order in Δ models) left out. [MEA-COVAR, confirmed]
- D6 Multiplicity: 3 outcomes × 2 contrasts + 2 regressions with 2 terms each = 10 tests; no
  adjustment or framing. [MOD-MULT, confirmed]
- D7 Model selection / reporting: only the final models; no order effect, no random-effect
  variances, no df, no model comparison. [MOD-SELECT, minor; REP-EFFECT]
- D8 Bayesian specifics: n/a.

## E. Internal consistency
(Hand arithmetic in RN l. 209–340 and `scratchpad/results_arith.py`; to be reproduced in
`R/02_consistency_checks.R`.)
- E1 Test statistics vs descriptives: from the Δ rows (n = 34) the paired t are 16.7 (SBR pos),
  12.5 (SBR neg), 8.4 (ET pos), 12.5 (ET neg), 13.8 (RMSSD pos), 8.9 (RMSSD neg). Reported p:
  0.002, < 0.001, < 0.001, < 0.001, 0.005, < 0.001 (last one in Fig. 2C only). The two exact
  p-values are inconsistent with every reported summary (even the unpaired worst case gives
  t ≈ 11). Ordering argument: the contrast with the larger t has the larger p for both SBR and
  RMSSD. Tables 3–4: estimate/SE reproduces t, t² reproduces F, CI = ±1.96 SE — internally
  consistent. [CON-STAT, confirmed]
- E2 GRIM / GRIMMER: age 6.05 ± 0.31 y, n = 34: 6.05 × 34 = 205.7, inconsistent with integer ages;
  feasible with half-year ages. BCS 2.88 feasible on a half-point scale. → `grim_consistent()`.
  [CON-GRIM, needs-data]
- E3 Derived quantities: difference of means vs reported Δ: SBR pos exact; SBR neg 6.74 vs 6.79;
  ET pos 0.78 vs 0.81; ET neg 1.20 vs 1.22; RMSSD pos 32.97 vs 37.73; RMSSD neg 10.09 vs 10.73.
  Signs: 5/6 contradict the definition. Implied within-donkey correlations from the Δ SDs are
  0.62–0.94 (feasible). Tables 3–4 intercepts and treatment terms reproduce from the Table 2 Δ
  means to ±0.13 → regressions were run on the Δ as printed. [CON-SIGN, confirmed]
- E4 Text vs figures vs tables: wind speed 0.21 m/s (text) vs 0.78 km/h (table); Table 1 title
  promises BCS, no row; RMSSD negative p in Fig. 2C only; Discussion "reduction in HRV in response
  to negative treatment" (FT l. 545) vs Table 2/Fig. 2C increase. [CON-XREF, confirmed; INF-CONTRA]
- E5 df and n: no df anywhere; CI widths imply ≈ 60 df in Tables 3–4; n per cell never stated;
  t = 2.82 ↔ p = 0.006 consistent with df ≈ 60. [REP-EFFECT]
- E6 Duplicated / contradictory text: medial-canthus sentence twice in Methods (FT ll. 725–730);
  "sensitive measure of both physical and emotional stress …" twice in Discussion (ll. 548–552);
  near-duplicate future-work passage (ll. 592–600); ΔET proposed as valence measure (l. 522) and
  warned against (l. 579) two pages apart. [CON-DUP, confirmed]

## F. Reporting
- F1 Guideline: ARRIVE claimed (FT l. 1024). Essential 10 items 3 (exclusions/missing), 4
  (randomisation method/concealment), 5 (blinding), 10b (effect sizes with CI) not met; no
  checklist supplied (RN l. 536–552). [REP-GUIDE, confirmed]
- F2 Effect sizes with uncertainty: none for the six condition contrasts (p only); Tables 3–4
  give estimates with CI. [REP-EFFECT, confirmed]
- F3 Exact p and n: p exact for two contrasts, "< 0.001" otherwise; n per analysis never stated;
  no df. [REP-EFFECT]
- F4 Software / code: R 4.2.3 + packages named; no code, no model output. [REP-CODE, confirmed]

## G. Inference
- G1 Conclusions follow: SBR bidirectional group-level effect is supported by the reported
  summaries (subject to E1). "Change in ET measures valence" rests on an untested 0.41 °C
  difference in the same direction; "RMSSD discriminates valence" rests on a between-treatment
  difference tested only after adjusting for a co-outcome; "use changes instead of absolute
  values" adds nothing beyond the pairing and still needs a baseline; SBR as a field indicator is
  a group-level finding presented as an individual-level tool (d ≈ 1.15 negative vs control,
  never evaluated). [INF-FOLLOW, confirmed]
- G2 Discussion vs results: "a reduction in HRV in response to negative treatment" — Results show
  an increase (47.26 → 57.35 ms, p < 0.001 in Fig. 2C). "The direction of change … became more
  obvious" — printed changes have no direction. [INF-CONTRA, confirmed]
- G3 Generalisation: one stimulus per valence, one exposure, one 3-min window, one population →
  "SBR decreases in response to a stressful or startling situation"; horse-style SBR rebound "not
  observed" when no time course was examined. [INF-GENER, confirmed]
- G4 Causal language: experimental design, so causal claims about the stimuli are legitimate; the
  causal reading of ΔSBR→ΔRMSSD "association" is not made explicitly. Minor. [n/a]
- G5 Mechanism: dopamine explanation for SBR is hedged ("did not measure dopamine"); "quicker
  mobilization" of ET under threat asserted without time-course data. [INF-MECH, minor]
- G6 Comparisons without comparator: "donkeys are not less sensitive than other animals";
  "challenges the notion that donkeys … experience less pain or stress than horses"; "respond …
  in a similar way to horses, goats, dogs, and cattle" — no other species, no pain measured.
  [INF-COMPAR, confirmed]

## H. Verdict (provisional)
Proposed: **conclusions not supported** for the HRV and ET valence claims and for the
"use changes" recommendation; **major concerns** for the design as a whole (no manipulation
check, confounded positive stimulus, unsigned change scores, p-values inconsistent with the
reported summaries). The one claim the reported data do support is the group-level
bidirectional SBR effect, pending the E1 inconsistency and the digitised data. Final verdict is
Alberto's call after stages 2–4 and the authors' reply.

Protocol version 0.1 applied as is; no protocol changes proposed from this paper yet, except a
note for later: the taxonomy lacks a code for "selective/incomplete reporting of planned
contrasts" (here: RMSSD negative only in a figure; order effect never reported). Currently filed
under REP-EFFECT.
