# Selection rules — version 0.3 (2026-11-25)

Two tracks are kept separate in `registry/papers.csv` and are never pooled when describing
the literature. Only the `systematic` track enters the meta-research; the `selected` track is
commentary.

Version history: v0.1 (2026-10-25) set the two tracks and left the systematic rule open.
v0.2 fixes the systematic sampling rule before the first systematic paper and caps the
`selected` share. v0.3 (2026-11-25), written after batch B01 and before B02, replaces the single
journal with a list of ten journals per field, one drawn at random for each batch, samples
field journals without the subfield filter, states that open access is not a criterion, and
adds requests from colleagues to the `selected` track. The rule is not changed within a batch; changes between
batches get a new version number here.

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
- **Journals.** Ten per field, listed in `protocol/journals.csv` with their linking ISSN:

  | Field | Multidisciplinary (subfield filter applied) | Field journals (sampled whole) |
  |---|---|---|
  | psychiatry | Scientific Reports, PLOS ONE | JAMA Psychiatry, The Lancet Psychiatry, The British Journal of Psychiatry, Psychological Medicine, Journal of Affective Disorders, BMC Psychiatry, Psychiatry Research, Translational Psychiatry |
  | ethology | Scientific Reports, PLOS ONE, Royal Society Open Science, Animals | Animal Behaviour, Behavioral Ecology, Behavioral Ecology and Sociobiology, Ethology, Applied Animal Behaviour Science, Animal Cognition |

  The list was fixed on three criteria, before any batch was drawn from it: the journal publishes
  original empirical research of the field every month; it is indexed in OpenAlex with dated
  articles; and the ten together span multidisciplinary open-access journals, the general
  journals of the field with the widest readership, and its large-volume journals. Nothing about
  the expected quality of a journal entered the choice, and neither did open access. The
  programme is at its start and the list is expected to grow: it may be changed between
  batches, never within one, and each change is a new version of this file with its reason.
- **One journal per batch, drawn at random.** At each batch the journals of the field not yet
  used in the current cycle are sorted by ISSN-L and one is drawn with
  `random.Random(seed).choice`; the seed is the date of the draw (`YYYYMMDD`), the same seed
  then used for the papers. A cycle ends when every journal of the current list has been used;
  the next batch starts a new cycle. The journal of a batch is therefore not known before the
  day of its draw, and a journal added to the list enters the cycle in progress.
  `tools/journal_draw.py` reads the batches so far from `registry/batches.csv` and makes the
  draw. Batch B01 (psychiatry, Scientific Reports) was drawn under v0.2 and counts as the first
  batch of the first psychiatry cycle.
- **Access.** A paper is not skipped because it is behind a paywall: once it has passed the
  screen on title and abstract, the full text is obtained through a library, from the authors
  or by purchase. Restricting the frame to open access would select journals and funders.
- **What the sample represents.** Each journal of the list contributes one paper per cycle, so the
  systematic sample is stratified by journal with equal weight, not proportional to the number
  of papers a journal publishes. Results are reported for these journals and by journal type,
  not for the field as a whole. v0.2 kept the venue constant across the two tracks; v0.3 gives
  that up for the systematic track.
- **Window.** One calendar month of publication dates, chosen at least three weeks in the past
  (so the month is complete in the index) and at most four months old (so the authors can be
  reached for the right of reply). If no paper of the frame is eligible, the frame is extended
  to the month before, with the same seed, and the extension is recorded in the batch row.
- **Field filter.** `type:article` always. For the multidisciplinary journals, OpenAlex
  `primary_topic.subfield`:
  - psychiatry: 2738 *Psychiatry and Mental health*;
  - ethology: 1103 *Animal Science and Zoology*, 1105 *Ecology, Evolution, Behavior and
    Systematics*, 2802 *Behavioral Neuroscience*.

  For the field journals no subfield filter is applied: the journal defines the field. (In
  October 2026 the psychiatry subfield covered 37 of 118 articles of BMC Psychiatry and 11 of 36
  of Psychological Medicine; filtering would drop most of a psychiatric journal for reasons of
  topic labelling.) Batches alternate between the fields, psychiatry first (P001 was ethology).

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
series, editorials, letters, conference abstracts and corrections (some journals have these
indexed as articles); software, methods and benchmark papers whose claim is about
a tool rather than about subjects; papers with an author personally known to Alberto; papers
whose full text cannot be obtained by any of the routes under Access, with the attempts logged. Nothing about design quality or statistics is a reason to
exclude, or the sample stops being blind.

### Record

`registry/batches.csv`: one row per batch with track, field, journal, ISSN, window, subfields
(empty for a field journal), frame size, seed, date drawn, number screened, DOI picked and registry id. The frame and the
order files sit in `registry/batches/`. `tools/journal_draw.py` draws the journal of the batch; `tools/sample_frame.py` downloads the
frame and writes the order file; the screen is done by hand in the order file.

## Track `selected`

Purpose: comment on papers that matter to Alberto or to colleagues, within the proportion
above. Chosen freely; the source is recorded (`own interest`, `colleague suggestion`,
`colleague request`, `media coverage`, `follow-up`).

Colleagues may ask for the review of a paper that interests them. A request always goes in
this track, never in the systematic one, and counts in the proportion above; Alberto decides
whether to take it. The registry records the source as `colleague request`. The opening
callout of the review states that the review was requested and whether the person who asked is
an author of the paper or has a stated interest in it; the person is named only with consent.
The protocol, the right of reply of the authors and the phrasing rules apply unchanged, and
the person who asked sees the review when it is published, not before.
 Papers by people Alberto knows are allowed on this track; the
review then states the acquaintance in its opening callout, and the right-of-reply and
phrasing rules apply unchanged.

Exemplar reviews (well-analysed papers) are welcome in either track and are flagged with
`verdict = sound` in the registry.
