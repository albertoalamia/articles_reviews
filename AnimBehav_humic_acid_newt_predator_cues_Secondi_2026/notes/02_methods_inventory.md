# Methods inventory — protocol v0.4 — Secondi et al. 2026 (P003)

Filled by Claude Code on 2026-11-25 (stage 1). Concern titles refer to `notes/03_concerns.md`.

## A. Selection and provenance
- A1 Track / source: `systematic`, batch B02 (selection v0.3): Animal Behaviour drawn at random
  among ten ethology journals (seed 20261125), October 2026, frame of 11, rank 1, eligible on the
  title (no abstract indexed). No author known to Alberto.
- A2 Version, DOI, dates: version of record, Animal Behaviour 241 (2026) 123735,
  doi 10.1016/j.anbehav.2026.123735. Received 9 Feb 2026, initial acceptance 21 Apr 2026, final
  acceptance 3 Aug 2026, online 19 Oct 2026. Closed access (read through the University of
  Milano-Bicocca library; PDF not committed).
- A3 Peer-review status: peer reviewed (MS. number A26-00085R, one revision); reports not public.
- A4 Data and code availability: stated "The data set and R script are provided as Supplementary
  Material. The data set is also available at https://doi.org/10.5281/zenodo.18200379." Found: the
  Zenodo record is public, CC BY 4.0, one xlsx with 1,166 rows and a dictionary sheet (downloaded,
  md5 verified). The R script is only in the journal's supplement, behind the subscription;
  obtained 2026-11-27 with Tables S1–S3, Figures S1–S2 and a 24-column copy of the dataset (same
  values in the shared columns). The script reads a second data file, "NAs converted to 0", that
  is not supplied, and does not run from top to bottom ("The script does not run as supplied...").

## B. Design
- B1 Question / pre-registration: whether fish olfactory cues and water colour change the diel
  activity of male smooth newts. No registration. Predictions: an interaction of cue, colour and
  time of day; both directions for colour stated as possible; a change "stronger at dusk".
- B2 Design type: laboratory experiment, 3 (water colour) × 2 (cue) between subjects, with 22
  repeated half-hour recordings per animal over 22 h.
- B3 Unit of analysis vs sampling unit: the newt is the experimental unit (one run each, tested
  alone); 22 sequences per newt analysed with a random intercept for newt nested in site, plus
  arena. Cue water from one tank (see "One source of predator cue"); up to eight newts per day
  share a session and a cue batch, and day is not modelled.
- B4 Control condition: aged water without fish for the cue; "clear" water (25 mg Pt/litre, still
  with humic acid added) for colour. Appropriate for the cue; for colour there is no control for
  the chemistry of humic acid apart from its optical effect.
- B5 Confounding of manipulation: (i) time of day = time since handling = time since the cue was
  added, for every animal ("Time of day cannot be separated from time since exposure");
  (ii) colour = humic acid concentration, with light not measured and a known effect of dissolved
  organic carbon on olfaction ("Water colour is manipulated with humic acid...").
- B6 Order / carryover / washout: each newt tested once; no carryover between treatments. Within a
  run the order of the slots is fixed by the clock.
- B7 Sample size justification: none; 8 or 9 newts per cell.
- B8 Blinding: tracking automated (EthoVision); who decided that a sequence "could not be tracked
  with enough reliability", and whether blind to treatment, is not stated.
- B9 Manipulation check: colour set by spectroscopy against a platinum–cobalt standard and pH
  reported; light in the arenas not measured; presence or concentration of the cue not checked
  (decay discussed from the literature).
- B10 Time origin and exposure timing (observational): n/a (experiment).
- B11 Selection into the analysed sample (observational): n/a. For the record: 53 males caught in
  five ponds; all 53 are in the dataset; sequences, not animals, are discarded.
- B12 Follow-up and attrition (observational): n/a; no animal lost.
- B13 Temporal order (observational): n/a.

## C. Measurement
- C1 Operationalisation: "activity" = total distance travelled and time spent moving in a 30-min
  sequence, from the tracked body point; "distance to the feeder" as a third response. Activity
  reduction is read as antipredator behaviour; shelter use, said to be "uncommon", is not analysed.
- C2 Reliability: none reported for the tracking (no manual check, no agreement between cameras,
  no validation in dark water).
- C3 Validity: "moving" is not defined; the variable sits near its ceiling (median 1,579 of
  1,800 s) and takes large values with almost no displacement ("What 'time spent moving' measures").
- C4 Scale type: distance is non-negative with exact zeros (72 of 1,128) and a floor at 1.5;
  modelled as normal after log(x + 1). Time moving is a bounded duration; ordered beta after
  scaling to [0, 1], a suitable family, fitted without the zeros.
- C5 Derived scores: none beyond the transformation. Units: mm in the paper, cm in the dataset.
- C6 Missing data: text: 39 sequences discarded (3.3 %). Dataset: 38 without distance, 36 without
  distance to feeder, 110 without time moving; the 72 extra are the zero-distance sequences;
  untracked sequences 32 with cues against 6 without. Handling: dropped; no discussion.
- C7 Measurement conditions / covariates: light at table level given for day and night; water
  temperature not reported; body size not measured or not used; test day, arena, capture site,
  site water colour and capture date are in the dataset.

## D. Model adequacy
- D1 Model vs design: random intercepts for arena and for newt nested in site; no structure for
  the 22 repeated measures beyond the intercept; no test day ("Twenty-two repeated measures per
  newt, time as an unordered factor").
- D2 Distributional family: normal on log(x + 1) for distance; normal for distance to feeder;
  ordered beta for time moving. See C4.
- D3 Assumption checks: "Heteroscedasticity and dispersion diagnostics confirmed the good fit of
  the models" (DHARMa); nothing shown; residual autocorrelation not mentioned.
- D4 Interactions: the three-way interaction is the model; tested by likelihood ratio (42 df).
- D5 Covariates: none. Body size acknowledged as missing.
- D6 Multiplicity: three responses; 198 slot-wise pairwise comparisons per response reported
  through asterisks; adjustment "Tukey": from the script and Table S2, none for fish against
  no fish (one comparison per family) and over three colour pairs within a slot, never across
  slots ("About 200 slot-wise comparisons...").
- D7 Model selection / reporting: backward selection by likelihood ratio tests; Table 1 gives one
  row for two responses and seven for the third; no coefficients, 132 fixed-effect parameters
  ("The fitted model cannot be read...", major).
- D8 Bayesian specifics: n/a.

## E. Internal consistency
- E1 Test statistics vs descriptives: no descriptives are printed. The nine P values of Table 1
  and the one in the text follow from their statistic and df (block A).
- E2 GRIM / GRIMMER: n/a (no means of integer data reported).
- E3 Derived quantities: capture-to-test interval 4.89 ± 1.83 days in the text, 5.19 ± 1.80 in the
  dataset.
- E4 Text vs figures vs tables: LRT 75.113 (text) against 75.209 (Table 1). The asterisks of
  Figure 2 match the slots listed in the text and Table S2. Units mm (paper) against cm (dataset).
  Table S3, captioned time spent moving, repeats Table S2 (195 of 198 estimates within 0.02) and
  does not hold the slots the text reports for time moving ("Supplementary Table S3 repeats...").
- E5 df and n: "53 individuals × 20 sequences" against 1,166 = 53 × 22; 21 and 42 df agree with 22
  slots. Discards: 39 against 38 / 36 / 110.
- E6 Duplicated / contradictory text: placement "75 min before testing" against 15 + 30 min.

## F. Reporting
- F1 Guideline: none cited. ARRIVE items missing that matter here: sample size justification,
  randomisation method, blinding of the discard decision, exclusions by group, effect sizes with
  intervals.
- F2 Effect sizes with uncertainty: none in the article; slot-wise contrasts with SE in Table
  S2, intervals announced in the caption and absent ("No estimate of any effect in the article").
- F3 Exact p and n: exact P in Table 1; pairwise results only as "P < 0.05"; n per cell not given
  in the paper (8 or 9, from the dataset).
- F4 Software / code: R 4.4.1, glmmTMB, DHARMa, emmeans, ggeffects, MuMIn; EthoVision XT 17. Data
  public; script in the supplement (also loads corrplot, performance, gridExtra), with a missing
  input file.

## G. Inference
- G1 Conclusions follow: that activity is lower with fish cues, most clearly in dark water in the
  first hours: supported by the raw data. That the response "occurred earlier" in dark water: read
  off the asterisks and not separable from time since exposure ("A claim about timing...").
- G2 Discussion vs results: "perch cues were well detected in all water colour treatments"
  against three isolated significant slots in clear water.
- G3 Generalisation: males, one area, bare arena; title "newts"; limits stated by the authors.
- G4 Causal language: the experiment supports causal statements about the two manipulations as
  delivered (cue water, humic acid); not about "visibility" or "the visual environment" as such.
- G5 Mechanism: anticipation of an earlier predator activity peak; no data ("Newts may
  anticipate...").
- G6 Comparisons without comparator: none of note.
- G7 Interpretation of the estimates (scale, population, role, reference; what the number does
  say): there is no estimate to interpret. The quantities the paper reports are a likelihood ratio
  statistic for a 42-df interaction (it says the 132 cell means are not additive in some way, not
  in which way), R² values, and the positions of P < 0.05 among slot-wise comparisons on the
  log10(x + 1) scale. Stage 3 has to supply: the ratio of distance with and without cues by colour
  and block of hours, and the difference of those ratios between colours, with intervals.

## H. Verdict (provisional) and summary
- H1 Verdict: major concerns (provisional, stage 1; no critical issue). The effect of the cue in
  dark water looks real in the raw data; what is not established is the claim about timing and its
  explanation. To be revisited after stages 2–4, which run on the authors' own data.
- H2 Quality table: generated in `review.qmd`; overrides and reasons, if any: none.
- H3 Estimates table: headline quantities to include: cue effect on distance by colour in the
  first six hours and in the rest of the run (ratio, interval); difference between colours; the
  same for time moving with and without the zero sequences; the paper's side holds the LRT and the
  asterisks.
