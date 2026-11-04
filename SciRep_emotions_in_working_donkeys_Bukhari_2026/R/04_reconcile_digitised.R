# 04_reconcile_digitised.R — Bukhari 2026, stage 2 (reconstruction from Figures 3 and 4)
#
# Inputs : data/derived/fig3_points_resolved.csv  (ΔSBR, ΔRMSSD per point; falls back to *_digitised.csv)
#          data/derived/fig4_points_resolved.csv  (ΔET,  ΔRMSSD per point; see data/derived/DIGITISATION_LOG.md)
#          data/raw/table2_changes.csv             (reported Δ means and SDs)
#          data/raw/tables3_4_regressions.csv      (reported regression tables)
# Outputs: data/derived/deltas_fig3.csv, deltas_fig4.csv   per-figure data with multiplicities
#          data/derived/deltas_triplets.csv                 (ΔSBR, ΔET, ΔRMSSD) matched by ΔRMSSD
#          output/tables/digitised_vs_table2.csv            means/SDs/sums vs Table 2
#          output/tables/tables3_4_refit.csv                OLS refit vs reported Tables 3–4
#          output/tables/digitised_hidden_points.csv        inferred hidden duplicates, with notes
# Run    : Rscript SciRep_emotions_in_working_donkeys_Bukhari_2026/R/04_reconcile_digitised.R
#
# Logic
#  1. Snap to the grids the figures reveal: ΔSBR integer, ΔET 0.1 °C, ΔRMSSD integer ms.
#     Report the snapping residuals (large ones = points partly covered by a fitted line).
#  2. Both figures share ΔRMSSD, so within a treatment the multiset of ΔRMSSD must be the same.
#     The union (max multiplicity) is the best estimate of the true multiset M. A value present in
#     one figure and missing from the other is a point hidden there under an identical point: its
#     missing coordinate is that of the identical point (unique) or ambiguous (several candidates).
#  3. The Table 2 Δ rows are means of these very values (the paper's regressions reproduce from
#     them, see 02_consistency_checks.R), so n × mean must equal the sum of the 34 values to within
#     rounding. With 33 of 34 values known, the 34th follows from the sum and must land on the grid.
#  4. Compare means and SDs with Table 2; refit Tables 3–4 by OLS on the reconstructed data
#     (donkey identities are unknown, so the random intercept cannot be reproduced; the reported CI
#     widths imply it was ≈ 0 anyway).
#  Nothing is typed in by hand; all reported numbers come from data/raw/.

suppressPackageStartupMessages(library(tidyverse))
here_art <- function(...) here::here("SciRep_emotions_in_working_donkeys_Bukhari_2026", ...)
out_tab <- here_art("output/tables"); dir.create(out_tab, showWarnings = FALSE, recursive = TRUE)
N <- 34L

# Prefer the files produced by tools/resolve_stacks.py (uncertain stacks resolved by the
# cross-figure and Table 2 constraints); fall back to the raw digitiser output.
pick <- function(stem) {
  r <- here_art("data/derived", paste0(stem, "_points_resolved.csv"))
  d <- here_art("data/derived", paste0(stem, "_points_digitised.csv"))
  if (file.exists(r)) { cat("using", basename(r), "\n"); r } else { cat("using", basename(d), "(no resolved file)\n"); d }
}
fig3 <- read_csv(pick("fig3"), show_col_types = FALSE)
fig4 <- read_csv(pick("fig4"), show_col_types = FALSE)
t2   <- read_csv(here_art("data/raw/table2_changes.csv"), show_col_types = FALSE)
regs <- read_csv(here_art("data/raw/tables3_4_regressions.csv"), show_col_types = FALSE)

# ---- 1. snap to grid -------------------------------------------------------------------------
snap <- function(x, step) round(x / step) * step
fig3 <- fig3 |> mutate(dSBR_raw = dSBR, dRMSSD_raw = dRMSSD,
                       dSBR = snap(dSBR, 1), dRMSSD = snap(dRMSSD, 1),
                       resid_x = dSBR_raw - dSBR, resid_y = dRMSSD_raw - dRMSSD, figure = 3L)
fig4 <- fig4 |> mutate(dET_raw = dET, dRMSSD_raw = dRMSSD,
                       dET = snap(dET, 0.1), dRMSSD = snap(dRMSSD, 1),
                       resid_x = dET_raw - dET, resid_y = dRMSSD_raw - dRMSSD, figure = 4L)
snap_report <- bind_rows(
  fig3 |> group_by(figure, series) |> summarise(n = n(), x_resid_mean = mean(abs(resid_x)), x_resid_max = max(abs(resid_x)),
                                                y_resid_mean = mean(abs(resid_y)), y_resid_max = max(abs(resid_y)),
                                                n_y_resid_over_0.3 = sum(abs(resid_y) > 0.3), .groups = "drop"),
  fig4 |> group_by(figure, series) |> summarise(n = n(), x_resid_mean = mean(abs(resid_x)), x_resid_max = max(abs(resid_x)),
                                                y_resid_mean = mean(abs(resid_y)), y_resid_max = max(abs(resid_y)),
                                                n_y_resid_over_0.3 = sum(abs(resid_y) > 0.3), .groups = "drop"))
cat("\n== Snapping residuals (grid units: ΔSBR 1, ΔET 0.1, ΔRMSSD 1) ==\n"); print(snap_report, width = 200)

# ---- 2. reconcile the ΔRMSSD multisets --------------------------------------------------------
empty_hidden <- tibble(series = character(), figure = integer(), dRMSSD = numeric(), n_hidden = integer(),
                       n_candidates = integer(), coord = numeric(), candidates = character(), note = character())
hidden <- list(); d3 <- list(); d4 <- list(); trip <- list()
for (s in c("positive", "negative")) {
  a <- fig3 |> filter(series == s); b <- fig4 |> filter(series == s)
  vals <- sort(unique(c(a$dRMSSD, b$dRMSSD)))
  ca <- as.integer(table(factor(a$dRMSSD, levels = vals)))
  cb <- as.integer(table(factor(b$dRMSSD, levels = vals)))
  cm <- pmax(ca, cb)                               # union multiset M
  M  <- rep(vals, cm)
  cat(sprintf("\n== %s: fig3 %d points, fig4 %d points, union %d (target %d) ==\n", s, nrow(a), nrow(b), length(M), N))

  # hidden in fig3: values with cm > ca; coordinate from the identical visible point(s)
  h3 <- bind_rows(empty_hidden, map_dfr(which(cm > ca), function(i) {
    cand <- a |> filter(dRMSSD == vals[i])
    tibble(series = s, figure = 3L, dRMSSD = vals[i], n_hidden = cm[i] - ca[i],
           n_candidates = nrow(cand),
           coord = if (nrow(cand) == 1) cand$dSBR else NA_real_,
           candidates = paste(cand$dSBR, collapse = "/"),
           note = if (nrow(cand) == 1) "duplicate of the single visible point with this ΔRMSSD"
                  else if (nrow(cand) == 0) "value seen only in the other figure; no visible twin here"
                  else "several visible points with this ΔRMSSD: ΔSBR ambiguous")
  }))
  h4 <- bind_rows(empty_hidden, map_dfr(which(cm > cb), function(i) {
    cand <- b |> filter(dRMSSD == vals[i])
    tibble(series = s, figure = 4L, dRMSSD = vals[i], n_hidden = cm[i] - cb[i],
           n_candidates = nrow(cand),
           coord = if (nrow(cand) == 1) cand$dET else NA_real_,
           candidates = paste(cand$dET, collapse = "/"),
           note = if (nrow(cand) == 1) "duplicate of the single visible point with this ΔRMSSD"
                  else if (nrow(cand) == 0) "value seen only in the other figure; no visible twin here"
                  else "several visible points with this ΔRMSSD: ΔET ambiguous")
  }))
  # Ambiguous hidden points: enumerate the candidate coordinates and keep the combination whose
  # total closes the gap to n × Table 2 mean, if exactly one does (tolerance = rounding of the mean).
  resolve <- function(h, visible_sum, outc, xcol) {
    amb <- which(is.na(h$coord) & h$n_candidates > 1)
    if (length(amb) == 0 || nrow(h) == 0) return(h)
    known <- visible_sum + sum(h$coord * h$n_hidden, na.rm = TRUE)
    target <- N * (t2 |> filter(outcome == outc, treatment == s))$delta_mean
    tol <- N * 0.5 * 10^(-nchar(sub("^[^.]*\\.?", "", format((t2 |> filter(outcome == outc, treatment == s))$delta_mean))))
    if (sum(h$n_hidden[amb]) + sum(h$n_hidden[!is.na(h$coord)]) + nrow(filter(if (xcol == "dSBR") a else b, TRUE)) < N)
      return(h)   # a point is missing from both figures: the sum cannot be used here
    sets <- lapply(amb, function(j) as.numeric(strsplit(h$candidates[j], "/")[[1]]))
    grid <- expand.grid(sets)
    tot  <- rowSums(sweep(as.matrix(grid), 2, h$n_hidden[amb], `*`))
    ok   <- which(abs(known + tot - target) <= tol + 1e-9)
    if (length(ok) == 1) {
      h$coord[amb] <- as.numeric(grid[ok, ]); h$note[amb] <- paste(h$note[amb], "— resolved by the Table 2 sum")
    } else {
      h$note[amb] <- paste0(h$note[amb], " — ", length(ok), " combinations fit the Table 2 sum")
    }
    h
  }
  h3 <- resolve(h3, sum(a$dSBR), "SBR", "dSBR")
  h4 <- resolve(h4, sum(b$dET),  "ET",  "dET")
  hidden[[s]] <- bind_rows(h3, h4)
  if (nrow(hidden[[s]])) { cat("  hidden points:\n"); print(hidden[[s]] |> select(-series), width = 200) }

  # per-figure data with multiplicities (hidden duplicates added when their coordinate is known)
  d3[[s]] <- bind_rows(
    a |> transmute(series, dRMSSD, dSBR, source = "visible", inferred = FALSE),
    h3 |> filter(!is.na(coord)) |> uncount(n_hidden) |>
      transmute(series, dRMSSD, dSBR = coord, source = "hidden duplicate (from fig4 multiset)", inferred = TRUE))
  d4[[s]] <- bind_rows(
    b |> transmute(series, dRMSSD, dET, source = "visible", inferred = FALSE),
    h4 |> filter(!is.na(coord)) |> uncount(n_hidden) |>
      transmute(series, dRMSSD, dET = coord, source = "hidden duplicate (from fig3 multiset)", inferred = TRUE))

  # triplets: match fig3 and fig4 rows by ΔRMSSD; ties within a value are arbitrary → tie_group
  x3 <- d3[[s]] |> arrange(dRMSSD, dSBR) |> group_by(dRMSSD) |> mutate(k = row_number(), m3 = n()) |> ungroup()
  x4 <- d4[[s]] |> arrange(dRMSSD, dET)  |> group_by(dRMSSD) |> mutate(k = row_number(), m4 = n()) |> ungroup()
  trip[[s]] <- full_join(x3 |> select(series, dRMSSD, k, dSBR, m3, src3 = source),
                         x4 |> select(series, dRMSSD, k, dET, m4, src4 = source),
                         by = c("series", "dRMSSD", "k")) |>
    mutate(tie_group = if_else(pmax(m3, m4, na.rm = TRUE) > 1, paste0(s, "_", dRMSSD), NA_character_),
           complete = !is.na(dSBR) & !is.na(dET)) |>
    select(series, dRMSSD, dSBR, dET, complete, tie_group, src3, src4)
}
hidden_tbl <- bind_rows(hidden); write_csv(hidden_tbl, file.path(out_tab, "digitised_hidden_points.csv"))
D3 <- bind_rows(d3); D4 <- bind_rows(d4); TR <- bind_rows(trip)

# ---- 3. the 34th point from the Table 2 sums, where one is missing --------------------------
t2w <- t2 |> select(outcome, treatment, delta_mean, delta_sd)
sum_target <- function(outc, s) { r <- t2w |> filter(outcome == outc, treatment == s); N * r$delta_mean }
sum_tol    <- function(outc, s) { r <- t2w |> filter(outcome == outc, treatment == s)
                                  N * 0.5 * 10^(-nchar(sub("^[^.]*\\.?", "", format(r$delta_mean)))) }
inferred34 <- list()
for (s in c("positive", "negative")) {
  n_known <- nrow(filter(TR, series == s))
  if (n_known == N - 1) {
    tr <- TR |> filter(series == s)
    miss <- tibble(
      series = s,
      dRMSSD = sum_target("RMSSD", s) - sum(tr$dRMSSD),
      dSBR   = if (all(!is.na(tr$dSBR))) sum_target("SBR", s) - sum(tr$dSBR) else NA_real_,
      dET    = if (all(!is.na(tr$dET)))  sum_target("ET",  s) - sum(tr$dET)  else NA_real_) |>
      mutate(dRMSSD_on_grid = abs(dRMSSD - round(dRMSSD)) <= sum_tol("RMSSD", s),
             dSBR_on_grid   = abs(dSBR - round(dSBR)) <= sum_tol("SBR", s),
             dET_on_grid    = abs(dET - round(dET, 1)) <= sum_tol("ET", s) + 1e-9,
             note = "34th point implied by n × Table 2 mean − sum of the 33 reconstructed values")
    cat(sprintf("\n== %s: 33 of 34 reconstructed; 34th point implied by the Table 2 sums ==\n", s)); print(miss, width = 200)
    inferred34[[s]] <- miss
  } else if (n_known != N) {
    cat(sprintf("\n== %s: %d of %d reconstructed; sums cannot pin down the rest ==\n", s, n_known, N))
  }
}

# ---- 4. compare with Table 2 ------------------------------------------------------------------
cmp <- bind_rows(
  D3 |> group_by(series) |> summarise(outcome = "SBR", n = n(), mean = mean(dSBR), sd = sd(dSBR), sum = sum(dSBR), .groups = "drop"),
  D4 |> group_by(series) |> summarise(outcome = "ET", n = n(), mean = mean(dET), sd = sd(dET), sum = sum(dET), .groups = "drop"),
  TR |> group_by(series) |> summarise(outcome = "RMSSD", n = n(), mean = mean(dRMSSD), sd = sd(dRMSSD), sum = sum(dRMSSD), .groups = "drop")) |>
  rename(treatment = series) |>
  left_join(t2w, by = c("outcome", "treatment")) |>
  mutate(sum_target_34 = N * delta_mean,
         sum_gap = sum_target_34 - sum,                     # what the missing point(s) must add up to
         mean_diff = mean - delta_mean, sd_diff = sd - delta_sd,
         note = if_else(n == N, "complete: compare mean and sd directly",
                        sprintf("%d of %d points: sum_gap is the total of the missing %d", n, N, N - n)))
cat("\n== Reconstructed Δ vs Table 2 ==\n"); print(cmp |> select(outcome, treatment, n, mean, delta_mean, sd, delta_sd, sum, sum_target_34, sum_gap, note), width = 220)
write_csv(cmp, file.path(out_tab, "digitised_vs_table2.csv"))

# ---- 5. refit Tables 3–4 by OLS on the reconstructed data -----------------------------------
refit <- function(dat, xvar, table_id) {
  dat <- dat |> mutate(treatment = factor(series, levels = c("negative", "positive")))
  f <- reformulate(c(xvar, "treatment"), response = "dRMSSD")
  m <- lm(f, data = dat)
  ci <- confint(m)
  tibble(table = table_id, term = c("Intercept", xvar, "treatment_positive"),
         estimate_refit = coef(m), ci_low_refit = ci[, 1], ci_high_refit = ci[, 2],
         se_refit = summary(m)$coefficients[, 2], t_refit = summary(m)$coefficients[, 3],
         n_rows = nrow(dat), n_inferred = sum(dat$inferred))
}
refit_tbl <- bind_rows(refit(D3, "dSBR", 3L), refit(D4, "dET", 4L)) |>
  left_join(regs |> select(table, term, estimate, ci_low, ci_high, se, t), by = c("table", "term")) |>
  mutate(estimate_diff = estimate_refit - estimate)
cat("\n== Tables 3–4: OLS refit on reconstructed Δ vs reported ==\n"); print(refit_tbl, width = 220)
write_csv(refit_tbl, file.path(out_tab, "tables3_4_refit.csv"))

# ---- write reconstructed data -----------------------------------------------------------------
write_csv(D3 |> arrange(series, dSBR, dRMSSD), here_art("data/derived/deltas_fig3.csv"))
write_csv(D4 |> arrange(series, dET, dRMSSD),  here_art("data/derived/deltas_fig4.csv"))
write_csv(TR |> arrange(series, dRMSSD),       here_art("data/derived/deltas_triplets.csv"))
write_csv(snap_report, file.path(out_tab, "digitised_snapping.csv"))
cat("\nWritten: data/derived/deltas_fig3.csv, deltas_fig4.csv, deltas_triplets.csv; output/tables/digitised_*.csv, tables3_4_refit.csv\n")
