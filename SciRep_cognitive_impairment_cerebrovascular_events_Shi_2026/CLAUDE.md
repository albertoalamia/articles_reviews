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
- Registry id: P002 — protocol version: 0.4 (0.4 of 2026-11-23 adds B10–B13 and four design codes for
  observational studies, three issues recoded; stages run under 0.1; 0.2 of 2026-11-21 adds G7 and the
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
- `run_model.sh` — compiles with CmdStan and samples; draws go to `$FITS_DIR/<this dir>/<model>/`.
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
- Later the same day: the DAG of protocol H4e is the graph of the Bayesian model (Levy–Mislevy
  convention, `lib/model_dag.R`), not a causal diagram; the two planned programs are drawn that
  way in the review from plan §3 and §5 (to be redrawn from the programs in S3); the causal
  structure stays as dagitty code in §3b.4 and is computed, not drawn, in the review.
- Next step: Alberto runs the tests and renders; commit; then S1 of the plan.

### 2026-11-22 (evening) — Skills; P2 confirmed; S1 of the stage 3 plan prepared
- Done: repo skills `dagify`, `render-check`, `new-review` and `tools/stan_to_dag.R` (committed).
  Alberto read the plan and confirmed P2 = LogNormal(log 2, 0.15) (plan §5; reference to quote at
  stage 5). S1 written: `R/lib_population.R` (A6 population code moved verbatim out of `R/05`,
  which now sources it), S1 block at the end of `R/01_prepare_data.R` writing
  `data/derived/pem_counts.csv`, `calibrated_population.csv` and nine JSON files in
  `data/derived/stan_data/`; `RECONSTRUCTION_LOG.md` §5; plan §7 records the file layout. A scratch
  copy of the block run by Claude on the committed reconstruction (outputs in the scratchpad only):
  events match Table 2 in all 28 scenario × model × group blocks; tail person-years 359 (uniform),
  709 (early), 723 (late) in the NCI group, isch model.
  On Alberto's question about censoring: the life table has no censoring before year 4 (A1, A4),
  which the paper's own design implies (non-attenders followed through records, nobody censored);
  a new concern "Loss to follow-up not reported; follow-up treated as complete through records"
  (REP-GUIDE, major, confirmed) added to `03_concerns.md`, `registry/issues.csv` (19 entries now),
  inventory B8 and F1, log §5. The quality table in `review.qmd` picks it up at the next render.
- Decided (and why): one exposure JSON per outcome with the ages at all three ceilings and an
  `age_max` switch, so the population is not written three times per outcome; ages to 3 decimals so
  that stages 3 and 4 read the same numbers; the E1 wide prior is a `beta_sd` key. The new concern
  is graded major because the exposed count (15) is sensitive to a few missed non-fatal strokes and
  the direction of the bias is not knowable from the paper; `confirmed` because the omission and
  the numbers at risk are the paper's own; the ascertainment argument is stated as a consequence.
- Open questions: as before.
- S1 run by Alberto and committed (recon_* and stage2_* unchanged; 9 JSON files; events match
  Table 2 in all 28 blocks). S2 prepared: `R/06_fit_frequentist.R` (E1 two models × three scenarios
  with 10,000-draw bootstrap, E1b vs stage 2 Cox and Table 2, E1c crude tail ratios and the group HR
  split at year 4, E2 profiled over θ_age ∈ {1, 1.25, 1.5, 1.75, 2, 2.5, implied} at three ceilings
  with profile-likelihood intervals, E3 age-equivalent, expected c-index and screening metrics for
  three flag rules, four checks of plan §8, two figures). Parse-checked only: the permission layer
  does not let Claude execute analysis scripts, so the first run is Alberto's.
- First run of `R/06` by Alberto: a bug in E2 (the per-decade age effect divided by 10 a second
  time, so the adjustment barely acted and HR(θ_implied) was 4.1, not 2.47) found by check 4 and
  fixed; two tolerances revised (plan §7); E1 gains the split-at-year-4 structure next to the
  proportional one, because the proportional model gives the exposed group 4.3 % by year 4 against
  2.6 % observed; the 4.2-year risks and the figure now come from the early scenario (plan §7).
  Confirmed by that run: E1b HRs 4.52 / 3.96 / 4.21 within 1–3 % of Table 2; tail rates 28–85 times
  the first four years; group HR for stroke 2.5 (0.99–6.4) before year 4 and 7.5 (3.6–15.5) after.
  Agreed with Alberto: a latent-variable (psychometric) model of cognition measured by the MMSE is
  added to the plan as a pre-specified source-B analysis after S2 (needs item or domain scores).
- Second run: all seven checks pass; figures checked (two rows, two columns; HR on a log scale).
  Stage 3 results: E1b 4.52 / 3.96 / 4.21; stroke HR 2.5 (0.99–6.4) before year 4, 7.5 (3.6–15.5)
  after; exposed CIF by year 4 4.3 % under proportionality against 2.6 % observed; 4.2-year risk
  8.1 vs 1.8 per 100 (RD 6, 3–12); E2 ischaemic stroke 4.4 → 2.47 (θ 1.56) → 1.84 (0.98–3.27, θ 2)
  → 1.47 (θ 2.5); death crosses 1 at θ 2; E3 at θ 2: 9 years of age (0.4–17), c 0.74 → 0.74
  (+0.003), "age ≥ 65" catches 53 % of future strokes vs 19 % for MMSE < 24. Committed as S2.
  Plan addition after S2: §1 E5 and §3c, cognition as a latent variable (GRM with education in the
  item locations, structural part, PEM outcome), source B only; §7 row; contacts.md notes the data
  to ask for if the authors engage.
- Next step: S3 in a fresh conversation: `stan/pem_competing.stan`, `stan/exposure_age.stan`,
  `run_model.sh` (switches prior_only, beta_sd, prior, age_max), prior-predictive section of
  `R/03_postprocess.R`, DAGs redrawn from the programs (dagify skill), review chunk updated.

### 2026-11-22 (night) — S3 of the plan prepared: the two Stan programs, the runner, the prior-predictive script
- Done: `stan/pem_competing.stan` (E1, E1b, E1c; switches `prior_only`, `beta_sd`, `split`) and
  `stan/exposure_age.stan` (E2, E3; switches `prior_only`, `prior`, `age_max`; the expected c-index
  and the screening metrics of `R/06` as generated quantities), both accepted by `stanc`
  (syntax and types only; not compiled, not sampled). `run_model.sh` rewritten from P001's
  (`--prior-only`, `--beta-sd`, `--split`, `--prior P1|P2|P3`, `--age-max`; draws in
  `$FITS_DIR/<article>/<model>/`, suffix scheme and seeds in its header; chain output to a log
  file per chain). `R/03_postprocess.R --prior`: prior predictive of the cell counts, cumulative
  incidences, HRs and tail ratios against the life table and Table 2, sampler diagnostics of the
  prior runs, and mapping checks (CIF, tail ratio, E, c-index, screening metrics recomputed in R
  from the parameter draws, tolerance 1e-4); parse-checked, helpers tried on synthetic draws.
  `R/01_prepare_data.R` writes a `split` key in the six `pem_*.json`. DAGs redrawn from the
  programs (12 and 17 nodes; scratch drawings checked for layout) in the `review.qmd` chunk;
  plan §3b.5, §7 (S3 row) and §8 (S3 row) updated.
- Decided (and why): the split-at-year-4 structure is a switch of the same program, because
  stage 3 reports E1 from both structures (plan §7, S2) and the side-by-side table needs both;
  the exposure prior runs use one outcome file, the prior being the same for the three; μ and
  the 4.2-year risk share one node in the DAG (same hazard, two horizons).
- Open questions: as before. To watch in the prior predictive: the tail cells of the exposed
  group (10 strokes and 9 deaths in 17.8 person-years, a rate about 100 times the prior median
  of α) may fall outside the prior 95 %; if so it is the tail anomaly of E1c showing up against a
  prior written for ordinary rates, and Alberto decides whether the α prior stays as planned.
  `R/06_fit_frequentist.R` and the `stage3_*` outputs were still untracked at the start of this
  session although S2 is recorded as committed: they go in the S3 commit.
- Next step: Alberto runs, from the repo root in the nix shell: `Rscript <art>/R/01_prepare_data.R`
  (only the six `pem_*.json` should change); the five prior runs (plan §8, S3 row);
  `Rscript <art>/R/03_postprocess.R --prior`. Claude checks the three tables and two figures;
  render `review.qmd` (render-check skill); commit. Then S4: `run_all.sh` and the main section of
  `R/03_postprocess.R`.
- S3 run by Alberto (2026-11-22): `R/01` changed only the six `pem_*.json`; both programs compile;
  the five prior runs pass the §5 thresholds (R-hat 1.00, ESS > 1,600, no divergences); the 16
  mapping checks are below 3e-6 against a tolerance of 1e-4 (one bug fixed in the `convergence()`
  helper of `R/03`: a column named `run` masked the run object). Prior predictive: 51 of 58 cell
  and group counts within the prior 95 %. Outside: the six tail cells with 9–41 events (all but the
  27 strokes of the unexposed) and the unexposed (0, 1] cell of ischaemic stroke (0 events where
  the prior median is 18); the four crude tail ratios (23–85) lie above the prior 95 % (upper limit
  13–16). Cumulative incidences at 4.2 years: prior 95 % 0.3–43 %, crude values at percentiles
  0.16–0.70. The exposure priors cover the two counts of the three outcomes (percentiles 0.33–0.63).
- Open for Alberto: whether the α prior stays as planned given the tail cells (Claude's proposal:
  keep it; the cells have 9–41 events against a prior SD of 1.5, and the comparison with stage 3
  shows any shrinkage). Expected in S4: under `--split` the tail group effect rests on 10 exposed
  events, so Normal(0, 1) will pull the stage 3 HR of 7.5 towards about 6; the `--beta-sd 2` run
  measures that.

### 2026-11-22 (late) — S3 committed; α prior kept; S4 prepared
- Done: S3 committed by Alberto (`e5e791f`, render checked: draft page, two DAG files in the
  freeze, no stale files). S4 written: `run_all.sh` (29 runs through `run_model.sh`, resumable,
  `--dry-run`) and the main section of `R/03_postprocess.R` (no argument): `stage4_convergence.csv`,
  `stage4_ppc.csv`, `stage4_estimates.csv`, `stage4_side_by_side.csv` (paper, stage 2, stage 3 and
  stage 4 per estimand, joined on model, scenario, structure, prior, ceiling and term),
  `stage4_ppc_pem.png`, `stage4_hr_by_prior.png`. A scratch copy of the main section was run by
  Claude on the five prior-only runs (outputs in the scratchpad only): it runs end to end and the
  stage 3 and paper columns land on the right rows; the split runs and the 80/100 ceilings were
  not exercised.
- Decided (and why): the α prior stays as planned (Alberto; plan §7): written before the data,
  not to be tuned to the tail anomaly. One run per outcome added, `--split --beta-sd 2`, to
  measure the shrinkage of the tail group effect. P1 is read beside the stage 3 profile at the
  implied θ_age and P2 beside θ_age = 2; P3 has no stage 3 counterpart.
- Open, cosmetic: the two-line DAG labels (RD/RR, c/sens, μ/r) overflow their nodes slightly; to
  fix when the section is rewritten in S5.
- Next step: Alberto runs `./<art>/run_all.sh` then `Rscript <art>/R/03_postprocess.R`; Claude
  checks the four tables and two figures against plan §6; commit. Then S5: H3 right half and the
  results sections of `review.qmd`, the P2 literature reference, registry status.

### 2026-11-23 — S4 run: 29 posterior runs, side-by-side table
- Done: Alberto ran `run_all.sh` (29 of 29) and `R/03_postprocess.R`. All runs pass the §5 thresholds
  (R-hat ≤ 1.01, ESS ≥ 920, no divergences, E-BFMI ≥ 0.86); 310 of 310 posterior predictive counts
  within the 95 %; both figures checked.
- Results: E1b HR 3.9 / 3.5 / 3.7 (isch / any / death), 12–14 % below stage 3 under Normal(0, 1),
  5–7 % below under Normal(0, 2). Split at year 4, ischaemic stroke: 1.9 (0.71–4.3) before,
  5.9 (2.7–12) after (stage 3: 2.5, 7.5); with SD 2: 2.2 and 7.1. E2 ischaemic stroke: P1 2.25
  (1.17–3.96), P2 1.68 (0.85–3.30), P3 1.93 (0.83–4.55); all three outcomes include 1 under P2 and
  P3, none under P1. E3 under P2: age-equivalent 6–7 years with intervals from below 0 to 21–24; c gain 0.001–0.002.
- Decided (and why): the P1 counterpart for death is the stage 3 grid point 1.5, not the implied
  1.88 (plan §7); the E1 shrinkage is larger than the "few percent" of §6 and is logged, prior kept.
- Open for S5: P1 is not "as Model 1 implies" for death (implied 1.88): say so, or read death under
  P2 only. The proportional-model tail ratio is common to both groups by construction, so its
  stage 3 column (crude, by group) is comparable only in the split runs. The P3 age-equivalent has
  an upper limit above 200 years (θ_age near 1): report the median and the share above 10 years.
- Next step: Alberto reruns `Rscript <art>/R/03_postprocess.R` (pairing fix; only the stage 3
  columns of the death P1 rows and the grey P1 point of the death panel change), commit; then S5.

### 2026-11-23 (later) — S4 committed; S5 written: re-analysis sections of the review
- Done: S4 committed (`19ee88b`). `review.qmd`: header callout; Re-analysis (data, stage 2, E1 hazard
  ratios, split at year 4, tail rates, cumulative incidences, E2 by prior, E3; seven tables, three
  figures, six evidence boxes, all numbers inline from `output/tables/`); "What this review fits"
  (equations, priors, limitations) and "Parameters side by side"; "What the estimates mean" (five
  rows); Right of reply; Reproducibility. Two-line DAG labels reduced so that they stay inside the
  nodes. `R/03_postprocess.R`: x label of `stage4_hr_by_prior.png` no longer says "P1 as Model 1
  implies". `references.bib`: Kelly-Hayes 2010 for P2. A scratch run of every chunk and inline
  expression by Claude (tables printed to the terminal only, system R): no error, no missing value.
- Decided (and why): absolute risks are quoted from the early-scenario split-at-year-4 run, because
  it is the structure that reproduces both the year-4 and the 4.2-year crude proportions (plan §7,
  S2); the death row under P1 is kept in the tables and labelled as not corresponding to Model 1;
  the P3 age-equivalent is shown with a sentence on why its upper limit is not interpretable.
  Registry status stays `reanalysis`: the stage 1 sections of the review are not drafted yet.
- Open: Alberto checks the Kelly-Hayes wording against the full text (the search excerpt says
  "after the age of 45"); Summary and verdict, What the paper does, Design, Measurement, Model
  adequacy, Internal consistency, Reporting, Do the conclusions follow, What would settle the open
  points and Minor are still the template text (stage 5 proper, from `notes/01`–`03` and the
  consistency tables); the primer.
- Next step: Alberto reruns `Rscript <art>/R/03_postprocess.R` (figure label), renders
  `review.qmd`; Claude checks the render (render-check skill); commit. Then the stage 1 sections.

### 2026-11-23 (evening) — S5 committed; stage 1 sections of the review drafted
- Done: S5 committed (`ed4a3d7`, render checked). `review.qmd` now has every section: Summary and
  verdict, What the paper does (the paper's Table 2), Design (time origin, two "baselines",
  exclusion for missing MMSE, loss to follow-up), Measurement (cut-off and schooling, occupation
  missing for about 29 %, outcome ascertainment), Model adequacy (age and schooling, death as
  censoring, 15 exposed events, covariates chosen by p-values), Internal consistency (what is
  consistent; Figure 2 against Table 2; numbers at risk against event counts; Table 1 and S1),
  Reporting, Do the conclusions follow, What would settle the open points, Minor. Four new tables;
  evidence boxes carry the tags of `notes/03_concerns.md` unchanged. One setup chunk at the top
  reads all raw, consistency and stage 2–4 tables. Scratch run of all chunks and inline expressions
  by Claude: no error, no missing value (two table bugs found and fixed that way). Registry status
  `draft`.
- Decided (and why): verdict drafted as "major concerns", with "not supported" for the screening
  recommendation only: the registry rule gives major concerns (no critical issue) and the screening
  claim is the one the paper's own counts contradict. It is Alberto's decision; the registry
  `verdict` cell is left empty until he confirms.
- Open: Alberto confirms or rewords the verdict; Kelly-Hayes wording to check against the full
  text; the plain-language primer; the full text goes to the authors only if they engage (right of
  reply), otherwise publication on or after 2026-12-11.
- Next step: Alberto renders `review.qmd`; render-check; commit. Then the primer.

### 2026-11-23 (night) — Protocol 0.4: design codes for observational studies
- Done: render of the full draft checked (clean). Alberto noticed that the quality table showed no
  design issue while the Design section discusses four. Cause: the taxonomy's design codes covered
  experiments only. Protocol 0.4: checklist B10–B13 (time origin and exposure timing, selection
  into the analysed sample, follow-up and attrition, temporal order) and codes `DES-ORIGIN`,
  `DES-SELECT`, `DES-ATTRIT`, `DES-TEMPORAL`. Three P002 issues recoded in `registry/issues.csv`
  and `notes/03_concerns.md` (follow-up timeline CON-XREF to DES-ORIGIN; exclusion for missing MMSE
  MEA-MISSING to DES-SELECT; loss to follow-up REP-GUIDE to DES-ATTRIT), severity and tags
  unchanged. Inventory B10–B13 filled; params and registry 0.4; templates updated.
- Decided (and why): applied before publication, as 0.2 and 0.3 were; it moves issues between
  domains and does not change what counts as a flaw. The two "baselines" stay MEA-COVAR (covariate
  timing). A short paragraph under the quality table names the three points discussed in one
  section and counted in another row.
- Open: as above (verdict, Kelly-Hayes wording, primer, right of reply). Outcome ascertainment
  differing by group has no code of its own (B12 mentions it); to decide when a paper needs it.
- Next step: Alberto runs `Rscript lib/tests/run_tests.R`, renders the review and `protocol.qmd`;
  render-check; commit.
