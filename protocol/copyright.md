# Copyright and access — version 1.0 (2026-11-28)

What this programme does with a paper, its supplements and its data, by licence class, and what
of it the public repository may contain. The appraisal protocol (`checklist.md`) says what is
examined; this file says what may be copied, quoted, processed and committed. It applies to every
paper from its scaffold on, whatever protocol version the review runs under. It is a working rule
written by a reviewer, not legal advice; Alberto decides the doubtful cases, and the Permissions
Helpdesk of the publisher is the route when a doubt remains (§7).

The programme is non-commercial: the site carries no advertising, no paid content and sells
nothing; the reviews are scholarship. Every rule below assumes that and fails if it changes.

## 1. Licence classes

Classify the paper at the scaffold (article `CLAUDE.md`, line "Access and licence"; checklist A4
records data availability, this line records the text's licence).

| class | what it is | PDF, full text, figure rasters, supplements | in the public repository |
|---|---|---|---|
| **A. Open licence** (CC BY, CC BY-NC, CC BY-NC-ND, CC0) | the licence text on the article | may be committed, unmodified, with the attribution the licence requires (authors, title, journal, DOI, licence) | yes, in `paper/` |
| **B. Subscription / all rights reserved** | copyright line without a public licence, with or without the sentence "All rights are reserved, including those for text and data mining, AI training, and similar technologies" | obtained through a library, from the authors or by purchase; stay on this machine; never sent to anyone | no: `.gitignore` block for `<dir>/paper/*` except `README.md` and `.gitkeep` |
| **C. The authors' data** | its own licence (a repository record), or none ("available on request") | with a public licence: committed with its record, licence, md5 and attribution; received on request or without a licence: local only, hashed in `RECEIVED_LOG.md`, used as the authors allowed | per the licence; never without one |

Supplementary material has the class of the article unless it carries its own licence; a script
in a supplement is read and described, not committed. The ND of CC BY-NC-ND forbids adaptations:
excerpts are reproduced unmodified; translation of the paper's text is limited to the gloss of a
quoted sentence in an Italian primer, with the original beside it.

## 2. Reading and analysing a class B paper

- **Private study.** Reading, extracting the text with `pdftotext`, keeping the files locally and
  transcribing numbers are the normal uses of a legally accessed article. The access route is
  logged in `data/raw/EXTRACTION_LOG.md` (library and date, purchase, or the authors).
- **Use with the AI assistant.** The rights reservation printed on Elsevier articles excludes
  text and data mining and AI training by third parties in general. Elsevier's copyright policy
  states, for subscription articles: "Where legal access is obtained by a user, that user is able
  to text or data mine subscription articles for non-commercial purposes without sharing any
  adaptation of the original content with others" (elsevier.com, policies and standards,
  copyright; read 2026-11-28). Its text-and-data-mining policy adds that researchers at
  subscribing institutions may mine subscribed content for non-commercial research under their
  institution's agreement. The programme's use of a single article, read with the assistant to
  write a human-authored appraisal, is within that statement on three conditions, all kept:
  non-commercial purpose; no adaptation of the text shared with anyone (what is published is
  criticism with short quotations, numbers as facts, and new analyses); nothing used to train
  any model. The article and the assistant's extraction stay local. For a publisher without such
  a statement, the same three conditions hold and §7 applies when in doubt.
- **Never:** share the PDF or the full text, including with the authors (they have it); feed the
  article to any bulk or automated pipeline beyond the appraisal; keep more than one copy outside
  the article folder.

## 3. What may be published, for any class

- **Quotation for criticism.** Italian law (l. 633/1941, art. 70) and the Berne Convention
  (art. 10) allow quoting passages of a work for criticism or discussion, within the limits the
  purpose justifies, with the source named. Every quotation in a review, a primer or a concern
  is therefore a sentence that the text then discusses, with page or line, attributed. A
  quotation that is not discussed is removed.
- **Ceiling for class B.** The verbatim text of a class B article reproduced across all the
  committed files of its folder stays under **400 words**, the benchmark the STM Permission
  Guidelines use for a single text extract from one article that publishers grant each other
  without a written request. It is a working ceiling, not a legal threshold. It is measured with
  `tools/quote_audit.py <dir>` (runs of seven or more consecutive words shared with the local
  full text; numeric runs excluded), which must pass before every commit of that folder.
  Class A papers have no ceiling; their reproduction follows the licence (attribution, ND).
- **Numbers.** Values read from tables, text and figures are facts. They are transcribed into
  `data/raw/*.csv` with the extraction log and committed (Elsevier's permissions FAQ: an
  original table built from data or factual information needs no permission, with the source
  acknowledged). A table copied whole is not a transcription of facts: for class B, a complete
  table (a supplementary table of all contrasts, say) is parsed by a committed script from the
  local supplement and the output stays local; the committed files hold the rows the review uses
  and the summaries the checks produce.
- **Figures.** Not reproduced for class B; points read from a figure are data and are committed
  as such. For class A, a figure may be shown unmodified with attribution when the review
  discusses it.
- **Reading notes.** `notes/01_reading_notes.md` is a working document with verbatim passages.
  For class B it stays local (`.gitignore` line in the folder's block) or is written as
  paraphrase with line pointers; the concerns file and the review carry the quotations that
  the criticism needs. For class A it is committed.
- **Authors' replies** are published in full, as the data request announces and as the authors
  are told when they receive the review.

## 4. Data under a public licence (class C)

The review names the record (authors, title, repository, DOI, version), the licence and the
checksum, in `data/raw/authors/RECEIVED_LOG.md` and in the review's reproducibility section. CC BY
requires that attribution wherever the data or anything derived from it appears, including the
figures of the review.

## 5. Procedure

1. **Scaffold** (`new-review`): classify the paper; write the "Access and licence" line; for
   class B add the `.gitignore` block (paper folder, reading notes) and `paper/README.md` from
   the template; for class C record the licence before downloading anything into `data/raw/`.
2. **Every commit of a class B folder**: `python3 tools/quote_audit.py <dir>` passes.
3. **Stage 5**: the audit runs on the review and primer; every quotation is attributed with page;
   figures of the paper absent; dataset attribution present.
4. **Right of reply**: the full text sent to the authors is the review, not the paper.

## 6. Applied to the papers in the registry (2026-11-28)

| paper | class | state on 2026-11-28 | to do |
|---|---|---|---|
| P001 Bukhari 2026, Sci Rep | A, CC BY-NC-ND 4.0 | paper committed, quotations attributed | none |
| P002 Shi 2026, Sci Rep | A, CC BY-NC-ND 4.0 | paper committed; audit 1,130 verbatim words, allowed by the licence | none |
| P003 Secondi 2026, Animal Behaviour | B (© ASAB, Elsevier; rights reservation printed); data C, CC BY 4.0 (Zenodo) | paper local; audit **1,111 verbatim words**, 823 of them in the reading notes; Tables S2–S3 transcribed whole (396 rows) and committed | reading notes local or paraphrased; S2–S3 transcription local, parser committed, rows used kept; audit under 400; access route already logged |

## 7. When in doubt

Elsevier Permissions Helpdesk: https://service.elsevier.com/app/contact/supporthub/permissions-helpdesk/.
A request names the article, the use (quotation for criticism in a non-commercial methodological
commentary; reading with an AI assistant for that purpose; transcription of numbers), and asks
for written confirmation. Other publishers: their permissions page, then the same message.

## 8. Sources

- Elsevier, *Copyright* (policies and standards): rights of authors and of others for
  subscription and open-access articles; the text-and-data-mining sentence quoted in §2. Read
  2026-11-28.
- Elsevier, *Permissions*: when permission is required; STM Permission Guidelines (2022): up to
  three figures or tables and single text extracts under 400 words per article between
  signatory publishers; original tables from factual information. Read 2026-11-28.
- Elsevier, *Text and data mining*: licence-based access for researchers at subscribing
  institutions, non-commercial research. Read 2026-11-28.
- Legge 22 aprile 1941 n. 633, art. 70 (quotation for criticism, discussion, teaching), art.
  70-ter and 70-quater (text and data mining; the latter excluded where the holder has reserved
  it); Directive (EU) 2019/790, art. 3–4; Berne Convention, art. 10.
- The article's copyright line: "© 2026 The Association for the Study of Animal Behaviour.
  Published by Elsevier Ltd. All rights are reserved, including those for text and data mining,
  AI training, and similar technologies."

## Changes

| version | date | change |
|---|---|---|
| 1.0 | 2026-11-28 | first version, after the first closed-access paper (P003) |
