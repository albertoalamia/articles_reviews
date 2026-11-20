# Reading notes — Shi et al. 2026, Sci Rep (P002)

Version read: "Article in Press" PDF (typeset accepted manuscript, 9 pages, dated 2026-10-29);
line numbers refer to `paper/Shi_2026_fulltext.txt`. Quotes are verbatim.

## Abstract (ll. 14–26)

- "community-based longitudinal study on 3,875 Chinese adults aged 40 and older who were free of
  stroke", MMSE "< 24 indicate impairment", "followed for 4.1 years".
- Cox models "adjusting for demographic factors, vascular risks, homocysteine, and intracranial
  arterial stenosis": ischaemic stroke aHR 2.55 (1.33–4.87), any stroke 2.32 (1.24–4.36), all-cause
  mortality 1.79 (0.96–3.36).
- Conclusion: "baseline cognitive impairment in stroke-free adults aged 40 and older is a significant
  predictor of future cerebrovascular events, emphasizing its importance in early risk assessment and
  prevention strategies".

## Introduction (ll. 64–90)

- Motivation: post-stroke cognitive impairment is well studied; "the predictive role of baseline
  cognitive deficits in cerebrovascular events remains underexplored" (l. 77–78).
- Prior evidence: "inconsistent associations between baseline cognitive impairment and stroke risk,
  with a hazard ratio (HR) of 1.19 reported in meta-analyses" (ll. 82–84, ref 10); previous studies
  "often failed to adequately adjust for vascular markers or socioeconomic confounders".
- Aim (ll. 87–90): "to evaluate whether baseline cognitive impairment can independently predict
  incident cerebrovascular events in a Chinese community-based cohort without a history of stroke",
  using the APAC study. No hypothesis beyond this; no registration mentioned.

## Methods

### Subjects and setting (ll. 95–113)
- APAC: 5,440 participants aged ≥ 40, free of CVD, TIA and stroke at baseline. "During 2010 and
  2011" risk factors, transcranial Doppler, ankle-brachial index and carotid duplex were collected.
- "In the first follow-up examination conducted in 2012/2013, additional assessments, including
  cognitive function evaluation, were performed." (ll. 108–109)
- "The present study further excluded individuals with documented stroke or CVD prior to the first
  follow-up." (ll. 110–111)
- Ethics: Beijing Tiantan Hospital 2010-014-01, Kailuan General Hospital 2006-05.

### Design and procedure
- Secondary analysis of a cohort. Exposure: MMSE measured once, at the 2012/2013 visit. Covariates
  (hypertension, diabetes, lipids, homocysteine, ICAS, ECAS, questionnaires) described under
  "baseline characteristics", collected 2010/2011 (ll. 106–108). Which visit supplies the Table 1
  values is not stated.
- Follow-up: "in-person interviews held every two years during regular medical check-ups until
  December 31, 2015, the occurrence of a predefined final event, or death" (ll. 141–142); staff
  "blinded to the baseline data"; missed visits covered by death certificates, discharge summaries
  from 11 hospitals and medical records.

### Measures (ll. 115–137, 139–151)
- MMSE 0–30, "A score of < 24 was defined as cognitive impairment in the present study" (ref 15, a
  blood-pressure cohort paper). No education-adjusted cut-off, no second instrument.
- Covariate definitions standard (hypertension ≥ 140/90 or medication or history; diabetes FBG ≥ 126
  mg/dl or medication or diagnosis; dyslipidaemia by history, medication or lipid thresholds; ICAS
  by TCD velocity thresholds; carotid stenosis ≥ 50 % by duplex).
- Outcomes: first stroke per AHA/ASA criteria confirmed by CT or MRI, classed ischaemic, ICH, SAH;
  "In cases of fatal incidents or when neuroimaging was unavailable, diagnosis was based on clinical
  evaluation and examination of medical records".

### Statistical analysis (verbatim, ll. 158–173)
- "All analyses were conducted using SAS version 9.4 ... A two-sided P < 0.05 was considered
  statistically significant. Normality of continuous variables was assessed using the Shapiro-Wilk
  test; variables with non-normal distribution were summarized as median (IQR) and compared using
  the Kruskal-Wallis tests. Categorical variables were presented as frequencies and percentages and
  were compared using the chi-square test."
- "Cox proportional hazards models were employed, using participants with normal cognition as the
  reference group. The proportional hazard assumption was met for survival analysis using the
  Schoenfeld residual plot method (P > 0.05)."
- "Three models were developed: Unadjusted Model; Model 1 was adjusted for age, gender, and
  education; and Model 2 included additional adjustments for homocysteine levels, ICAS,
  hypertension, and occupation. Covariates were selected based on their established association
  with stroke risk and their imbalance between groups in baseline comparisons."
- "The Kaplan-Meier method and log-rank test were utilized to estimate the cumulative incidence of
  ischemic stroke, any stroke, and mortality."
- Not stated: functional form of age and homocysteine; time origin and time scale; handling of
  death as a competing event; n with complete covariates; any sample-size reasoning.

## Results

### Flow (ll. 178–186; Fig. 1)
- 5,440 → excluded 53 (stroke/CVD before the first follow-up) + 1,512 (missing MMSE) = 1,565 →
  3,875 analysed. Excluded vs included: "older (mean age: 54.6 vs. 51.6 years, p < 0.0001)", male
  67.0 vs 57.0 %, hypertension 53.4 vs 45.8 %, diabetes 14.8 vs 10.9 %, ICAS 15.7 vs 12.2 % (no p);
  Supplementary Table S1 (not in the PDF).

### Table-by-table
- Table 1 (p. 5): columns Overall 3875, NCI 3683, CI 192, P. Transcribed in
  `data/raw/table1_baseline.csv`. Points noticed on reading:
  - Manual worker 51.8 % (NCI) vs 53.1 % (CI), P = 0.0005; the text (ll. 219–220) says CI
    participants "were more likely to be manual workers (51.8.% vs. 53.1%, P = 0.0005)".
  - LDL overall median (IQR) 2.5 (1.5, 3.1) while NCI 2.5 (1.9, 3.1) and CI 2.4 (1.9, 3.1).
  - Smoking 63.2 % overall with 57.0 % male; the row label does not say current or ever.
  - "Inactive or moderately active" merges two of the three stated activity categories.
  - Age: Table 1 median 51.6 (overall); Discussion (l. 346) "relatively young baseline age
    (median: 53.4 years)".
- Table 2 (p. 6): events n (%) and HRs for three outcomes × three models; transcribed in
  `data/raw/table2_cox.csv`. 15 events in the CI group for each of the three outcomes (15 ischaemic
  = 15 any stroke, so no haemorrhagic stroke among the 192). Reference rows printed "Ref.".
  Footnotes: Model 1 age, gender, education; Model 2 adds homocysteine, ICAS, hypertension,
  occupation.

### Figure-by-figure
- Fig. 1 (p. 4): flowchart, numbers as in the text.
- Fig. 2 (p. 6): three Kaplan–Meier panels (ischaemic stroke, any stroke, all-cause mortality),
  y-axis "Cumulative incidence (%)" with ticks 0 and 1, x-axis 0–4.2 years, "Logrank p < 0.0001"
  in each panel, numbers at risk at 0–4 years. In every panel the CI (red) curve has exactly four
  steps of equal height 0.25 and ends at 1.0; the NCI (blue) curve ends near 0.58 (A), 0.70 (B),
  0.45 (C). Numbers at risk at year 4: NCI 3614 / 3605 / 3653, CI 181 / 181 / 186. Panel C shows
  NCI deaths from about 0.05 years. Readings in `data/raw/fig2_curve_features.csv`.
  Caption text says "P values were calculated using the log-rank test"; the Results text says
  "log-rank test P < 0.01 for each" (l. 228).

### Text (ll. 216–231)
- Median MMSE 29 (27–30); 192 (5.0 %) impaired. "Over a median follow-up of 4.1 years, the
  cumulative incidences of ischemic stroke, any stroke, and all-cause mortality were 2.1%, 2.3%, and
  2.2%".

## Discussion (claims, in order; ll. 236–352)

1. "provides evidence that baseline cognitive impairment, as evaluated by the MMSE, independently
   predicts cerebrovascular events" (ll. 236–237); "2.32 to 2.55 times higher risk".
2. "The study suggests that cognitive screening could be valuable for identifying stroke-free adults
   who are at a greater risk of experiencing cerebrovascular events in the future." (ll. 300–302)
3. Effect sizes "were significantly larger than the pooled HR of 1.19 from previous meta-analyses"
   (ll. 304–306); explained by ICAS prevalence and by adjustment for homocysteine and ICAS; cognitive
   impairment as "an integrative marker of diffuse vascular injury or neurovascular unit
   dysfunction beyond focal stenosis".
4. Mechanisms (ll. 311–333): vascular risk factors, small vessel disease, immunometabolic pathway
   (neutrophil-to-HDL ratio, ref 27); all from the literature, none measured here.
5. Strengths: prospective design, community sample, adjustment for ICAS.
6. Limitations (ll. 336–348): MMSE alone, educational bias, residual confounding; "about 28.8% of
   participants were excluded due to missing MMSE data ... which may have introduced selection
   bias—though we have adjusted for these factors in our models"; unmeasured socioeconomic factors;
   short follow-up; no mortality association, "relatively young baseline age (median: 53.4 years),
   where competing risks are non-negligible"; generalisability.
7. Conclusion (ll. 349–352): "cognitive impairment is associated with an increased risk of future
   cerebrovascular events in stroke-free Chinese adults. This may aid early risk identification".

## Supplementary Table S1 (docx, one table: excluded 1565 vs included 3875)

- Transcribed in `data/raw/suppl_table_s1.csv`. The "included 3875" column is Table 1's "Overall"
  column and agrees with it except: manual worker 2009 (73.3 %) vs 2009 (51.9 %); middle school
  2394 (42.9 %) vs 1662 (42.9 %) (the three included education counts sum to 4,607); LDL IQR
  (1.9, 3.1) vs (1.5, 3.1).
- Age is "median (IQR)" 54.6 (46.7, 68.4) vs 51.6 (45.3, 59.7); the Results text calls 54.6 a mean.
- Percentages that are not fractions of 1565 or 3875: manual worker 653 (75.0 %) and 2009
  (73.3 %), i.e. denominators 871 and about 2,740; ECAS 1 (0.5 %) and 60 (1.6 %), i.e. about 200
  and 3,640–3,870. The printed p-values for these two rows (0.3352, 0.2184) follow from the
  reduced denominators, not from the group sizes; the other p-values follow from the group sizes.
- Excluded participants: older, more often male, hypertensive, diabetic, with ICAS and higher
  homocysteine, lower HDL; education less often high school (36.2 vs 46.9 %).

## Declarations (ll. 354–381)

- Supplementary information online (Table S1). Funding "Not applicable". Data: "not publicly
  available due to privacy or ethical restrictions, but are available from the corresponding author
  on reasonable request". No code statement. No reporting guideline (STROBE) mentioned. Competing
  interests none. Consent: "all participants" (l. 112–113) and "All participants or their legal
  proxies" (l. 380).
- Corresponding author Xinsheng Han, hansong2022@126.com, Kaifeng Central Hospital (ll. 487–491).
  Analysis by Z.S. with X.T. and A.W. (ll. 360–362).

## References noticed (titles as printed)

- Ref 16, cited for the Society of Radiologists in Ultrasound carotid criteria, is "Monitoring
  intracranial atherosclerosis with transcranial and extracranial carotid Doppler: A promising
  initial step" (Atherosclerosis 363, 73–74).
- Ref 17, cited for the AHA/ASA stroke diagnostic criteria, is "Guidelines for the early management
  of patients with acute ischemic stroke: 2019 update ..." at Stroke 50, 3331–3332 (two pages).
- Ref 18, cited for the higher prevalence of intracranial atherosclerosis in Chinese populations, is
  the Society for Vascular Surgery guideline on extracranial cerebrovascular disease.
- Ref 21, cited for the link extending "to cerebrovascular events, including stroke", is Fogg et al.
  on mortality and hospital stay in older emergency admissions.
- Ref 28, cited as "previous dementia research" on mortality, is a cross-sectional prevalence study.
- Abbreviation list prints BMI and CI twice (ll. 37–38, 60–61).
