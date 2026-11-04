# Simulation log — condition contrasts of Bukhari et al. 2026

Purpose: the six treatment-vs-control contrasts (Table 2, Figure 2, Results 2.4) are reported as
p-values only, and no per-donkey condition values are available. This log records (1) what the
reconstructed unsigned changes of Figures 3–4 (`DIGITISATION_LOG.md`) determine about those
contrasts exactly, without simulation, and (2) the complete per-donkey datasets simulated to be
consistent with every known quantity, on which the model the paper describes was refitted.
Code: `R/lib_simulate_conditions.R`, `R/06_condition_contrasts.R` (2026-11-04; seed 1, 200
replicates per scenario). Nothing below is the authors' data.

## 1. What is determined without simulation

Per outcome and treatment we know the 34 unsigned changes |d| with d = control − treatment
(figures) and the control and treatment means and SDs (Table 2). The signs are unknown, but

- the mean of the signed d is mu_control − mu_treatment (Table 2, ±0.01 from rounding);
- the sum of d² equals the sum of |d|² (figures; exact for ΔSBR, ±1 ms and ±0.05 °C per value
  of plotting rounding for ΔRMSSD and ΔET).

Hence SD(d), the paired t, its CI and the control–treatment correlation follow exactly, and the
signs enter only through the "reversed sum": the |d| of donkeys that moved against the group
direction add up to R = (Σ|d| − 34·|mean d|)/2. `output/tables/contrasts_exact.csv`:

| contrast | mean d | SD of signed d | paired t (df 33) | p | reported p | consistent | r(control, treatment) | reversed sum R |
|---|---|---|---|---|---|---|---|---|
| SBR positive | −19.00 | 6.63 | 16.7 | 1e-17 | 0.002 | no | 0.62 | 0 |
| SBR negative | 6.74 | 3.30 | 11.9 | 2e-13 | <0.001 | yes | 0.84 | 1 (±0.17) |
| RMSSD positive | −32.97 | 24.5 | 7.8 | 5e-9 | 0.005 | no | 0.47 | 81 (77–85) |
| RMSSD negative | −10.09 | 7.97 | 7.4 | 2e-8 | <0.001 | yes | 0.92 | 11 (7–15) |
| ET positive | −0.78 | 0.61 | 7.4 | 1e-8 | <0.001 | yes | 0.81 | 0.5 (0.0–1.0) |
| ET negative | −1.20 | 0.64 | 10.9 | 2e-12 | <0.001 | yes | 0.78 | 0.5 (0.0–1.0) |

The 02_consistency_checks.R block A used the Table 2 Δ SD as the SD of the signed differences;
that overstated t for RMSSD (13.8 and 8.9 instead of 7.8 and 7.4) because the Δ rows are SDs of
unsigned values. The two exact p-values remain inconsistent with the data by a wide margin:
p = 0.005 needs t = 3.0, the data give 7.8; p = 0.002 needs t = 3.4, the data give 16.7.

Donkeys that moved against the group direction (`contrasts_reversed_counts.csv`, exhaustive
enumeration of sign patterns whose reversed sum lies in the admissible interval):

| contrast | admissible sign patterns | donkeys reversed |
|---|---|---|
| SBR positive | 1 | 0: every donkey blinked more with lucerne |
| SBR negative | 1 | exactly 1, the donkey with ΔSBR = 1 blink/min |
| RMSSD positive | 584 | 2 to 4 (mode 3) had lower RMSSD with lucerne than in control |
| RMSSD negative | 676 | 1 to 6 (mode 3) had lower RMSSD with the clipper than in control |
| ET positive | 467 | 1 to 5 (mode 3) |
| ET negative | 32 | 0 to 2 |

Positive vs negative, never tested in the paper (`contrasts_pos_vs_neg_bounds.csv`): the mean
difference is known, the SD depends on the unknown within-donkey correlation of the two changes.

| outcome | positive − negative | t if independent | p | t in the worst case (ρ = −1) | p | correlation at which p = 0.05 |
|---|---|---|---|---|---|---|
| SBR | 25.7 blinks/min | 20.3 | 3e-20 | 15.1 | 2e-16 | none |
| RMSSD | 22.9 ms | 5.2 | 1e-5 | 4.1 | 0.0002 | none |
| ET | −0.42 °C | 2.8 | 0.009 | 2.0 | 0.059 | −0.85 |

So SBR and RMSSD differ between the two treatments under any pairing; ET differs unless the two
changes of a donkey are correlated at −0.85 or below.

## 2. Simulated complete datasets

For each outcome, 200 datasets per scenario of ρ_dd ∈ {−0.5, 0, 0.5}, the assumed correlation
between a donkey's two changes (the one quantity nothing pins down):

1. Signs: a sign pattern drawn uniformly from the admissible ones (subset-sum dynamic programme,
   backward sampling), applied to the exact unsigned changes; zeros carry no sign.
2. Control values: 34 normal deviates rescaled to exactly the Table 2 control mean and SD.
3. Pairing: Gaussian-copula rank coupling of control values and the two signed changes with the
   correlations implied by the treatment SDs (Var(t) = Var(c) + Var(d) − 2 Cov(c, d)), then
   random pairwise swaps within each change vector until the three correlations are within 0.01
   of target. Treatment = control − d. Marginals are therefore exact multisets; the Table 2
   treatment SDs are matched to ±0.1 in every replicate (`sim_moment_check.csv`).
4. Order: a random permutation of the three conditions per donkey; no order effect is simulated.
5. Model: `lmer(y ~ condition + order + (1 | donkey), REML)` with lmerTest Satterthwaite p-values,
   as the paper describes (R 4.2.3, lme4, lmerTest; order as a factor since the paper does not
   say). Positive vs negative via `contest1D`.

`sim_contrasts_summary.csv`, medians over replicates (range over the three scenarios):

| outcome | contrast | estimate | SE | df | t | p (median) | p (max over all replicates) | reported |
|---|---|---|---|---|---|---|---|---|
| SBR | positive − control | 19.0 | 0.94–1.15 | 64 | 16.5–20.2 | 1e-29–1e-24 | 3e-22 | 0.002 |
| SBR | negative − control | −6.7 | 0.94–1.15 | 64 | −5.9 to −7.1 | 1e-9–2e-7 | 6e-6 | <0.001 |
| SBR | negative − positive | −25.7 | 0.94–1.15 | 64 | −22 to −27 | <1e-31 | 1e-28 | not tested |
| RMSSD | positive − control | 33.0 | 3.4–3.9 | 64 | 8.4–9.7 | 3e-14–7e-12 | 1e-10 | 0.005 |
| RMSSD | negative − control | 10.0 | 3.4–3.9 | 64 | 2.6–3.0 | 0.004–0.013 | 0.065 | <0.001 |
| RMSSD | negative − positive | −22.9 | 3.4–3.9 | 64 | −5.8 to −6.8 | 5e-9–2e-7 | 4e-6 | not tested |
| ET | positive − control | 0.76 | 0.11–0.15 | 64 | 5.2–6.7 | 6e-9–2e-6 | 3e-5 | <0.001 |
| ET | negative − control | 1.18 | 0.11–0.15 | 64 | 8.1–10.5 | 2e-15–2e-11 | 7e-10 | <0.001 |
| ET | negative − positive | 0.42 | 0.11–0.15 | 64 | 2.9–3.7 | 0.0004–0.006 | 0.026 | not tested |

Donkey SD / residual SD (medians): SBR 4.9–5.6 / 3.8–4.7; RMSSD 15.2–17.2 / 13.8–16.0; ET
0.78–0.87 / 0.46–0.60. No singular fits.

Reading. (a) The described model gives one pooled residual variance, so all three contrasts of
an outcome share one SE. For RMSSD this SE (3.4–3.9) is smaller than the paired SE of the
positive contrast (4.2) and 2.5–2.9 times larger than that of the negative contrast (1.4): the
model overstates the precision of the positive contrast and understates that of the negative one.
(b) Under the described model the ordering of the two RMSSD p-values is positive ≪ negative
(≈ 1e-12 vs ≈ 0.01); the paper reports positive 0.005 and negative < 0.001, the reverse. No
replicate in any scenario, and no analysis in section 1, yields p = 0.005 for the positive RMSSD
contrast or p = 0.002 for the positive SBR contrast. (c) The RMSSD negative contrast reaches
p < 0.001 in no replicate under the described model, although it does under a paired test; the
Figure 2C bracket is therefore reproduced only by an analysis other than the one described.
(d) Positive and negative treatments differ for all three outcomes in every replicate at the
0.05 level.

## Limitations

- Everything inherits the reconstruction's assumptions: n = 34 per condition with no exclusions,
  Δ computed per donkey as control − treatment on the same values that enter the condition
  means, plotting rounding of ΔRMSSD and ΔET.
- The simulated control values are normal and the pairing is a Gaussian copula; the real joint
  distribution may differ. Condition means, SDs and the Δ multisets are matched, higher moments
  are not constrained.
- ρ_dd is unknown; results are given for three values and move monotonically with it.
- No order effect is simulated because none is reported; the order term costs 2 df only.
- `simulated_conditions_example.csv` (ρ_dd = 0, replicate 1 of each outcome) is one draw, for
  developing the stage 3–4 code; inference should use the ensemble or, preferably, the authors'
  data if they arrive.
