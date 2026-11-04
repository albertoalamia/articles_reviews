# Digitisation log — Figures 3 and 4 of Bukhari et al. 2026

Purpose: recover the 68 change scores per figure (34 positive, 34 negative) that the paper plots
but does not tabulate. Source rasters are the native JPEG images embedded in the PDF, saved as
`data/raw/figures/fig3_dRMSSD_vs_dSBR_p8.png` (1263 × 947) and `fig4_dRMSSD_vs_dET_p9.png`
(1263 × 947), hashes in `data/raw/EXTRACTION_LOG.md`. This is a derived dataset produced by code,
presented as our own reconstruction with its uncertainty, not as the authors' data.

## Pipeline (final, 2026-11-03)

Run from the article folder inside the nix shell (Pillow 11.2, NumPy, SciPy 1.15 from `shell.nix`):

```
# 1. points from pixels
python3 ../tools/digitise_scatter.py data/raw/figures/fig3_dRMSSD_vs_dSBR_p8.png \
  --x-ticks 0,10,20,30 --y-ticks 0,20,40,60 --series positive=#00BFC4 negative=#F8766D \
  --xname dSBR --yname dRMSSD --xgrid 1 --ygrid 1 \
  --out data/derived/fig3_points_digitised.csv --overlay output/figures/fig3_digitisation_overlay.png \
  > data/derived/fig3_digitisation_report.json
python3 ../tools/digitise_scatter.py data/raw/figures/fig4_dRMSSD_vs_dET_p9.png \
  --x-ticks 0,0.5,1,1.5,2,2.5 --y-ticks 0,20,40,60 --series positive=#00BFC4 negative=#F8766D \
  --xname dET --yname dRMSSD --xgrid 0.1 --ygrid 1 --xpad 0.4 \
  --out data/derived/fig4_points_digitised.csv --overlay output/figures/fig4_digitisation_overlay.png \
  > data/derived/fig4_digitisation_report.json
# 2. uncertain stacks resolved by the cross-figure and Table 2 constraints (≈ 1 min)
python3 ../tools/resolve_stacks.py \
  --fig-a data/derived/fig3_points_digitised.csv --xa dSBR --xa-step 1 \
  --fig-b data/derived/fig4_points_digitised.csv --xb dET  --xb-step 0.1 \
  --shared dRMSSD --shared-step 1 --table2 data/raw/table2_changes.csv --exact SBR --n 34 \
  --out-a data/derived/fig3_points_resolved.csv --out-b data/derived/fig4_points_resolved.csv \
  --report data/derived/resolve_stacks_report.json
# 3. reconciliation, comparison with Table 2, OLS refit of Tables 3–4
Rscript R/04_reconcile_digitised.R          # from the repo root: Rscript <article>/R/04_reconcile_digitised.R
```

Defaults otherwise: colour tolerance 70 (RGB distance), opening disc radius 3 px, min blob area
20 px, k-means seed 1. `--xpad 0.4` on Figure 4 keeps the legend keys (x ≈ 2.76 in data units)
out of the panel; with the default margin they were counted as one point per series.

## Calibration

Major gridlines detected automatically and matched to the tick labels:

| figure | axis | gridline px | spacing px | spacing CV | max residual (data units) | px per unit |
|---|---|---|---|---|---|---|
| 3 | x (ΔSBR) | 137, 354, 572, 790 | 217–218 | 0.002 | 0.017 | 21.8 |
| 3 | y (ΔRMSSD) | 206, 406, 605, 805 | 199.5–200 | 0.001 | 0.014 | 10.0 |
| 4 | x (ΔET) | 158, 322, 485, 649, 812, 975 | 163–164 | 0.002 | 0.001 | 327 |
| 4 | y (ΔRMSSD) | 196, 383, 570, 757 | 187 | 0.000 | 0.001 | 9.35 |

Pixel resolution ≈ 0.05 blinks/min, ≈ 0.003 °C and ≈ 0.1 ms per pixel; a free disc (≈ 230 px²,
≈ 17 px across) is located to better than one pixel.

## What the points reveal about the data

- ΔSBR values lie on integers (snapping residual ≤ 0.14, mean 0.01), ΔET on a 0.1 °C grid
  (residual ≤ 0.001), ΔRMSSD on integers (mean residual 0.02–0.03). ΔSBR is an exact integer
  count; ΔRMSSD and ΔET were evidently rounded for plotting, because the reported means
  (unrounded data) differ from the means of the plotted values by less than the plotting step
  (see below). All 68 + 68 plotted values are ≥ 0.
- Points are drawn with transparency (estimated alpha 0.80 for both colours), so overlapping
  discs are darker. The summed layer depth of a blob divided by that of a single disc counts
  the discs, including two discs on exactly the same spot. This count is reliable away from the
  fitted regression line; where the opaque line crosses a blob it is biased and the blob is
  flagged `on_line`.

## Counts and resolution

| figure | series | blobs | points, digitiser | of which on the line | points after resolution |
|---|---|---|---|---|---|
| 3 | positive | 30 | 34 | 0 (one small fragment) | 34 |
| 3 | negative | 23 | 35 | 6 blobs | 34 |
| 4 | positive | 28 | 34 | 0 | 34 |
| 4 | negative | 27 | 34 | 4 blobs | 34 |

Coincident pairs found by transparency alone (both confirmed by the other figure): positive
(ΔSBR 19, 56 ms) in Figure 3, (ΔET 1.6, 15 ms) in Figure 4, negative (ΔSBR 7, 9 ms) in Figure 3.

`tools/resolve_stacks.py` enumerates, for every on-line blob, all multisets of grid nodes within
the blob's extent (sizes k − 2 … k + 2 around the digitiser's count; lowest and highest level
occupied; no two-level gap) and keeps the joint configurations of both figures that satisfy:
(1) identical ΔRMSSD multisets in the two figures, (2) 34 points per series, (3) ΔSBR sum equal
to 34 × 6.79 within rounding of the mean (integer data, so the sum is pinned to 231), ΔRMSSD and
ΔET sums within 34 × half a plotting step of 34 × the reported mean. Result for the negative
series: 3 configurations, identical except for which of the levels 6, 7, 8 sits at ΔSBR 4 in the
stack at ΔSBR 4–5; the one matching the digitiser's own placement was kept (image distance 0 vs
1 and 2 grid steps), flagged `resolved_by = constraints+image`. The decisive stack is at ΔSBR 9:
six donkeys, 13 ms three times, 14 ms twice, 15 ms once (the digitiser counted five). Positive
series: one fragment (ΔSBR 10, 23 ms) resolved; everything else as digitised.
Report: `data/derived/resolve_stacks_report.json`.

## Check against Table 2 (`output/tables/digitised_vs_table2.csv`)

| Δ | n | reconstructed mean (SD) | reported mean (SD) | sum | 34 × reported mean |
|---|---|---|---|---|---|
| SBR positive | 34 | 19.00 (6.63) | 19.0 (6.62) | 646 | 646 |
| SBR negative | 34 | 6.79 (3.18) | 6.79 (3.17) | 231 | 230.86 |
| ET positive | 34 | 0.812 (0.567) | 0.81 (0.56) | 27.6 | 27.54 |
| ET negative | 34 | 1.229 (0.579) | 1.22 (0.57) | 41.8 | 41.48 |
| RMSSD positive | 34 | 37.74 (15.95) | 37.73 (15.95) | 1283 | 1282.82 |
| RMSSD negative | 34 | 10.74 (7.05) | 10.73 (7.04) | 365 | 364.82 |

Every mean agrees to the reported precision or to within the plotting rounding (ΔET negative
1.229 vs 1.22: 0.1 °C rounding of 34 values allows ±0.05 on the mean). Every SD agrees to
±0.01. The Δ rows of Table 2 are therefore the means and SDs of exactly these plotted, unsigned
values.

## Check against Tables 3–4 (`output/tables/tables3_4_refit.csv`, OLS on the 68 rows)

| table | term | reported (SE) | refit (SE) |
|---|---|---|---|
| 3 | intercept | 1.72 (2.42) | 1.71 (2.42) |
| 3 | ΔSBR | 1.32 (0.24) | 1.33 (0.244) |
| 3 | treatment positive | 10.82 (3.83) | 10.80 (3.88) |
| 4 | intercept | 26.43 (3.16) | 26.04 (3.19) |
| 4 | ΔET | −12.76 (2.15) | −12.45 (2.18) |
| 4 | treatment positive | 21.66 (2.37) | 21.80 (2.62) |

Table 3 is reproduced to the second decimal by ordinary least squares on the plotted values,
which confirms that the "repeated-measure" model had a donkey random-intercept variance of
essentially zero. Table 4 differs by 0.1–0.4 because the plotted ΔET are rounded to 0.1 °C while
the authors fitted the unrounded values.

## Limitations

- Donkey identity is not recoverable: the pairing of a positive with a negative point of the same
  animal is unknown, so the random intercept cannot be fitted; OLS is the closest refit (and,
  as shown, equivalent here).
- Triplets (ΔSBR, ΔET, ΔRMSSD) in `deltas_triplets.csv` are matched by ΔRMSSD within series;
  where several points share a ΔRMSSD value the ΔSBR–ΔET pairing is arbitrary and flagged
  (`tie_group`). This does not affect the two separate regressions, only a joint model.
- ΔRMSSD and ΔET carry plotting rounding (±0.5 ms, ±0.05 °C per value).
- Control-level values and the sign of each change are not in any figure.
- Overlays for visual verification: `output/figures/fig3_digitisation_overlay.png`,
  `fig4_digitisation_overlay.png` (black crosses = single points, red = points from split or
  resolved blobs, magenta = calibration gridlines, green = panel boundary).
