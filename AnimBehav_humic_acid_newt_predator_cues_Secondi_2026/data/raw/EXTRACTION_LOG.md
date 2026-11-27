# Extraction log — Secondi et al. 2026 (version of record)

Source PDF: `paper/Secondi_2026_AnimBehav_123735.pdf`
(sha256 f0683c82cceeef6b605f4db88a6af3ab4aeaa295eebce841d4bcd8909563bf72; 8 pages; PDF created
2026-10-22; downloaded by Alberto through the University of Milano-Bicocca library on 2026-11-25
as `1-s2.0-S0003347226002733-main.pdf` and renamed). Text extraction
`paper/Secondi_2026_fulltext.txt` (pdftotext -layout; sha256
b6ba4d24019e330f614ba594c97a04dc617407e97eb7a14592d9aeb66980cb8c). Version: the typeset article
with volume and article number (Animal Behaviour 241 (2026) 123735; available online 19 October
2026), i.e. the version of record. Received 9 February 2026, initial acceptance 21 April 2026,
final acceptance 3 August 2026, MS. number A26-00085R.

**Not committed.** The article is closed access (© 2026 The Association for the Study of Animal
Behaviour, Elsevier; "All rights are reserved, including those for text and data mining, AI
training, and similar technologies"). The PDF, the extracted text and the figure rasters stay in
`paper/`, which `.gitignore` excludes. The files below hold numbers and short quotations only.

Extracted by Claude Code on 2026-11-25; Table 1 and the Figure 2 asterisks were checked against
the rendered pages (pdftoppm, 130 dpi), not only against the text. Line numbers refer to the
fulltext file; "p5", "p6" are PDF pages where the two-column extraction interleaves lines.
Values are transcribed exactly as printed, including inconsistencies.

| file | content | PDF page | checked against |
|---|---|---|---|
| `table1_lrt.csv` | Table 1, all nine rows (likelihood ratio statistic, df, P, bold), plus the statistic for total distance as given in the Results text (75.113 against 75.209 in the table) | 4, 5 | page image and text |
| `text_numbers.csv` | sample, dates, treatments, arena, recording schedule, sequences and discards, R² values, the hours of reduced activity quoted in the Discussion | 2–6 | text |
| `pairwise_significant.csv` | every pairwise difference the Results report as significant (Tukey, P < 0.05), by response, comparison and time slot, with whether it is in the text, in Figure 2, or both | 4, 5 | text and page image |
| `tableS2_S3_contrasts.csv` | Supplementary Tables S2 and S3: all 198 + 198 slot-wise contrasts (estimate, SE, z ratio, P as printed), with the table, the contrast, the stratum, the hour as printed and the slot number 1–22 added | supplement | row counts (66 + 132 per table), hour sequence 15…12 in every stratum |
| `authors/2026-11-25_zenodo_18200380_dataset.xlsx` | the authors' public dataset (see `authors/RECEIVED_LOG.md`) | — | md5 published by Zenodo |

Figure rasters (native, `pdfimages -png`), kept in `paper/figures/`, not committed:
```
7b9a11ce0709d2d1123f4614c81fc163c5a3c0e689b50259db45c0bdde4d4c60  fig1a_distance_p4.png
ae27b86523669276f607066ff5a9d37548e3c88f1f776221220b00c2e4d808f9  fig1b_time_moving_p4.png
36e0aa7f752941afb648e7c7c9babea6b478917cdddb1ace3fef5d789b7b9113  fig1c_distance_feeder_p4.png
3207ee40910db861387d71c80b69433852aa04f9d459bcea055fc95dd5ee44f0  fig2a_clear_p5.png
45bd4f470da55ee9eea2d026f4b2513366d99f75b05c2bf6c3b093d1a29bb59d  fig2a_dark_p5.png
b98356b1ea5a8d4a405c914a90e5693359ece6645b3e6e7b641d52f93f666c07  fig2a_medium_p5.png
51da2dd7d40e3076f6fb7ec96560e1e799e3eb47bcf143e4f42e3898651afe1c  fig2b_fish_p5.png
8ed462577d546879235f1aa53bf8f5229998fd05d5d16b9190ea1f3a3f34bfc4  fig2b_nofish_p5.png
```

Notes
- Time slots. Recording starts at 15:30; each sequence lasts 30 min and starts on the half hour.
  The paper names a slot by the hour before it ("2200 hours for 2230–2300 hours"), so "1500" is
  15:30–16:00 and "1200" is 12:30–13:00: 22 slots. The dataset numbers them 1 to 22 (`Trial`)
  and gives the interval (`Trial_Time`).
- Figure 2. The x axis of every panel prints "0000" followed by "0010" where 0100 is meant.
  The asterisk of panel (b) "No fish" that the text places at 2200 sits between the 2200 and 2300
  ticks. Panel (a) has 3, 2 and 6 asterisks (clear, medium, dark), as in the text.
- Units. The paper gives distance travelled and distance to the feeder in mm (Methods, Figure 1
  axes, Figure 2 axis). The dictionary sheet of the dataset gives both in cm. Transcribed as
  printed in each source; see the consistency script, block C.
- Figure 1 caption: "(c) mean distance to the feeder (right)" and "Bars show the activity" for
  what are box plots with the raw points; no numbers were read from Figure 1.
- No table of descriptive statistics, model coefficients or estimated marginal means is printed
  in the article.

## Supplement (added 2026-11-27)

Downloaded by Alberto through the University of Milano-Bicocca library on 2026-11-27 as
`paper/1-s2.0-S0003347226002733-mmc1.zip` and unpacked in `paper/ANBEH-D-26-00085_SuppMat/`.
Not committed (same reason as the PDF). sha256:
```
0dfa022919f414194ca575ebe6dab711f9f2097a5a9074cf684cae928dc3b699  1-s2.0-S0003347226002733-mmc1.zip
894059f90be6fe5ed04ade89db18d42c625bb9f6eca89f1d1c965f581e1897dd  Electronic Supplementary material.docx
ec9b5e98ce2e0b082eb980170241ba7dc25e5d94f46d573d3dd26bd4d18f1c3e  ESM- R Script_newts_videotracking_2024.Rmd
d7c8422fbb346e1a567544de3ec83f27136d54a09718e1d62d9ea17165d9a281  VideotrackingData.xlsx
```
- `VideotrackingData.xlsx`: sheet `Data_R`, 1,166 rows, 24 columns (the EthoVision output:
  distance, velocity, acceleration, distance to feeder, moving and not moving), and a `Metadata`
  sheet of 30 lines. Not the same file as the Zenodo copy (16 columns), but `D.tot`, `DF.mean`
  and `Mov.cum` are identical in the two, value by value and missing by missing (38, 36, 110).
  The checks keep reading the Zenodo copy, which is public. The metadata sheet gives every
  distance in cm.
- `ESM- R Script_newts_videotracking_2024.Rmd`: 680 lines, dated 2025-04-29. Read, not run.
- `Electronic Supplementary material.docx`: Figure S1 (raw distances by slot, colour and cue;
  looked at), Figure S2 and Table S1 (embedded as EMF pictures; **not read by Claude**, to be
  looked at in the document by Alberto), Tables S2 and S3 (text tables).
- Tables S2 and S3 were converted with `quarto pandoc <docx> -t plain --wrap=none` and parsed by
  a script (non-breaking spaces normalised); nothing typed by hand. Each table has two halves
  side by side: fish against no fish by colour and hour (66 rows) and colour pairs by cue
  treatment and hour (132 rows). The level prefixes of S2 ("1.Clear") were dropped. The captions
  announce "LCI and UCI ... for the 95 % interval confidence"; neither table has those columns.
  P values printed as 0.000 are kept as 0.000.
