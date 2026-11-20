# Selection rules — version 0.2 (2026-11-20)

Two tracks are kept separate in `registry/papers.csv` and are never pooled when describing
the literature. Only the `systematic` track enters the meta-research; the `selected` track is
commentary.

Version history: v0.1 (2026-10-25) set the two tracks and left the systematic rule open.
v0.2 fixes the systematic sampling rule before the first systematic paper and caps the
`selected` share. The rule is not changed within a batch; changes between batches get a new
version number here.

## Proportion of the two tracks

At most half of the papers in the registry are `selected`. Operationally: when a paper is
added, the count of `selected` papers after the addition may not exceed the count of
`systematic` papers; if it would, the next paper must be `systematic`. P001 (selected) counts,
so P002 is systematic and P003 may be selected. The cap is checked on `registry/papers.csv`
at the time of adding, regardless of status.

## Track `systematic`

Purpose: test the hypothesis that a large share of published research in psychiatry and
ethology has serious methodological problems. Papers are chosen without prior suspicion; the
only human judgement is an eligibility screen on title and abstract, applied in the drawn
order and logged for every paper screened.

### Frame

- **Source.** OpenAlex (`https://api.openalex.org/works`), which is open, needs no login and
  gives the same answer to anyone who repeats the query. The frame is downloaded once, saved
  under `registry/batches/` and committed; the draw is made on the saved file, so the batch is
  reproducible even after OpenAlex re-indexes.
- **Journal.** Scientific Reports (ISSN 2045-2322) for the first batches of both fields: it
  publishes both fields in volume, is open access, requires a data availability statement, and
  is the venue of P001, so venue is held constant across the two tracks. A field journal may
  be used in a later batch; the batch row records the journal.
- **Window.** One calendar month of publication dates, chosen at least three weeks in the past
  (so the month is complete in the index) and at most four months old (so the authors can be
  reached for the right of reply).
- **Field filter.** OpenAlex `primary_topic.subfield`:
  - psychiatry: 2738 *Psychiatry and Mental health*;
  - ethology: 1103 *Animal Science and Zoology*, 1105 *Ecology, Evolution, Behavior and
    Systematics*, 2802 *Behavioral Neuroscience*.
  `type:article` only. Batches alternate between the fields, psychiatry first (P001 was
  ethology).

### Draw

- The frame is sorted by DOI, then permuted with `random.Random(seed).shuffle` in Python; the
  seed is the batch date as an integer (`YYYYMMDD`) and is recorded. The permuted list is saved
  as `registry/batches/<batch>_order.csv`.
- Papers are screened in that order, on title and abstract only, until the first eligible one;
  N = 1 per batch. Every screened paper gets a row with `eligible = yes/no` and a reason. A
  second paper from the same batch, if ever needed, continues the same order; no redraw.

### Eligibility screen (decided before seeing the list)

Eligible: an empirical study that collects or analyses data on human participants
(psychiatry) or on non-human animals as subjects (ethology) and reports inferential statistics
in support of a scientific claim about those subjects.

Not eligible, with the reason logged: reviews, meta-analyses, protocols, case reports and case
series, editorials and corrections; software, methods and benchmark papers whose claim is about
a tool rather than about subjects; papers with an author personally known to Alberto; papers
whose full text cannot be obtained. Nothing about design quality or statistics is a reason to
exclude, or the sample stops being blind.

### Record

`registry/batches.csv`: one row per batch with track, field, journal, ISSN, window, subfields,
frame size, seed, date drawn, number screened, DOI picked and registry id. The frame and the
order files sit in `registry/batches/`. `tools/sample_frame.py` downloads the frame and writes
the order file; the screen is done by hand in the order file.

## Track `selected`

Purpose: comment on papers that matter to Alberto or to colleagues, within the proportion
above. Chosen freely; the source is recorded (`own interest`, `colleague suggestion`,
`media coverage`, `follow-up`). Papers by people Alberto knows are allowed on this track; the
review then states the acquaintance in its opening callout, and the right-of-reply and
phrasing rules apply unchanged.

Exemplar reviews (well-analysed papers) are welcome in either track and are flagged with
`verdict = sound` in the registry.
