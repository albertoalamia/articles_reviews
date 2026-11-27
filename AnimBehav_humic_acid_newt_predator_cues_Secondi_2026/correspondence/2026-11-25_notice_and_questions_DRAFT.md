# Notice of commentary and questions — DRAFT (not sent)

To: {secondi}
Subject: Secondi et al. 2026, Animal Behaviour, humic acid and newt response to predator cues: questions on the data and notice of a methodological commentary

---

Dear Dr Secondi,

I am a psychiatrist and biostatistician based in Italy. I work with animals in a clinical setting
(donkey-assisted interventions), and I run a small programme that re-examines the methods of
published studies in psychiatry and in animal behaviour, paper by paper, with every check made
reproducible. Your recent article in Animal Behaviour on humic acid and the response of smooth
newts to perch cues (doi 10.1016/j.anbehav.2026.123735) was drawn at random for this programme, not
chosen: the journal and the article were both selected by a seeded draw.

First, thank you for depositing the data on Zenodo under an open licence and for publishing the
R script with the article. It is what makes a careful reading possible, and it is less common
than it should be.

I am writing for three reasons.

The first is to tell you openly that I intend to publish a methodological commentary on the
article. I plan to refit the models you describe on your data and to fit alongside them models
that treat the 22 recordings of each animal as a time course (serial correlation, time as a smooth
function, test day), in both a frequentist and a Bayesian framework, and to express the effect of
the cue as estimates with intervals by water colour and period of the run. You would receive the
full text before anything is made public, and your response would be published together with it.

The second is that I could not reconcile a few elements of the article with the dataset and the
supplement, and I would rather ask than guess. A misunderstanding on my side is entirely possible.

1. The Results give 39 discarded sequences (3.3 %). In the dataset the distance travelled is
   missing in 38 sequences, and the time spent moving in 110. The 72 additional missing values of
   time spent moving are exactly the 72 sequences in which the distance travelled is 0. The R
   script reads a second file, "VideotrackingData-reprise-time_moving.xlsx", with the comment
   "NAs converted to 0"; I could not find it in the supplement or on Zenodo. Which missing values
   were set to 0 (the 72, or all 110), and which analyses used that file?
2. Supplementary Table S3 is captioned as the contrasts for the proportion of time spent moving,
   but its values are almost those of Table S2 for distance travelled (195 of the 198 estimates
   agree within 0.02), and the time slots it marks as significant are not those the Results give
   for time spent moving. Is it possible that the table of the distance model, fitted on the
   other copy of the data, was placed there?
3. The Results describe the pairwise comparisons as Tukey tests. In Table S2 the P values of the
   fish against no fish comparisons equal the unadjusted P of the z ratio, which is what the
   emmeans call in the script gives when there is one comparison per colour and hour. Do I read
   correctly that no adjustment was applied across the 22 hours?
4. The article gives the two distances in mm; the dictionary sheet of the dataset gives them in
   cm, and the distance to the feeder reaches 32.7 in an arena of 30 × 25 cm. Which is correct?
5. The Results read "1166 video sequences (53 individuals × 20 sequences)"; the dataset has 22
   sequences per animal. I take 22 to be right.
6. The likelihood ratio statistic for total distance is 75.113 in the text and 75.209 in Table 1.
7. The time between capture and testing is 4.89 ± 1.83 days in the text and 5.19 ± 1.80 days from
   the dates in the dataset; the test-day labels (Day1 to Day8) do not follow the test dates.

The third is to ask for a few things the article does not state, in whatever form is convenient:

1. The second data file read by the script, and the contrasts for time spent moving.
2. How "moving" was defined in EthoVision (thresholds), and the minimum distance setting.
3. How many perch supplied the cue water, and which batch was used on which test day.
4. Whether light in the water of the arenas was measured in the three colour treatments.
5. Why each discarded sequence was discarded, if this was recorded.
6. Whether every run started at 15:30, or whether some started at another hour. I ask because, as
   I read the design, the time of day and the time since the cue was added coincide for all
   animals, and I would like to be sure I have not missed something.
7. Body size of the newts, if it was measured.

In return, I will share with you the full analysis before anyone else: all code, the processed
data and step-by-step instructions, in a pinned software environment, so that every result can be
reproduced on your side from start to finish.

For transparency, I should add that if I receive no reply within three weeks I will proceed with
the commentary on the article and the public dataset, and publish it without further notice. In
that case too the commentary, with all code and instructions, will be freely available on my site
(https://reviews.telepsichiatria.org) so that it can be checked and challenged by anyone,
yourselves first of all.

Thank you for your time.

With kind regards,

Alberto Alamia, MD
Psychiatrist, biostatistician
telepsichiatria.org

---

## Notes for sending
- Addresses are not written in this file (public repository): `{secondi}` is resolved by
  the send script from `correspondence/addresses.local`, which is gitignored.
- Only Secondi's address is printed in the article. The co-authors' addresses (Helsinki, Turku)
  can be added in Cc if Alberto wants them informed directly (they are on the institutional
  pages): add a line per person to `addresses.local` and a `Cc: {key}, {key}` line here.
- The signature has no email line: add it by hand if wanted (the Shi letter had one).
- Alberto has not read the paper yet: read `notes/03_concerns.md` and this letter before sending,
  and run `R/02_consistency_checks.R` first so that the seven numbered points rest on his own run
  (points 2 and 3 are block I, added on 2026-11-27 after the supplement arrived).
- Revised 2026-11-27: the request for the R script was dropped (it is in the supplement);
  points 1 to 3 now refer to the script and to Tables S2–S3.
- Three-week window from the sending date; publication proceeds after it as the letter states.
- When sent: `tools/send_email.py` renames this file `_DRAFT` → `_SENT` and appends the `Sent:`
  line; then a row in `contacts.md` → Log with the deadline, `authors_contacted` in the registry.
