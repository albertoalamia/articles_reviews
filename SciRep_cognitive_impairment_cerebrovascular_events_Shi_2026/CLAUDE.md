# Sci Rep — Baseline cognitive impairment and cerebrovascular events in stroke-free adults (Shi 2026)

Article-specific context for Claude Code. Repo-wide rules are in the root `CLAUDE.md`.

## Paper

- Citation: Shi Z., Wang A., Meng X., Tian X., Sun Y., Li J., Zhang X., Han X. (2026). Baseline
  cognitive impairment predicts cerebrovascular events in stroke-free chinese adults. *Scientific
  Reports*. Received 21 Jul 2026, accepted 26 Oct 2026, online 29 Oct 2026 (Article in Press).
  Kaifeng Central Hospital and Beijing Tiantan Hospital (APAC study). Corresponding author
  Xinsheng Han (address in `correspondence/contacts.md`).
- DOI: 10.1038/s41598-026-78298-4
- Version reviewed: Article in Press, the typeset accepted manuscript (9 pages, PDF dated
  2026-10-29, sha256 78b36511…783b); CC BY-NC-ND 4.0. The version of record will replace it.
- Track: `systematic` — source: batch B01 (selection v0.2; Scientific Reports, October 2026,
  OpenAlex subfield Psychiatry and Mental health, seed 20261120, rank 1 of 30, eligible on the title).
- Field: psychiatry
- Registry id: P002 — protocol version: 0.3 (stages run under 0.1; 0.2 of 2026-11-21 adds G7 and the
  H2 quality table and H3 estimates table; 0.3 of 2026-11-22 adds H4, the models written out;
  both applied before publication)
- Data availability as stated: "not publicly available due to privacy or ethical restrictions, but
  are available from the corresponding author on reasonable request"; no code; SAS 9.4.
- What the paper claims (in the authors' terms): baseline cognitive impairment (MMSE < 24)
  "independently forecasted the occurrence of ischemic stroke (aHR = 2.55, 95% CI 1.33–4.87) and
  any stroke (aHR = 2.32, 1.24–4.36), but not all-cause mortality (aHR = 1.79, 0.96–3.36)" over a
  median 4.1 years in 3,875 stroke-free Chinese adults aged 40+; therefore "cognitive screening
  could be valuable for identifying stroke-free adults who are at a greater risk".

## Design in one paragraph

Secondary analysis of the APAC community cohort (Beijing Tiantan / Kailuan): 5,440 adults aged
≥ 40 free of CVD, TIA and stroke at the 2010/2011 baseline (risk factors, transcranial Doppler,
carotid duplex). MMSE administered once at the first follow-up visit in 2012/2013; 1,512 without
MMSE and 53 with stroke/CVD before that visit excluded; 3,875 analysed, 192 (5.0 %) with MMSE < 24.
Follow-up by two-yearly visits, death certificates and hospital records until 2015-12-31.
Outcomes: first ischaemic stroke, any stroke, all-cause death (81, 90, 86 events; 15 of each in
the impaired group). Cox models: unadjusted; Model 1 age, gender, education; Model 2 adds
homocysteine, ICAS, hypertension, occupation (covariates chosen by "established association" and
Table 1 imbalance). Kaplan–Meier curves with log-rank tests (Fig. 2). Time origin, age functional
form and handling of death as a competing event not stated.

## Files

- `paper/` — PDF(s), supplementary material, authors' code if any. Read-only.
- `notes/01_reading_notes.md` — section-by-section notes with page references.
- `notes/02_methods_inventory.md` — protocol checklist A–G filled in.
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

### 2026-11-20
- Done: first paper of the `systematic` track. Selection rule fixed (protocol/selection.md v0.2,
  50 % cap on `selected`), frame of 30 drawn from OpenAlex with `tools/sample_frame.py`
  (registry/batches/B01_*), rank 1 screened eligible on the title (no abstract indexed); folder
  scaffolded from the template; registry row P002 (status `reading`).
- Decided (and why): eligibility judged on the title only, the rule allows it and no exclusion
  reason applied; the paper is cognitive epidemiology rather than core psychiatry, kept because the
  field is defined by the frame, not by topic taste (noted for the next batch's filter).
- Open questions: full author list, affiliations and data availability (from the PDF); whether the
  version online is the version of record; design (cohort? registry? n, follow-up, outcome
  definition, model).
- Next step: Alberto files the PDF in `paper/` (https://www.nature.com/articles/s41598-026-78298-4.pdf)
  and any supplement; then stage 1: `notes/01_reading_notes.md`, `notes/02_methods_inventory.md`,
  transcription of every reported number to `data/raw/` with `EXTRACTION_LOG.md`,
  `R/02_consistency_checks.R`, `notes/03_concerns.md`, data request to the corresponding author.

### 2026-11-20 (evening) — Stage 1 written, checks run, supplement read
- Done: PDF and supplement (docx, Table S1) filed and hashed; `paper/Shi_2026_fulltext.txt`;
  `data/raw/` (Table 1, Table 2, Table S1, Fig. 2 numbers at risk and curve features, text
  numbers, two rasters) with `EXTRACTION_LOG.md`; `notes/01_reading_notes.md`,
  `notes/02_methods_inventory.md`, `notes/03_concerns.md` (18 entries, mirrored in
  `registry/issues.csv`); `R/02_consistency_checks.R` blocks A–H run once by Alberto (outputs in
  `output/tables/`), block H then rewritten around Table S1 and to be rerun;
  data request sent by Alberto 2026-11-20 23:19 (`correspondence/2026-11-20_data_request_SENT.md`,
  logged in `contacts.md`; reply window to 2026-12-11); registry status `inventory`,
  authors_contacted filled.
- Decided (and why): Fig. 2 graded `major` not `critical` because the HRs in Table 2 are
  arithmetically coherent with the event counts (CI widths match 1/15 + 1/d) and do not depend on
  the figure; the timeline contradiction graded `major confirmed` with its resolution `needs-data`;
  the manual-worker row re-read after S1: the p of 0.0005 is probably computed on the ~2,740 with
  occupation data while the percentages use 3683 and 192, so the finding is "percentages and p from
  different denominators, 29 % missing never disclosed, Model 2 on an undisclosed subset"
  (CON-STAT kept, new MEA-MISSING confirmed); provisional verdict `major concerns`. Alberto's
  reading (2026-11-20): the KM curves look odd, 15 exposed events are too few for the HR precision
  claimed and for any PH assessment, Cox has its own limits, and Table 1 p-values test no
  hypothesis and should not have been used to pick covariates; all four are in `03_concerns.md`.
- Open questions: time origin of the follow-up (2010/2011 baseline or 2012/2013 MMSE visit);
  which visit supplies the covariates; what dataset Fig. 2 was drawn from; why at least half of the
  deaths must fall after year 4 given the numbers at risk; n and events in Model 2; reasons for
  missing MMSE and occupation.
- Next step: Alberto reruns `Rscript SciRep_cognitive_impairment_cerebrovascular_events_Shi_2026/R/02_consistency_checks.R`
  in the nix shell (block H now reads `suppl_table_s1.csv`); Claude checks the H rows; commit.
  If the authors reply, ask for n and events per model (the request went out before S1 was read,
  so it names the 51.9 % vs 73.3 % discrepancy only indirectly through the P = 0.0005). Then stage 2:
  reconstruct the Cox and Kaplan–Meier results from Table 2 and the numbers at risk while waiting
  for data.

### 2026-11-21 — Protocol v0.2 applied
- Done: `review.qmd` gains the quality table chunk (H2) and the "What the estimates mean" section
  (H3) with the left half fixed from the paper (cause-specific HR conditional on seven covariates
  in an unsized complete-case subset, read by the Discussion as "2.32 to 2.55 times higher risk");
  params protocol_version 0.2; registry 0.2; inventory G7 and H1–H3 filled; G7 note added to the
  screening concern.
- Decided (and why): v0.2 applied at stage 1 since nothing is published; the right half of the H3
  table waits for the stage 3–4 estimands.
- Open questions: as in the previous entry.
- Next step: Alberto renders `review.qmd` once so the freeze matches; stage 2 in a fresh
  conversation (reconstruction from Table 2 and the numbers at risk; H3 right half defined in
  `notes/04_analysis_plan.md` with an interpretation sentence per estimand).

### 2026-11-21 (evening) — Stage 2 run: reconstruction, reproduction, Model 1 calibration
- Done: `R/01_prepare_data.R` rebuilds 3,875 persons from Table 2 and the Fig. 2 numbers at risk
  under three timing scenarios (log `data/derived/RECONSTRUCTION_LOG.md`, assumptions A1–A6,
  results §4); `R/04_reproduce_cox_km.R` refits the unadjusted Cox, log-rank, 1 − KM and
  Aalen–Johansen curves and interval rates; `R/05_model1_age_confounding.R` calibrates an
  exponential model to the Table 2 counts and asks what age effect reproduces Model 1. Run three
  times by Alberto (two reconstruction bugs fixed: tail events censored before they happened;
  survivors censored before the tail events in the deterministic scenarios). Outputs
  `output/tables/stage2_*.csv`, two figures. Concerns, registry notes and status `reanalysis`
  updated; no evidence tag changed.
- Results in one line each: the three unadjusted HRs, CIs and log-rank p reproduce to the second
  decimal; the curves the numbers imply end at 8 % (CI) and 2 % (NCI) against the 100 % and
  0.45–0.70 drawn; two thirds of the exposed strokes and 60 % of the exposed deaths are forced
  into the last 0.2 years (rates 28–85 times those before); Model 1 is reproduced only if age
  multiplies the stroke hazard by ~1.5–1.7 per decade, and with a doubling per decade the
  adjusted HR would be 1.6–1.8 with a CI including 1.
- Decided (and why): the age distribution above the Table 1 quartiles is an explicit assumption
  (A6, log-normal truncated at 90, sensitivity 80–100) because an untruncated log-normal with
  that spread produces ages above 200 and made the first run meaningless; the figure is drawn
  from the deterministic scenario so that nothing in it is random; the KM value at the axis end
  under uniform timing (0.26) is reported as an artefact of A3–A4, not as a finding.
- Open questions: as before, plus whether the authors' Model 1 used age linear, categorical or as
  time scale (determines whether the calibration applies).
- Next step: stage 3 in a fresh conversation: `notes/04_analysis_plan.md` with estimands and an
  interpretation sentence each (cumulative incidence with death competing by group; exposure HR
  as a function of the age effect, with the age effect as a parameter; added value of MMSE over
  age for screening in the calibrated population), then the frequentist fit and the matching Stan
  model (stage 4) sharing the same likelihood. On the authors' data, if it arrives, the plan
  switches to the measured covariates and the continuous MMSE.

### 2026-11-22 — Stage 3 plan drafted; protocol v0.3 (the models written out)
- Done: `notes/04_analysis_plan.md` v1.0 (E1 piecewise-exponential competing risks on the
  reconstructed life table; E2 exposure HR as a function of the age effect, profiled in stage 3
  and under three priors in stage 4; E3 age-equivalent, c-index gain, screening metrics vs an age
  rule; section 8 steps S1–S5) with section 3b: the paper's Cox model and KM in notation, the
  p-value table, the re-analysis models, the parameter table, the causal diagram as dagitty code
  with every edge sourced (P/D/A/H) and the adjustment-set reading, the plate diagrams to draw in
  S3. Protocol v0.3 (checklist H4) applied: `review.qmd` gains "The models, written out" with
  the equations, the p-value table and the DAG chunk (adjustment sets computed in the chunk);
  params and registry 0.3. `lib/plate_diagram.R` added for the stage 4 figures; `shell.nix` gains
  dagitty and ggdag.
- Decided (and why): the DAG carries U (subclinical cerebrovascular disease) as an explicit
  assumed node because it separates the paper's prediction wording, which survives it, from its
  causal wording, which does not; the prior P2 reference for the age effect is left for Alberto
  to choose before stage 5.
- Open questions: as before; Alberto's reading of the plan (estimands, priors, the DAG edges).
- Next step: Alberto enters the rebuilt shell, runs the tests, previews the review (DAG renders,
  adjustment sets print), reads the plan; commit; then S1 of the plan.
