# Methods inventory — protocol v0.2 (v0.1 items unchanged; G7, H2, H3 added 2026-11-21) — Shi et al. 2026 (P002)

## A. Selection and provenance
- A1 Track / source: `systematic`; batch B01 (Scientific Reports, October 2026, OpenAlex subfield
  Psychiatry and Mental health, seed 20261120), rank 1 of 30, eligible on the title.
- A2 Version, DOI, dates: "Article in Press" (typeset accepted manuscript, 9 pages, PDF dated
  2026-10-29); doi 10.1038/s41598-026-78298-4; received 2026-07-21, accepted 2026-10-26, online
  2026-10-29. Version of record not yet published.
- A3 Peer-review status: peer reviewed (Sci Rep); reviewer reports not public at the time of reading.
- A4 Data and code availability: data "available from the corresponding author on reasonable
  request"; no code statement; SAS 9.4. Supplementary Table S1 online (not yet filed).

## B. Design
- B1 Question / pre-registration: whether MMSE < 24 at the 2012/2013 visit predicts stroke and death;
  no registration, no pre-specified analysis plan; secondary analysis of the APAC cohort.
- B2 Design type: prospective community cohort, exposure measured once, time-to-event outcomes.
- B3 Unit of analysis vs sampling unit: individual participants, one record each; no clustering
  (two centres' ethics approvals, clustering not modelled; minor).
- B4 Control condition: n/a (observational); comparison group MMSE ≥ 24.
- B5 Confounding: exposure (MMSE < 24) is strongly tied to age (median 62.8 vs 51.3) and education
  (48.4 % vs 8.2 % primary or less); adjustment linear in age (functional form not stated) and by a
  three-level education variable. Diabetes, BMI, lipids, smoking, drinking, activity, ECAS measured
  and not in the models.
- B6 Order / carryover / washout: n/a.
- B7 Sample size justification: none. 15 exposed events per outcome; 81–90 events for nine
  parameters in Model 2.
- B8 Blinding: follow-up staff "blinded to the baseline data"; outcome adjudication not described
  beyond AHA/ASA criteria; no statement for the analysts.
- B9 Manipulation check: n/a; the exposure is a measured state, not a manipulation.

## C. Measurement
- C1 Operationalisation: "cognitive impairment" = MMSE < 24 at a single visit; the construct in the
  title is cognitive impairment, the measure is a screening score known to depend on schooling.
- C2 Reliability: none reported (single administration, raters not described).
- C3 Validity: cut-off taken from ref 15 (a cohort paper), not validated for a population with
  10 % illiterate/primary education; the authors acknowledge "educational bias".
- C4 Scale type: MMSE dichotomised; the continuous score is never used (no dose-response).
- C5 Derived scores: none beyond the dichotomy.
- C6 Missing data: 1,512 of 5,440 (27.8 %) without MMSE excluded; excluded participants older, more
  often male, hypertensive, diabetic, with ICAS; complete-case analysis; no imputation or weighting;
  the Discussion argues that adjustment "for these factors in our models" addresses selection, which
  it does not. Covariate missingness is not reported, but Supplementary Table S1 shows that the
  occupation variable exists for about 2,740 of the 3,875 included (2009 = 73.3 %) and 871 of the
  1,565 excluded, and ECAS for about 3,750 and 200; occupation is a Model 2 covariate, so the n of
  the headline model is at most about 2,740 and is never stated.
- C7 Measurement conditions / covariates: covariates measured 2010/2011, exposure 2012/2013; the
  paper calls both "baseline"; which visit supplies Table 1 is not stated (age 51.6 in Table 1 vs
  53.4 in the Discussion suggests the 2010/2011 values).

## D. Model adequacy
- D1 Model vs design: Cox with a single binary exposure; time origin not stated; if the origin is
  the 2010/2011 baseline (the only reading that allows 4 years of follow-up for 99 % of the sample),
  the exposure was measured about two years after time zero and everybody was event-free until then;
  if the origin is the MMSE visit, a 4.1-year median follow-up ending 2015-12-31 is impossible.
  Death competes with stroke (7.8 % of the exposed died); treated as censoring; KM "cumulative
  incidence" rather than a cumulative incidence function.
- D2 Distributional family: Cox (semi-parametric), adequate for time-to-event; descriptive tests
  (Kruskal–Wallis for two groups, chi-square) adequate as tests but the comparisons themselves are
  descriptive, not hypotheses.
- D3 Assumption checks: proportional hazards "met ... Schoenfeld residual plot method (P > 0.05)";
  no statistic, no variable named; with 15 exposed events the test has little power whatever it
  returned. Shapiro–Wilk used to choose summaries.
- D4 Interactions: none tested (age × exposure, education × exposure would be the natural ones).
- D5 Covariates: chosen "based on their established association with stroke risk and their
  imbalance between groups in baseline comparisons"; post hoc, p-value driven; occupation entered
  on a Table 1 p of 0.0005 that the counts do not reproduce; diabetes (established risk factor) left
  out; functional forms not stated.
- D6 Multiplicity: three outcomes × three models plus 21 Table 1 tests; no framing; "P < 0.05"
  throughout.
- D7 Model selection / reporting: three nested models reported, no others; no n per model.
- D8 Bayesian specifics: n/a.

## E. Internal consistency (details in `R/02_consistency_checks.R`, run outputs in `output/tables/`)
- E1 Test statistics vs descriptives: Table 1 chi-square p-values recomputed from the counts
  (Pearson, no continuity correction): 9 of 11 reproduce to four decimals or the "<" bound;
  manual worker (51.8 vs 53.1 %, P = 0.0005) gives p = 0.716 (chi-square 0.13, 12.1 needed); ECAS
  0.5368 printed vs 0.5380 recomputed (one unit in the third decimal). Unadjusted HR CIs match
  1/15 + 1/d widths to within 0.01; Wald chi-squares 24–28, so the figure's "< 0.0001" is right
  and the text's "< 0.01" merely loose.
- E2 GRIM / GRIMMER: n/a (no means of integer scales; medians only).
- E3 Derived quantities: 37 of 39 Table 1 percentages and all 9 Table 2 percentages reproduce;
  the two that do not (manual worker overall 51.9, ECAS overall 1.6) are one unit off, as from a
  denominator a few short of 3,875; S1 gives the same counts as 73.3 % and 1.6 % of smaller
  denominators; LDL overall Q1 (1.5) lies below both group Q1 (1.9, 1.9) and S1 prints 1.9; the
  other 23 overall quantiles lie between the group values; cumulative incidences 2.1 / 2.3 / 2.2 %
  reproduce; Model 1 keeps 60 % of the unadjusted log HR for the strokes and 42 % for death.
- E4 Text vs figures vs tables: S1 "included" vs Table 1 "overall": manual worker 73.3 vs 51.9 %,
  middle school 2394 vs 1662 (S1 education counts sum to 4,607), LDL Q1 1.9 vs 1.5; Fig. 2 CI curves (four steps of 0.25 to 1.0) vs 15 / 192 events and
  181–186 at risk at year 4; NCI curves end at 0.45–0.70 on a 0–1 "%" axis vs 1.8–2.0 %; log-rank
  "< 0.01" (text) vs "< 0.0001" (figure); manual worker direction reversed in the text; median age
  51.6 vs 53.4; "28.8 % excluded due to missing MMSE" is 1565 / 5440, not 1512 / 5440 (27.8 %);
  "mean age 54.6 vs 51.6" compares with the Table 1 median.
- E5 df and n: 3875 throughout; n per model not given; numbers at risk consistent with Table 2 for
  the stroke panels (3614 − 3605 = 9 = 75 − 66) but imply that ≥ 41 of 71 NCI deaths and ≥ 9 of 15
  CI deaths fall after year 4, within the last ~0.2 years of the axis; median follow-up 4.1 years
  incompatible with a 2012/2013 origin and a 2015-12-31 end.
- E6 Duplicated / contradictory text: abbreviations BMI and CI listed twice; "51.8.%"; consent
  "all participants" vs "participants or their legal proxies"; reference titles not matching the
  statements they support (refs 16, 17, 18, 21, 28).

## F. Reporting
- F1 Guideline: none claimed; STROBE items missing: time origin and follow-up definition, n per
  analysis, handling of missing covariates, competing risks, functional forms, absolute risks with CIs.
- F2 Effect sizes with uncertainty: HRs with 95 % CIs, yes; no absolute risk difference, no
  discrimination measure for the screening claim.
- F3 Exact p and n: Table 1 p exact to four decimals; Cox p-values not given (CIs only); n per
  model absent; PH test p given as "> 0.05".
- F4 Software / code: SAS 9.4; no code.

## G. Inference
- G1 Conclusions follow: the adjusted association (Model 2 HR 2.5, CI 1.3–4.9) is what the data
  show, with residual confounding by age and education open; "independently predicts" and
  "cognitive screening could be valuable" go beyond it: 15 of 81 ischaemic strokes occurred in the
  CI group (sensitivity 19 %, PPV 7.8 %).
- G2 Discussion vs results: the Discussion's median age 53.4 contradicts Table 1 (51.6); otherwise
  the Discussion restates Table 2 correctly.
- G3 Generalisation: limited to Chinese community adults aged ≥ 40 and acknowledged.
- G4 Causal language: "predicts", "predictor", "forecasted" (predictive, acceptable); "integrative
  marker of diffuse vascular injury" and "may ... contribute to the progression" are causal or
  mechanistic readings of an association.
- G5 Mechanism: the whole mechanistic paragraph is literature-based speculation, presented as
  "Several mechanisms may explain"; adequately hedged except the "integrative marker" sentence.
- G6 Comparisons without comparator: "significantly larger than the pooled HR of 1.19" with no test
  and a different exposure definition in the meta-analysis.

- G7 Interpretation of the estimates: "individuals with cognitive impairment had a 2.32 to 2.55 times higher risk" reads a
  hazard ratio as a risk ratio; the quantity is a cause-specific hazard ratio conditional on seven
  covariates in the complete-case subset (at most about 2,740), origin of the time scale unstated,
  death as censoring; "independently predicts" and the screening sentence read a conditional
  association as individual-level prediction (sensitivity 18.5 %, PPV 7.8 % from Table 2). Absolute
  risks 7.8 % vs 1.8 % are never stated as such.

## H. Verdict (provisional) and summary
- H1 Verdict: major concerns (provisional, stage 1).
- H2 Quality table: generated from the registry in `review.qmd`; no override.
- H3 Estimates table: the three adjusted HRs (left half fixed at stage 1); re-analysis estimands to be defined in `notes/04_analysis_plan.md` (cumulative incidence with death as competing event, age-scale HR, continuous MMSE, added value over age).

Verdict text:
`major concerns`. The association in Table 2 is arithmetically coherent (CIs match the event
counts) and plausibly real in direction, but the figure that supports it cannot have been drawn from
the reported data, the follow-up timeline is internally impossible as stated, one Table 1 p-value
that drove covariate selection does not reproduce, confounding by age and education is only
partly addressed, death is not treated as a competing event, and the screening recommendation is
not supported by the reported counts.
