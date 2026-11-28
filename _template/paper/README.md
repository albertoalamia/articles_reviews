# paper/ — <First author> et al. <Year>, <Journal>

Save here, with these names:

- `<First>_<Year>_<Journal>_<id>.pdf` — the article, from https://doi.org/<DOI>
  (access route: library / purchase / the authors; date).
- The supplement, under the publisher's file names, unpacked in a subfolder if it is an archive.

Claude then extracts `<First>_<Year>_fulltext.txt` with `pdftotext -layout` and records the sha256
of every file, the version (preprint, accepted manuscript, version of record) and the access date
in `data/raw/EXTRACTION_LOG.md`.

**Access and licence** (`protocol/copyright.md`, class A / B / C): <fill in>.

- Class A (open licence): the files above are committed unmodified, with the attribution the
  licence requires; delete this paragraph's class B lines.
- Class B (subscription, all rights reserved): the PDF, the supplements, the extracted full text
  and the figure rasters are for private study and stay on this machine; the root `.gitignore`
  has a block for this folder (`paper/*` except this file and `.gitkeep`, and
  `notes/01_reading_notes.md`). The repository is public. Notes and the review quote only the
  sentences they discuss, and `python3 tools/quote_audit.py <dir>` passes before every commit.
