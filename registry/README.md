# Registry

Three flat tables, hand-edited, read by the site index and by any later cross-paper analysis.

- `papers.csv` — one row per paper. `track` is `systematic` or `selected` (see
  `protocol/selection.md`). `status` moves through `reading` → `inventory` → `reanalysis` →
  `draft` → `authors-contacted` → `published`. `verdict` uses the protocol H scale.
- `issues.csv` — one row per flagged issue. `issue_code` from `protocol/taxonomy.csv`;
  `severity` in `critical | major | minor`; `evidence` in `confirmed | inferred | needs-data`;
  `location` is where in the paper (e.g. `Table 2`, `Fig 2C`, `Discussion para 3`).
- `batches.csv` — one row per systematic sampling batch (journal, window, subfields, frame
  size, seed, paper picked), with the frame and the screened order under `batches/`, written
  by `tools/sample_frame.py` as `protocol/selection.md` prescribes. The `selected` share is
  capped at one half of `papers.csv`.

Keep rows minimal. The argument lives in the review; the registry is for counting.
