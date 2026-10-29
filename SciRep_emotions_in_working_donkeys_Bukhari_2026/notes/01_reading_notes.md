# Reading notes — Bukhari et al. 2026

Line numbers refer to `paper/Bukhari_2026_fulltext.txt`. Quotes are verbatim. Items marked ⚑ feed
`02_methods_inventory.md` or `03_concerns.md`.

## Abstract (ll. 83–105)

- Framing: "there is currently no research available on donkey emotions" (l. 85). First study of its kind
  claimed.
- Design as stated: 34 donkeys, three treatments (positive = feeding high-quality lucerne; negative = sound
  of hair clippers; control = "recorded standing in their usual environment"). "Data were analyzed using
  linear models."
- Results as stated:
  - SBR "increased during positive treatment and decreased with the negative treatment compared to the
    control" — bidirectional.
  - ET: "An increase in ET was found for both negative and positive treatment compared to the control" —
    same direction in both arms.
  - HRV: no condition contrast reported in the abstract at all. Only the Δ regressions: ΔSBR→ΔHRV
    "estimated=1.32, t=5.44, p<0.001"; ΔET→ΔHRV "estimated= -12.76, t= -5.93, p<0.001".
- Conclusion as stated: "ET, SBR, and HRV may act as indicators of emotions in donkeys."
- ⚑ "control group" used for a within-subject condition (l. 94). Minor wording [CON-DUP/REP-GUIDE minor].
- ⚑ The abstract gives no direction for the RMSSD condition effects; check whether that omission is
  because RMSSD rose under the negative treatment (see Results).

## Introduction (ll. 106–216)

### Claims about the measures (each later used to interpret results)
- SBR: "has been utilized to measure stress responses in humans 21 and offers a non-invasive method for
  assessing stress in animals 13,22,23" (l. 144). Dopaminergic mechanism via monkey agonist/antagonist
  study (ref 25). "SBR is a reliable measure of stress in humans and animals 10,13,21" (l. 155).
  ⚑ SBR is introduced as a *stress* (negative-arousal) marker, yet the hypothesis and discussion treat it
  as a *valence* marker that rises with positive affect. Direction of SBR under stress is not stated here
  (humans: decreases with focused attention, l. 152). The construct is left ambiguous [MEA-CONSTR].
- ET: "effectively evaluates animal stress across a range of species 26–29" (l. 167); mechanism = blood flow
  changes "commonly affected by stress" (l. 174); "negative relationship between ET and heart rate
  variability (HRV) was observed in response to stress 26" (l. 177).
  ⚑ ET is introduced as a stress/arousal marker only; nothing here supports ET discriminating valence.
- HRV/RMSSD: relaxed state → increased RMSSD (refs 40,44); stress → decreased HRV (26,45,46); positive
  interactions → increased RMSSD (40,44) (ll. 191–196). Caveat acknowledged: RMSSD "is influenced by the
  specific metric used, heart rate, respiration, physical activity, and the level of physiological arousal"
  (ll. 199–200).
  ⚑ The authors themselves name heart rate, respiration and physical activity as confounders of RMSSD;
  check whether Methods/Results report any of them [REP-GUIDE, DES-CONF].

### Donkey-specific rationale (ll. 203–213)
- Stoicism, freeze rather than flight (refs 48,49); belief that donkeys feel less pain/stress (ref 50);
  recognising sentience improves management (ref 20). Motivates the study; no quantitative prior for donkeys.

### Hypotheses as stated (ll. 214–218), verbatim
> "We hypothesized that positive treatment would lead to a greater change in SBR than negative
> treatment. In contrast, negative treatment would result in a greater change in ET than positive
> treatment, and the change in HRV would be greater during positive treatment than during negative
> treatment."

- ⚑ All three hypotheses are about the *magnitude* of change ("greater change"), not its direction. This
  is consistent with the Δ values later being reported without sign (see Results/Table 2). It also means
  the hypotheses as written cannot test valence, which is what the Discussion claims [MEA-DERIVED,
  INF-FOLLOW].
- ⚑ No pre-registration mentioned anywhere in the Introduction [DES-PREREG — confirm in Methods].
- ⚑ No hypothesis about the *direction* of SBR, ET or HRV under each treatment, although the Discussion
  will interpret directions.

## Methods (section 5, ll. 621–785; placed after the Discussion in this journal format)

### 5.1 Ethics (ll. 623–624)
- CityU Animal Research Ethics Sub-Committee No. P9610463. Verbal consent from owners (l. 650).

### 5.2 Sample size (ll. 632–641), verbatim where it matters
- G*Power 3.1. Horse studies cited: SBR 11.1 → 6.2 blinks/min under minor stress (ref 10); ET 32.3 → 35.9 °C
  under acute stress (ref 29).
- > "These studies were used to support the biological plausibility of detecting treatment-related changes
  > in donkeys, but not to derive the effect size for the power analysis. We hypothesized that changes to
  > the SBR, ET, and HRV of donkeys exposed to positive and negative stimuli would be comparable to
  > previous horse studies 10,29. Therefore, the input parameters set for G*Power were alpha (α = 0.05),
  > power (0.95), and effect size (ρ = 0.5), leading to a sample size estimation of 34 donkeys"
- ⚑ Internal contradiction: horse data "not used to derive the effect size", then ρ justified by
  comparability with horses [DES-POWER, confirmed].
- ⚑ ρ is a correlation effect size. The primary analyses are within-subject condition contrasts and
  mixed models; no correlation test is reported as primary. Which G*Power test yields n = 34 for ρ = 0.5,
  α = 0.05, 1−β = 0.95 is unclear (a two-sided bivariate correlation test needs ≈ 46; one-sided ≈ 38).
  → recompute in `R/02_consistency_checks.R` with `pwr` [DES-POWER, confirmed/needs recomputation].

### 5.3 Animals (ll. 642–656)
- 34 Pakistani working donkeys; age 6.05 ± 0.31 y; 20 jennies, 14 jacks; BCS 2.88 ± 0.40 (Donkey Sanctuary
  1–5 scale); health by SEBWAT (ref 15); no medication in the previous month (owner report).
- ⚑ Age SD 0.31 y in 34 working donkeys implies nearly all animals aged exactly 6. If ages are integers,
  6.05 is GRIM-inconsistent (6.05 × 34 = 205.7, not an integer; nearest feasible means 6.03 and 6.06).
  Ages estimated by dentition in half-years would make it feasible. [CON-GRIM, needs-data] → check with
  `grim_consistent(6.05, 34)` and `(…, items = 2)` for half-year resolution.
- BCS 2.88 with half-point scale: 2.88 × 34 = 97.9 ≈ 98/34 = 2.882 → feasible.
- Table 1 title mentions BCS but the table lists only ambient variables (ll. 258–262) [CON-XREF, minor, confirmed].

### 5.4 Design and data collection (ll. 657–713), verbatim where it matters
- "A randomized crossover trial … with a one-hour washout period." Single session, same day, all three
  conditions, each recorded for 3 min → 9 min of data per donkey. Measurements 10:00–14:00.
- Habituation: researcher (SSUHB) spent 2 h/day for 1.5 months with each donkey; equipment habituation.
  > "We chose the SBR as the habituation criterion. When we noticed that the blink rate (blinks per min)
  > stayed constant in the presence and absence of the experimenter and research equipment, we
  > concluded that habituation had been achieved."
  ⚑ Primary outcome used as the habituation criterion; no numeric criterion given [DES-CTRL minor, confirmed].
- Treatments: positive = "high-quality green lucerne (food, 8-liter bucket)", noted as rare and expensive for
  these donkeys; negative = "sound of hair clippers held close to the donkey's right ear"; control = "standing
  calmly in their usual living environment without positive or negative treatment and any other interaction".
  Chosen after dog (ref 9) and horse (ref 10) studies.
  ⚑ Positive condition = eating from a bucket: head down, chewing, jaw/facial muscle activity. Confounds
  blinking (mechanical), periocular temperature, and RR intervals (movement, respiration). No non-food
  positive stimulus, no behavioural coding [DES-CONF, inferred; DES-MANIP, confirmed — no manipulation
  check anywhere in Methods].
  ⚑ Negative condition = clipper *sound* only (not clipping). Novel sound near the ear is also an
  attention/orienting stimulus; for a "freeze" species (Intro ll. 203–205) arousal and valence cannot be
  told apart without behaviour.
- Randomisation, verbatim:
  > "The treatment sequence was randomly assigned by generating random numbers between one to three
  > using Microsoft Excel. Number one was designated as the control treatment, number two as the positive
  > treatment, and number three as the negative treatment."
  ⚑ This describes drawing numbers 1–3, not a permutation of the three treatments. It does not say whether
  all six orders were used or how many donkeys received each sequence. Sequence allocation is never
  reported [DES-CARRY, confirmed as unreported; needs-data for the actual allocation].
- ⚑ Carryover: 1-h washout after a sustained aversive sound or after a food reward, within a single
  session; order is a fixed effect in the models but carryover (treatment × preceding treatment) is not
  assessed [DES-CARRY, confirmed].
- ⚑ Time of day: all within 10:00–14:00, but with three conditions per donkey and 1-h washouts, order is
  partly confounded with time of day and ambient temperature (SD 4.55 °C, Table 1) [MEA-COVAR].
- "On data collection day, donkeys were not working." Good.
- Figure 5: setup (FLIR T530, GoPro, Polar Equine V800).

### 5.5 Spontaneous blink rate (ll. 714–720)
- GoPro HERO Black, 30 fps; offline coding by two coders; "Each coder counted the number of blinks per
  minute. SBR was reported as blinks per minute for each donkey under each test condition."
- ⚑ Unclear whether SBR per condition is the mean of three 1-min counts or the 3-min count divided by 3.
  Either way the underlying datum is a count over 3 min → Poisson/NB family is natural [MOD-FAMILY].
- ⚑ How the eye was filmed while the head was in an 8-L bucket is not described [DES-CONF, inferred].
- ⚑ Coders: blinding to condition impossible from video (bucket/clipper visible) and not claimed
  [DES-BLIND, confirmed as unreported].

### 5.6 Eye temperature (ll. 721–739)
- FLIR T530, 90° to sagittal plane, 1 m, under shade; left eye; maximum temperature at the medial canthus;
  FLIR Tools+; laser distance. Ambient temperature and humidity (LondiSun LS-204) and wind speed
  (Kestrel 1000) measured "as they may affect thermography in field conditions".
- ⚑ The ambient variables are measured for exactly this reason and then do not appear in any model
  (see 5.8) [MEA-COVAR, confirmed].
- ⚑ Duplicated sentence: "The maximum temperature at the medial canthus of the eye was recorded …
  most reliable temperature measurement 32" appears twice (ll. 725–726 and 729–730) [CON-DUP, confirmed].
- ⚑ Frames used: max of the whole 3-min video? one frame? not stated. Head-down posture in the bucket
  changes angle and distance; the 90°/1 m protocol cannot hold during eating [DES-CONF, inferred].

### 5.7 Heart rate variability (ll. 740–747)
- Polar Equine V800; RMSSD (ms); Polar FlowSync → Kubios HRV Standard 3.5.0; "low threshold (0.35 s) for
  artifact correction according to previous research 10,23".
- ⚑ Not reported: percentage of corrected beats per window, mean HR per condition, respiration, movement.
  The Introduction (ll. 199–200) itself lists HR, respiration and activity as RMSSD confounders. 3-min
  windows during chewing are the worst case for electrode movement artefacts [REP-GUIDE, confirmed;
  DES-CONF, inferred].

### 5.8 Statistical analysis (ll. 748–785), verbatim where it matters
- Descriptives mean ± SD. Shapiro–Wilk on "the data": "Data were normally distributed according to the
  Shapiro–Wilk test (p > 0.05); therefore, raw, untransformed data were used for all analyses."
  ⚑ Normality tested on raw outcomes, not residuals; SBR is a count [MOD-ASSUMP, confirmed; MOD-FAMILY].
- Coder-1 data used for analysis; coder-2 for agreement via Bland–Altman ("Band-Altman" typo, l. 754).
- Condition models: "Linear mixed-effects models (with an individual donkey as a random effect) were
  fitted to individually compare SBR, ET, and HRV (quantified as RMSSD) under the positive or negative
  treatment with the control. The order of the treatment application was included in the model as a
  fixed effect."
  ⚑ "Individually compare … positive or negative … with the control" suggests separate two-condition
  models per contrast (6 models, 68 rows each) rather than one three-level model per outcome; not
  explicit. No multiplicity statement for 6 contrasts + 2 regressions [MOD-STRUCT inferred; MOD-MULT
  confirmed as absent].
- Change scores, verbatim: "The change in each parameter (SBR, ET, and HRV) was calculated (control
  minus positive and control minus negative treatment)."
  ⚑ Definition confirmed: Δ = control − treatment. Under this definition Δ must be negative whenever the
  treatment value exceeds control. Compare with Table 2 and Figs 3–4 in Results [MEA-DERIVED / CON-SIGN].
- Δ regressions: two "repeated-measure linear regression models", donkey as random effect;
  model 1: ΔRMSSD ~ ΔSBR + treatment; model 2: ΔRMSSD ~ ΔET + treatment.
  ⚑ No ΔSBR × treatment interaction → parallel slopes forced across positive and negative [MOD-INTER,
  confirmed]. Both Δs in a donkey share the same control measurement → induced correlation and
  regression-to-the-mean artefacts [MEA-DERIVED, inferred]. Each donkey contributes exactly 2 rows; a
  random intercept on 2 rows per subject is weakly identified.
- Software: R 4.2.3, tidyverse, lme4, lmerTest, RStudio (l. 785). ⚑ So p-values presumably from
  lmerTest (Satterthwaite df). No code, no model output tables, no effect sizes with CIs stated as planned
  [REP-CODE, REP-EFFECT — confirm in Results].
- Not mentioned anywhere in Methods: pre-registration [DES-PREREG], blinding [DES-BLIND], missing data
  or exclusions [MEA-MISSING], handling of the three 1-min counts, behavioural measures [DES-MANIP].

## Results (section 2, ll. 225–420)

Arithmetic below is hand-checked from the reported numbers (script
`scratchpad/results_arith.py`, to be moved into `R/02_consistency_checks.R`). Nothing here is from
the raw data.

### 2.1 Coder agreement for SBR (ll. 227–251, Fig. 1)
- Bland–Altman, coder 1 vs coder 2, one plot per condition. Bias −0.09 (control), −0.15 (positive),
  −0.17 (negative) blinks/min. "The limits of agreement were narrow (less than the SBR standard
  deviations) in all situations".
- ⚑ Limits of agreement are not given numerically, only as "less than the SD"; no ICC or
  coder-reliability coefficient; unclear whether agreement is on the per-minute counts or on the
  per-condition mean [MEA-RELIAB, confirmed as incompletely reported]. Values could be read off Fig. 1
  if needed.

### 2.2 Environment, Table 1 (ll. 252–261)
- Table 1: ambient temperature 25.65 ± 4.55 °C, humidity 34.64 ± 5.79 %, wind speed 0.78 ± 0.31 km/h.
- ⚑ Table 1 title promises body condition score; no BCS row exists, and BCS is reported nowhere in
  Results [REP-INCOMPLETE, confirmed].
- ⚑ Wind speed: text "0.21 (ms-1)", table "0.78 ± 0.31 km/h". 0.21 m/s = 0.76 km/h; 0.78 km/h = 0.22 m/s.
  Trivial, but one of the two is a rounding of the other with a different unit [CON-UNITS, confirmed,
  minor].
- Measured "because they may affect thermography" (Methods) but used in no model and not even
  reported per condition or per donkey [MOD-CONFOUND, confirmed].

### 2.3 Descriptives and change scores, Table 2 (ll. 263–306) — the key table
Reported values (mean ± SD, n = 34 assumed; no n stated per cell):

| Outcome | Control | Positive | Negative | Δ positive (reported) | Δ negative (reported) |
|---|---|---|---|---|---|
| SBR (blinks/min) | 18.94 ± 5.83 | 37.94 ± 8.37 | 12.20 ± 5.89 | 19.0 ± 6.62 | 6.79 ± 3.17 |
| ET (°C) | 34.55 ± 0.93 | 35.33 ± 1.02 | 35.75 ± 0.99 | 0.81 ± 0.56 | 1.22 ± 0.57 |
| RMSSD (ms) | 47.26 ± 17.52 | 80.23 ± 27.23 | 57.35 ± 20.30 | 37.73 ± 15.95 | 10.73 ± 7.04 |

- Table caption and Methods both define Δ as "control minus positive and control minus negative".
- ⚑ **Sign.** Under that definition five of the six Δ must be negative (treatment > control for SBR
  positive, ET both, RMSSD both). All six reported Δ are positive. Only Δ SBR negative (12.20 < 18.94)
  has the sign the definition implies. The reported Δ are therefore either treatment − control with
  SBR-negative flipped, or absolute magnitudes. Table 3–4 arithmetic (below) shows the regressions
  were run on the Δ exactly as printed in Table 2 [CON-SIGN, confirmed].
- ⚑ **Magnitude.** With complete paired data, mean(Δ) must equal the difference of the two means
  exactly (up to rounding of ±0.01 on each mean, i.e. ±0.02 on the difference):

  | Δ | control − treatment | feasible range | reported |Δ| | discrepancy |
  |---|---|---|---|---|
  | SBR pos | −19.00 | 18.99–19.01 | 19.0 | 0 |
  | SBR neg | 6.74 | 6.73–6.75 | 6.79 | 0.05 |
  | ET pos | −0.78 | 0.77–0.79 | 0.81 | 0.02 |
  | ET neg | −1.20 | 1.19–1.21 | 1.22 | 0.01 |
  | RMSSD pos | −32.97 | 32.96–32.98 | 37.73 | **4.76** |
  | RMSSD neg | −10.09 | 10.08–10.10 | 10.73 | 0.64 |

  Five of six are outside the feasible range; RMSSD positive is off by 4.8 ms (14 %). Possible
  causes: (a) different n in the Δ row than in the absolute rows (missing/excluded pairs, nowhere
  stated), (b) Δ computed on a different quantity, (c) transcription, (d) **Δ reported as absolute
  values |control − treatment|** [CON-MEANS, confirmed; cause needs-data].
- ⚑ **Hypothesis (d) fits every observation** [inferred, strong]:
  1. all six Δ are positive in Table 2, Tables 3–4, and Figs 3–4 (every one of the 68 points in
     each figure has Δ ≥ 0; ΔET has one point at exactly 0.0);
  2. mean|d| ≥ |mean d| always, and all five discrepant cells have reported Δ *above* the
     feasible range, none below (chance of 5/5 same direction under symmetric error: 1/32);
  3. the one exact cell, SBR positive (19.0 = 19.0), is the one where no donkey could plausibly
     have changed in the wrong direction (mean/SD = 2.9, minimum ΔSBR in Fig. 3 ≈ 10);
  4. the excess is largest for RMSSD positive, the outcome with the widest within-donkey spread.
  Under (d), excess = 2 × (sum of wrong-direction changes)/34, so the sum of wrong-direction
  changes is ≈ −81 ms (RMSSD pos), −11 ms (RMSSD neg), −0.9 blinks/min (SBR neg), −0.5 °C (ET pos),
  −0.3 °C (ET neg). I.e. several donkeys had *lower* RMSSD under lucerne than under control, and
  the Δ row hides their sign. If (d) is right, Tables 3–4 and Figs 3–4 are regressions on absolute
  changes, and the "association" between ΔSBR and ΔRMSSD is between magnitudes with direction
  removed. Test: digitise Figs 3–4 (below) and compare the digitised mean/SD with Table 2; the
  absolute-value hypothesis predicts SD(|Δ|) < SD(Δ) implied by the paired SDs.
- Δ SDs are feasible: implied within-donkey correlation r = (SD₁² + SD₂² − SD_Δ²)/(2·SD₁·SD₂) is
  0.62 (SBR pos), 0.85 (SBR neg), 0.84 (ET pos), 0.83 (ET neg), 0.83 (RMSSD pos), 0.94 (RMSSD neg).
  All in [−1, 1], so no impossibility there; keep the values for the simulation-based
  reconstruction later.
- ⚑ Text (l. 272) repeats the Δ row verbatim; nothing on n, missing values, or artefact exclusions
  for HRV. HR itself and the RR-artefact percentage (Methods 5.7) are never reported [REP-INCOMPLETE,
  confirmed].

### 2.4 Condition contrasts, Fig. 2 (ll. 308–335)
Text, verbatim numbers: SBR positive "p=0.002"; SBR negative "p<0.001"; ET negative "p<0.001"; ET
positive "p<0.001"; RMSSD positive "p=0.005". Fig. 2 caption: "P-values were generated using linear
mixed models."
- ⚑ **p-values inconsistent with the reported Δ.** Paired-t equivalents from the Δ rows (n = 34):

  | contrast | Δ ± SD | t = Δ/(SD/√34) | p (any df ≥ 30) | reported |
  |---|---|---|---|---|
  | SBR pos | 19.0 ± 6.62 | 16.7 | < 10⁻¹⁵ | 0.002 |
  | SBR neg | 6.79 ± 3.17 | 12.5 | < 10⁻¹² | < 0.001 |
  | ET pos | 0.81 ± 0.56 | 8.4 | < 10⁻⁹ | < 0.001 |
  | ET neg | 1.22 ± 0.57 | 12.5 | < 10⁻¹² | < 0.001 |
  | RMSSD pos | 37.73 ± 15.95 | 13.8 | < 10⁻¹⁴ | 0.005 |
  | RMSSD neg | 10.73 ± 7.04 | 8.9 | < 10⁻⁹ | < 0.001 (Fig. 2C bracket only, not in text) |

  A mixed model with donkey random intercept and order as a fixed effect is at least as powerful
  as the paired t on these data; adding an order term with 2–5 df cannot move p from 10⁻¹⁵ to 0.002.
  Even the between-subject (unpaired, worst-case) t for SBR positive is
  19.0/√(5.83²/34 + 8.37²/34) = 10.9, p < 10⁻¹⁴. The two exact p-values (0.002, 0.005) are
  inconsistent with every number in Table 2; the three "< 0.001" are consistent. Note the pattern:
  exactly the two exact p-values are the inconsistent ones [CON-PVAL, confirmed].
- ⚑ **Ordering argument, df-free.** For both SBR and RMSSD the positive contrast has the larger
  standardised change (t 16.7 vs 12.5; 13.8 vs 8.9) yet the *larger* p (0.002 vs < 0.001; 0.005 vs
  < 0.001). Whatever the model and df, the contrast with the larger t cannot have the larger p when
  the two models have the same structure. This holds without any assumption about df or the order
  term [CON-PVAL, confirmed].
- RMSSD negative vs control: not in the text; Fig. 2C shows a "P < 0.001" bracket control–negative
  (and "P = 0.005" control–positive). Reported in the figure only [REP-INCOMPLETE, minor].
- ⚑ No estimates, CIs, df, order-effect estimates, random-effect variances, or model tables for the
  six condition models; p-values only [REP-EFFECT, REP-MODEL, confirmed].
- ⚑ SBR and ET both increase under positive and ET increases under negative too; the "opposite
  direction" claim holds for SBR only. ET goes the same way in both valences (0.81 vs 1.22 °C), RMSSD
  goes the same way in both (37.7 vs 10.7 ms). No test of positive vs negative is reported for any
  outcome, which is the contrast the valence claim needs [INF-CLAIM, confirmed].
- Fig. 2: box plots per condition for the three outcomes → medians/IQR/whiskers extractable if the
  summary-data reconstruction needs a distribution check (SBR skew, RMSSD skew).

### 2.5 Δ-regressions, Tables 3–4, Figs 3–4 (ll. 336–414)
Table 3 (ΔRMSSD ~ ΔSBR + treatment, negative = reference), as printed:

| term | estimate | 95 % CI | SE | t | F | p |
|---|---|---|---|---|---|---|
| Intercept | 1.72 | −2.97 – 6.43 | 2.42 | 0.71 | – | 0.47 |
| ΔSBR | 1.32 | 0.85 – 1.79 | 0.24 | 5.44 | 29.60 | < 0.001 |
| Treatment (positive) | 10.82 | 3.32 – 18.28 | 3.83 | 2.82 | 7.95 | 0.006 |

Table 4 (ΔRMSSD ~ ΔET + treatment):

| term | estimate | 95 % CI | SE | t | F | p |
|---|---|---|---|---|---|---|
| Intercept | 26.43 | 20.24 – 32.62 | 3.16 | 8.34 | – | < 0.001 |
| ΔET | −12.76 | −16.97 – −8.54 | 2.15 | −5.93 | 35.18 | < 0.001 |
| Treatment (positive) | 21.66 | 17.02 – 26.37 | 2.37 | 9.11 | 82.99 | < 0.001 |

- Internal checks, all pass: estimate/SE reproduces t to ±0.03; t² reproduces F to ±0.02; CI
  half-widths equal 1.95–1.97 × SE (so df are large, ≈ 60–65, consistent with 68 rows and a
  near-zero random-intercept variance). t = 2.82 with p = 0.006 implies df ≈ 60 as well.
  ⚑ df never reported; a near-zero donkey variance would mean the "repeated-measure" model
  collapses to OLS on 68 rows [REP-MODEL, confirmed; MOD-STRUCT, inferred].
- Cross-check against Table 2 Δ means (OLS identities, approximate for a mixed model):
  intercept ≈ ȳ_neg − b·x̄_neg: 10.73 − 1.32×6.79 = 1.77 (reported 1.72); 10.73 + 12.76×1.22 = 26.30
  (reported 26.43). Treatment ≈ (ȳ_pos − ȳ_neg) − b·(x̄_pos − x̄_neg): 27.0 − 1.32×12.21 = 10.88
  (reported 10.82); 27.0 + 12.76×(−0.41) = 21.77 (reported 21.66). → Tables 3–4 were fitted on the
  Δ exactly as printed in Table 2 (all positive). So Table 2's Δ row, Tables 3–4 and Figs 3–4 are one
  consistent block; Table 2's absolute rows and the 2.4 p-values are what disagree with it.
- ⚑ **Interpretation under the printed signs.** With all Δ positive, "a greater change in SBR" means a
  larger *increase* under positive and a larger *decrease* under negative. A single slope of 1.32
  pools two opposite physiological relations, with no interaction term to let them differ. Under the
  stated definition (control − treatment) the two treatment groups would sit on opposite sides of
  zero on the x-axis and the pooled slope would be driven almost entirely by the treatment
  separation [MOD-INTER, MEA-DERIVED, confirmed].
- ⚑ The treatment coefficient (10.82 with ΔSBR; 21.66 with ΔET) is the mean ΔRMSSD difference after
  adjusting for a covariate that is itself a treatment outcome: adjusting for a mediator/collider.
  Raw difference is 27.0 ms [MOD-CONFOUND (post-treatment adjustment), confirmed].
- ⚑ Both Δ in a donkey share the one control value → built-in positive correlation between ΔRMSSD
  and ΔSBR/ΔET via the shared control term, plus regression to the mean. Not addressed
  [MEA-DERIVED, inferred].
- Wording: "associated with a higher RMSSD level" (l. 341) — the outcome is a change, not a level.
- No multiplicity adjustment across 6 contrasts + 4 regression terms [MOD-MULT, confirmed].

### Table-by-table
- Table 1: environment; BCS missing despite the title; wind-speed unit mismatch with text.
- Table 2: absolute means per condition and Δ; Δ signs contradict the definition; Δ magnitudes
  inconsistent with the means for 5/6 cells (RMSSD pos by 4.8 ms); no n per cell.
- Table 3: ΔRMSSD ~ ΔSBR + treatment; internally consistent; consistent with Table 2 Δ row.
- Table 4: ΔRMSSD ~ ΔET + treatment; internally consistent; consistent with Table 2 Δ row.

### Figure-by-figure
- Fig. 1: Bland–Altman per condition; LoA not given numerically → extract if needed.
- Fig. 2 (p. 7, viewed 2026-10-29): Excel-style box plots (box = IQR, line = median, × = mean,
  whiskers, dots = outliers), one panel per outcome, three conditions. Brackets: A "P = 0.002"
  control–positive, "P < 0.001" control–negative; B "P < 0.001" both; C "P = 0.005" control–positive,
  "P < 0.001" control–negative. Rough reads: SBR control median ≈ 19 (box 15–24, whiskers 9–28),
  positive ≈ 38 (33–45; 22–58), negative ≈ 12 (8–16; 3–29). ET control ≈ 34.5 (33.8–35.2; 33.1–36.0),
  positive ≈ 35.3 (34.6–36.1; 33.7–37.5), negative ≈ 35.7 (35.2–36.2; 33.9–37.5, outliers ≈ 38.1,
  33.5). RMSSD control ≈ 47 (35–62; 18–80), positive ≈ 78 (62–100; 22–132), negative ≈ 55 (42–78;
  28–100). Medians close to the means → no gross skew at the condition level; RMSSD positive has a
  long upper tail (whisker to 132).
- Fig. 3 (p. 8) and Fig. 4 (p. 9): **scatter plots with all 68 raw points** (34 teal = positive,
  34 salmon = negative) plus two parallel fitted lines. Axes: Fig. 3 ΔSBR 0–37 (x) vs ΔRMSSD 0–75
  (y); Fig. 4 ΔET 0.0–2.4 (x) vs ΔRMSSD (y). ΔET values sit on a 0.1 °C grid; ΔSBR shows vertical
  stacks (e.g. at ≈ 17–19) suggesting integer or 1/3-step values; ΔRMSSD looks continuous. All Δ
  ≥ 0 in both figures. One salmon outlier at ΔSBR ≈ 11, ΔRMSSD ≈ 31. Positive points span ΔSBR
  ≈ 10–37 and ΔRMSSD ≈ 15–75; negative ΔSBR ≈ 1–14, ΔRMSSD ≈ 1–31.
  → **Digitisation plan**: the two figures share the y-variable (ΔRMSSD), so the 68 (ΔSBR, ΔRMSSD)
  pairs from Fig. 3 can be matched to the 68 (ΔET, ΔRMSSD) pairs from Fig. 4 by y-value and
  treatment colour, giving (ΔSBR, ΔET, ΔRMSSD) per donkey × treatment, up to digitising error and
  ambiguities where y-values coincide. That is enough to (i) recompute the Table 2 Δ rows, (ii)
  refit Tables 3–4 exactly, (iii) test the absolute-value hypothesis, (iv) fit the Δ-regressions
  properly (interaction, no shared-control artefact cannot be fixed without control values).
  Control-level values are *not* recoverable from any figure. Extract the embedded rasters with
  `pdfimages -png` (native resolution) rather than re-rendering the page.

### Not in Results at all
Order effect (estimate or test), per-condition n, missing data/exclusions, HRV artefact %, heart
rate, respiration, ambient covariates per condition, positive-vs-negative contrasts, model df or
random-effect variances, any CI for the condition contrasts, any behavioural validation of the
induced states, the sign of any individual donkey's change.

## Discussion (section 3, ll. 421–610) and Conclusion (section 4, ll. 611–620) — claims, in order

Seven paragraphs. For each: what is claimed, what in Results supports it, what does not.

### ¶1 Summary and the "change" proposal (ll. 422–441)
- Verbatim: "Our results showed an increase in ET and a decrease in SBR in response to a negative
  treatment ... However, both ET and SBR increased in response to the positive treatment." — matches
  Table 2.
- Verbatim (l. 429–431): "When we calculated the change in each parameter (control minus positive and
  control minus negative treatment), the direction of change in each variable became more obvious. In
  response to positive treatment, the change in HRV and SBR was higher, but the change in ET was lower,
  while during negative treatment, the change in HRV and SBR was lower, and the change in ET was higher."
  ⚑ "Higher"/"lower" here compare the *size* of Δ between treatments, not its direction. The printed Δ
  carry no direction at all (Results 2.3). The sentence claims the opposite of what the table does
  [INF-CLAIM, confirmed]. The positive-vs-negative comparison of Δ is never tested for any outcome
  except as the covariate-adjusted treatment term in Tables 3–4 [INF-UNTESTED, confirmed].
- Verbatim (l. 439–441): "We propose that instead of considering absolute values for ET, SBR, and HRV,
  we should assess donkey emotions using the change in ET, SBR, and HRV."
  ⚑ A change requires a within-animal control measurement, so the proposal does not remove the need
  for a baseline; and absolute values and changes are the same data minus one constant per donkey, so
  the "direction" is identical in both. The only new information in Δ is the pairing. Unsupported as a
  methodological recommendation [INF-FOLLOW, confirmed].
- "HRV and SBR are likely more related to autonomic regulation, attention, and emotional valence,
  whereas ET mainly reflects arousal" — post hoc; the Introduction hypotheses (ll. 214–218) were about
  magnitudes only and said nothing about valence vs arousal [INF-POSTHOC, confirmed].

### ¶2 Stoicism and welfare (ll. 442–470)
- Verbatim (l. 467): "Our study suggests that donkeys are not less sensitive than other animals,
  although they may show less overt behavioral change".
  ⚑ No other species was measured, no behaviour other than blinking was measured, no pain was
  studied. Cross-species comparison is by citation only [INF-OVERREACH, confirmed]. The welfare advice
  that follows (owners, loud noises, equipment) is not a result of this study.

### ¶3 SBR (ll. 471–506)
- Decrease under clipper, consistent with horses (refs 10, 13, 53); increase under lucerne attributed
  to dopaminergic activity, hedged ("did not measure dopamine").
- Verbatim: "after an initial decrease in SBR in response to the negative stimulus, SBR started
  increasing [in horses]. This was not observed in our study with donkeys."
  ⚑ Not observed because not examined: SBR was counted per minute over a 3-min window (Methods 5.5)
  and only the per-condition value is reported. No time course is shown anywhere. "Not observed" ≠
  "absent" [INF-ABSENCE, confirmed].
- "Our study demonstrates that SBR decreases in response to a stressful or startling situation" — one
  stimulus, one exposure, one window; generalisation from a single negative stimulus [INF-GENERAL,
  confirmed]. No manipulation check that the clipper was in fact stressful (no behaviour, no HR) —
  the only evidence that the stimulus was negative is the outcomes themselves [DES-MANIP, confirmed].

### ¶4 ET (ll. 507–544)
- Increase under both treatments; acknowledges arousal interpretation (dogs feeding, goats).
- Verbatim (l. 520–523): "Interestingly, the change in ET during the negative treatment (1.22±0.57°C)
  was greater than positive treatment (0.81±0.56°C) in our study. Therefore, we propose that absolute
  ET is a measure of arousal, whereas change in ET is the measure of positive and negative emotions in
  donkeys."
  ⚑ The 0.41 °C difference between treatments is never tested (no positive-vs-negative contrast; the
  Table 4 treatment term is on ΔRMSSD, not ΔET). Both changes are in the same direction, so Δ ET
  cannot indicate valence without an untested threshold. "Absolute ET measures arousal, change in ET
  measures valence" is not a coherent distinction: the change is the absolute value minus the
  control value [INF-UNTESTED, INF-FOLLOW, confirmed].
- Ambient temperature varied with SD 4.55 °C across sessions (Table 1) and was measured "because it
  may affect thermography", yet the 0.41 °C between-treatment difference is interpreted without
  adjusting for it or for order [MOD-CONFOUND, confirmed].
- "quicker mobilization of the physiological responses ... to negative versus positive contexts" —
  time course not measured [INF-ABSENCE].
- ⚑ Contradicted later in ¶6: "ET should be interpreted carefully as it increases in both positive and
  negative treatment" (l. 579–580). The paper proposes ΔET as a valence measure and warns against it
  within two pages [CON-TEXT, confirmed].

### ¶5 HRV (ll. 545–572)
- Verbatim (l. 545–546): "We found an increase in RMSSD in response to positive treatment and a
  reduction in HRV in response to negative treatment (stressful situation), which is consistent with
  previous studies in horses".
  ⚑ **Contradicts the paper's own Results.** Table 2: RMSSD control 47.26 → negative 57.35 ms, an
  *increase*; Fig. 2C marks control–negative "P < 0.001" with the negative box above control; Δ
  RMSSD negative = 10.73 ± 7.04. No reduction of RMSSD under the negative treatment appears anywhere
  in Results. This is the central claim for HRV as a valence marker and it is inconsistent with the
  reported data [CON-TEXT, INF-CLAIM, confirmed]. (Under the absolute-value hypothesis in Results 2.3
  a minority of donkeys may have had lower RMSSD under clipper, sum ≈ −11 ms; that would not make
  the mean a reduction.)
- Duplicated sentence, verbatim twice (ll. 548–552): "It is a sensitive measure of both physical and
  emotional stress in horses 58, and it is a commonly used autonomic nervous system (ANS) correlate,
  estimating the sympathovagal balance as a psychophysiological marker of emotion regulation across
  species" [REP-EDIT, confirmed].
- Verbatim (l. 569–570): "similar to the change in RMSSD, which was high in donkeys when lucerne was
  provided for eating."
  ⚑ The positive stimulus is *eating*. Chewing, swallowing, head-down posture and altered breathing
  change RR intervals, respiratory sinus arrhythmia and therefore RMSSD, independently of emotion;
  head-in-bucket also changes eye position for the thermal camera and the blink video. Ultra-short
  (3-min) RMSSD is the metric most sensitive to respiration and artefacts, and artefact handling,
  respiration and HR are not reported (admitted in ¶6, l. 583–592). The positive-treatment effects on
  all three outcomes are confounded with feeding behaviour [DES-MANIP, MEA-CONFOUND, inferred].
  Checked Methods 5.4–5.6 (2026-10-29): the lucerne was in an "8-liter bucket"; nothing is said about
  camera distance, head position, or how the medial canthus was imaged and blinks counted while the
  head was in the bucket. Ask the authors.
- Cited comparisons (goats 65 vs 45 ms; Przewalski winter/summer; sport horses) are descriptive
  support, not evidence about this design.

### ¶6 Practical implications and limitations (ll. 573–610)
- "SBR is a relatively easy measure ... A decrease in SBR may indicate a stressful situation" — as a
  field indicator without a within-animal control, the negative-vs-control separation is
  12.20 ± 5.89 vs 18.94 ± 5.83 (d ≈ 1.15, overlap substantial); classification performance never
  evaluated. → stage 3: compute AUC / sensitivity at plausible cut-offs from the summary data
  [INF-CLAIM, inferred].
- Admitted limitations, verbatim where useful: "RMSSD was the only HRV metric analyzed" (l. 583);
  future work should account for "artefacts, respiratory influences, and ectopic beats" (l. 591–592);
  "this study only included one behavior (SBR) and lacked a comprehensive behavioral investigation
  during treatments" (l. 607–608).
  ⚑ The last admission is the manipulation-check gap: there is no independent evidence that the
  intended emotional states were induced [DES-MANIP, confirmed by the authors' own statement].
- Near-duplicate passage: "It would also be helpful if further research could include longer
  observations ... after removal of the treatment" (l. 592–596) and "Future research should include
  longer observation periods ... along with a washout period" (l. 597–600) say the same thing twice
  [REP-EDIT, minor].
- Not acknowledged as limitations anywhere: single stimulus per valence; 1-h washout and carryover;
  order effect not reported; ambient temperature range; feeding confound; absolute-value Δ; no
  positive-vs-negative test; no pre-registration; unedited duplicate text.

### ¶7 Conclusion (ll. 611–620)
- Verbatim (l. 613–615): "The positive treatment was associated with numerically greater changes in
  RMSSD and SBR, and a smaller change in ET. In contrast, the negative treatment was associated with
  numerically smaller changes in RMSSD and SBR, and a larger change in ET."
  ⚑ "Numerically" is accurate: none of these between-treatment differences is tested. The Conclusion
  is more careful than ¶1 and ¶4, which present the same comparisons as findings [INF-UNTESTED,
  confirmed].
- "SBR may provide a simple and practical behavioral indicator of donkey responses to positive and
  negative treatment, without the requirement for sophisticated equipment" — see ¶6 note; the data
  support a group-level difference, not an individual-level indicator.
- Verbatim (l. 618–620): "our study challenges the notion that donkeys are stoic and experience less
  pain or stress than horses. We found that donkeys respond to positive and negative treatments in a
  similar way to other species such as horses, goats, dogs, and cattle."
  ⚑ No horse, pain, or other-species data in the study; "similar way" is a qualitative reading of the
  literature [INF-OVERREACH, confirmed].

### Discussion vs Results — the three sentences that matter most for the review
1. l. 545–546: "a reduction in HRV in response to negative treatment" — Results show an increase.
2. l. 429–431: changes made "the direction of change ... more obvious" — the printed changes have no
   direction.
3. l. 520–523: ΔET as "the measure of positive and negative emotions" — untested 0.41 °C difference,
   same direction under both valences, contradicted at l. 579–580.

## Declarations (ll. 1018–1050) and front matter (ll. 1–82)

### Version and publication status
- Unedited accepted manuscript, "Article in Press"; publisher's note (l. 20–22): "there may be errors
  present which affect the content". Received 16 Dec 2025, accepted 14 Jul 2026.
- "If this paper is publishing under a Transparent Peer Review model then Peer Review reports will
  publish with the final article." → check the version of record for (i) reviewer reports, (ii) whether
  the duplicated sentences and the Table 1 BCS row were fixed, (iii) whether any number in Tables 2–4
  changed. The review must be re-verified against the version of record before publication
  [procedural, not a finding].
- Licence CC BY-NC-ND 4.0: quoting and reproducing figures for criticism is fine; "no adapted
  material" means digitised data are presented as our own derived dataset with provenance, not as a
  modified figure.
- Two corresponding authors (Bukhari, Parkes). All four e-mails on the title page (contacts.md).

### Ethical approval
- CityU Animal Research Ethics Sub-Committee No. P9610463; "in accordance with relevant institutional
  and national guidelines". Owner consent was verbal (Methods, l. 650). No welfare monitoring or
  stopping rule for the clipper stimulus described.

### ARRIVE statement, verbatim: "This study is reported in accordance with the ARRIVE guidelines"
- ⚑ Checked against ARRIVE 2.0 "Essential 10" (items 1–10), from the reading of Methods and Results:
  | ARRIVE 2.0 item | status in the paper |
  |---|---|
  | 1 Study design (groups, experimental unit) | partly: crossover stated; unit (donkey) implicit |
  | 2 Sample size (how determined) | stated, but derivation unclear and self-contradictory (Methods 5.2) |
  | 3 Inclusion/exclusion criteria, exclusions, missing data | inclusion criteria given (age, health); **no statement on exclusions or missing data** |
  | 4 Randomisation (method, allocation concealment) | "random numbers" only; no method, no concealment, no sequence reporting |
  | 5 Blinding | **absent** (coders, thermography reading, analyst) |
  | 6 Outcome measures | stated |
  | 7 Statistical methods, software, assumption checks | partly: models named, df/variances not reported; normality on raw data |
  | 8 Experimental animals | stated (breed unspecified, age, sex, BCS promised but not reported) |
  | 9 Experimental procedures | partly: timing, washout; camera distance/head position during feeding absent |
  | 10 Results: descriptives with variability; effect size with CI | descriptives yes; **no CI for any condition contrast** |
  Items 3, 4, 5 and 10b are not met; the compliance statement is not supported by the text
  [REP-GUIDELINE, confirmed]. No ARRIVE checklist is supplied as supplementary material.

### Data availability, verbatim: "The datasets used and/or analyzed during the current study available
### from the corresponding author on reasonable request."
- No repository, no supplement, no raw RR intervals or thermograms. Requested 2026-10-25
  (`correspondence/`); follow-up due 2026-11-15 [REP-DATA, confirmed].
- Scientific Reports policy encourages but does not require deposition; the statement is compliant
  with the journal, not with the "fully reproducible" standard.

### Code
- No code availability statement at all. Software named (R 4.2.3, tidyverse, lme4, lmerTest). No
  scripts, no model specifications beyond prose [REP-CODE, confirmed].

### Author contributions
- "Formal data analysis": SSUHB only. Conceptualization/Investigation/Methodology: SSUHB, AGM, RSVP.
  PVS: supervision and review. Noted for the correspondence only (who to address technical questions
  to); not a finding.

### Competing interests and funding
- None declared; CityU funding, "no role" statement. One author affiliated with the Hong Kong Jockey
  Club (affiliation 4). Nothing further.

### Acknowledgements
- Owners, local veterinarians, "brick kiln owners" → confirms the working-donkey population and the
  field setting (brick kilns) in which ambient conditions varied (Table 1).

### Figure legends (ll. 1037–1050)
- Fig. 5 is a graphical summary (equipment: FLIR T530, GoPro, Polar monitor). No data.
- Legends repeat those in the body; nothing new.

### Absent from the entire paper (now confirmed across all sections)
Pre-registration; blinding; exclusions/missing data; randomisation method and sequences; order
effect estimates; HR, artefact %, respiration; ambient covariates in any model; positive-vs-negative
contrasts; CIs for condition contrasts; model df and random-effect variances; code; data; behavioural
manipulation check; BCS values despite being promised in Table 1.

