# Selection rules — version 0.1 (2026-10-25)

Two tracks are kept separate in `registry/papers.csv` and are never pooled when describing
the literature.

## Track `systematic`

Purpose: test the hypothesis that a large share of published research in psychiatry and
ethology has serious methodological problems. Papers must be chosen *without* prior suspicion.

Rule (to be fixed before the first systematic paper is added, and then not changed within a
batch):

- Journals: TBD (candidates: Scientific Reports, Applied Animal Behaviour Science, Animals,
  Journal of Psychiatric Research, Psychiatry Research, BMC Psychiatry).
- Sampling: the first N original research articles of a given issue, or a random draw with a
  recorded seed from the issue's table of contents.
- Exclusions: reviews, protocols, case reports, editorials.
- Each batch records journal, issue, N, seed, date.

## Track `selected`

Purpose: comment on papers that matter to Alberto or to colleagues. Chosen freely; the source
is recorded (`own interest`, `colleague suggestion`, `media coverage`, `follow-up`).

Exemplar reviews (well-analysed papers) are welcome in either track and are flagged with
`verdict = sound` in the registry.
