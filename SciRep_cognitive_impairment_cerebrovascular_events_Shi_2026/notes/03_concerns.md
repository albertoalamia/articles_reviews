# Concerns — Shi et al. 2026 (P002)

One entry per concern; mirrored in `registry/issues.csv`. Numbers quoted here come from the
transcription in `data/raw/`; recomputed values are confirmed by `R/02_consistency_checks.R`
(outputs in `output/tables/`, run 2026-11-20 in the nix shell). All evidence tags below were
re-checked against `consistency_summary.csv` after the run; none changed. Two further small findings
from the run: the Table 1 overall percentages for manual worker (51.9; 2009 / 3875 = 51.8) and ECAS
(1.6; 60 / 3875 = 1.5), and the ECAS p (0.5368 printed, 0.5380 from the counts), are each one unit
off in the last digit, as they would be if those rows were computed on slightly fewer than 3,875
participants; covariate missingness is not reported anywhere (added to the missing-data entry).

### Kaplan–Meier curves incompatible with Table 2 and with their own numbers at risk
- Code: CON-XREF — Severity: major — Evidence: confirmed
- Location: Fig. 2 (all three panels) vs Table 2
- What: in each panel the CI curve rises in four equal steps of 0.25 to 1.0, the shape of a
  Kaplan–Meier estimate for four subjects who all fail; Table 2 reports 15 events among 192 (7.8 %)
  for each outcome, and the numbers printed under the axis show 181–186 of the 192 still at risk at
  year 4. The NCI curves end near 0.58, 0.70 and 0.45 on an axis labelled "Cumulative incidence (%)"
  with a top tick of 1, against 1.8, 2.0 and 1.9 % in Table 2: too small for percent, too large for a
  proportion. The log-rank p is "< 0.0001" in the figure and "< 0.01" in the text.
- Why it matters: the figure is the only display of the time course and of the group contrast; it
  cannot have been produced from the data that gave Table 2. The HRs themselves are unaffected by
  the figure, but what dataset the curves and the log-rank tests were computed on is unknown.
- How to check further: ask for the dataset and code behind Fig. 2; with the individual data, redraw
  the curves (and cumulative incidence functions with death as a competing event).

### Follow-up timeline cannot hold as stated
- Code: CON-XREF — Severity: major — Evidence: confirmed
- Location: Methods ll. 108–109, 141–142; Results l. 226; Fig. 2 numbers at risk
- What: the MMSE was measured "from 2012 to 2013", follow-up ran "until December 31, 2015", and the
  median follow-up is 4.1 years. From a 2012/2013 origin the longest possible follow-up is 4.0 years
  and the shortest 2.0; a median of 4.1 is impossible and so is 99.2 % of the NCI group (3653 / 3683)
  and 96.9 % of the CI group (186 / 192) still at risk at 4 years. From the 2010/2011 APAC baseline
  4 years for everyone is possible, but then the exposure was measured about two years after time
  zero, participants were event-free until then by construction, and the deaths that panel C shows
  in the first year of follow-up belong to people who could not have taken the MMSE in 2012/2013.
- Why it matters: the time origin determines whether the hazard ratios compare exposure groups over
  a period that begins before the exposure was known (immortal time) and what "4.1 years" means.
- How to check further: ask the authors for the time origin, the distribution of follow-up and the
  visit dates; recompute with the individual data.

### Deaths implied to cluster at the end of the axis
- Code: CON-XREF — Severity: major — Evidence: needs-data
- Location: Fig. 2 panel C numbers at risk vs Table 2
- What: at year 4 the NCI risk set has lost only 30 of 3683 (deaths plus censorings) and the CI
  risk set 6 of 192, yet Table 2 counts 71 and 15 deaths. At least 41 NCI deaths (58 %) and 9 CI
  deaths (60 %) must fall after year 4, in the last ~0.2 years of the axis: a death rate some
  fifty times the rate before year 4. The red curve in panel C shows nothing after 3.4 years.
- Why it matters: either death dates were set to the end of follow-up for deaths found through
  registries (which would also distort the stroke analyses, where death is a censoring event), or
  the numbers at risk and the totals come from different datasets.
- How to check further: distribution of event dates by source of ascertainment (interview, death
  certificate, hospital record).

### The manual-worker row of Table 1: percentages and p-value from different denominators
- Code: CON-STAT — Severity: major — Evidence: confirmed
- Location: Table 1 "Manual worker"; Supplementary Table S1; Results ll. 219–220; Methods ll. 170–172
- What: Table 1 prints 1907 (51.8 %) vs 102 (53.1 %), P = 0.0005; those percentages are fractions
  of 3683 and 192 and give a chi-square of 0.13 (p = 0.72; 12.1 is needed for the printed p).
  Supplementary Table S1 prints the same 2009 included manual workers as 73.3 %, a fraction of
  about 2,740, and the 653 excluded as 75.0 % of 871: the occupation variable is missing for about
  1,130 of the 3,875 included (29 %) and 694 of the 1,565 excluded, which the paper never says.
  The S1 p-value for that row, 0.3352, is reproduced exactly from 653 / 871 vs 2009 / 2741 (the
  group sizes give 1e-11), so the Table 1 p of 0.0005 was in all likelihood computed on the
  participants with data too, where the impaired
  group must be almost entirely manual workers; the percentages printed beside it hide this. The
  text reads the row as CI participants "more likely to be manual workers (51.8.% vs. 53.1%)",
  with the group values in the wrong order. Covariates were "selected based on ... their imbalance
  between groups", occupation is in Model 2 and diabetes (14.1 vs 10.8 %) is not.
- Why it matters: the headline model adjusts for a variable absent in 29 % of the sample; SAS
  drops those records, so Model 2 is fitted on at most about 2,740 participants and fewer events
  than Table 2 shows, and nothing in the paper says so. The inconsistent row is the visible trace
  of this.
- How to check further: n and events per model, and the occupation variable as coded, from the
  authors; `output/tables/consistency_H_s1_pvalues_denominators.csv` for the denominators.

### Model 2 is fitted on an undisclosed subset
- Code: MEA-MISSING — Severity: major — Evidence: confirmed
- Location: Table 2 Model 2; Supplementary Table S1 manual-worker row; Methods ll. 169–171
- What: occupation, a Model 2 covariate, is available for about 2,740 of the 3,875 (the
  denominator behind "2009 (73.3 %)" in S1). A complete-case Cox model in SAS uses only records
  with every covariate present, so Model 2 has at most about 2,740 participants and an unknown
  number of the 81 / 90 / 86 events, while Table 2 presents Models 1 and 2 side by side as if on
  the same data. ECAS (about 3,750 with data) is not in the models; homocysteine and ICAS
  completeness is unknown.
- Why it matters: the Model 1 to Model 2 comparison (2.47 → 2.55) is read as "adjustment for
  vascular markers does not weaken the association"; part or all of the difference may be the
  change of sample. The precision of Model 2 (CI 1.33–4.87) refers to a sample the reader cannot
  size.
- How to check further: n and events per model from the authors; with the data, Model 2 on the
  Model 1 sample with occupation imputed, and Model 1 restricted to the Model 2 sample.

### Overall LDL quartile outside both group quartiles
- Code: CON-XREF — Severity: minor — Evidence: confirmed
- Location: Table 1, LDL row
- What: overall median (IQR) 2.5 (1.5, 3.1) while NCI is 2.5 (1.9, 3.1) and CI 2.4 (1.9, 3.1). A
  quantile of the union of two groups lies between the two group quantiles; 1.5 does not.
  Supplementary Table S1 prints the same column as 2.5 (1.9, 3.1), so 1.5 is a transcription error
  in Table 1.
- Why it matters: small in itself; it shows the table was not checked, and it adds to the question
  of which dataset each number comes from.
- How to check further: none; settled by S1.

### "Baseline" refers to two visits two years apart
- Code: MEA-COVAR — Severity: major — Evidence: inferred
- Location: Methods ll. 105–109, 117–118; Table 1; Discussion l. 346
- What: covariates and vascular imaging date from 2010/2011, the exposure from 2012/2013. Table 1
  gives a median age of 51.6 and the Discussion 53.4, a difference of about the two years between
  the visits, which suggests the covariates in the models are the 2010/2011 values. Hypertension,
  homocysteine and ICAS status two years before the exposure are used to adjust a comparison defined
  at the later visit.
- Why it matters: covariates measured before the exposure cannot capture the confounding present
  at the time of exposure; combined with the time-origin question above it leaves the design of the
  follow-up unclear.
- How to check further: ask which visit supplies each covariate and the age in Table 1.

### Confounding by age and education only partly addressed
- Code: MEA-COVAR — Severity: major — Evidence: inferred
- Location: Table 1; Table 2; Methods ll. 169–172
- What: the CI group is 11.5 years older at the median, with an IQR reaching 74.9 against 59.1, and
  48.4 % vs 8.2 % have primary schooling or less. Adjusting for age, gender and education removes
  about 40 % of the unadjusted log HR (4.55 → 2.47 for ischaemic stroke, 4.16 → 1.83 for death);
  the functional form of age is not stated (a linear term in a group spanning 53–75 years at the
  quartiles under-adjusts), no age × exposure or education × exposure interaction is examined, no
  dose-response on the continuous MMSE is shown, and diabetes, BMI, lipids, smoking, drinking,
  activity and ECAS, all measured, are left out of every model.
- Why it matters: the remaining HR of about 2.5 is the whole result; the paper itself notes that
  the meta-analytic estimate is 1.19 and offers Chinese vascular biology as the explanation, while
  residual confounding by age and schooling is the alternative the design cannot exclude.
- How to check further: with the data, age as the time scale or splines, education-adjusted MMSE
  cut-offs, the continuous score, a model with all measured covariates (stage 3).

### Death not treated as a competing event
- Code: MOD-STRUCT — Severity: major — Evidence: inferred
- Location: Methods ll. 164–173; Fig. 2; Discussion ll. 345–347
- What: 7.8 % of the CI group died within the follow-up against 1.9 % of the NCI group. The stroke
  analyses censor at death and the "cumulative incidence" curves are 1 − KM, which overstate the
  risk of stroke in the group that dies more; no cumulative incidence function or subdistribution
  model is reported. The authors mention that "competing risks are non-negligible" for the
  mortality result only.
- Why it matters: with a four-fold difference in mortality the bias is in the direction of the
  reported effect, although small at these event rates; the point is that it was not assessed.
- How to check further: Aalen–Johansen estimates and Fine–Gray or cause-specific models with the
  data (stage 3).

### Fifteen exposed events: proportional hazards and a nine-parameter model
- Code: REP-GUIDE — Severity: major — Evidence: confirmed
- Location: Table 2; Methods ll. 167–171
- What: each outcome has 15 events in the exposed group. The proportional-hazards assumption is
  reported as "met ... (P > 0.05)" without a statistic or the variable tested; a Schoenfeld test on
  15 events cannot detect anything but gross departures. Model 2 has nine parameters (exposure,
  age, gender, two education dummies, homocysteine, ICAS, hypertension, occupation) for 81–90
  events, nine or ten events per parameter, below the usual ten and with the exposure's
  information carried by 15 events. No n per model is given.
- Why it matters: the precision shown (CI 1.33–4.87) is as good as it gets with 15 events; the
  adjusted estimates are fragile to the specification, and nothing in the paper shows how fragile.
- How to check further: sensitivity to covariate sets and functional forms with the data; Firth or
  penalised Cox; Bayesian model with weakly informative priors (stage 4).

### Hypothesis tests on descriptives, then used to choose covariates
- Code: MOD-MULT — Severity: minor — Evidence: confirmed
- Location: Table 1; Methods ll. 160–163, 171–172
- What: 21 two-group tests on baseline descriptives, each at P < 0.05, none a study hypothesis;
  the significant ones then drive the covariate set of Model 2 (together with "established
  association"). Three outcomes × three Cox models follow with the same threshold and no framing.
- Why it matters: a descriptive table does not test hypotheses; selecting adjustment variables by
  baseline p-values conditions on the sample and, in this paper, on a p-value that is itself not
  reproducible.
- How to check further: none needed; a pre-specified covariate set is the remedy (stage 3 plan).

### Complete-case analysis after excluding 28 % of the cohort
- Code: MEA-MISSING — Severity: major — Evidence: confirmed
- Location: Results ll. 180–186; Fig. 1; Discussion ll. 339–341
- What: 1,512 of 5,440 (27.8 %) had no MMSE and were dropped; they were older, more often male,
  hypertensive, diabetic and with ICAS. No imputation, no weighting; the Discussion holds that
  adjustment "for these factors in our models" addresses the selection, which adjusts the
  included sample and says nothing about the excluded one. The percentage given, 28.8 %, is the
  total exclusion (1565 / 5440), not the MMSE one. Missingness of covariates is not reported;
  the overall percentages for manual worker (51.9 vs 51.8 from 2009 / 3875) and ECAS (1.6 vs 1.5
  from 60 / 3875) and the ECAS p (0.5368 vs 0.5380) are consistent with denominators a few
  participants short of 3,875 in those rows, so the models' n is probably below 3,875 as well.
- Why it matters: the excluded third is the part of the cohort with more vascular disease, the
  stratum where cognitive impairment is most prevalent; the estimated HR applies to a selected
  sample.
- How to check further: reasons for missing MMSE (not attended, refused, incomplete); inverse
  probability weighting with the data.

### MMSE < 24 as "cognitive impairment" in a population with 10 % primary schooling or less
- Code: MEA-CONSTR — Severity: major — Evidence: inferred
- Location: Methods ll. 117–120; Table 1 education rows; Discussion ll. 336–339
- What: a single administration of a screening instrument with a fixed cut-off defines the
  exposure. 93 of the 192 "impaired" (48.4 %) have primary schooling or less; in the whole cohort
  the figure is 10.2 %. The paper does not use education-specific cut-offs, a second instrument,
  or the continuous score. The authors call this "potential educational bias".
- Why it matters: part of the exposure is literacy rather than cognition; the title's claim is
  about cognitive impairment.
- How to check further: education-stratified analysis and continuous MMSE with the data.

### The screening recommendation is not supported by the reported counts
- Code: INF-FOLLOW — Severity: major — Evidence: confirmed
- Location: Abstract ll. 23–26; Discussion ll. 300–302, 349–351
- What: "cognitive screening could be valuable for identifying stroke-free adults who are at a
  greater risk". From Table 2, 15 of the 81 ischaemic strokes occurred in the CI group: as a
  screening rule MMSE < 24 has sensitivity 18.5 %, specificity 95.3 %, positive predictive value
  7.8 % and a positive likelihood ratio of about 4; no discrimination, calibration or added value
  over age is reported. A hazard ratio is not a measure of screening performance. The Discussion's
  "2.32 to 2.55 times higher risk" also reads the hazard ratio as a risk ratio (protocol G7); the
  absolute risks, 7.8 % against 1.8 %, are never stated as such.
- Why it matters: it is the practical conclusion of the paper and the one a clinical reader takes
  away.
- How to check further: none needed for the statement; with the data, C-index with and without
  MMSE, net reclassification against age alone.

### Comparison with the meta-analytic HR without a test
- Code: INF-COMPAR — Severity: minor — Evidence: confirmed
- Location: Discussion ll. 303–310
- What: the effect sizes "were significantly larger than the pooled HR of 1.19" with no comparison
  performed, and the difference is attributed to Chinese vascular biology; the meta-analysis pools
  different exposure definitions and populations, and the paper's own attenuation from 4.55 to 2.47
  on adjusting three variables points to confounding as the untested alternative.
- Why it matters: it turns a possible artefact of adjustment into a biological claim.
- How to check further: none; wording.

### No registration, no reporting guideline, no code
- Code: REP-CODE — Severity: minor — Evidence: confirmed
- Location: Declarations ll. 365–369; whole paper
- What: secondary analysis of a cohort with no registered plan; STROBE not mentioned; items absent:
  time origin, follow-up definition, n per analysis, covariate missingness, functional forms,
  absolute risks; data on request only; no code; funding "Not applicable".
- Why it matters: every open point above would be closed by the dataset and the SAS code.
- How to check further: data request (sent, see `correspondence/`).

### Supplementary Table S1 disagrees with Table 1 in two cells
- Code: CON-XREF — Severity: minor — Evidence: confirmed
- Location: Supplementary Table S1, "included 3875" column vs Table 1 "Overall 3875"
- What: middle school 2394 (42.9 %) in S1 vs 1662 (42.9 %) in Table 1; 2394 / 3875 = 61.8 %, and the
  three S1 included education counts sum to 4,607. Manual worker 73.3 % vs 51.9 % for the same
  2009 (see above). The text's "mean age: 54.6 vs. 51.6" is S1's median. All other shared cells
  agree.
- Why it matters: small; the columns were produced by different runs and not reconciled.
- How to check further: none.

### Text, table and reference discrepancies
- Code: CON-XREF — Severity: minor — Evidence: confirmed
- Location: Results ll. 184, 219–220; Discussion l. 346; Fig. 2 caption; references 16, 17, 18, 21, 28
- What: median age 51.6 (Table 1)
  vs 53.4 (Discussion); log-rank "< 0.01" vs "< 0.0001"; "Captions:" left in both figure legends;
  "51.8.%"; abbreviations BMI and CI listed twice; consent from "all participants" and from
  "participants or their legal proxies"; five references whose printed titles do not match the
  statement they support (SRU carotid criteria → a commentary on intracranial Doppler; AHA/ASA
  diagnostic criteria → a two-page guideline update; ICAS prevalence in Chinese → the SVS
  extracranial guideline; cognition and stroke → a paper on hospital admissions; "previous dementia
  research" on mortality → a cross-sectional prevalence study).
- Why it matters: individually trivial; together they show that the manuscript was not read
  against its own numbers before submission or in review.
- How to check further: none.
