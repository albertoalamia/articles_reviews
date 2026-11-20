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
- `notes/04_analysis_plan.md` — the stage 3–4 specification (v1.1). §7 logs every deviation
  from the plan with its reason; §8 is the execution schedule S1–S10 with the exact commands.
- `run_all.sh` — the 660 stage 4 CmdStan runs (resumable, `--dry-run`, `--reruns-only`);
  `run_model.sh <model> <data.json> [switches]` for one run. Draws live under
  `$FITS_DIR/SciRep_emotions_in_working_donkeys_Bukhari_2026/<model>/`, never in this tree.
- `R/03_postprocess.R` — stage 4 post-processing: `--prior`, `--example`, `--collect`, main
  pass (side-by-side table, PPC, LOO), `--e5`.

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

### 2026-11-04 — Stage 2 complete (commits 29ea1b9 … 7a211d4)
- Done: Figures 3–4 digitised with `tools/digitise_scatter.py` (transparency-based counting of
  overlapping points) and `tools/resolve_stacks.py` (stacks under the fitted line resolved by the
  cross-figure and Table 2 constraints); all 68 + 68 change scores recovered,
  `data/derived/deltas_*.csv`, log in `DIGITISATION_LOG.md`. `R/04_reconcile_digitised.R`: every
  Table 2 Δ mean and SD reproduced to the printed digit, Table 3 to the second decimal by OLS,
  Table 4 within plotting rounding. `R/05_gof_authors_models.R`: goodness of fit of the Tables
  3–4 models. `R/06_condition_contrasts.R` + `R/lib_simulate_conditions.R`: exact
  signed-difference results for the six contrasts, enumeration of reversed-direction donkeys,
  positive-vs-negative bounds, and the described mixed model refitted on 1800 simulated complete
  datasets (3 outcomes × 3 pairing scenarios × 200), log in `SIMULATION_LOG.md`. `shell.nix`
  gained pillow/numpy/scipy and lme4/lmerTest/emmeans/glmmTMB. Concerns updated (29 entries: M15 pooled
  variance, M16 reading of the regression coefficients, added 2026-11-06), registry 33 rows,
  status `reanalysis`.
- Key findings: (1) Table 2 Δ rows are the means/SDs of the plotted unsigned values; the donkeys
  that moved against the group direction are pinned: none (SBR-pos), exactly one (SBR-neg), 2–4
  (RMSSD-pos), 1–6 (RMSSD-neg), 1–5 and 0–2 (ET). (2) With reversals accounted for, the paired t
  are 16.7 (SBR-pos) and 7.8 (RMSSD-pos) vs 3.4 and 3.0 needed for the reported p; the described
  mixed model never reproduces 0.002 or 0.005 and orders the RMSSD p-values the other way round
  (negative p 0.004–0.065 under it, not < 0.001). (3) The Tables 3–4 mean structure is adequate
  (within-treatment slopes 1.21/1.36 for ΔSBR) but the error model is not: residual SD 2.2–2.4×
  larger in the positive treatment, non-normal, negative fitted values in the ΔET model; GLS or
  Gamma better by 17–28 AICc with the same predictive error. 55 % of R² is the treatment dummy;
  the donkey random intercept is ≈ 0 (confirmed). (4) Positive vs negative differs for all three
  outcomes under any pairing (ET: p 0.009 to 0.059).
- Decided: reconstruction-based findings tagged `inferred` (assumption: n = 34 complete pairs, Δ
  per donkey on the same values as the condition means, plotting rounding of ΔRMSSD/ΔET); the
  absolute-value reading not upgraded to `confirmed` for the same reason. The RMSSD 0.005 matching
  the negative contrast under the described model is noted as an observation, not written up as a
  transposition (does not hold for SBR). Stage 3–4 outcome families: Gamma or log-normal for RMSSD
  with condition-specific dispersion; count model for SBR; Gaussian for ET; three-level condition
  factor, order, donkey intercept; positive − negative as a named contrast. The simulated example
  dataset is for developing code only; inference on the ensemble or the authors' data.
- Open questions: authors' data (request 2026-10-25, McElligott deferred to Parkes/Bukhari on
  2026-10-26, follow-up due 2026-11-15); whether the condition models were six two-level or three
  three-level fits; order as factor or numeric; version of record and reviewer reports;
  `contacts.md` summary cell for McElligott's reply still to fill by hand; whether to add Panzera
  & Statelli 2025 (PubPeer pointer filed) as a `selected` candidate.
- Next step: Stage 3 — write `notes/04_analysis_plan.md` from the template (estimands, families,
  fixed/random structure, contrasts, one row per Stan program), then fit with lme4/glmmTMB on the
  simulated ensemble (or the authors' data) and report estimates with intervals; stage 4 mirrors
  it in `stan/`.

### 2026-11-19 — Stages 3 and 4 complete (commits d552249 … d561b97)
- Done: `notes/04_analysis_plan.md` v1.1 (estimands E1–E5, families, one shared model table
  mapping each row onto a Stan program, priors, schedule S1–S10, 15 deviations logged in §7).
  S1: reconstructed ensemble, three pairing scenarios (ρ_dd = −0.5, 0, 0.5) × 200 replicates,
  30 of them written as CmdStan JSON. Stage 3 (`R/02_fit_frequentist.R`, glmmTMB): planned
  models on the 600 replicates with Rubin pooling, DHARMa diagnostics, AICc comparison set,
  E4 slopes, parametric bootstrap and leave-one-donkey-out on the example; `output/tables/stage3_*`.
  Stage 4: seven Stan programs in `stan/` (`sbr_nb2`, `sbr_poisson`, `et_mvn`, `et_normal`,
  `rmssd_lognormal_mvn`, `rmssd_gamma`, `delta_slopes`), prior predictive check, mapping check
  against glmmTMB on the example replicate (89 of 91 quantities within 1 SE), `run_all.sh` over
  660 runs (22 per replicate × 30; 7.0 GB in `$FITS_DIR`, 63 min; three SBR runs rerun at 2000
  iterations), all 660 within the §5 thresholds (max R-hat 1.0096, min ESS 594, no divergences,
  E-BFMI ≥ 0.32); `R/03_postprocess.R`: pooled posteriors, `stage4_side_by_side.csv`, posterior
  predictive checks, LOO, E5 (`stage4_e5_auc.csv`).
- Key findings (ensemble, ρ_dd = 0; the other scenarios agree to the rounding shown unless
  stated; all `inferred`, reconstruction assumptions as in stage 2): (1) Condition differences,
  stage 3 and stage 4 identical to the second digit. SBR positive − control +18.5 [15.6, 21.5]
  blinks/min, negative − control −6.5 [−8.5, −4.5], positive − negative +25.1 [22.0, 28.2]
  (ratio 3.1). ET +0.76 [0.55, 0.98] and +1.17 [0.93, 1.41] °C, positive − negative −0.41
  [−0.72, −0.10]. RMSSD +34 [21, 47] and +10.3 [6.0, 14.8] ms, positive − negative +24 [10.5,
  37] ms (ratio 1.4). The Table 2 |Δ| means are reproduced; positive vs negative, never tested
  in the paper, differs for all three outcomes. (2) E4: the common Δ-on-Δ slopes of Tables 3–4
  do not hold within treatment. ΔRMSSD on ΔSBR is +1.64 [0.35, 2.94] in the positive and −1.26
  [−2.02, −0.51] in the negative treatment (difference 2.9 [1.4, 4.4]); on ΔET −16.8 [−31.5,
  −2.2] and −7.5 [−11.2, −3.8] (difference −9.3 [−24.4, 5.8]); residual SD 3.2 × larger in the
  positive treatment. (3) E3: SBR latent ICC 0.49 [0.32, 0.66]; ET within-donkey correlations
  0.59–0.80; RMSSD 0.92 between control and negative but 0.3 between control and positive.
  (4) Stage 3 vs stage 4: the 27 E1/E2 rows differ by at most 0.07 posterior SD and lie inside
  the prior ×2 / ×0.5 bracket; posterior intervals are 1.01–1.37 × the Wald widths; the largest
  difference over 234 rows is 0.84 SD, on the ET correlations (LKJ shrinkage). Prior scale,
  Poisson vs NB2, Gamma vs log-normal and pooled σ change no conclusion. (5) The PPC recovers
  every mean and mean |Δ| but not the SBR variances nor the RMSSD positive tail; read as a
  property of the Gaussian reconstruction (`needs-data`), consistent with stage 3 AICc (the
  raw-scale Gaussian MVN best in ≥ 98 % of replicates). glmmTMB could not identify the NB2 φ on
  the reconstructed counts (Poisson fallback in 50–100 % of replicates, DHARMa dispersion ratio
  0.76–0.83); the Bayesian NB2 samples under the half-normal prior on 1/√φ and agrees with it.
  LOO is reliable for the MVN programs and E4 only. (6) E5: one SBR reading from an unknown
  donkey separates positive from negative (AUC 0.99) and positive from control (0.94), control
  from negative only moderately (0.81; best cut-off ≥ 16 blinks/min, sensitivity 0.71,
  specificity 0.75).
- Decided: plan v1.1 (ET and RMSSD as MVN with an unstructured 3 × 3 donkey covariance;
  log-normal MVN as the RMSSD Bayesian program, Gamma with condition dispersion as sensitivity);
  the family question raised by the PPC is deferred to the authors' data, planned families kept;
  the candidate Poisson–log-normal MVN SBR program is not written unless the failure reappears on
  real data; E5 extended beyond the §3 definition (different-donkey and same-donkey AUC, Youden
  threshold), logged in §7; stage 4 on 10 replicates per scenario, compared with stage 3 both on
  the same 10 (Rubin) and on 200; no draws in the project tree.
- Open questions: authors' data (Parkes, 2026-11-09: will review the data and reply; the
  acknowledgement proposed end of November 2026, more time on request). If data arrive, S1–S9
  rerun unchanged on them and the PPC decides the family question. Version of record and
  reviewer reports; Panzera & Statelli 2025 as a `selected` candidate;
  `_freeze/.../review/execute-results/html.json` is modified locally and left out of commits
  until the stage 5 render.
- Next step: Stage 5 — `review.qmd` following the template sections, with the side-by-side
  table from `stage4_side_by_side.csv`, `stage4_forest_e1_e2.png`, the PPC figures and the E5
  table; every number from the output tables, none typed. Keep `draft: true`: the authors
  engaged on 2026-11-09, so they receive the full review before publication.

### 2026-11-20 — Stage 5 draft written and sent to the authors (commits 5044f8f …)
- Done: `review.qmd` (technical review, 13 pages as PDF) and `primer.qmd` (plain-language
  companion, 2 pages) written from the stage 1–4 outputs, every number read from
  `output/tables/`; HTML and PDF formats (XeLaTeX, TeX Gyre Pagella, `fig-pos: H`,
  `tools/pdf-divs.lua` for the evidence tags); both `draft: true`. Full text sent to all four
  authors on 2026-11-19 22:36 (`correspondence/2026-11-19_full_text_SENT.md`): PDFs attached,
  five-point summary, publication proposed on or after 2026-12-11, reply published in full, more
  time on request. Registry status `authors-contacted`.
- Decided (and why): verdict kept as "conclusions not supported" for the HRV/ET valence claims
  and "major concerns" overall, pending Alberto's reading pass; publication date three weeks
  from sending, mirroring the data-request rule; figures placed in text in the PDF because a
  float deferred past a longtable was lost.
- Open questions: authors' reply and data (if data arrive before publication, S1–S9 rerun and
  the text recomputed); version of record and reviewer reports; whether to translate the primer.
- Next step: wait for the reply window; on reply, fill the Right of reply section (TODO comment),
  re-render, set `draft: false` on both pages, push; then `verdict` and
  `date_review_published` in the registry.
