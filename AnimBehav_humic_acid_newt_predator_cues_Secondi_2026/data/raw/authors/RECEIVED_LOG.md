# Data from the authors — Secondi et al. 2026

Nothing was received by correspondence. The paper's Data Availability statement points to a
public deposit, downloaded by Claude Code on 2026-11-25 with `curl` from the Zenodo API.

| file here | source | licence | size | md5 (as published by Zenodo) | sha256 |
|---|---|---|---|---|---|
| `2026-11-25_zenodo_18200380_dataset.xlsx` | Zenodo record 18200380 (concept DOI 10.5281/zenodo.18200379, the DOI the paper cites), "Influence of water colour and predation risk on newt activity", Secondi, Blanchet, Xu, Arzel, published 2026-01-09; original file name `Dataset-Influence of water colour and predation risk on newt activity.xlsx` | CC BY 4.0 | 113,238 bytes | 806ca2405c2704ca0dd43a8a87d4ebc7 (matches) | c38ea62193075d4ee7efb686aad93c93a35a15e12b70bc54198efa480e8e775d |

Content: sheet `Feuil1`, 1,166 rows (53 newts × 22 sequences) and 16 columns; sheet `Feuil2`, the
variable dictionary (16 rows). The file is kept unchanged; `R/02_consistency_checks.R` reads it
with `readxl`. The licence allows redistribution with attribution, so the file is committed.

Not yet obtained: the Supplementary Material of the article (Table S1 site water colour, Tables
S2–S3 and Fig. S1–S2 on time spent moving and untransformed distances, and the R script the Data
Availability statement mentions). It is on the journal page, behind the subscription; Alberto
downloads it into `paper/` (not committed).
