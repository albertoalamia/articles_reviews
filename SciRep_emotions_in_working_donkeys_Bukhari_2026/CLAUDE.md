# Sci Rep — HRV, eye temperature and blink rate as measures of emotion in working donkeys (Bukhari 2026)

Article-specific context for Claude Code. Repo-wide rules are in the root `CLAUDE.md`.

## Paper

- Citation: Bukhari S.S.U.H., McElligott A.G., Steagall P.V., Parkes R.S.V. (2026). Heart rate
  variability, eye temperature, and spontaneous blink rates as measures of emotions in working
  donkeys. *Scientific Reports*. Received 16 Dec 2025, accepted 14 Jul 2026, online 22 Jul 2026.
- DOI: 10.1038/s41598-026-62753-3
- Version reviewed: unedited accepted manuscript ("Article in Press"), CC BY-NC-ND 4.0.
  Check later whether the version of record and Transparent Peer Review reports are out.
- Track: `selected` — source: own interest (Alberto works on donkey-assisted therapy).
- Field: ethology
- Registry id: P001 — protocol version: 0.1
- Data availability as stated: "on request".
- What the paper claims: three physiological measures (RMSSD, eye temperature, spontaneous blink
  rate) discriminate positive and negative emotional states induced in working donkeys, and the
  blink rate is proposed as a simple field indicator of valence.

## Design in one paragraph

Within-subject crossover, n = 34 working donkeys, three conditions in one session: control,
positive (lucerne in a bucket), negative (clipper). 3-min windows, 1-h washout, order as a fixed
effect. Outcomes: SBR (count), eye temperature (IR thermography), RMSSD (ultra-short HRV).
Analysis as described: linear mixed models on condition means; "change" scores defined as
control minus treatment; regressions of ΔRMSSD on ΔSBR and ΔET. Power analysis based on a
correlation with ρ = 0.5.

## Files

See `_template/CLAUDE.md` for the folder convention. Specific to this paper:

- `notes/00_first_pass_claude_ai_2026-10-25.md` — Alberto's first-pass critique produced in a
  claude.ai conversation, plus notes on publication status and on the metascience landscape.
  Source of the initial concerns list; every item still has to be re-verified against the PDF.
- `paper/Bukhari_2026_SciRep_s41598-026-62753-3_accepted_manuscript.pdf`

## STATUS

### 2026-10-25
- Done: repo pushed to GitHub and site live at albertoalamia.github.io/articles_reviews/ (this review is a blank draft page there); folder scaffolded from template; paper and first-pass critique filed; registry row P001
  created (status `reading`); `notes/03_concerns.md` seeded from the first pass.
- Decided: first author is Bukhari (Syed is a given name), folder renamed accordingly.
- Open questions: is the version of record out, with reviewer reports? Can the per-condition
  numbers in Table 2 / Figs 2–4 be extracted precisely enough for a re-analysis on summary data?
- Next step: Phase 1 — read the PDF in full, fill `notes/01_reading_notes.md` and
  `notes/02_methods_inventory.md`, re-verify each seeded concern, extract Table 2 into
  `data/raw/` with an extraction log, and run `R/02_consistency_checks.R`.

### 2026-10-31 — Phase 1 complete (commits a601ecc … 77a2059)
- Done: full reading notes (6 sections, verbatim quotes, 590 lines); methods inventory A–H;
  27 concerns re-verified with evidence tags, 31 rows in `registry/issues.csv` (6 critical, 15
  major, 10 minor); all reported numbers transcribed to `data/raw/*.csv` with
  `EXTRACTION_LOG.md`; native figure rasters saved with hashes; `R/02_consistency_checks.R`
  written and run from nvim, outputs in `output/tables/consistency_*.csv`.
- Key findings, all reproduced by the script: (1) all six Δ printed positive although defined as
  control − treatment, five magnitudes outside the rounding range of the means (RMSSD positive
  37.73 vs 32.97) — everything fits Δ = |control − treatment|, inferred; (2) the two exact
  p-values (0.002, 0.005) inconsistent with paired t of 16.7 and 13.8, and the larger t has the
  larger p; (3) Discussion says RMSSD fell under the clipper, Results show +10.7 ms, p < 0.001;
  (4) positive vs negative never tested for any outcome; (5) no manipulation check and the
  positive stimulus is eating; (6) SBR is an integer count (Fig. 1) and the mean 12.20 is
  unattainable with n = 34; age 6.05 unattainable at whole- or half-year resolution.
- Decided: n = 34 assumed in every check and stated in an `assumption` column; power
  derivation identified (point-biserial correlation, one-sided) so DES-POWER is about relevance,
  not reproducibility; Figs 3–4 contain all 68 Δ points per figure, digitisation postponed to
  stage 2; taxonomy codes used in the inventory/concerns/registry, ad hoc codes in the reading
  notes mapped there; provisional verdict "conclusions not supported" for the HRV/ET valence
  claims, "major concerns" overall, Alberto to decide after stages 2–4.
- Open questions: authors' reply (data request sent 2026-10-25, follow-up due 2026-11-15); n per
  cell and exclusions; how the eye was imaged during feeding; signed per-donkey Δ; version of
  record and reviewer reports; whether to digitise Figs 3–4 before or after 2026-11-15; apply
  the 5-stage workflow text and the right-of-reply amendment to the root `CLAUDE.md` (pending
  Alberto's decision).
- Next step: Stage 2 — reproduce the authors' analysis. (a) If data arrive: `R/01_prepare_data.R`
  → JSON, refit the six condition LMMs and Tables 3–4 as described. (b) Otherwise: digitise
  Figs 3–4 (68 points each, match by ΔRMSSD and colour) into `data/derived/` with a log,
  refit Tables 3–4 on the digitised Δ, test the absolute-value hypothesis; simulate paired
  condition data from Table 2 means/SDs and the implied correlations (0.62–0.94) for the
  condition contrasts. Then write `notes/04_analysis_plan.md` for stages 3–4 (GLMM for SBR,
  log-normal/Gamma for RMSSD, three-level condition factor, positive − negative contrast,
  order; identical structure in Stan).
