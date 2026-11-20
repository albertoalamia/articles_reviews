# Extraction log — Shi et al. 2026 (Article in Press)

Source PDF: `paper/Shi_2026_SciRep_s41598-026-78298-4.pdf`
(sha256 78b36511d8beaabb8942c4b9b442cea5e7c32c5b3febcfc6cee109eddaff783b; 9 pages, InDesign
export dated 2026-10-29; text extraction `paper/Shi_2026_fulltext.txt`, pdftotext -layout).
Version: "Article in Press", the typeset accepted manuscript; the page header says the final
edited version will replace it. Extracted by Claude Code on 2026-11-20, every value checked
against the rendered page (pdftoppm 110 dpi) by eye, not only against the text extraction. Line
numbers refer to the fulltext file. Values are transcribed exactly as printed, including
inconsistencies.

| file | content | PDF page | checked against |
|---|---|---|---|
| `table1_baseline.csv` | Table 1, all cells; one row per variable (education as three rows sharing one p) | 5 | page image and text |
| `table2_cox.csv` | Table 2, all cells; `hr_* = 1` on the reference rows stands for "Ref." | 6 | page image and text |
| `fig2_at_risk.csv` | numbers at risk printed under the three Kaplan–Meier panels | 6 | native raster (1716 × 428) |
| `fig2_curve_features.csv` | step times, step heights and end values read by eye from the panels, with a precision column | 6 | native raster, panels enlarged 2× |
| `text_numbers.csv` | flow numbers, dates, follow-up, incidences, the in-text comparisons, covariate lists | 1–7 | text |
| `suppl_table_s1.csv` | Supplementary Table S1 (excluded 1565 vs included 3875), all cells, with the matching Table 1 row name | supplement | docx table read from the XML |
| `figures/fig1_flowchart_p4.png` | embedded raster, native 1445 × 889, grey | 4 | `pdfimages -png` |
| `figures/fig2_kaplan_meier_p6.png` | embedded raster, native 1716 × 428, RGB | 6 | `pdfimages -png` |

sha256 of the rasters:
```
0e0c2d61007d73d47a1e32234d8cbd118590f7f7439a6e105206714f6088dcdc  fig1_flowchart_p4.png
1249b5bdba70279df56a79cfde60d1db40a12c058eb0b1529b5639b4c94fa2ec  fig2_kaplan_meier_p6.png
```

Notes
- Table 1 group sizes are in the column headers: Overall 3875, NCI 3683, CI 192. The paper gives
  no n per model, so every recomputation assumes complete covariate data for all 3875.
- Table 1 `p_type`: `less_than` for "< 0.0001", `exact` otherwise. The three education rows share
  one test (`p_scope`).
- Fig. 2 y-axis is labelled "Cumulative incidence (%)" with ticks at 0 and 1 only. Step heights
  and end values are given in axis units; what unit the axis is in is itself one of the open
  points (see `notes/03_concerns.md`). Step times are read to about ±0.05 years; the NCI end
  values to about ±0.03 axis units. These readings support only coarse statements (number of
  steps, order of magnitude), never a recomputation to the second decimal.
- Supplement: `paper/41598_2026_78298_MOESM1_ESM.docx` (sha256
  945d25d0ff5a589e648b093245165794d61bbcdca061d2b3c15d5c0d566ccbe6), one table, read from
  `word/document.xml` on 2026-11-20; row labels kept as printed (lower case, "Hcy", "heavy drink").
  Its "included 3875" column should equal the "Overall 3875" column of Table 1; where it does not,
  both values are kept as printed (middle school 2394 vs 1662; manual worker 73.3 % vs 51.9 %;
  LDL Q1 1.9 vs 1.5).
- Reproduction command for the rasters:
  `pdfimages -png paper/Shi_2026_SciRep_s41598-026-78298-4.pdf figures/x`
  (image 1 = Fig. 1 on page 4, image 2 = Fig. 2 on page 6; image 0 is the journal logo).
