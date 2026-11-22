# Analysis plan — stages 3 (frequentist) and 4 (Bayesian)

Written before any model of stages 3–4 is fitted. One specification, two inference engines:
every row below must map one-to-one onto the Stan program. Changes after fitting are logged at
the end, with the reason.

## 1. Estimands
What quantities answer the paper's question, on which scale, with which contrasts. For each, one
sentence saying how a reader should interpret the number (scale; conditional on what; typical
unit or average over units; what 0 or 1 means), which becomes the right half of the estimates
table in `review.qmd` (protocol H3).
- E1: … — reads as: …
- E2: … — reads as: …

## 2. Data
- Source (authors' data / digitised / simulated) and the log that documents it:
- Unit of analysis, number of units, rows per unit:
- Outcomes and their natural scale and support (count, positive continuous, bounded, …):
- Covariates and how they are coded (reference levels, centring):
- Exclusions and missing data, and how they are handled:

## 3. Model, shared by both stages

| element | specification | lme4 / glmmTMB | Stan |
|---|---|---|---|
| outcome family and link | | | |
| fixed effects | | | |
| random effects | | | |
| contrasts / derived quantities | | | |
| dispersion / variance structure | | | |

## 3b. The models in notation (protocol H4; draft of the review section "The models, written out")

### 3b.1 What the paper fits
The paper's model(s) in notation, from the Methods wording (quote it). For each parameter: what
it is (scale, conditional on what, for which unit), what the paper reads it as (quote), what it
hides. Then the p-value table:

| where | $H_0$ in symbols | was $H_0$ the question? | what the number hides |
|---|---|---|---|

### 3b.2 What this review fits
The stage 3–4 model(s) in the same notation, derived quantities written out, and the model's own
limitations listed under it.

### 3b.3 Parameters side by side (feeds the H3 table)

| symbol | the paper | this review | read as |
|---|---|---|---|

### 3b.4 Causal diagram of the question
dagitty code (rendered with ggdag in `review.qmd`); every edge labelled P (stated by the paper),
D (standard for the design), A (assumed here); adjustment sets from `dagitty::adjustmentSets()`;
what the diagram says about the paper's coefficients; what a graph cannot show (time origin,
competing events, selection into the sample).

### 3b.5 Graphical models of the stage 4 programs
One plate diagram per Stan program (`lib/plate_diagram.R`): data nodes, parameters, prior
constants, derived quantities; each node a line of the program.

## 4. Stage 3 specifics (frequentist)
- Software and version; estimation method (ML/REML, df method):
- Intervals (profile, Wald, bootstrap):
- Diagnostics (residuals, dispersion, influence):

## 5. Stage 4 specifics (Bayesian)
- Priors, with justification and scale (weakly informative by default; prior predictive check):
- Sampler settings (chains, warmup, sampling, seed) — defaults in `run_model.sh`:
- Diagnostics (R-hat, ESS, divergences, E-BFMI), posterior predictive checks:
- Sensitivity analyses (alternative priors, alternative families):

## 6. Comparison table planned for `review.qmd`
Rows = estimands; columns = authors' reported value, stage 2 reproduction, stage 3 estimate
(interval), stage 4 posterior median (interval). State what difference between stages 3 and 4
would be attributable to priors rather than to model choice.

## 7. Deviations from this plan
| date | what changed | why |
|---|---|---|
