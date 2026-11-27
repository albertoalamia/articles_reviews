# paper/ — Secondi et al. 2026, Animal Behaviour

Save here, with these names:

- `Secondi_2026_AnimBehav_123735.pdf` — the article (in place since 2026-11-25), from
  https://doi.org/10.1016/j.anbehav.2026.123735 (through the University of Milano-Bicocca library).
- The supplement (in place since 2026-11-27, under the publisher's names):
  `1-s2.0-S0003347226002733-mmc1.zip`, unpacked in `ANBEH-D-26-00085_SuppMat/` (the document
  with Figures S1–S2 and Tables S1–S3, the R script, a copy of the dataset).

Claude then extracts `Secondi_2026_fulltext.txt` with `pdftotext -layout` and records the sha256
of every file, the version (article in press or version of record) and the access date in
`data/raw/EXTRACTION_LOG.md`.

**Copyright.** Animal Behaviour is a subscription journal and this article is not open access.
The PDF, the supplements and the extracted full text are for private study and stay on this
machine: `.gitignore` excludes everything in this folder except this file and `.gitkeep`. The
repository is public. Notes and the review quote only the sentences they discuss.
