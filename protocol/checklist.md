# Appraisal protocol — version 0.1 (2026-10-25)

Applied identically to every paper. Each item gets an answer and, where a concern arises, an
entry in `registry/issues.csv` with an evidence tag:

- **confirmed** — follows from the paper's own text, tables or figures; no external data needed.
- **inferred** — a reasonable reading of what the paper reports, but it depends on an assumption
  about what the authors did.
- **needs-data** — can only be settled with the raw data or the authors' code.

Record the protocol version in the article's `CLAUDE.md` and in `registry/papers.csv`.
Changes to this file bump the version; old reviews are not re-run silently.

## A. Selection and provenance

- A1. Track: `systematic` (chosen by the sampling rule in `protocol/selection.md`) or `selected`
  (chosen for interest, or suggested by a colleague). Name the source.
- A2. Version reviewed: accepted manuscript, version of record, preprint. DOI, dates received /
  accepted / published.
- A3. Peer-review status and whether reviewer reports are public.
- A4. Data and code availability as stated, and as actually found.

## B. Design

- B1. Question and pre-registration: is the primary hypothesis stated, and was it registered?
- B2. Design type (RCT, crossover, cohort, case-control, within-subject experiment, observational).
- B3. Unit of analysis vs unit of randomisation / sampling (pseudoreplication, clustering,
  repeated measures).
- B4. Control condition: appropriate, and is the comparison the one the conclusion needs?
- B5. Confounding: are the manipulation and the outcome separable (e.g. a stimulus that also
  changes posture, feeding, time of day)?
- B6. Order, carryover and washout in crossover or repeated designs.
- B7. Sample size justification: does the power calculation match the primary contrast?
- B8. Blinding of participants, operators, raters, and of data extraction.
- B9. Manipulation check: evidence that the intended state or exposure actually occurred.

## C. Measurement

- C1. Operationalisation: does the measured quantity map onto the construct claimed?
- C2. Reliability reported (inter-rater, test-retest, internal consistency) and adequate?
- C3. Validity evidence for the instrument in this population or species.
- C4. Scale type honoured: ordinal data not treated as interval without justification; counts
  modelled as counts.
- C5. Derived scores: change scores, ratios, composites — defined precisely, sign preserved,
  shared-baseline artefacts acknowledged.
- C6. Missing data: amount, mechanism, handling.
- C7. Measurement conditions and covariates recorded (environment, time, device settings).

## D. Model adequacy

- D1. Model matches the design (random effects for repeated measures, clustering, order).
- D2. Distributional family matches the outcome.
- D3. Assumption checks on the right object (residuals, not raw data; posterior predictive
  checks for Bayesian models).
- D4. Interactions tested where parallel slopes are assumed.
- D5. Covariates: pre-specified vs post hoc; measured confounders left out.
- D6. Multiplicity: number of outcomes and tests vs how inference is adjusted or framed.
- D7. Model selection and reporting: are alternative models reported, or only the winning one?
- D8. For Bayesian analyses: priors stated and justified, convergence diagnostics, sensitivity.

## E. Internal consistency

Recompute whatever can be recomputed from reported numbers (functions in `lib/consistency.R`).

- E1. Test statistics and p-values from means, SDs and n (statcheck logic).
- E2. GRIM / GRIMMER: are reported means and SDs arithmetically possible for the n and scale?
- E3. Derived quantities: do differences of means equal reported mean differences; do signs agree?
- E4. Figures vs tables vs text: same numbers, same direction, same significance markers.
- E5. Degrees of freedom and n consistent across sections.
- E6. Duplicated or contradictory sentences, which often signal late edits to results.

## F. Reporting guidelines

- F1. Guideline claimed (ARRIVE, CONSORT, STROBE, PRISMA, SPIRIT) and item-by-item check of the
  items that matter for the critique.
- F2. Effect sizes with uncertainty intervals, not only p-values.
- F3. Exact p-values, exact n per analysis.
- F4. Software, versions, and code.

## G. Inference and conclusions

- G1. Do the conclusions follow from the results as reported?
- G2. Does the discussion contradict any result?
- G3. Generalisation beyond the sample, population, species or setting.
- G4. Causal language in non-causal designs.
- G5. Claims about mechanism (e.g. neurotransmitters) labelled as speculation or not.
- G6. Comparative claims (vs other groups or species) made without the comparison in the data.

## H. Verdict

One of: `sound`, `minor concerns`, `major concerns`, `conclusions not supported`. Written with
the phrasing rule: describe inconsistencies with the reported data, never intent.

## I. Right of reply

- I1. Authors contacted (date, channel, what was sent) before public posting.
- I2. Reply received and incorporated; disagreements stated fairly.
- I3. Post-publication route taken (blog only, PubPeer, Matters Arising, letter to editor).
