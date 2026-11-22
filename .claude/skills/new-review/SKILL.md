---
name: new-review
description: Set up a new paper for appraisal (stage 1 scaffolding) - batch draw or selected pick, article folder from _template, registry row, contacts, data-request letter with the right-of-reply notice and the three-week clock. Use when Alberto adds a paper, says "next paper", "new review" or "draw the next batch".
---

# new-review — from a DOI to a scaffolded stage 1

Rules that frame everything below: root `CLAUDE.md` (instructions first, evidence tags, phrasing,
right of reply), `protocol/checklist.md` (version recorded in the review's `params`),
`protocol/selection.md` (tracks). Claude writes files and gives commands; Alberto downloads the
paper, runs scripts, sends mail, commits.

## 1. Which paper

- **Track `systematic`** (to test the premise): one paper per batch, drawn blind.
  Alberto runs, inside the shell, from the repo root:
  ```
  python3 tools/sample_frame.py --batch B0x --field <psychiatry|ethology> --from YYYY-MM-01 --to YYYY-MM-DD --subfields <ids> --seed YYYYMMDD
  ```
  It writes `registry/batches/B0x_frame.csv|json|order.csv`. He screens `B0x_order.csv` in
  order with the eligibility screen of `selection.md`, filling `eligible` and `reason` until the
  first `yes`. Then a row in `registry/batches.csv` (columns: batch, track, field, journal,
  issn, window, subfields, frame_size, seed, date_drawn, n_screened, picked_doi, paper_id,
  notes). The rule is not changed inside a batch. The `selected` share stays under the cap in
  `selection.md`.
- **Track `selected`** (interest, a colleague's suggestion): record the source in the registry
  `source` column and in the article `CLAUDE.md`.

## 2. Folder and registry

1. Name: `<Journal>_<short_title>_<FirstAuthor>_<Year>` (e.g.
   `SciRep_cognitive_impairment_cerebrovascular_events_Shi_2026`). Copy the skeleton:
   `cp -r _template <dir>` (Alberto), then delete `<dir>/shell.nix` unless the paper needs
   extra packages.
2. `registry/papers.csv`: next `P0xx`; columns id, dir, track, source, doi, journal, year,
   first_author, field, version_reviewed, protocol_version, status, date_added,
   date_review_published, verdict, authors_contacted, reply_received, pubpeer_url. Status
   vocabulary in use: `reading` → `inventory` → `authors-contacted` → `reanalysis` →
   `published` (only `published` reaches the site index through `lib/quality_table.R`).
3. `<dir>/CLAUDE.md`: fill the Paper block (citation, DOI, version reviewed, track and source,
   field, registry id, protocol version, data availability statement verbatim, the claim in the
   authors' terms), the design paragraph, and a first STATUS entry dated today.
4. `<dir>/review.qmd` front matter: title, description, date, categories, `draft: true`,
   `params$protocol_version` and `params$track`; `quality_table("P0xx")` in the summary chunk.
   The site lists `*/review.qmd` automatically; nothing to add in `_quarto.yml`.

## 3. The paper itself (Alberto files, Claude reads)

- Alberto saves the PDF and supplements into `<dir>/paper/` (read-only). Claude extracts
  `paper/<First>_<Year>_fulltext.txt` with `pdftotext -layout` and records sha256 of each file
  in `data/raw/EXTRACTION_LOG.md` together with the version (preprint, accepted manuscript,
  version of record) and the access date.
- Figures that carry numbers: native rasters into `data/raw/figures/` with hashes;
  `tools/digitise_scatter.py` for points.

## 4. Stage 1 proper (separate conversation if long)

`notes/01_reading_notes.md` (section by section, verbatim quotes with page), `notes/02_methods_inventory.md`
(checklist A–H), every reported number into `data/raw/*.csv` with the extraction log,
`R/02_consistency_checks.R` (Alberto runs; outputs to `output/tables/`), `notes/03_concerns.md`
(one entry per concern, tag `confirmed` / `inferred` / `needs-data`, severity minor / major /
critical) mirrored in `registry/issues.csv` (paper_id, issue_code from `protocol/taxonomy.csv`,
severity, evidence, location, note; quote the paper in `note`, notes with commas in quotes).

## 5. Contacts and the data request

1. `<dir>/correspondence/contacts.md`: a table of authors (role, name, email, affiliation) from
   the paper's author block, with the line of the full text it came from; the data availability
   statement verbatim; a "Log" table (Date, Direction, To/From, Channel, Summary, File) as the
   **last table in the file** (`tools/fetch_email.py` appends to it).
2. Draft `<dir>/correspondence/YYYY-MM-DD_data_request_DRAFT.md` in the format of
   `tools/send_email.py`: a title line, `To:` / `Subject:` header, `---`, body, `---`, notes for
   sending. The body, in this order and in plain prose:
   - who Alberto is and why the question matters to him clinically (one paragraph, specific);
   - the request: data underlying the paper as the data availability statement provides;
   - the aim stated openly: a methodological re-analysis (which models), **to be published as a
     commentary**; the authors receive the full text before publication and their response is
     published with it;
   - the specific elements that could not be reconciled, each as "I could not reconcile X with
     Y", with the admission that a misunderstanding on the reader's side is possible, never a
     judgement of intent;
   - a numbered list of what would be ideal (per-participant records and dates, covariates,
     events, the analysis code or output listings, the figure datasets, excluded participants);
   - what the authors get: the full analysis, code, processed data and instructions in a pinned
     environment before anyone else;
   - **the clock**: no reply within three weeks, or data not shareable, and the commentary on
     the reported numbers proceeds and is published without further notice, with all code
     public so that it can be checked and challenged, by the authors first of all;
   - thanks, signature with role and site.
   Look at the two existing `*_data_request_SENT.md` files for tone and length.
3. Alberto sends it. He runs the send script himself (give him the command in a code block:
   `python3 tools/send_email.py <dir>/correspondence/<file>_DRAFT.md`, `--dry-run` first).
   The script renames the file to `_SENT.md` and appends the `Sent:` line. Claude then adds
   the Log row in `contacts.md` with the reply deadline (send date + 21 days), fills
   `authors_contacted` in the registry, sets status `authors-contacted`, and writes the deadline
   in the STATUS entry.
4. Replies: Alberto fetches with `tools/fetch_email.py --article <dir> --sent-file <SENT file>`;
   received messages are Markdown in `correspondence/`, attachments in `data/raw/authors/`
   with `RECEIVED_LOG.md`; raw `.eml` never committed. Record every message sent and received.

Privacy: never put Alberto's email address or name in a request to an external service; the
credentials live in `~/.config/gmail_sender/`, outside the repo. The sandbox plugin refuses
Bash commands that contain the address or name `tools/send_email.py` / `tools/fetch_email.py`:
write those commands for Alberto, do not run them.

## 6. End of the session

STATUS entry in `<dir>/CLAUDE.md` (done / decided and why / open questions / next step), registry
status, and the commit command (see `render-check` for its form).
