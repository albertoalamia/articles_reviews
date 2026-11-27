# Concerns — Secondi et al. 2026 (P003)

One entry per concern; each is a row in `registry/issues.csv`. Drafted by Claude Code on
2026-11-25 at stage 1, from the paper, its own numbers and the public dataset the paper cites.
"Confirmed" means: follows from the paper's text, table or figures, or from its published dataset,
with no assumption. Numbers quoted from the dataset are those of `R/02_consistency_checks.R`
(run by Alberto on 2026-11-27; same numbers as Claude's scratch run). Nothing here has been
refitted: every statement about what a different model would show waits for stage 2.

Revised on 2026-11-27 after the journal's supplement was obtained (Tables S1–S3, Figures S1–S2,
the R script, a copy of the dataset with the full EthoVision columns). The script settles how
the pairwise tests were adjusted, the supplement holds slot-wise contrasts with standard errors,
and two new entries were added (Table S3; the script and its missing input file). Block I of the
consistency script is from Claude's scratch run until Alberto re-runs it.

What is sound, for the record: the data are public under CC BY and the code is in the supplement;
the models in the script are the models the Methods describe; Table S2 agrees with the Results
text and with Figure 2 for distance travelled, slot by slot; allocation is balanced within capture site and within test day; tracking is automated; all nine P
values of Table 1 follow from their statistic and df; the raw data do show a large difference in
the dark water treatment in the first hours of the run.

## Design

### Time of day cannot be separated from time since exposure
- Code: DES-CONF — Severity: major — Evidence: confirmed
- Location: Methods, "Experimental Design" (ll. 159–171); Abstract; Discussion paras 2–3
- What: every newt was put in its arena, received the cue water 15 min later, and was recorded
  from 15:30 for 22 h. The slot "1500" is the first half hour of recording for all 53 animals; the
  slot "2000" is the sixth. Time of day, time since handling and time since the cue was poured are
  one variable. No run started at another hour.
- Why it matters: the paper's main claim is about timing ("This response occurred earlier in the
  dark water group", "a progressive shift of the antipredator response towards an earlier start").
  The dark-water difference sits in slots 1–6, the first six hours after exposure, and is gone by
  about 21:00. A response that is strongest right after the cue is added and then wanes
  (habituation, cue decay, recovery from handling), at a rate that depends on water colour, gives
  the same figure. The design cannot tell "earlier in the day" from "sooner after exposure".
- How to check further: not checkable in these data. Stage 2 can describe the time course as a
  function of hours since exposure (onset, half-recovery time by cell); only runs started at
  different hours would separate the two.

### Water colour is manipulated with humic acid, which changes more than light
- Code: DES-CONF — Severity: major — Evidence: inferred
- Location: Methods (ll. 173–177, 215–220); Discussion para 5 ("DOC has been reported to impair
  olfaction")
- What: the three colours are three concentrations of a commercial humic acid product. Light in
  the water of the arenas was not measured; pH is reported (7.86–8.08). The Discussion itself notes
  that dissolved organic carbon impairs olfaction in aquatic vertebrates, and the cue is olfactory.
- Why it matters: the interpretation is visual ("tune their diel activity to the visual
  environment", "predation risk is perceived as higher when visibility is lower"). A chemical
  effect of humic substances on the cue, on its detection or on the animal would also produce a
  colour × cue interaction. The assumption here is that no evidence in the paper isolates the
  optical route; hence "inferred".
- How to check further: ask the authors for irradiance in the arenas by treatment; a design with
  neutral-density filters or dyes without humic substances would separate light from chemistry.

### One source of predator cue
- Code: DES-UNIT — Severity: minor — Evidence: needs-data
- Location: Methods (ll. 179–185)
- What: cue water came from one 70-litre tank holding "a European perch (minimum length: 22 cm,
  maximum length: 26 cm)" for 2–3 days. The number of perch used over the eight test days is not
  stated; each day's eight arenas share one cue batch.
- Why it matters: the cue treatment is replicated across newts but not across cue sources; day and
  batch are not in the model.
- How to check further: ask how many perch, and which batch on which day; add test day to the
  model at stage 3.

### No sample size justification; eight or nine newts per cell
- Code: DES-POWER — Severity: minor — Evidence: confirmed
- Location: Methods; dataset
- What: 53 newts in six cells (8 or 9 each); no power analysis or precision target. The fitted
  model has 132 cell-by-slot means.
- Why it matters: each slot-wise comparison of two cells rests on at most 9 against 9 animals.
- How to check further: stage 3 reports intervals for the contrasts that matter.

### No registration; the timing prediction differs from the finding
- Code: DES-PREREG — Severity: minor — Evidence: confirmed
- Location: Introduction (ll. 101–119); Discussion para 3
- What: no registration. Two opposite directional predictions for water colour are both stated.
  The one specific prediction is a change "stronger at dusk than during the rest of the day"; the
  finding is a difference in the afternoon, "long before sunset and twilight", "while we predicted
  a reduction of activity around sunset in all treatments".
- Why it matters: the interpretation of the timing was formed after seeing the data.
- How to check further: none; a matter of how the result is framed.

## Measurement

### Sequences with zero distance are missing from the time-moving analysis
- Code: MEA-MISSING — Severity: major — Evidence: confirmed
- Location: Results para 1 ("we discarded 39 sequences (3.3%)"); dataset, column `Mov.cum`
- What: the dataset has distance travelled missing in 38 sequences and time spent moving missing
  in 110 (9.4 %). The 72 extra missing values are exactly the 72 sequences whose distance
  travelled is 0. A newt that did not move for 30 minutes is recorded as "not available", not as
  0 s moving. Of the 110, 77 are in the fish-cue treatment and 33 in the no-cue treatment; by
  cell, from 1 (clear, no cue) to 35 (dark, cue).
- Why it matters: the model of time spent moving (ordered beta, R² 0.46 and 0.85, the second
  significant triple interaction) is fitted without the least active sequences, which are more
  frequent with cues. The paper reports 39 discards for all analyses.
- Added 2026-11-27 (supplement): the authors' script reads the dataset twice, first
  `VideotrackingData.xlsx` ("original dataset"), then, overwriting it,
  `VideotrackingData-reprise-time_moving.xlsx` with the comment "NAs converted to 0". The second
  file is not in the supplement and not on Zenodo; the supplied file has the 110 missing values
  and no zero in `Mov.cum`. So the published analysis may have used zeros; which missing values
  were set to 0 (the 72 zero-distance sequences only, or also the 38 untracked ones, which would
  then count as "no movement") cannot be told from the supplied materials. The evidence tag stays
  `confirmed` for the dataset as published; what the fitted model used is `needs-data`.
- How to check further: ask the authors for the second file; stage 2 refits the time-moving model
  with the 72 zeros restored (the ordered beta family has a point mass at 0 for this purpose),
  with all 110 set to 0, and with none, and compares each with the Results text.

### What "time spent moving" measures
- Code: MEA-CONSTR — Severity: major — Evidence: inferred
- Location: Methods, "Statistical Analysis" (l. 188); Figure 1b; dataset
- What: no definition of "moving" is given. The median is 1,579 s out of 1,800: by this measure a
  newt moves 88 % of the time. In the 72 sequences with less than 10 units of distance travelled
  (the minimum recorded step is 1.5), 40 have more than 600 s "moving". Rank correlation with
  distance travelled 0.60.
- Why it matters: the variable is presented as a second measure of activity that confirms the
  first. A measure near its ceiling that registers minutes of movement without displacement is
  measuring something else (body or tail movement, tracking jitter); the assumption is about what
  the software setting was.
- How to check further: ask for the EthoVision movement thresholds; stage 2 looks at the joint
  distribution.

### Untracked sequences are concentrated in the fish-cue treatment
- Code: MEA-MISSING — Severity: minor — Evidence: confirmed
- Location: Results para 1; dataset
- What: 38 sequences have no distance (the text says 39): 32 with fish cues, 6 without. Three
  newts account for 23 of them.
- Why it matters: "could not be tracked with enough reliability" depends on the treatment, so the
  discards are not ignorable by default; an immobile or hidden animal is both harder to track and
  less active.
- How to check further: ask why each sequence was discarded; sensitivity analysis at stage 2.

### Body size, test day and time in captivity not used
- Code: MEA-COVAR — Severity: minor — Evidence: confirmed
- Location: Discussion (limitations); Methods
- What: body size was not a covariate (acknowledged by the authors). Test day (eight sessions) and
  days since capture (3 to 8) are in the dataset and not in the models.
- Why it matters: with 8 or 9 animals per cell, a between-animal covariate can matter.
- How to check further: stage 3.

## Model adequacy

### Twenty-two repeated measures per newt, time as an unordered factor
- Code: MOD-STRUCT — Severity: major — Evidence: confirmed
- Location: Methods, "Statistical Analysis" (ll. 189–195)
- What: time enters as a factor with 22 levels in a three-way interaction (132 cell means, 42 df
  for the interaction); the repeated measures of a newt are handled by a random intercept only.
  No serial correlation, no random slope, no smooth of time; test day is absent.
- Why it matters: consecutive half hours of the same animal are not exchangeable. A random
  intercept assumes they are, which makes slot-wise standard errors too small when activity runs in
  bouts, and the likelihood ratio test of the interaction anticonservative. Treating the hours as
  unordered also discards the information that makes a claim about timing testable.
- How to check further: stage 2 refits the model as described and examines residual
  autocorrelation within newt; stage 3 fits time as a smooth or with an autoregressive structure.

### About 200 slot-wise comparisons per response, the fish comparisons unadjusted
- Code: MOD-MULT — Severity: major — Evidence: confirmed
- Location: Results paras 2–4 ("Tukey test: P < 0.05"); Figure 2; supplement, Table S2 and R script
- What: for each response the Results compare fish against no fish in each colour at each slot
  (66 comparisons) and each pair of colours within each cue treatment at each slot (132): 198 per
  response, 396 for the two responses. 34 are reported as significant at P < 0.05, all as "Tukey"
  tests. The script computes them as `emmeans(m, ~ FishT | ColorT | Trial)` followed by
  `contrast(., "tukey")`: one comparison per colour and slot, so there is nothing to adjust, and
  for colours (`~ ColorT | FishT | Trial`) the adjustment covers the three pairs of one slot, not
  the 22 slots. Table S2 confirms it: the 66 printed P values of the fish comparisons equal the
  unadjusted two-sided normal P of the printed z ratio (largest difference 0.004, rounding).
- Why it matters: 3.3 of the 66 fish comparisons would pass 0.05 with no difference anywhere. The
  five significant slots outside dark water (clear at 1900, 2100, 2300; medium at 1700, 2200; z
  between −2.0 and −2.3) are what such noise looks like; the block of six in dark water (z down to
  −5.1) is not. With a Holm adjustment over the 66 tests, computed from the printed z, two remain
  (dark water at 1700 and 1900). The Discussion's "over 3 h" in clear water and the reading that
  the response in clear water comes later both rest on the five.
- How to check further: stage 2 reproduces the contrasts from the script; stage 3 replaces them
  with a few planned contrasts.

### Families chosen after trying others
- Code: MOD-FAMILY — Severity: minor — Evidence: inferred
- Location: Methods (ll. 196–202)
- What: distance travelled is modelled as normal after log(x + 1), "after unsuccessfully attempting
  to fit other distributions"; 72 of 1,128 values are exact zeros and the smallest non-zero value
  is 1.5, a floor of the tracking. Diagnostics are said to confirm the fit; none is shown.
- Why it matters: a point mass at zero that is more frequent in one treatment is part of the
  effect, and a log(x + 1) normal model spreads it into the variance.
- Alberto, 2026-11-27: reads the log(x + 1) normal model as a fallback, not a modelling choice.
  The paper's own words support no more than this: it was adopted "after unsuccessfully
  attempting to fit other distributions", and which ones is not said. Stays `minor`, `inferred`
  until the residuals of the refitted model are seen; to be raised if they show misfit.
- How to check further: stage 2 (DHARMa on the refitted model), stage 3 (hurdle or Tweedie).

### The fitted model cannot be read: one 42-df test per response
- Code: MOD-SELECT — Severity: major — Evidence: confirmed
- Location: Methods (ll. 205–207); Table 1; supplement, R script
- What: the model is `colour * cue * time slot` with time as a 22-level factor: 132 fixed-effect
  parameters (3 main effects, 3 two-way interactions, the three-way interaction) for 53 newts.
  "A backward procedure was conducted to select the minimal model"; for distance and for time
  spent moving it stops at the first step, and Table 1 prints one row per response, the
  likelihood ratio test of the three-way interaction on 42 df. No coefficient, no lower-order
  term and no variance component is reported, in the article or in the supplement.
- Why it matters: a 42-df test says that the 132 cell means are not additive in some way; it
  does not say in which way, at which hours, or in which direction. The question of the paper
  (does the cue effect differ between colours, and when) needs an interaction of the three
  factors, so the interaction is not the problem; its form is. With time unordered, nothing in
  the model can express "earlier" or "later", and the answer is then sought in 198 slot-wise
  comparisons. A model with a few interpretable parameters (for example a cue effect per colour
  in the early and late part of the run, or a smooth of time by cell) would carry the estimate
  the claim needs.
- The test itself (added 2026-11-27, `inferred` until stage 2): the likelihood ratio test
  treats the 22 recordings of a newt as independent given its random intercept. They are
  consecutive hours of one animal; if the residuals are serially correlated the test is too
  liberal, and "P = 0.001" for the 42-df interaction overstates the evidence. A model with 132
  cell means also fits the sample better than a smaller one by construction, so in-sample fit
  (the R² of 0.46 and 0.85) says nothing about whether the extra parameters describe newts or
  noise.
- How to check this: stage 2, on the refitted model: autocorrelation of the residuals within
  newt; prediction of newts left out of the fit (cross-validation by newt, never by sequence)
  for the 132-parameter model against smaller ones.
- History: drafted on 2026-11-25 as "Backward selection, one row reported", minor. Raised to
  major and rewritten on 2026-11-27 at Alberto's decision after his reading of the paper: the
  model as reported gives the reader nothing to interpret. The script (2026-11-27) shows the
  selection sequence for distance to the feeder (seven refits, down to time slot only) and none
  for the other two responses, as described; it also calls `MuMIn::dredge` on the distance model
  under the name of the feeder model, with no result reported.
- How to check further: stage 2 refits the model and prints its coefficients and variance
  components; stage 3 specifies the alternative in `notes/04_analysis_plan.md` before fitting.

## Internal consistency

### Numbers that disagree within the paper
- Code: CON-XREF — Severity: minor — Evidence: confirmed
- Location: Results para 1; Table 1; Methods; Figures 1–2
- What: "1166 video sequences (53 individuals × 20 sequences)": 53 × 20 = 1,060; 53 × 22 = 1,166.
  The likelihood ratio statistic for total distance is 75.113 in the text and 75.209 in Table 1.
  Placement "75 min before testing" against 15 + 30 min in the next paragraph. Figure 2 prints
  "0010" for 0100; its caption says "(log10 + 1)"; the Figure 1 caption has a stray "(right)" and
  calls the box plots "Bars".
- Why it matters: none of these changes a result; they are recorded.
- How to check further: none needed.

### The paper against its dataset
- Code: CON-XREF — Severity: minor — Evidence: confirmed
- Location: Methods; Results para 1; Figure 1; Zenodo record
- What: distances are in mm in the paper and in cm in the dataset's dictionary; distance to the
  feeder reaches 32.7 in a 30 × 25 cm arena, so cm (the metadata sheet of the supplement's copy
  also says cm for every EthoVision distance; the script labels the axis mm in three panels of
  Figure 2 and cm in two). Discards: 39 in the text; 38, 36 and 110
  missing values in the three columns. Capture-to-test interval: 4.89 ± 1.83 days in the text,
  5.19 ± 1.80 in the dataset (range 3–8 in both). First capture 28 May in the text, 29 May in the
  dataset. Test-day labels do not follow the dates (the day labelled 1 is 5 June, after the days
  labelled 2, 4 and 5), and the first five test dates are not "four consecutive days" plus a fifth.
- Why it matters: the unit is a factor of ten on every distance in the figures; the dates matter
  only if day enters a model. The missing-value count is its own entry above.
- How to check further: ask the authors which is right.

### Supplementary Table S3 repeats Table S2
- Code: CON-XREF — Severity: major — Evidence: confirmed
- Location: supplement, Tables S2 and S3; Results para 4 ("Supplementary Table S2—S3, Fig. S2")
- What: Table S2 is captioned as the contrasts for distance travelled, Table S3 as those for the
  proportion of time spent moving (an ordered beta model, on another scale). Of the 198 estimates
  of S3, 195 are within 0.02 of the corresponding estimate of S2 (162 within 0.005; correlation
  0.999); the standard errors differ by 0.01 at most. The three rows that differ are
  the comparisons involving clear water with fish cues at 1900. The slots S3 marks below 0.05 for
  fish against no fish (clear 2100, 2300; medium 1700, 2200; dark 1500 to 2000) are not those the
  Results give for time spent moving (clear 2000; medium 2300; dark 1600 to 1900 and 2100).
- Why it matters: the contrasts behind every statement of the Results on time spent moving are
  not in the supplement; what is printed in their place reads as a second fit of the distance
  model on a slightly different copy of the data (inferred: the script's Figure 2 code carries
  two sets of asterisks, one commented "Not NA_corrected dataset", and they are the sets of S2
  and of S3).
- How to check further: stage 2 fits the distance model on the supplied data and on the data
  with zeros restored and compares both with S2 and S3; ask the authors for the time-moving
  contrasts.

## Reporting

### The script does not run as supplied and reads a file that is not supplied
- Code: REP-CODE — Severity: major — Evidence: confirmed
- Location: supplement, `ESM- R Script_newts_videotracking_2024.Rmd`; Data Availability
- What: the script loads `VideotrackingData-reprise-time_moving.xlsx` ("NAs converted to 0")
  over the supplied dataset; that file is in neither the supplement nor the Zenodo record. Some
  chunks call objects that are never created (`b`, `m`, a model with `treatment:hour_cat`). The
  asterisks of the figures are typed by hand (`annotate("text", label = "*", x = ...)`), in two
  versions for Figure 2 ("Not NA_corrected dataset" kept as a comment). The published Figure 2
  and Table S2 carry the "not corrected" set (clear water: 1900, 2100, 2300); the script as
  supplied draws the other (2100, 2300), which is the set of Table S3.
- Why it matters: at least one reported asterisk (clear water, 1900: P 0.024 in S2, 0.091 in S3)
  depends on which copy of the data is used, and the supplied materials do not say which copy
  produced which published result. Sharing the script is what makes this visible, and is to the
  authors' credit.
- For Alberto: severity is a judgement; `minor` is defensible if stage 2 reproduces everything
  from the supplied file.
- How to check further: stage 2; ask for the second file.

### No estimate of any effect in the article
- Code: REP-EFFECT — Severity: major — Evidence: confirmed
- Location: Abstract; Results; Table 1; supplement, Table S2
- What: the article reports likelihood ratio tests, R² and asterisks. No mean, difference, ratio
  or interval is given for any contrast, in the text or in a table; Figure 1 pools the 22 hours.
  "Predation risk strongly attenuated activity" has no number. Revised 2026-11-27: the
  supplement does hold estimates. Table S2 gives the 198 slot-wise contrasts for distance on the
  log10(x + 1) scale with standard errors (for example −2.08, SE 0.41, in dark water at 1700: a
  ratio of about 1 to 120 on the shifted scale). Its caption announces lower and upper 95 %
  limits; the table has no such columns. No contrast is aggregated over hours, none is
  back-transformed, and nothing estimates the difference in timing between colours.
- Why it matters: the reader of the article cannot tell how large the reduction is, in which
  units, with what uncertainty; the reader of the supplement gets 198 numbers and no summary. The
  dataset shows the reduction is large in dark water early in the run (median distance 21 against
  1,415 in slots 1–6) and absent in clear water in the same slots (423 against 363).
- Alberto, 2026-11-27: stays `major`. Slot-wise contrasts are of little use to a reader; what
  is missing is the estimates of the parameters of a model that answers the question, and the
  quantity the title is about (a shift in timing) has no estimate anywhere.
- How to check further: stage 3 supplies the estimates.

### Reporting guideline, randomisation, cue source
- Code: REP-GUIDE — Severity: minor — Evidence: confirmed
- Location: Methods
- What: no guideline cited (ARRIVE); the randomisation method, the definition of "moving", the
  number of perch and the reasons for discarding sequences are not given.
- Why it matters: each is needed to judge a concern above.
- How to check further: questions to the authors.

## Inference

### A claim about timing rests on which slots pass P < 0.05
- Code: INF-FOLLOW — Severity: major — Evidence: confirmed
- Location: Abstract; Results para 2; Discussion para 3
- What: "This response occurred earlier in the dark water group than in the control group" is
  read off the position of the asterisks: 1500–2000 in dark water, 1900, 2100 and 2300 in clear
  water. "distance travelled was reduced over 6 h in dark water and over 3 h in clear water" counts
  significant slots. No quantity describing timing (onset, peak, duration) is estimated or
  compared between colours.
- Why it matters: a difference between "significant here" and "not significant there" is not a
  test of a shift. The same data are also described by "a large early effect in dark water, little
  or none in clear water": a difference in size, not in timing. Together with the first design
  concern, the timing claim of the title and abstract is not established by the analysis reported.
- How to check further: stage 3 estimates the cue effect by block of hours and its difference
  between colours, with intervals.

### "Newts may anticipate the shift in the activity of the predator"
- Code: INF-MECH — Severity: major — Evidence: confirmed
- Location: Abstract; Discussion para 3
- What: the explanation offered is that newts anticipate an earlier activity peak of perch in
  darker water. No perch activity was measured; light was constant through the day; the first
  hours are also the hours after handling and cue addition.
- Why it matters: it is the sentence of the abstract that gives the result its meaning, and it has
  no data behind it in this study. The authors mark it with "may".
- How to check further: none in these data.

### "perch cues were well detected in all water colour treatments"
- Code: INF-FOLLOW — Severity: minor — Evidence: confirmed
- Location: Discussion para 5
- What: "our results demonstrate that perch cues were well detected in all water colour
  treatments". In clear water the fish and no-fish curves differ at three non-adjacent slots out
  of 22, and in the first six slots the medians are 423 and 363.
- Why it matters: if the cue had little effect in clear water, the paper's reading of the colour
  effect (same detection, different response) loses its premise.
- How to check further: stage 3, cue effect in clear water with its interval.

### Males of one population in a bare arena
- Code: INF-GENER — Severity: minor — Evidence: confirmed
- Location: Title; Discussion (limitations)
- What: 53 males from five ponds of one area, tested alone in a glass tank; the title says
  "newts", and the closing paragraph speaks of water browning in boreal freshwaters. The authors
  state both limits.
- Why it matters: scope of the conclusion.
- How to check further: none.
