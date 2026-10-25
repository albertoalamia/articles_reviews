# <Journal> — <Short title> (<FirstAuthor> <Year>)

Article-specific context for Claude Code. Repo-wide rules are in the root `CLAUDE.md`.

## Paper

- Citation: 
- DOI: 
- Version reviewed (preprint / accepted manuscript / version of record): 
- Track: `systematic` | `selected` — source: 
- Field: psychiatry | ethology | other
- Registry id: P0xx — protocol version: 0.1
- Data availability as stated: 
- What the paper claims (two sentences, in the authors' terms): 

## Design in one paragraph

(Units, conditions, n, outcomes, primary analysis as described by the authors.)

## Files

- `paper/` — PDF(s), supplementary material, authors' code if any. Read-only.
- `notes/01_reading_notes.md` — section-by-section notes with page references.
- `notes/02_methods_inventory.md` — protocol checklist A–G filled in.
- `notes/03_concerns.md` — one entry per concern, tagged confirmed / inferred / needs-data,
  mirrored as rows in `registry/issues.csv`.
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

### YYYY-MM-DD
- Done:
- Decided (and why):
- Open questions:
- Next step:
