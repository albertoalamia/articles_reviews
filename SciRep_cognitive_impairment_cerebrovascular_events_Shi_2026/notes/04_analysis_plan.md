# Analysis plan — stages 3 (frequentist) and 4 (Bayesian), Shi et al. 2026 (P002)

**Version 1.0 — 2026-11-21, draft for Alberto's review; section 3b added 2026-11-22.** Any change after review is logged in
section 7 and bumps the version; the version in force is quoted in `review.qmd`. Execution
follows the step schedule in section 8: Claude prepares one step, Alberto reviews and runs it, the
output is checked against the step's criteria, the step is committed before the next is prepared.

Written before any model of stages 3–4 is fitted. One specification, two inference engines:
every row of section 3 maps one-to-one onto a Stan program in `stan/`. Protocol v0.2 (G7, H3:
each estimand carries the sentence a reader needs to interpret its number).

Why re-analyse at all, given stage 2: the unadjusted hazard ratios reproduce, so the question is
not whether Table 2 follows from the counts but what the counts can and cannot support. The paper
reports relative hazards only, with death as censoring, and an adjusted estimate whose main
adjustment variable (age) has no reported coefficient or functional form; its conclusion is about
screening, which no reported quantity addresses. Stages 3–4 estimate, with uncertainty, (i) the
absolute risks the hazard ratios translate into, with death competing; (ii) how the age-adjusted
exposure effect depends on the age effect the paper does not report; (iii) what a positive MMSE
screen adds over age. Everything runs on the reconstruction of stage 2 (no covariates beyond
group) and on the age–sex population calibrated to Table 1; on the authors' data, if they arrive,
the same estimands are re-estimated with the measured covariates (section 7 will record the
switch).

## 1. Estimands

All contrasts are MMSE < 24 (CI) against MMSE ≥ 24 (NCI). Time is years from the paper's time
zero, whichever it is (the reconstruction inherits the paper's axis); 4 years is the last point
the numbers at risk fix, 4.2 years the end of the axis.

- **E1 — absolute risk with death competing**, per outcome (ischaemic stroke, any stroke) and
  group: the cumulative incidence at 4 and at 4.2 years from a piecewise-exponential model of the
  cause-specific hazards (stroke, death), with the risk difference and risk ratio CI − NCI;
  for death, the cumulative incidence by group. — *Reads as:* of 100 people with MMSE < 24
  followed for 4.2 years, this many have a first ischaemic stroke before dying of anything else,
  against this many of 100 with MMSE ≥ 24; the difference per 100 is the absolute excess the
  hazard ratio translates into in this cohort's age mix, a group comparison that includes the
  eleven-year age difference between the groups, not an effect for a person of given age.
- **E1b — cause-specific hazard ratios** for ischaemic stroke, any stroke and death from the same
  model (one group coefficient per cause, baseline hazard free per interval), with the stage 2
  Cox fits as the check. — *Reads as:* how many times higher the rate of a first event is among
  those with MMSE < 24 than among those with MMSE ≥ 24 who are still event-free at the same time,
  averaged over the follow-up; unadjusted, so part of it is age.
- **E1c — time pattern**: the ratio of each cause's rate in the tail (4, 4.2] to its rate over
  years 0–4, by group, and the group HR estimated separately before and after year 4. —
  *Reads as:* 1 means a constant event rate; a ratio of 30 or 80 means the event dates the
  numbers at risk imply pile up in the last ten weeks of follow-up, which no cohort produces
  unless event dates were assigned to the end of follow-up; the before/after HRs say whether the
  group contrast rests on the dated events or on the piled-up ones.
- **E2 — exposure hazard ratio for people of the same age and sex, as a function of the age
  effect**: in the calibrated population (ages and sex per group from Table 1, A6), the HR for
  MMSE < 24 that reproduces the Table 2 counts when a decade of age multiplies the hazard by
  θ_age ∈ {1, 1.25, 1.5, 1.75, 2, 2.5} and being male by 1.3 (stage 3: θ_age fixed, profile over
  the grid); and under three priors on θ_age (stage 4: "as Model 1 implies", "as population
  studies report", "unknown between 1 and 3"). Also, per outcome, the θ_age at which the
  adjusted HR equals Model 1. — *Reads as:* the hazard ratio between two people of the same age
  and sex who differ in MMSE status, if a decade of age multiplies the hazard by θ_age; the paper
  does not report θ_age, so the number is shown for several values and the reader picks the one
  they find credible for this cohort; the paper's Model 1 corresponds to θ_age ≈ 1.5.
- **E3 — what a positive screen adds over age**, derived from E2's model at each θ_age, no new
  fit:
  - E3a *age-equivalent*: log(HR_CI) / log(θ_age) decades, the years of age that carry the same
    hazard as MMSE < 24. — *Reads as:* "an MMSE below 24 carries the stroke hazard of being this
    many years older"; under 10 years the screen tells a clinician less than the birth date.
  - E3b *discrimination*: the c-index of the 4.2-year stroke risk ranking by age alone and by age
    plus MMSE status, and its gain, in the calibrated population (closed form over the population,
    simulation for the interval). — *Reads as:* the probability that a randomly chosen future
    case is ranked above a randomly chosen non-case (0.5 coin toss, 1 perfect); a screening test
    is worth adding only if the gain over age is material.
  - E3c *screening metrics at 4.2 years*: sensitivity 15/81 (ischaemic stroke), specificity,
    positive and negative predictive value, with binomial intervals; and, from E2's model, the
    same metrics for "age ≥ 65" and for "age ≥ 65 or MMSE < 24". — *Reads as:* of every 100
    people who will have a stroke in four years, how many the MMSE flags (and how many of those
    flagged go on to have one); compared with flagging by age alone.

- **E5 — the effect of cognition, not of a cut-off** (source B only; added 2026-11-22, see §3c):
  the hazard ratio per standard deviation of latent cognition θ, measured by the MMSE through a
  measurement model with education-specific item parameters, with death competing; and the share
  of the 192 "impaired" whose θ is within the range of the "unimpaired". — *Reads as:* how much the
  stroke rate changes per unit of cognition as the MMSE items measure it, once the score's dependence
  on schooling is in the measurement part and not in the exposure; and how many of those labelled
  impaired by "< 24" the scale itself cannot separate from the rest.

Not estimands: Model 2 (an undisclosed subset, four more covariates); anything on the continuous
MMSE, education-specific cut-offs, or MMSE × age interaction; all need the authors' data and
move to section 7 if they arrive.

## 2. Data

- **Source A (default): the stage 2 reconstruction**, `data/derived/recon_persons.csv` from
  `R/01_prepare_data.R`, documented in `data/derived/RECONSTRUCTION_LOG.md` (assumptions A1–A5).
  For E1 the data are aggregated to one row per group × interval × cause: events and person-years
  (`data/derived/pem_counts.csv`), intervals (0, 1], (1, 2], (2, 3], (3, 4], (4, 4.2]. Events per
  cell are fixed by the reconstruction; person-years depend on timing within interval, so the
  main analysis uses the uniform scenario (replicate 1) and the early and late scenarios bound
  the person-years (sensitivity). Under A5 a person with another stroke stays at risk of
  ischaemic stroke and of death until censoring; nobody has two events.
- **Source A′: the calibrated population** for E2–E3, `data/derived/calibrated_population.csv`
  from `R/lib_population.R` (moved out of `R/05_model1_age_confounding.R`, same code): 3,875
  rows with group, age (shifted log-normal truncated at 90, fitted to the Table 1 median and
  quartiles per group; A6), male (Table 1 shares, independent of age within group), follow-up
  4.1 years. No individual event is attached to an age: the likelihood for E2 uses the group
  totals only (section 3), so the age effect is not identified by these data, by construction.
- **Source B: the authors' data** if they arrive (request 2026-11-20; window to 2026-12-11).
  Same estimands; E1 on the real times, E2 with age as a measured covariate (then θ_age is
  estimated, not assumed), E3 with the real age–MMSE joint distribution; source A becomes a
  sensitivity analysis. E5 (§3c) needs, in addition, the MMSE at item or domain level (the 30
  items, or the 11 domain scores); with total scores only, E5 reduces to a measurement-error
  model with an assumed reliability and is reported as a sensitivity analysis, not an estimate.
  Item-level scores are the first addition to the data request if the authors engage.
- Unit: person (3,683 + 192); for E1 the aggregated cell (2 groups × 5 intervals × 2 causes per
  model, two models: {ischaemic, death} and {any stroke, death}).
- Outcomes: counts per cell with person-years offset (E1); counts per group (E2).
- Covariates: group (0/1); interval (factor, 5 levels); cause (factor); age centred at 50 and in
  decades; male (0/1). No missing data by construction.

## 3. Model, shared by both stages

| element | specification | R (stage 3) | Stan (stage 4) |
|---|---|---|---|
| E1 outcome family and link | events_{g,j,k} ~ Poisson(PY_{g,j,k} · h_{g,j,k}), log link (piecewise exponential; the likelihood of a Cox model with a step baseline) | `glm(events ~ 0 + interval:cause + ci:cause + offset(log(py)), poisson)` | `stan/pem_competing.stan` |
| E1 fixed effects | log h_{g,j,k} = α_{j,k} + β_k · CI_g (one baseline per interval and cause, one group effect per cause) | as above | same |
| E1 derived | CIF_k(t) = Σ_j ∫ h_k S(u) du with S(u) = exp(−Σ_k H_k(u)), closed form per interval; RD, RR; tail ratio exp(α_{5,k} − log-weighted mean of α_{1..4,k}) per group; before/after HR from a variant with β_k × 1[j = 5] | parametric bootstrap from the asymptotic normal of the coefficients (10,000 draws) | generated quantities, same formulas |
| E2 outcome family | events_g ~ Poisson(Σ_{i∈g} (1 − exp(−h_i · 4.1))), h_i = λ_0 exp(β_CI CI_i + β_age age_c,i + β_male male_i) | ML at fixed (β_age, β_male), two counts and two free parameters: the calibration of stage 2 with Poisson uncertainty; profile-likelihood interval for β_CI | `stan/exposure_age.stan`, β_age a parameter with prior (section 5) |
| E3 derived | E3a: β_CI / β_age · 10 years; E3b: c-index of the 4.2-year risk 1 − exp(−h_i · 4.2) ranking, age alone (β_CI = 0 ranking) vs age + MMSE, over the population pairs; E3c: metrics from the predicted risks | from the same draws | generated quantities |
| dispersion | none beyond Poisson (counts are the cells of a life table; overdispersion is not a question here) | — | — |
| random effects | none | — | — |

The {any stroke, death} model reuses the same program with the stroke counts replaced. Other
stroke is not modelled separately (0 of 192 against 9 of 3,683; the ML contrast is infinite).

## 3c. Pre-specified for source B: cognition as a latent variable (added 2026-11-22)

Written before any data, so that it is on record. Convention of Levy and Mislevy, *Bayesian
Psychometric Modeling*: a measurement part, a structural part, an outcome part, one Stan program.

- **Measurement.** Items $y_{ij}$, $j = 1..J$ ($J = 30$ binary items, or 11 ordinal domain scores),
  $$\Pr(y_{ij} \ge c) = \operatorname{logit}^{-1}\big(a_j(\theta_i - b_{jc}) \big), \qquad
  b_{jc} = b^{0}_{jc} + \delta_{j}\,\mathrm{edu}_i,$$
  a graded response model (two-parameter logistic for binary items) with location shifts $\delta_j$
  by education level: the "educational bias" the authors mention becomes a parameter per item
  instead of a property of the exposure. The total score and the cut-off at 24 are not used.
- **Structural.** $\theta_i \sim \mathrm{N}(\gamma_{a} a_i + \gamma_{e}\,\mathrm{edu}_i + \gamma_{m} m_i,\ 1)$:
  cognition depends on age, education and sex; its scale is fixed by the unit variance.
- **Outcome.** Cause-specific hazards as in E1, with $\theta_i$ in place of $\mathrm{CI}_i$:
  $\log h_{ik}(t) = \alpha_{jk} + \beta_k\,\theta_i + \beta_{ak} a_i + \beta_{mk} m_i + \beta_{ek}\,\mathrm{edu}_i$,
  $t \in I_j$, death competing. $\exp(\beta_k)$ is the hazard ratio per SD of cognition.
- **Derived.** The posterior of $\theta_i$ for each person; the share of the 192 with MMSE < 24
  whose posterior mean $\theta$ lies above the 10th percentile of the other group; $\exp(\beta_k)$
  for a difference in θ equal to the mean difference between the two MMSE groups, which is the
  quantity comparable to the paper's HR; the attenuation factor between that and the HR of the
  indicator.
- **What the paper's analysis is in this notation.** $\theta_i$ replaced by $\mathbf 1[\sum_j y_{ij} < 24]$:
  one item, no error, $\delta_j = 0$ for every item, and the education adjustment moved from the
  measurement part to the hazard, where it competes with the exposure for the same variance.
- **Priors.** $a_j \sim \mathrm{LogN}(0, 0.5)$; $b_{jc}$ ordered, $\mathrm{N}(0, 2)$; $\delta_j \sim \mathrm{N}(0, 0.5)$;
  $\gamma \sim \mathrm{N}(0, 1)$; $\alpha_{jk}$, $\beta_k$ as in §5. The MMSE ceiling (median 29 of
  30) means θ is measured well only in its lower range; the posterior SDs of $\theta_i$ say where.
- **Limitations, stated in advance.** One administration: no test-retest, so reliability comes
  from the item model, not from repetition; the model is identified by the item structure, and
  with domain scores only the discrimination parameters are weakly identified; with total scores
  only, none of it is identified without an assumed reliability. Fifteen exposed events bound the
  precision of $\beta_k$ whatever the measurement model does.
- **Stage mapping.** Stage 3 counterpart: a two-step version (factor scores from a frequentist
  GRM, then the Cox or PEM on the scores), reported as the approximation it is; stage 4: the joint
  program `stan/latent_cognition_pem.stan`, drawn with `lib/model_dag.R`.

## 3b. The models in notation (draft of the public section "The models, written out")

Added 2026-11-22 on Alberto's request: the paper's models and the proposed ones side by side in
mathematical notation, with what each parameter is, what the paper reads it as, and what the
p-values in the paper test. This is the draft of the review section; the Stan programs of
stage 4 are checked against the equations here.

### 3b.1 What the paper fits

**Cox proportional-hazards models** (Methods ll. 164–173), one per outcome $k \in \{$ischaemic
stroke, any stroke, death$\}$ and per covariate set $z$:

$$h_k(t \mid \mathrm{CI}_i, z_i) = h_{0k}(t)\, \exp\!\big(\beta_k\, \mathrm{CI}_i + \gamma_k^{\top} z_i\big),$$

with $z = \varnothing$ (unadjusted), $z = (\text{age}, \text{gender}, \text{education})$ (Model 1),
$z$ plus (homocysteine, ICAS, hypertension, occupation) (Model 2). Reported: $\exp(\hat\beta_k)$
with a Wald 95 % interval; $h_{0k}$ is profiled out and never shown; $\gamma_k$ is never shown.

What $\exp(\beta_k)$ is: the ratio of the *cause-specific hazards*, the instantaneous rate of a
first event of type $k$ at time $t$ among people still event-free at $t$, between a person with
MMSE < 24 and one with MMSE ≥ 24 *with the same $z$*, assumed constant over $t$ (proportional
hazards), with $t$ measured from an origin the paper does not state, among the people with
complete $z$ (an unstated number for Model 2), with death treated as independent censoring for
the stroke outcomes.

What the paper reads it as: "a 2.32 to 2.55 times higher risk" (Discussion). A hazard ratio is
not a risk ratio. The 4.2-year risk of a first ischaemic stroke in group $g$ is

$$F_{g}(t) = \int_0^{t} S_g(u)\, h_{g}(u)\, du, \qquad S_g(u) = \exp\!\Big(-\!\!\sum_{k'} \int_0^{u} h_{g k'}(v)\, dv\Big),$$

which needs the baseline hazard and the death hazard the paper does not report; with the counts
of Table 2 it is 7.8 % against 1.8 %, a risk ratio of 4.4 and a risk difference of 6 per 100 over
four years, before any adjustment.

How age enters: presumably $\gamma_{\text{age}} \cdot \text{age}_i$, linear on the log hazard, so
that each decade multiplies the hazard by $\theta_{\text{age}} = \exp(10\,\gamma_{\text{age}})$,
the same factor at 45 and at 75. In a rare-event setting the unadjusted and the adjusted
coefficients are tied by

$$\mathrm{HR}_{\text{crude}} \;\approx\; \exp(\beta_k)\times
\frac{\mathbb{E}\big[\exp(\gamma_k^{\top} z) \mid \mathrm{CI} = 1\big]}{\mathbb{E}\big[\exp(\gamma_k^{\top} z) \mid \mathrm{CI} = 0\big]},$$

the second factor being the confounding ratio: how much more hazard the exposed group carries
through $z$ alone. The paper gives the left side (4.55) and $\exp(\beta_k)$ (2.47) and so fixes
the confounding ratio at 1.84, without saying what $\gamma_k$ produces it. Section 3 E2 inverts
this identity.

**Kaplan–Meier curves** (Fig. 2): $\hat S_{gk}(t) = \prod_{t_j \le t}\big(1 - d_{gkj}/n_{gj}\big)$,
drawn as $1 - \hat S_{gk}(t)$ and labelled "cumulative incidence". Without competing events
$1 - S$ is the cumulative incidence; with death competing, the quantity that answers "what share
had a stroke by $t$" is $F_g(t)$ above (Aalen–Johansen in estimate form), and
$F_g(t) \le 1 - \hat S_{g,\text{stroke}}(t)$, the gap growing with the death rate. The stage 2
reconstruction puts the gap at 0.002 here: negligible in size, but the label is a different
quantity.

**What the p-values test.** Every p-value in the paper answers a question of the form "if $H_0$
were true, how often would data at least this far from it arise"; none of them is an estimate of
anything the conclusion needs.

| where | $H_0$ in symbols | was $H_0$ ever the question? | what the number hides |
|---|---|---|---|
| Table 1, 21 rows | $F_v^{\mathrm{CI}} = F_v^{\mathrm{NCI}}$ for each baseline variable $v$ | no: two groups defined by cognition differ in age by construction; the question is how much, and whether it matters for $\beta_k$ | the size of each difference (age: 11.5 years at the median) and its consequence; used instead to select $z$ for Model 2 |
| Fig. 2, log-rank | $h_k^{\mathrm{CI}}(t) = h_k^{\mathrm{NCI}}(t)$ for all $t$ | no: nobody doubted that older, less educated people have more strokes | the curves themselves, which here contradict the table |
| Methods, PH test | $\beta_k(t) = \beta_k$ for all $t$ | a model check, fine in itself | with 15 exposed events the test has power against gross departures only; "P > 0.05" is not evidence of proportionality |
| Table 2, intervals | implicitly $\beta_k = 0$ at the interval's edge | the interval is the useful part; its width ($\pm 0.65$ on the log scale) is set by 15 events | — |

### 3b.2 What this review fits

**E1, piecewise-exponential cause-specific hazards** on the life table the numbers at risk fix.
Intervals $I_j$, $j = 1..5$ ((0, 1], (1, 2], (2, 3], (3, 4], (4, 4.2]); causes $k \in \{$stroke,
death$\}$; groups $g$. In $I_j$ the hazard is constant:

$$h_{gk}(t) = \exp\!\big(\alpha_{jk} + \beta_k\, \mathrm{CI}_g\big), \quad t \in I_j; \qquad
D_{gjk} \sim \mathrm{Poisson}\!\big(\mathrm{PY}_{gj}\, h_{gk}\big).$$

This is the Cox model of the paper with $h_{0k}$ a step function, estimated instead of profiled
out: $\beta_k$ has the same meaning as the paper's unadjusted $\beta_k$ (stage 2 checks that the
two agree), and because $\alpha_{jk}$ is estimated the model can also give absolute quantities.
With $S_g(t_{j-1})$ the probability of being event-free at the start of $I_j$,
$h_{g\cdot} = \sum_k h_{gk}$ and $\Delta_j = |I_j|$,

$$F_{gk}(t_j) = F_{gk}(t_{j-1}) + S_g(t_{j-1})\, \frac{h_{gk}}{h_{g\cdot}}\, \big(1 - e^{-h_{g\cdot}\Delta_j}\big),
\qquad S_g(t_j) = S_g(t_{j-1})\, e^{-h_{g\cdot}\Delta_j}.$$

Derived: $F_{gk}(4)$, $F_{gk}(4.2)$; $\mathrm{RD}_k = F_{1k} - F_{0k}$; $\mathrm{RR}_k = F_{1k}/F_{0k}$;
the tail ratio $\exp(\alpha_{5k}) / \bar h_{k,0\text{–}4}$ with $\bar h$ the person-time-weighted
mean of $\exp(\alpha_{jk})$, $j \le 4$; and, in a variant, $\beta_k^{(0\text{–}4)}$ and
$\beta_k^{(4\text{–}4.2)}$.

Limitations, stated: the cells come from a reconstruction (A1–A5); the intervals are the
figure's, not chosen by the data; $\beta_k$ is still unadjusted, because the reconstruction has
no covariates; constant hazard within a year is a coarse step; the model inherits the paper's
time origin, whatever it is.

**E2, the exposure effect given an age effect**, on the calibrated population (A6). For person
$i$ with age $a_i$ (decades from 50), sex $m_i$, group $g_i$, follow-up $\tau = 4.1$:

$$\mu_i = 1 - \exp\!\big(-\tau\, \lambda_0\, e^{\,\beta_{\mathrm{CI}} \mathrm{CI}_i + \beta_{\text{age}} a_i + \beta_{m} m_i}\big),
\qquad D_g \sim \mathrm{Poisson}\Big(\sum_{i \in g} \mu_i\Big).$$

Two counts, two free parameters $(\lambda_0, \beta_{\mathrm{CI}})$ once $(\beta_{\text{age}},
\beta_m)$ are given: the likelihood is saturated, and $\exp(\beta_{\mathrm{CI}})$ is the
paper's Model 1 quantity, the hazard ratio between two people of the same age and sex, *as a
function of* $\theta_{\text{age}} = e^{10\beta_{\text{age}}}$. Stage 3 fixes $\theta_{\text{age}}$
on a grid; stage 4 gives it a prior and integrates. The model adds no information to the paper's
numbers: it makes visible the assumption the adjusted estimate rests on, which the paper leaves
implicit.

Limitations, stated: ages are a fitted distribution, not data (A6, with the ceiling as
sensitivity); education, correlated with age, is not in the model (it would lower
$\exp(\beta_{\mathrm{CI}})$ further); sex is independent of age within group by assumption;
constant hazard over the 4.1 years; the identity holds for rare events (here 2 %).

**E3, derived.** Age-equivalent $\Delta a = 10\,\beta_{\mathrm{CI}}/\beta_{\text{age}}$ years.
Discrimination: with $r_i = 1 - \exp(-4.2\, h_i)$ the 4.2-year risk, the c-index of a ranking $r$
is $\Pr(r_i > r_j \mid i \text{ case}, j \text{ non-case})$, computed for $r$ from age and sex
alone ($\beta_{\mathrm{CI}} := 0$) and from age, sex and MMSE; the gain is the second minus the
first. Screening metrics at 4.2 years from the same $r_i$ and a flag rule (MMSE < 24; age ≥ 65;
either).

### 3b.3 Parameters side by side (feeds the H3 table)

| symbol | the paper | this review | read as |
|---|---|---|---|
| $\exp(\beta_k)$, unadjusted | 4.55 / 3.99 / 4.16, Cox | same from the PEM (E1b), expected to agree | rate ratio between groups among the event-free; includes age |
| $\exp(\beta_k)$, adjusted | 2.47 / 2.28 / 1.83 (Model 1), $\gamma$ unreported | $\exp(\beta_{\mathrm{CI}})(\theta_{\text{age}})$, a curve, and a posterior under each prior | same-age, same-sex rate ratio, conditional on the age effect one believes |
| $h_{0k}(t)$ | profiled out | $\exp(\alpha_{jk})$ per year | the rate in the unexposed, per 100 person-years; the tail cell is the figure's anomaly |
| $1 - \hat S(t)$ | drawn, labelled cumulative incidence | $F_{gk}(t)$ with death competing | share of the group with a first stroke by $t$ |
| — | not reported | $\mathrm{RD}_k$, $\mathrm{RR}_k$ | absolute excess per 100 over 4.2 years |
| $\theta_{\text{age}}$ | not reported; ≈ 1.5 implied | fixed or prior | hazard multiplier per decade of age |
| — | "screening could be valuable" | $\Delta a$, c-index gain, sensitivity / PPV vs an age rule | what a positive screen tells beyond the birth date |

### 3b.4 Causal structure of the question (2026-11-22; computed in `review.qmd`, not drawn)

The structure the paper's Methods and Table 1 imply, drawn so that the meaning of each
coefficient can be read off it. Every arrow carries its source: **P** stated by the paper,
**D** standard for this design or population, **A** assumed here (an alternative the paper does
not discuss). The diagram is a statement about the structure of the problem, not about what the
authors believe. Competing risk and time origin are not graph edges and are noted below.

```r
# dagitty syntax; rendered with ggdag in review.qmd (shell.nix: dagitty, ggdag). Age and sex share
# one node: same edges, both in Model 1 (drawn separately the graph has 22 edges and no readable layout).
dag {
  CI      [exposure]     # MMSE < 24, measured 2012/13
  Stroke  [outcome]      # first ischaemic stroke, to 2015-12-31
  Death                  # all-cause death (competing event for Stroke)
  AgeSex                 # age (years) and sex
  Edu                    # education, three levels
  Occ                    # manual worker (29 % missing)
  Vasc                   # vascular risk measured 2010/11: hypertension, Hcy, ICAS, diabetes, lipids, smoking
  U       [latent]       # subclinical cerebrovascular disease, not measured
  S       [adjusted]     # analysed: MMSE available in 2012/13 and event-free until then
  AgeSex -> CI   AgeSex -> Stroke   AgeSex -> Death   AgeSex -> Vasc   AgeSex -> S
  Edu -> CI      Edu -> Stroke      Edu -> Occ        Edu -> S
  Occ -> Vasc
  Vasc -> CI     Vasc -> Stroke     Vasc -> Death     Vasc -> S
  U -> CI        U -> Stroke
  CI -> Stroke   CI -> Death
  Stroke -> Death
}
```

| edge | source | note |
|---|---|---|
| Age → CI, Sex → CI, Edu → CI | P | Table 1: 62.8 vs 51.3 years; 69 vs 56 % male; 48 vs 8 % primary schooling or less |
| Age → Stroke, Age → Death, Sex → Stroke, Sex → Death | D | population epidemiology; the paper adjusts for both in Model 1 |
| Edu → Stroke | D | socio-economic gradient; the paper adjusts for it in Model 1 |
| Age → Vasc, Vasc → Stroke, Vasc → Death | D / P | the paper's Model 2 covariates and Discussion |
| Vasc → CI | P | Introduction: vascular risk factors "associated with cognitive decline"; measured 2010/11, two years before the MMSE, so a cause of exposure status, not a mediator |
| Edu → Occ, Occ → Vasc | A | manual work as a socio-economic marker; the paper puts occupation in Model 2 without saying why |
| U → CI, U → Stroke | A | silent infarcts and small-vessel disease lower MMSE scores and precede clinical stroke; the alternative reading of the whole result ("CI marks disease already under way") |
| CI → Stroke, CI → Death | the hypothesis | what the paper's $\beta$ is meant to estimate |
| Stroke → Death | D | — |
| Age, Edu, Vasc → S | A / P | 1,512 of 5,440 without MMSE were "older and more vascular" (Results); the analysis conditions on S |

What the diagram says about the paper's coefficients, to be confirmed by `dagitty::adjustmentSets()`
in the review chunk:

- Without U, the minimal adjustment set for the total effect of CI on Stroke is {Age, Sex, Edu,
  Vasc} (plus S, conditioned on by design; confirmed by the review chunk, 2026-11-22): Model 1 leaves Vasc open; Model 2 adds three of its components plus Occ, which is not
  needed once Vasc is in. So neither model is the adjustment set the paper's own covariates
  imply, and Model 2 is fitted on the subset with Occ.
- With U, no adjustment set exists: the "independent" association is not identified as an
  effect of cognition on stroke by any choice of measured covariates. That is not a flaw of the
  paper's analysis but of its wording: "independently forecasted" is a prediction claim, which U
  does not threaten, while "cognitive impairment … heightens the risk" (Discussion) is a causal
  claim, which U does.
- Conditioning on S (analysing the 3,875) opens no backdoor path in this graph, since S has no
  descendant on the CI–Stroke path, but it changes the population: the estimates are for people
  who survived event-free to 2012/13 and completed an MMSE, and the paper reads them as for
  stroke-free adults aged 40+.
- Death is a competing event, not a confounder: the stroke hazard ratio is cause-specific
  whatever the adjustment; the cumulative incidence needs the death hazard (3b.2, E1).
- Time origin: if follow-up starts in 2010/11 while exposure is measured in 2012/13, the two
  years before the MMSE are immortal time for the exposed group; a graph does not show it and
  the reconstruction cannot resolve it (needs-data).

### 3b.5 DAGs of the stage 4 programs (drawn in `review.qmd` from this plan; redrawn from the programs in S3)

One graph per program with `lib/model_dag.R` (convention of Levy and Mislevy, *Bayesian
Psychometric Modeling*, as in the Metilfenidato manuscript): prior constants, parameters, derived
quantities, covariates, data; each node a line of the Stan program.

- `pem_competing.stan`: indices $g \in \{0, 1\}$, $j = 1..5$, $k \in \{1, 2\}$; covariates
  $\mathrm{CI}_g$, $\mathrm{PY}_{gj}$; parameters $\alpha_{jk}$, $\beta_k$ with priors
  $(\log 0.005, 1.5)$ and $(0, 1)$; derived $h_{gjk}$; data $D_{gjk}$; generated $F_{gk}(t)$, RD, RR,
  tail ratio.
- `exposure_age.stan`: index $i = 1..3875$; covariates $a_i, m_i, \mathrm{CI}_i$ (fixed by A6);
  parameters $\lambda_0, \beta_{\mathrm{CI}}, \beta_{\text{age}}, \beta_m$ with their priors,
  $\beta_{\text{age}}$'s switchable (P1, P2, P3); derived $\mu_i$, $E_g$; data $D_g$; generated
  $\Delta a$, c-index, screening metrics.

## 4. Stage 3 specifics (frequentist)
- R 4.4.3 in the pinned shell; `glm` (ML); survival only for the check against stage 2.
- Intervals: Wald on the log scale for α and β; parametric bootstrap (MVN of the coefficients,
  10,000 draws, seed 20261121) for CIF, RD, RR, tail ratios; profile likelihood for β_CI in E2.
- Diagnostics: deviance against the saturated model (the PEM has one parameter per interval and
  cause, so only the group effect is a restriction: deviance tests proportionality across
  intervals per cause); the E1b HRs against the stage 2 Cox fits (agreement within 0.05 expected,
  the baseline being a step function); E2 at θ_age = 1 against the unadjusted HR.

## 5. Stage 4 specifics (Bayesian)
- Priors, E1: α_{j,k} ~ Normal(log(0.005), 1.5) (rates per person-year of order 0.5 %, a
  decade either way); β_k ~ Normal(0, 1) (HR between 0.14 and 7 at 95 %). Prior predictive:
  cumulative incidences at 4.2 years spread over 0–20 %, not concentrated.
- Priors, E2: λ_0 ~ LogNormal(log(0.004), 1.5); β_CI ~ Normal(0, 1); β_male ~ Normal(log 1.3,
  0.15); β_age under three priors, run separately and reported side by side:
  - P1 "as Model 1 implies": θ_age ~ LogNormal(log 1.55, 0.10);
  - P2 "as population studies report": θ_age ~ LogNormal(log 2, 0.15) (stroke incidence roughly
    doubles per decade after middle age; values confirmed by Alberto 2026-11-22 after reading the
    plan; the literature reference is quoted at stage 5, before anything is published);
  - P3 "unknown": log θ_age ~ Uniform(0, log 3).
  The posterior for β_CI under P3 is the honest statement of what the paper's numbers say about
  the age-adjusted effect without an assumption on the age effect.
- Sampler: 4 chains, 1000 warmup, 1000 sampling, adapt_delta 0.95, seed 20261121 (+ model
  index), via `run_model.sh` (adapted from P001: model name, data file, `--prior-only`,
  `--prior` P1/P2/P3 for `exposure_age`).
- Diagnostics: R-hat < 1.01, bulk and tail ESS > 400, no divergences, E-BFMI > 0.3; posterior
  predictive: cell counts of the life table against the observed (E1); the two group totals (E2).
- Sensitivity: E1 with person-years from the early and late scenarios; E1 with β_k ~ Normal(0, 2);
  E2 with the age ceiling at 80 and 100 (data switch).

## 6. Comparison table planned for `review.qmd`

Rows = estimands; columns = the paper's value and its reading (left half, already in
`review.qmd`), stage 2 reproduction, stage 3 estimate (interval), stage 4 posterior median
(interval), and the H3 reading sentence. Expected: stage 3 and stage 4 agree for E1 (the priors
are weak against 66–75 and 71 events per cause; the 15 exposed events carry the group effect,
where a Normal(0, 1) prior will shrink the HR by a few percent — that difference is the prior's);
for E2 the difference between stages is the point of the exercise: stage 3 conditions on θ_age,
stage 4 integrates over a stated prior.

## 7. Deviations from this plan
| date | what changed | why |
|---|---|---|
| 2026-11-22 (S1) | Stan data files: `pem_{isch,any}.json` (uniform replicate 1) plus `_early` / `_late` copies with the bounding person-years; `exposure_age_{isch,any,death}.json` carry the ages at the three ceilings (`age_90`, `age_80`, `age_100`) and an `age_max` switch, instead of one file per ceiling; the E1 wide-prior sensitivity is a `beta_sd` switch (1; 2) rather than a `prior_scale` multiplier; ages are written to 3 decimals (years) so that stages 3 and 4 read identical inputs | one population file per outcome keeps the data folder small (the population is the same for the three outcomes); the switches are the keys `run_model.sh` rewrites, as in P001 |
| 2026-11-22 (S2) | E1 checks: the tolerance for the PEM hazard ratios against the stage 2 Cox fit is 0.15, not 0.05; the 4.2-year check of the split model against the crude proportion is 0.005 (the constant hazard over a 0.2-year tail holding 19 exposed events at its start overshoots by 0.006 in that group; the late scenario undershoots; the two bracket the crude 7.8 %); the E2 check at θ_age = 1 compares with Table 2's unadjusted HR, not with the stage 2 Cox | a step baseline against exact event times in a tail that holds half the events: the PEM is within 1–3 % of Table 2 and the exponential model within 2 %, while the stage 2 Cox under uniform timing is 1–2 % below Table 2 (first run of `R/06`: differences 0.06–0.14 and 0.02–0.11) |
| 2026-11-22 (S2) | E1 absolute risks are reported from two structures: the planned proportional group effect, and the group effect split before and after year 4; the figure and the 4.2-year values come from the early scenario (everyone followed to 4.2) | the proportional model gives the exposed group 4.3 % by year 4 where the Aalen–Johansen estimate is 2.6 %: it averages a group effect of 2.5 before year 4 and 7.5 after; the split model follows the data. Under uniform censoring in (4.0, 4.2] the 4.2-year risk from the uniform scenario is an extrapolation of the tail hazard (10.7 % against the 7.8 % observed): the 4.2-year value is identified only when everyone is followed to 4.2 |
| 2026-11-22 | §1 E5 and §3c added: cognition as a latent variable measured by the MMSE items, with education in the measurement part; pre-specified for the authors' data only | the paper's claim is about cognitive impairment, its analysis is about one score below a cut-off; the difference is a measurement model, which only item-level data can fit. Added after S2 so that it is on record before any reply from the authors (Alberto, 2026-11-22) |

## 8. Execution schedule

| step | Claude prepares | Alberto runs | check before committing |
|---|---|---|---|
| S1 | `R/lib_population.R` (population code out of `R/05`), `R/01_prepare_data.R` block for `pem_counts.csv` (three scenarios), `calibrated_population.csv`, Stan JSON in `data/derived/stan_data/` (`pem_isch.json`, `pem_any.json`, `exposure_age_{isch,any,death}.json`, with `prior_only`, `prior`, `age_max` switches); `R/05` sources the lib and must reproduce its tables unchanged | `Rscript <art>/R/01_prepare_data.R`; `Rscript <art>/R/05_model1_age_confounding.R` | `stage2_*` tables byte-identical (diff); cell events sum to Table 2; person-years per scenario as expected |
| S2 | `R/06_fit_frequentist.R`: E1 (two models), E1b vs stage 2, E1c, bootstrap; E2 profile over the θ_age grid; E3 derived; tables `output/tables/stage3_*.csv`, figures `stage3_cif.png`, `stage3_hr_by_age_effect.png` | `Rscript <art>/R/06_fit_frequentist.R` (seconds) | E1b within 0.05 of stage 2; CIF at 4.2 (early person-years) within 0.002 of the crude proportions; E2 at θ_age = 1 equals the unadjusted HR; E2 at the implied θ_age equals Model 1 |
| S3 | `stan/pem_competing.stan`, `stan/exposure_age.stan`, `run_model.sh`; prior predictive section of `R/03_postprocess.R` | `./<art>/run_model.sh pem_competing --prior-only` etc.; `Rscript <art>/R/03_postprocess.R --prior` | both compile; prior predictive covers the observed cells without concentrating |
| S4 | runs: `pem_competing` × {isch, any} × {main, early, late, wide prior}; `exposure_age` × {isch, any, death} × {P1, P2, P3} × {ceiling 90; 80, 100 for P2}; `R/03_postprocess.R` main: estimands, diagnostics, PPC, side-by-side table `stage4_side_by_side.csv`, figures | `./<art>/run_all.sh` (≈ 21 runs, minutes); `Rscript <art>/R/03_postprocess.R` | all runs pass the thresholds; stage 3 vs 4 as section 6 expects |
| S5 | H3 right half and the results sections of `review.qmd`; STATUS; registry `status` | render | — |
