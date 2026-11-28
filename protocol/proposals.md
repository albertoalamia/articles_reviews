# Proposals — parked changes to the protocol, the templates, the shared code or the site

Rule (root `CLAUDE.md`, `CONVERSATIONS.md` §2.1): a review runs under the protocol version in force
when it started; a need that appears during a review is written here and handled in a separate
`repo:` conversation. One row per proposal; `status` is `open`, `done (vX.Y, date)` or `dropped (why)`.

| date | from | proposal | status |
|---|---|---|---|
| 2026-11-28 | repo | Conversation rules (`CONVERSATIONS.md`, skills `session-start`, `session-end`, STATUS field "Open the next conversation with") | done (2026-11-28) |
| 2026-11-28 | P003 | Closed-access papers: what may be read, quoted, transcribed and committed; `protocol/copyright.md` v1.0, `tools/quote_audit.py`, template `paper/README.md`, "Access and licence" line, skills updated | done (2026-11-28) |
| 2026-11-28 | repo → P003 | Apply `copyright.md` to P003: reading notes local (gitignore line, `git rm --cached`), Tables S2–S3 transcription local with a committed parser and the rows the review uses, audit under 400 words; consider whether the already-pushed history needs rewriting (Alberto) | open: conversation `P003 stage 1: copyright compliance` |
| 2026-11-28 | P003 | `copyright.md` §2 "Use with the AI assistant" rests on the copyright-policy footnote only, while Elsevier's website terms (revised 12 March 2026) forbid using content "in combination with an artificial intelligence tool" unless a licence or subscription agreement permits. Reviewed 2026-11-28 (Elsevier terms, Bicocca library pages, l. 633/1941 art. 70-ter to 70-septies, the assistant's data handling): `protocol/copyright_v1.1_DRAFT.md`. Decided by Alberto: class B papers stay in the frame and are read with the assistant on the Max plan with model training disabled, on a stated and unverified assumption about the institution's agreement, with six conditions; the library and the publisher are not asked; a two-zone rule with a local model is the documented fallback. To do: adopt as `copyright.md` v1.1 (§2–4 of the draft), `tools/quote_check.py`, `protocol/local_zone.txt`, `cleanupPeriodDays`, template, skills `new-review` and `session-start`, `protocol.qmd`, root `CLAUDE.md`; then delete the draft | open: draft written 2026-11-28; conversation `repo: adopt copyright v1.1` |
