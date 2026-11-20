# Sci Rep — Baseline cognitive impairment and cerebrovascular events in stroke-free adults (Shi 2026)

Article-specific context for Claude Code. Repo-wide rules are in the root `CLAUDE.md`.

## Paper

- Citation: Shi Z. and 7 co-authors (2026). Baseline cognitive impairment predicts
  cerebrovascular events in stroke-free chinese adults. *Scientific Reports*. Received 21 Jul 2026,
  accepted 26 Oct 2026, online 29 Oct 2026. Author list and affiliations to complete from the PDF.
- DOI: 10.1038/s41598-026-78298-4
- Version reviewed (preprint / accepted manuscript / version of record): to record when the PDF is filed
  (CC BY-NC-ND 4.0 per Crossref).
- Track: `systematic` — source: batch B01 (selection v0.2; Scientific Reports, October 2026,
  OpenAlex subfield Psychiatry and Mental health, seed 20261120, rank 1 of 30, eligible on the title).
- Field: psychiatry
- Registry id: P002 — protocol version: 0.1
- Data availability as stated: to record from the PDF
- What the paper claims (two sentences, in the authors' terms): to record from the PDF; the title
  claims that baseline cognitive impairment predicts later cerebrovascular events in adults without
  prior stroke.

## Design in one paragraph

(Units, conditions, n, outcomes, primary analysis as described by the authors.)

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
