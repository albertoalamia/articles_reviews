# Proposals — parked changes to the protocol, the templates, the shared code or the site

Rule (root `CLAUDE.md`, `CONVERSATIONS.md` §2.1): a review runs under the protocol version in force
when it started; a need that appears during a review is written here and handled in a separate
`repo:` conversation. One row per proposal; `status` is `open`, `done (vX.Y, date)` or `dropped (why)`.

| date | from | proposal | status |
|---|---|---|---|
| 2026-11-28 | repo | Conversation rules (`CONVERSATIONS.md`, skills `session-start`, `session-end`, STATUS field "Open the next conversation with") | done (2026-11-28) |
| 2026-11-28 | P003 | Closed-access papers: what may be read, quoted, transcribed and committed; `protocol/copyright.md` v1.0, `tools/quote_audit.py`, template `paper/README.md`, "Access and licence" line, skills updated | done (2026-11-28) |
| 2026-11-28 | repo → P003 | Apply `copyright.md` to P003: reading notes local (gitignore line, `git rm --cached`), Tables S2–S3 transcription local with a committed parser and the rows the review uses, audit under 400 words; consider whether the already-pushed history needs rewriting (Alberto) | open: conversation `P003 stage 1: copyright compliance` |
