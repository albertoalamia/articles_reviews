# Anim Behav — Humic acid and the response of newts to predator olfactory cues (Secondi 2026)

Article-specific context for Claude Code. Repo-wide rules are in the root `CLAUDE.md`.

## Paper

- Citation: Secondi J., Blanchet C. C., Xu O., Loehr J., Arzel C. (2026). Increasing humic acid concentration alters the intensity and the diel response of newts to predator olfactory cues.
  *Animal Behaviour*, 241, 123735. Angers and Lyon 1 (Secondi, corresponding), Helsinki (Blanchet, Xu, Loehr),
  Turku and OMPO (Arzel). Received 9 Feb 2026, final acceptance 3 Aug 2026, online 19 Oct 2026.
- DOI: 10.1016/j.anbehav.2026.123735
- Version reviewed (preprint / accepted manuscript / version of record): version of record
  (8 pages, sha256 f0683c82…bf72, `paper/Secondi_2026_AnimBehav_123735.pdf`). Closed access; obtained
  by Alberto through the University of Milano-Bicocca library on 2026-11-25. **The PDF, supplements and the extracted full text are
  copyrighted and are not committed** (`.gitignore` covers `paper/` of this folder; see
  `paper/README.md`). Quote only what a review needs.
- Track: `systematic` — source: batch B02 (selection v0.3; Animal Behaviour drawn with
  `tools/journal_draw.py`, seed 20261125; October 2026; whole journal, no subfield filter; frame of
  11, rank 1, eligible on the title, no abstract indexed).
- Field: ethology
- Registry id: P003 — protocol version: 0.4
- Data availability as stated: "The data set and R script are provided as Supplementary Material.
  The data set is also available at https://doi.org/10.5281/zenodo.18200379." The Zenodo record
  is public (CC BY 4.0) and is in `data/raw/authors/`, committed. The supplement (R script,
  Tables S1–S3, Figures S1–S2, a 24-column copy of the dataset) is in
  `paper/ANBEH-D-26-00085_SuppMat/` since 2026-11-27, not committed.
- What the paper claims (two sentences, in the authors' terms): "Predation risk strongly attenuated activity";
  the reduction with fish cues "occurred earlier in the dark water group than in the control group",
  so "the interaction between predation risk and water colour was time dependent". "Newts may
  anticipate the shift in the activity of the predator, whose peak activity is expected to occur
  earlier in darker water too."

## Design in one paragraph

Laboratory experiment on 53 male smooth newts (*Lissotriton vulgaris*) caught in five ponds in
southern Finland, May–June 2024. Between subjects: water colour (clear, medium, dark: 25, 165,
275 mg Pt/litre, by adding commercial humic acid) × olfactory cue (100 ml of water from a perch
tank, or aged water); 8 or 9 newts per cell, each tested once, alone, in a 30 × 25 cm arena.
Every run starts at 15:30, 30 min after the cue is added, and lasts 22 h: 22 half-hour video
sequences, one per hour, tracked with EthoVision. Responses per sequence: distance travelled, time
spent moving, mean distance to a feeder. Analysis as described: mixed models (glmmTMB) with the
three-way interaction colour × cue × time slot (time as a 22-level factor), random intercepts for
arena and for newt nested in site; normal errors on log(x + 1) distance, ordered beta for time
moving; likelihood ratio tests, backward selection, Tukey post hoc comparisons by slot (emmeans;
from the script: unadjusted for fish against no fish, over three colour pairs within a slot).
No estimate of any effect in the article; slot-wise contrasts with SE in supplementary Table S2.

## Files

- `paper/` — PDF(s), supplementary material, authors' code if any. Read-only.
- `notes/01_reading_notes.md` — section-by-section notes with page references.
- `notes/02_methods_inventory.md` — protocol checklist A–H filled in.
- `notes/03_concerns.md` — one entry per concern, tagged confirmed / inferred / needs-data,
  mirrored as rows in `registry/issues.csv`.
- `notes/04_analysis_plan.md` — the shared specification for stages 3 (frequentist) and 4
  (Bayesian): estimands, family, structure, contrasts, priors; written before fitting.
- `correspondence/` — every message sent (`tools/send_email.py`) and received
  (`tools/fetch_email.py`), plus `contacts.md` with the log table.
- `data/raw/` — numbers as extracted from tables/figures (one CSV per table, with an
  `EXTRACTION_LOG.md` saying where each came from) or data received from the authors.
- `data/derived/` — tidy data and `*.json` for CmdStan, produced by `R/01_prepare_data.R`.
- `stan/` — `.stan` models, one per file, named by structure (`nb_crossover_order.stan`).
- `run_<model>.sh` — compiles with CmdStan and samples; draws go to `$FITS_DIR/<this dir>/`.
- `R/0x_*.R` — numbered scripts: prepare, consistency checks, post-process, figures.
- `output/figures`, `output/tables` — small artefacts only.
- `correspondence/` — what was sent to the authors and what came back, dated.
- `review.qmd` — the public review. `draft: true` until authors have been contacted.

## STATUS

<!-- Update at the end of every session. Newest entry first. -->

### 2026-11-27 (night) — Alberto has read the paper
- Decided (Alberto): the model-reporting concern is raised to major and rewritten ("The fitted
  model cannot be read: one 42-df test per response"); count now 12 major, 11 minor, none
  critical. "No estimate" stays major: slot-wise contrasts are not what a reader needs, the
  parameters of a model that answers the question are. The log(x + 1) normal family stays minor
  and inferred until stage 2 shows the residuals. A three-way interaction with an unordered
  22-level time factor is the wrong form for a question about timing; stage 3 is to use few
  interpretable parameters.
- Agreed for the next stages (Alberto and Claude, 2026-11-27; to be written properly in
  `notes/04_analysis_plan.md` before any fit):
  (a) stage 2 checks whether the authors' 132-parameter model overfits: residual
  autocorrelation within newt, and out-of-sample prediction with whole newts left out, against
  reduced models (no three-way term; no interaction at all);
  (b) the candidate replacement is a longitudinal model: a daily activity curve shared by all
  newts, a cue effect that starts at exposure and fades (size and duration), those two
  quantities allowed to differ by colour as the only interaction, serial correlation within
  newt; about a dozen parameters;
  (c) the interaction is tested by comparing predictive performance with and without it
  (cue effect common to the three colours against colour-specific), by newt-level
  cross-validation in stage 3 and leave-one-newt-out in stage 4, not by a P value alone;
  (d) fading: model the fading of the response, not of the cue; the two cannot be separated
  in this design (the paper quotes cue half-lives of 35.6 to 126.92 h, i.e. 65–89 % left after
  22 h), and time since exposure equals time of day for every newt, so a fading term and the
  daily curve are separated only by the no-cue groups.
  (e) performance indices (Alberto, 2026-11-27): not prediction of left-out newts alone; also
  AIC and BIC for the frequentist fits (maximum likelihood, same rows, same response scale;
  marginal AIC, with the number of parameters stated) and WAIC next to LOO for the Bayesian
  ones, all in one table per comparison. Models on different response scales (log-normal
  against two-part) are compared only after putting the likelihoods on the same scale;
  (f) log scale or two-part model for distance: decided after the stage 2 residuals.
  (g) reference for the longitudinal models: Fitzmaurice, Laird and Ware, *Applied Longitudinal
  Analysis*, 2nd ed. (Alberto's copy, `~/Documents/books/Fitz`, outside the repo). The authors'
  model is what ch. 5–6 call the analysis of response profiles (time saturated), with the
  drawbacks listed in §6.1: an omnibus interaction test that "does not indicate the specific
  ways in which the mean response profiles differ", and time-ordering ignored. Candidate from
  §6.3 and the CD4 case study of §8.8: a linear spline in time (truncated line functions, one
  or two knots), slopes by group, random intercept and random spline slopes per newt (ch. 8),
  serial correlation by an autoregressive or exponential pattern (§7.4). Knots fixed in
  advance from the design (for instance lights off and lights on), not searched in the data.
  §7.5 advises against BIC for choosing the covariance model; ML, not REML, to compare means.
- Open: Alberto's further modelling points, if any; the letter not sent. Block I was run by
  Alberto on 2026-11-27 (identical to the scratch run) and the review re-rendered after the
  last registry change.

### 2026-11-27 — Supplement read; stage 1 revised
- Done: Alberto ran `R/02_consistency_checks.R` (blocks A–H: same numbers as the scratch run),
  rendered `review.qmd`, and filed the supplement. Claude read the R script and the supplement
  document, compared the supplement's dataset with the Zenodo copy (identical in the three
  analysed columns), transcribed Tables S2–S3 (`data/raw/tableS2_S3_contrasts.csv`, 396 rows,
  parsed, not typed), added block I to the consistency script, revised `notes/03_concerns.md`
  (23 entries: 11 major, 12 minor, none critical), `notes/02_methods_inventory.md`, the
  extraction log, the registry rows and the draft letter.
- What the supplement changed: (1) "Tukey" settled: the 66 fish against no fish comparisons per
  response are unadjusted, and the P values of Table S2 are the plain normal P of z; of the 11
  significant ones, 2 remain after Holm over the 66 (dark water, 1700 and 1900); the 5 outside
  dark water have z between −2.0 and −2.3. (2) Table S3, captioned time spent moving, repeats
  Table S2 (195 of 198 estimates within 0.02) and does not hold the slots the Results report for
  time moving: new concern, major. (3) The script reads a second data file ("NAs converted to
  0") that is not supplied, does not run as supplied, and types the asterisks by hand in two
  versions; the asterisk for clear water at 1900 exists in one version only: new concern, major.
  (4) "No estimate of any effect" narrowed to the article: Table S2 has slot-wise contrasts with
  SE (no intervals, none aggregated). (5) What is sound: the script's models are those of the
  Methods; Table S2 matches the Results text and Figure 2 for distance, slot by slot.
- Decided (and why): the transcribed contrasts (numbers only) are committed like Table 1; the
  supplement files are not. The letter no longer asks for the script; it asks for the second
  data file and the time-moving contrasts, and has two new numbered points (S3, adjustment).
- Open questions: block I comes from Claude's scratch run until Alberto re-runs the script.
  Table S1 and Figure S2 are EMF pictures in the docx that Claude did not read. Severity of the
  two new concerns and of "No estimate..." is for Alberto. Everything else as on 2026-11-25:
  Alberto has not read the paper.
- Next step: Alberto re-runs the consistency script, reads the paper, the concerns and the
  letter, sends the letter (three-week clock), commits. Stage 2 in a fresh conversation: run the
  authors' models from their script on the supplied data, with the 72 zeros restored and with
  all 110 missing set to 0, and see which copy gives Table 1, Table S2, Table S3 and the
  time-moving slots of the Results.

### 2026-11-25 (evening) — Stage 1 written; the authors' dataset is public
- Done: PDF filed (renamed, hashed), full text extracted, figure rasters in `paper/figures/` (all
  local, not committed). The paper cites a public dataset (Zenodo, CC BY 4.0): downloaded to
  `data/raw/authors/` with `RECEIVED_LOG.md`, md5 verified. `data/raw/` (Table 1, text numbers,
  the pairwise differences reported as significant) with `EXTRACTION_LOG.md`;
  `notes/01_reading_notes.md`, `notes/02_methods_inventory.md` (protocol 0.4),
  `notes/03_concerns.md` (21 entries, mirrored in `registry/issues.csv`: 9 major, 12 minor, none
  critical); `R/02_consistency_checks.R` (blocks A–H: Table 1 P values, sequence counts and
  missing values, units, dates, the design as the data show it, number of pairwise tests, raw
  medians by cell and block of hours; no model fitted). A scratch copy was run by Claude with
  outputs in the scratchpad only; the numbers in the notes come from it and Alberto's run is the
  reference. `correspondence/contacts.md` and a draft letter
  (`2026-11-25_notice_and_questions_DRAFT.md`). Registry status `inventory`.
- Main points: (1) every run starts at 15:30, so time of day and time since exposure are one
  variable, and the claim that the response "occurred earlier" in dark water cannot be told from
  "sooner after exposure"; (2) that claim is read off the positions of P < 0.05 among about 200
  slot-wise comparisons per response; (3) the 72 sequences with zero distance are coded as missing
  for time spent moving and drop out of that analysis (110 missing against 39 reported); (4) time
  as a 22-level factor with a random intercept only; (5) no effect estimate anywhere. The raw data
  do show a large cue effect in dark water in the first six hours (median distance 21 against
  1,415) and none in clear water in the same hours (423 against 363).
- Decided (and why): because the data are public the letter is a notice of the commentary with
  questions, not a data request; the three-week clock still starts when it is sent. Provisional
  verdict `major concerns`. The article's copyright line reserves text and data mining; the review
  uses the full text for criticism and quotation only and nothing of it is redistributed (Alberto
  to judge whether more caution is needed).
- Open questions: Alberto has not read the paper yet: every concern is a draft for his reading.
  The supplement (Tables S1–S3, Fig. S1–S2, the R script) is not in `paper/` yet; with the script,
  stage 2 can refit the authors' models exactly. Family of the Tukey adjustment; definition of
  "moving"; number of perch.
- Next step: Alberto runs `Rscript AnimBehav_humic_acid_newt_predator_cues_Secondi_2026/R/02_consistency_checks.R`,
  renders `review.qmd` once, downloads the supplement into `paper/`, reads the paper and the
  concerns, then sends the letter. Commit. Stage 2 in a fresh conversation: refit the described
  models on the dataset (glmmTMB, as in the script), reproduce Table 1 and the asterisks, residual
  autocorrelation, the time-moving model with the zeros restored.

### 2026-11-25
- Done: second paper of the `systematic` track, first under selection v0.3. Journal drawn at
  random among the ten ethology journals (Animal Behaviour), frame of 11 articles of October 2026
  from OpenAlex (`registry/batches/B02_*`), rank 1 screened eligible on the title; folder
  scaffolded from the template; registry row P003 (status `reading`); `registry/batches.csv` row
  B02.
- Decided (and why): eligibility on the title only (no abstract indexed), as for B01; closed
  access is not a reason to skip (selection v0.3, Access); the copyrighted PDF and full text stay
  out of the public repository, unlike the two CC-licensed Scientific Reports papers.
- Open questions: version, data availability statement, design, sample sizes, models: all from
  the PDF. (Alberto confirmed on 2026-11-25 that no author is known to him.)
- Next step: Alberto saves the PDF and any supplement in `paper/` (names in `paper/README.md`);
  then stage 1: full text extraction and hashes, `notes/01_reading_notes.md`,
  `notes/02_methods_inventory.md` (protocol 0.4), numbers to `data/raw/` with
  `EXTRACTION_LOG.md`, `R/02_consistency_checks.R`, `notes/03_concerns.md`, contacts and the
  data request.
