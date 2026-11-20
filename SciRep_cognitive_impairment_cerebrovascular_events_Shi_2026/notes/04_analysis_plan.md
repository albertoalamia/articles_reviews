# Analysis plan — stages 3 (frequentist) and 4 (Bayesian)

Written before any model of stages 3–4 is fitted. One specification, two inference engines:
every row below must map one-to-one onto the Stan program. Changes after fitting are logged at
the end, with the reason.

## 1. Estimands
What quantities answer the paper's question, on which scale, with which contrasts.
- E1:
- E2:

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
