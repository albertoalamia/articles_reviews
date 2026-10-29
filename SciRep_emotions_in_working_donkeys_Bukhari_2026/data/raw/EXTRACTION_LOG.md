# Extraction log — Bukhari 2026 (accepted manuscript)

Source PDF: `paper/Bukhari_2026_SciRep_s41598-026-62753-3_accepted_manuscript.pdf`
(sha256 d0ef73522d0f11b0160bef0460106f565e9c89fefadf4972689fd8bc9c0d32a9; text extraction `paper/Bukhari_2026_fulltext.txt`, pdftotext -layout).
Extracted by Claude Code on 2026-10-29, every value checked against the rendered PDF page
(pdftoppm 150 dpi) by eye, not only against the text extraction. Line numbers refer to the
fulltext file. Values are transcribed exactly as printed, including inconsistencies.

| file | content | PDF page | checked against |
|---|---|---|---|
| `table1_environment.csv` | Table 1 + the m/s value in the text | 5 | page image and text |
| `table2_conditions.csv` | Table 2, absolute rows | 6 | page image and text |
| `table2_changes.csv` | Table 2, "Change in …" rows, definition as in caption | 6 | page image and text |
| `tables3_4_regressions.csv` | Tables 3 and 4, all cells | 8, 9 | page image and text |
| `text_contrast_pvalues.csv` | the six condition-contrast p-values from 2.4 and Fig. 2 brackets | 6, 7 | page image and text |
| `fig1_bland_altman.csv` | bias and limits of agreement printed as labels on Fig. 1 | 5 | page image only (LoA not in text) |
| `methods_numbers.csv` | n, age, sex, BCS, power inputs, timing | 10–11 | text |
| `figures/fig1_bland_altman_p5.png` | embedded raster, native 1555×1074 | 5 | `pdfimages -png` |
| `figures/fig2_boxplots_p7.png` | embedded raster, native 1509×1125 | 7 | `pdfimages -png` |
| `figures/fig3_dRMSSD_vs_dSBR_p8.png` | embedded raster, native 1263×947 | 8 | `pdfimages -png` |
| `figures/fig4_dRMSSD_vs_dET_p9.png` | embedded raster, native 1263×947 | 9 | `pdfimages -png` |

sha256 of the rasters:
```
1006e6b0aa2c37bcca9ae71a6f6e5d173041a6e37f8ba4011c8640d7fe9bb35d  fig1_bland_altman_p5.png
c66cc407574d522a5b2acdef02fce11117bd86edb7aba1ce0f68ae4e7eea62a4  fig2_boxplots_p7.png
b51a4ca6eb2014cc3cbe3038afa38a4298cc8a35c54c6c704df6eba46f0e87f4  fig3_dRMSSD_vs_dSBR_p8.png
bb474889a6ce58a6ae4fea1ad448b3483813ea155efdbe9352bc021b9c176715  fig4_dRMSSD_vs_dET_p9.png
```

Notes
- `n_stated` in `table2_conditions.csv` is NA because the paper never gives n per cell; n = 34 is
  assumed in all checks and the assumption is recorded where used.
- Table 2 Δ rows are transcribed with the sign as printed (all positive) and the definition as
  printed (control minus treatment). The two are inconsistent; see `notes/03_concerns.md`.
- Fig. 1: all plotted coder differences lie on integer values (−2, −1, 0, 1, 2) and all means on a
  half-integer grid, so SBR per donkey per condition is an integer count. Used for GRIM.
- Figures 3 and 4 contain the 68 raw Δ points each; digitisation is a stage-2 task, output will
  go to `data/derived/` with its own log.
- Reproduction command for the rasters:
  `pdfimages -png -f 5 -l 9 paper/Bukhari_2026_SciRep_s41598-026-62753-3_accepted_manuscript.pdf figures/x`
  then rename by page (page 5 → fig1, 7 → fig2, 8 → fig3, 9 → fig4).
