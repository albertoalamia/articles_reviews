# 00_parse_supplement.R — Secondi et al. 2026, Animal Behaviour (P003)
#
# Parses Supplementary Tables S2 and S3 (slot-wise contrasts) from the journal's supplement into
# one CSV. The supplement is a class B file (protocol/copyright.md): it is not in the repository,
# and neither is the output of this script, which is a complete copy of two tables. What is
# committed is this parser and the summaries that block I of 02_consistency_checks.R produces.
#
# Input  : paper/ANBEH-D-26-00085_SuppMat/Electronic Supplementary material.docx
#          (local; sha256 in data/raw/EXTRACTION_LOG.md)
# Output : data/raw/tableS2_S3_contrasts.csv (local, gitignored), 396 rows:
#          table, contrast, within, hour, slot, estimate, se, z_ratio, p_value
#          Numbers are kept as printed (character), including trailing zeros and P = 0.000.
# Run    : from the nix shell, any working directory inside the repo:
#          Rscript AnimBehav_humic_acid_newt_predator_cues_Secondi_2026/R/00_parse_supplement.R
#          An optional argument gives another output path (used for scratch checks).

art  <- here::here("AnimBehav_humic_acid_newt_predator_cues_Secondi_2026")
docx <- file.path(art, "paper/ANBEH-D-26-00085_SuppMat/Electronic Supplementary material.docx")
args <- commandArgs(trailingOnly = TRUE)
dest <- if (length(args) >= 1) args[1] else file.path(art, "data/raw/tableS2_S3_contrasts.csv")
if (!file.exists(docx)) stop("supplement not found: ", docx, "\nIt is not in the repository; see paper/README.md.")

# docx -> plain text with the pandoc that ships with Quarto; tables come out one row per line
txt <- tempfile(fileext = ".txt")
st  <- system2("quarto", c("pandoc", shQuote(docx), "-t", "plain", "--wrap=none", "-o", shQuote(txt)))
if (st != 0) stop("quarto pandoc failed")
x <- readLines(txt, encoding = "UTF-8", warn = FALSE)
x <- gsub(" ", " ", x)                       # non-breaking spaces inside the contrast labels
x <- gsub("−", "-", x)                       # a typographic minus, if any

# the two tables start at their full captions (the list of captions at the top is shorter)
start <- sapply(c(S2 = "^Table S2\\. .*computed from", S3 = "^Table S3\\. .*computed from"), function(p) grep(p, x)[1])
stopifnot(!anyNA(start), start["S2"] < start["S3"])
block <- list(S2 = x[start["S2"]:(start["S3"] - 1)], S3 = x[start["S3"]:length(x)])

num   <- "(-?[0-9]+\\.[0-9]+)"
lvl   <- "(Clear|Medium|Dark)"
left  <- paste0("Fish - No fish\\s+", lvl, "\\s+([0-9]+)\\s+", num, "\\s+", num, "\\s+", num, "\\s+", num)
right <- paste0("(?:[0-9]\\.)?", lvl, " - (?:[0-9]\\.)?", lvl, "\\s+(Fish|No fish)\\s+([0-9]+)\\s+", num, "\\s+", num, "\\s+", num, "\\s+", num)
slot_of <- function(h) match(as.integer(h) %% 24, c(15:23, 0:12))   # midnight is printed as 24

parse_table <- function(lines, name) {
  rows <- list()
  for (l in lines) {                               # each line: left half (cue), then right half (colour pair)
    m <- regmatches(l, regexec(left, l, perl = TRUE))[[1]]
    if (length(m)) rows[[length(rows) + 1]] <- data.frame(table = name, contrast = "fish - no fish", within = tolower(m[2]),
        hour = m[3], slot = slot_of(m[3]), estimate = m[4], se = m[5], z_ratio = m[6], p_value = m[7])
    m <- regmatches(l, regexec(right, l, perl = TRUE))[[1]]
    if (length(m)) rows[[length(rows) + 1]] <- data.frame(table = name, contrast = tolower(paste(m[2], "-", m[3])), within = tolower(m[4]),
        hour = m[5], slot = slot_of(m[5]), estimate = m[6], se = m[7], z_ratio = m[8], p_value = m[9])
  }
  do.call(rbind, rows)
}
ct <- rbind(parse_table(block$S2, "S2"), parse_table(block$S3, "S3"))

# checks: 66 + 132 rows per table, every stratum has the 22 slots once, in the order 15 ... 12
n <- table(ct$table, ct$contrast == "fish - no fish")
stopifnot(nrow(ct) == 396, all(n[, "TRUE"] == 66), all(n[, "FALSE"] == 132), !anyNA(ct$slot))
by_stratum <- split(ct$slot, paste(ct$table, ct$contrast, ct$within))
stopifnot(length(by_stratum) == 18, all(sapply(by_stratum, function(s) identical(as.integer(s), 1:22))))

write.csv(ct, dest, row.names = FALSE, quote = FALSE)
cat(sprintf("%d rows written to %s\nmd5 %s\n", nrow(ct), dest, tools::md5sum(dest)))
