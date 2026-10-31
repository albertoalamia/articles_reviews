# CLAUDE.md — articles_reviews

Guidance for Claude Code in this repository. Article-specific context lives in each article's
own `CLAUDE.md`; read its STATUS section first when working on a paper.

## What this is

A programme of methodological appraisal of published research in psychiatry and ethology, run by
Alberto Alamia (psychiatrist, biostatistician). Premise: a large share of published studies has
serious methodological problems. The programme builds a repeatable appraisal protocol, applies it
paper after paper, makes every numerical check reproducible, and accumulates evidence on
recurring failure modes. Outputs: a Quarto website at https://reviews.telepsichiatria.org, and
for the strongest findings PubPeer comments or Matters Arising.

Two tracks, never pooled: `systematic` (papers chosen by the sampling rule in
`protocol/selection.md`, to test the premise) and `selected` (papers chosen for interest or
suggested by colleagues, to comment).

## Layout

```
CLAUDE.md, README.md          this file; index of reviews + Alberto's setup checklist
shell.nix, .envrc             pinned nix environment (R, Quarto, CmdStan, TeX). Always work inside it.
_quarto.yml, index.qmd, about.qmd, protocol.qmd, theme.scss, CNAME   the website
protocol/                     checklist.md (versioned), taxonomy.csv (issue codes), selection.md
registry/                     papers.csv (one row per paper), issues.csv (one row per issue)
lib/consistency.R             shared R functions for recomputation checks; tests in lib/tests/
_template/                    skeleton copied for each new article
<Journal>_<shorttitle>_<FirstAuthor>_<Year>/   one folder per paper (see _template/CLAUDE.md)
.github/workflows/publish.yml renders the site from _freeze/ and deploys to GitHub Pages
```

## Commands

```bash
nix-shell                                   # enter the environment (or let direnv do it)
Rscript lib/tests/run_tests.R               # test the consistency toolkit
quarto preview                              # live preview of the site
quarto render                               # full render; writes _freeze/ (commit it)
./<article>/run_model.sh <model>            # compile + sample a Stan model with CmdStan
```

## Workflow for one paper

Five stages, each its own conversation, started from the repo root. Stages 3 and 4 share one
model so that their results can be compared in a single table.

1. **Methodology review.** Fill `notes/01_reading_notes.md` (section by section, verbatim quotes)
   and `notes/02_methods_inventory.md` (protocol A–H). Transcribe every reported number into
   `data/raw/` with an `EXTRACTION_LOG.md`; save native figure rasters with hashes. Write and run
   `R/02_consistency_checks.R` from the raw files, outputs in `output/tables/`. Re-verify
   `notes/03_concerns.md` with evidence tags; add rows to `registry/issues.csv`. Send the data
   request and log it in `correspondence/`.
2. **Reproduce the authors' analysis.** On their data if they share it, otherwise on data
   reconstructed from tables and figures (digitised points, simulated pairs from means, SDs and
   implied correlations), each with its own log in `data/derived/`. Refit exactly the models
   described and report what reproduces and what does not. `R/01_prepare_data.R` writes JSON for
   CmdStan.
3. **Frequentist alternative.** Write `notes/04_analysis_plan.md` first: outcome families, fixed
   and random structure, contrasts and estimands, stated so that each maps one-to-one onto a Stan
   program. Then fit it (lme4/glmmTMB or equivalent) and report estimates with intervals.
4. **Bayesian analysis.** The same likelihood, structure, contrasts and estimands as stage 3, as
   `.stan` files in `stan/`, run via `run_model.sh`, draws in `$FITS_DIR`, post-processing in
   `R/03_postprocess.R`. Priors, diagnostics and sensitivity reported. Stage 3 and stage 4 results
   go side by side in one table in `review.qmd`.
5. **Write-up.** `review.qmd` following the template sections. Keep `draft: true` until the
   right-of-reply rule below is satisfied. Freeze, render, check, then set `draft: false` and push.

End every session by updating the article `CLAUDE.md` STATUS (done / decided and why / open
questions / next step) and `registry/papers.csv` status.

## Rules

- **Instructions first.** Explain what to do and let Alberto do it; execute only when he explicitly asks.
- **Protocol is fixed per review.** Use `protocol/checklist.md` as is; record its version. Propose
  changes to the protocol separately, never mid-review.
- **Evidence tags on every concern:** `confirmed` (from the paper's own numbers), `inferred`
  (depends on an assumption), `needs-data`. Do not upgrade a tag without saying why.
- **Phrasing.** Criticise methods and numbers, never intent or integrity. Write "inconsistent with
  the reported data", not "wrong" or "manipulated". Italian defamation law applies to Alberto.
- **Right of reply.** The corresponding authors are contacted at the data-request stage, with
  notice that a methodological commentary will be published. If they engage, they receive the
  full review before publication and their reply is published with it. If no reply arrives
  within three weeks of the request, publication proceeds without a second notice, as the request
  itself states. Record every message, sent and received, in `correspondence/` (send with
  `tools/send_email.py`, fetch with `tools/fetch_email.py`).
- **Separate judgment.** Claude drafts, recomputes, and proposes; Alberto decides what goes in
  the final review. Flag anything Claude is unsure of rather than smoothing it over.
- **Reproducibility.** Every number in a review comes from code in the article folder, run in
  the nix shell. No hand-typed results.

## Stan and storage

- Models are standalone `.stan` files compiled and sampled with **CmdStan from the shell**
  (`run_model.sh`). Never fit through rstan, brms or cmdstanr. R is for data preparation (JSON via
  jsonlite) and post-processing (`posterior::read_cmdstan_csv`, bayesplot, loo).
- Draw CSVs go to `$FITS_DIR/<article>/` on the archive disk
  (`/media/alberto/Archive/bayesian/articles_reviews`). The project tree is on a small encrypted
  volume: only small summaries, figures and tables live here. Check the disk is mounted first.
- Compiled model binaries are gitignored; `.stan`, JSON data and run scripts are committed.

## Site and publishing

- Quarto website, `execute: freeze: auto`. Analyses run locally; `_freeze/` is committed; the
  GitHub Action renders without R or Stan and deploys to GitHub Pages, served at
  reviews.telepsichiatria.org via CNAME. Comments via giscus (GitHub Discussions on this repo).
- A review is published by setting `draft: false` and pushing to `main`. While `draft: true`,
  `draft-mode: gone` keeps it out of listings, search and sitemap; its URL serves a blank page
  (verified 2026-10-25), so no draft text is ever public.
- Until the DNS record exists the site is served at https://albertoalamia.github.io/articles_reviews/.
- Site chrome in English; individual reviews may be in Italian (`lang: it` in front matter).

## Language and tone of written output

Plain, specific, numbers in tables, one claim per sentence. Lead with the verdict. Quote the
paper exactly when a sentence is criticised.
