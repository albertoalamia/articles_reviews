# Sci Rep — HRV, eye temperature and blink rate as measures of emotion in working donkeys (Bukhari 2026)

Article-specific context for Claude Code. Repo-wide rules are in the root `CLAUDE.md`.

## Paper

- Citation: Bukhari S.S.U.H., McElligott A.G., Steagall P.V., Parkes R.S.V. (2026). Heart rate
  variability, eye temperature, and spontaneous blink rates as measures of emotions in working
  donkeys. *Scientific Reports*. Received 16 Dec 2025, accepted 14 Jul 2026, online 22 Jul 2026.
- DOI: 10.1038/s41598-026-62753-3
- Version reviewed: unedited accepted manuscript ("Article in Press"), CC BY-NC-ND 4.0.
  Check later whether the version of record and Transparent Peer Review reports are out.
- Track: `selected` — source: own interest (Alberto works on donkey-assisted therapy).
- Field: ethology
- Registry id: P001 — protocol version: 0.1
- Data availability as stated: "on request".
- What the paper claims: three physiological measures (RMSSD, eye temperature, spontaneous blink
  rate) discriminate positive and negative emotional states induced in working donkeys, and the
  blink rate is proposed as a simple field indicator of valence.

## Design in one paragraph

Within-subject crossover, n = 34 working donkeys, three conditions in one session: control,
positive (lucerne in a bucket), negative (clipper). 3-min windows, 1-h washout, order as a fixed
effect. Outcomes: SBR (count), eye temperature (IR thermography), RMSSD (ultra-short HRV).
Analysis as described: linear mixed models on condition means; "change" scores defined as
control minus treatment; regressions of ΔRMSSD on ΔSBR and ΔET. Power analysis based on a
correlation with ρ = 0.5.

## Files

See `_template/CLAUDE.md` for the folder convention. Specific to this paper:

- `notes/00_first_pass_claude_ai_2026-10-25.md` — Alberto's first-pass critique produced in a
  claude.ai conversation, plus notes on publication status and on the metascience landscape.
  Source of the initial concerns list; every item still has to be re-verified against the PDF.
- `paper/Bukhari_2026_SciRep_s41598-026-62753-3_accepted_manuscript.pdf`

## STATUS

### 2026-10-25
- Done: repo pushed to GitHub and site live at albertoalamia.github.io/articles_reviews/ (this review is a blank draft page there); folder scaffolded from template; paper and first-pass critique filed; registry row P001
  created (status `reading`); `notes/03_concerns.md` seeded from the first pass.
- Decided: first author is Bukhari (Syed is a given name), folder renamed accordingly.
- Open questions: is the version of record out, with reviewer reports? Can the per-condition
  numbers in Table 2 / Figs 2–4 be extracted precisely enough for a re-analysis on summary data?
- Next step: Phase 1 — read the PDF in full, fill `notes/01_reading_notes.md` and
  `notes/02_methods_inventory.md`, re-verify each seeded concern, extract Table 2 into
  `data/raw/` with an extraction log, and run `R/02_consistency_checks.R`.
