# Reading notes — Secondi et al. 2026, Animal Behaviour 241, 123735 (P003)

Section by section. Line numbers refer to `paper/Secondi_2026_fulltext.txt` (not committed: the
article is closed access); "p5", "p6" are PDF pages where the two-column extraction interleaves.
Quotations are exact. Written by Claude Code on 2026-11-25 from the full text, the rendered pages
4–5 and the public dataset; Alberto has not yet read the paper.

## Abstract (ll. 36–54)

- Question: "the influence of predation risk (fish olfactory cue) and water colour on the diel
  activity pattern of the newt Lissotriton vulgaris".
- Results as stated: "Predation risk strongly attenuated activity. The effect of water colour was
  more complex. Newts reduced their activity in the presence of fish cues. This response occurred
  earlier in the dark water group than in the control group. Therefore, the interaction between
  predation risk and water colour was time dependent."
- Interpretation: "Newts may anticipate the shift in the activity of the predator, whose peak
  activity is expected to occur earlier in darker water too."
- Conclusion: the finding "highlights the importance of considering the prey's capacity to finely
  assess variation in predation risk and tune their diel activity to the visual environment".
- No number in the abstract: no n, no effect size.

## Introduction (hypotheses as stated; ll. 61–122)

- Framework: landscape of fear and "schedule of fear" (Palmer et al. 2022): prey shift activity in
  time when they cannot shift in space.
- On water colour the authors state that theory gives no direction: "there is no clear general
  theoretical expectation about prey's responses to changes in water colour" (ll. 119–121); a
  meta-analysis found the effect of turbidity on predatory fish activity "did not differ from zero".
- Hypothesis (ll. 101–119): "both the presence of olfactory cues and water colour affect the
  activity of newts"; "we predicted an interaction between predation risk, water colour and time of
  the day". Two opposite directional predictions are both stated: if predators' detection of prey
  is mostly affected, "newt activity should be higher in brown water than in clear water";
  "Conversely, if predator detection by prey is mostly affected, then newt activity should be more
  reduced in dark water".
- The one specific prediction on timing: "we predicted that the change in newt activity at dusk
  would depend on water colour and would be stronger at dusk than during the rest of the day."
- No registration is mentioned.

## Methods

### Subjects and setting (ll. 126–151)
- "We caught 53 male smooth newts in five wetlands in the Evo Natura 2000 forest area ... between
  28 May 2024 and 11 June 2024." Site water colour "range 107–170 mg Pt/litre; see Supplementary
  Table S1".
- Housing: plastic tanks, "Each tank hosted four individuals from the same pond", untreated tap
  (ground) water, natural photoperiod, fed live isopods.
- "The mean (± SD) time between capture and testing was 4.89 ± 1.83 days (range 3–8 days)."
- "Fish presence could not be ascertained in the ponds": prior experience of the newts with fish
  is unknown.

### Design and procedure (ll. 156–221)
- "two-way factorial design": water colour (clear, medium, dark: 25, 165, 275 mg Pt/litre, by
  dilution of commercial humic acid; pH 7.86–8.08) × olfactory cue (perch water or aged water).
- "Newts were assigned randomly to experimental treatments." Method not described.
- Fish cue: "transferring to each experimental tank 100 ml of water from a 70-litre tank in which a
  European perch (minimum length: 22 cm, maximum length: 26 cm) had been housed for 2–3 days". One
  cue tank; the length range suggests more than one perch over the experiment; number not stated.
- Cue decay discussed from the literature (half-lives 35.6–126.9 h): "the concentration of
  olfactory cues would be between 65.16% and 88.68% of the initial concentration after 22 h".
- "All individuals were tested once": between-subject design; each newt contributes one 22-h run
  in one colour × cue cell.
- Arena: glass tank 30 × 25 × 40 cm with 15 cm of water; a feeder tube with one live isopod behind
  mesh in a corner; a shelter opposite. "Newts were not fed for 48 h prior to their testing day."
- Timeline of a run: newt placed "75 min before testing"; feeder tube inserted 15 min later;
  elsewhere: "we placed individuals in the experimental tank and poured control or fish water into
  the tank 15 min later. We waited 30 min for the newts to recover from the manipulation, then
  started the test at 1530 hours." (The two descriptions give 75 min and 45 min between placement
  and the first recording.)
- Light: "nocturnal period between 2330 and 0430 hours"; 9.1 lx (day) and 0.017 lx (night) at table
  level. Light in the water of the three colour treatments was not measured.
- Recording: "30 min video sequences at 60 min intervals for 22 h, the last sequence ending at 1300
  hours the next day"; "We refer to each time slot by the starting hour (2200 hours for 2230–2300
  hours)". 22 slots, 15:30–16:00 to 12:30–13:00. Every run starts at 15:30, so the time of day and
  the time since the cue was added are the same variable.
- "up to eight individuals" per daily session; "36 newts were captured in the first trapping
  session (12 newts from 3 sites), so eight newts were tested on four consecutive days, and the four
  remaining individuals were tested on the fifth day".
- Tracking: EthoVision XT 17, two infrared cameras each over four tanks, infrared backlight.
  "The positions of tanks across the table were balanced according to water colour, fish treatment
  and the two cameras." "Newts were tracked continuously during each time sequence except when
  they entered the shelter, which was uncommon."

### Measures (ll. 186–188)
- "the total distance travelled (mm), the mean distance to the feeder (mm) and the time spent
  moving (s)" per 30-min sequence. No definition of "moving" (velocity or displacement threshold),
  no tracking validation in dark water.

### Statistical analysis (ll. 186–211, verbatim)
- "We used generalized mixed models to analyse the response variables. The models included a
  triple interaction between water colour, fish treatment and the time sequence, which was coded as
  a factor, each level corresponding to a different time of the day. Arena position and newt
  identity (ID) nested in site were included as random factors in all models."
- "For total distance travelled and mean distance to the feeder we used a normal distribution of
  errors. We applied a log (x + 1) transformation to distance travelled after unsuccessfully
  attempting to fit other distributions that would not require a transformation of the response
  variable. For time spent moving, we used an ordered beta regression after scaling the response
  variable within the [0;1] interval."
- "Heteroscedasticity and dispersion diagnostics confirmed the good fit of the models." glmmTMB,
  DHARMa. "A backward procedure was conducted to select the minimal model for each response
  variable using likelihood ratio tests." "Post hoc Tukey tests were computed using the emmeans
  package". R² from MuMIn.
- Not stated: the family of comparisons the Tukey adjustment covers; any correlation structure for
  the 22 repeated measures; test day or cue batch; sample size justification.

## Results (ll. 228–252 and p5)

- "Out of the 1166 video sequences (53 individuals × 20 sequences), we discarded 39 sequences
  (3.3%) because newts could not be tracked with enough reliability."
- Total distance: "best fitted by the full model"; triple interaction "χ²42 = 75.113, P = 0.001"
  (Table 1: 75.209); marginal and conditional R² 0.200 and 0.403.
- "Overall, raw data show that newts travelled shorter total distances when fish cues were present,
  and the decrease was more pronounced when they were in the dark water treatment (Fig. 1)."
- Fish against no fish, by colour (Tukey, P < 0.05): clear, "significant differences at 1900, 2100
  and 2300 hours"; medium, "only at 1700 and 2200 hours"; dark, "newts sharply reduced activity
  between 1500 and 2000 hours in the presence of fish cues ... while the distance travelled
  remained fairly similar between fish treatments for the rest of the day."
- Colours compared within cue treatment: with cues, dark lower than both others "at 1500, 1700 and
  1800 hours", than medium at 1900 and than clear at 0500; without cues, dark lower than medium
  "at 2200, 0300 and 0800 hours" and than clear at 0300.
- Time spent moving: significant triple interaction (Table 1: 62.697, df 42, P = 0.021); details in
  Supplementary Tables S2–S3 and Fig. S2; R² 0.459 and 0.852. Fish below no fish "at 2000 hours in
  the clear water treatment and at 2300 hours in the medium water treatment, and from 1600 to 1900
  hours and 2100 hours in the dark water treatment".
- Distance to the feeder: "none of the predictors explained the variation ... and no model
  performed better than the null model (P > 0.05; Table 1, Fig. 1)."

### Table-by-table
- Table 1 (p5): likelihood ratio statistic, df and P. One row (the triple interaction) for total
  distance and for time spent moving; seven rows for distance to the feeder. All nine P values
  follow from the statistic and df (script, block A). No coefficient, mean or interval anywhere.

### Figure-by-figure
- Figure 1 (p4): box plots of the raw data by colour and cue over the whole 22 h. Axes in mm for
  both distances. Caption: "(c) mean distance to the feeder (right)", "Bars show the activity".
- Figure 2 (p5): model predictions of log10 distance by slot, (a) fish against no fish within each
  colour, (b) the three colours within each cue treatment; asterisks for P < 0.05; night shaded.
  Caption: "Predictions of transformed data (log10 + 1)". The x axis prints "0010" for 0100. In the
  dark panel the two lines are far apart from the first slot (15:30) and meet at about 21:00.

## Discussion (claims, in order; p6)

1. "According to our predictions, newt activity ... was strongly reduced when predator cues were
   present."
2. "the reduction of activity in the presence of fish cues was stronger in the dark water colour
   treatment than in the two other treatments. This result supports the hypothesis that predation
   risk is perceived as higher when visibility is lower."
3. "Water colour also affected the timing of the antipredator response." "Considering only
   significant differences between the fish and the no fish treatment, distance travelled was
   reduced over 6 h in dark water and over 3 h in clear water, hinting at compression of the
   activity period."
4. "The strongest drop in activity occurred in the dark water treatment between 1500 and 1800
   hours, long before sunset and twilight. This pattern suggests a progressive shift of the
   antipredator response towards an earlier start as water darkened, while we predicted a reduction
   of activity around sunset in all treatments."
5. Two explanations offered: altered perception of time in dark water (set aside), or "the newts
   account for the change in the activity pattern of the predators". "Since light was constant
   during the tests, this would imply that time was accurately assessed and that newts adjusted
   their behaviour according to the current time and lighting conditions."
6. Limitations acknowledged: body size not a covariate; limited ecological realism; males only;
   "We do not know whether the newts associated the olfactory cues to the species that produced
   them. However, our results demonstrate that perch cues were well detected in all water colour
   treatments."
7. "DOC has been reported to impair olfaction in aquatic vertebrates": stated, not examined as an
   explanation of the colour effect.
8. Closing: "The results of the present study suggests that temporal tuning of antipredator
   behaviour to the photic environment can be achieved by some species."

Not discussed: that the first slots are also the first hours after handling and after the cue was
poured, so "earlier in the day" and "sooner after exposure" cannot be told apart.

## Declarations

- Data: "The data set and R script are provided as Supplementary Material. The data set is also
  available at https://doi.org/10.5281/zenodo.18200379." The Zenodo record is public, CC BY 4.0
  (one xlsx, 1,166 rows). The R script is in the journal's supplement (not yet obtained).
- Ethics: permits ELY-keskus and ESAVI (ESAVI/6410/2020); newts released at the pond of origin.
- Author contributions: formal analysis by the first author.
- No reporting guideline is cited (ARRIVE). No registration.

## First look at the dataset (script blocks B–H; nothing fitted)

- 53 newts × 22 slots = 1,166 rows; 8 or 9 newts in each of the six colour × cue cells; allocation
  balanced within capture site and within test day.
- Distance travelled is missing in 38 sequences, distance to the feeder in 36, time spent moving in
  110. The 72 extra missing values of time spent moving are exactly the sequences in which the
  distance travelled is 0.
- Untracked sequences: 32 with fish cues, 6 without.
- Dictionary sheet: both distances "(cm)". Distance to the feeder ranges from 0.9 to 32.7 in an
  arena whose diagonal is 39 cm.
- Time spent moving has a median of 1,579 s out of 1,800.
- Median distance in the first six slots (15:30–21:00): dark water 21 with cues against 1,415
  without; clear water 423 against 363. In the other sixteen slots the cells are close.
- Test dates do not follow the day labels (the day labelled 1 is the fourth by date), and the mean
  capture-to-test interval is 5.19 days against the 4.89 of the text.
