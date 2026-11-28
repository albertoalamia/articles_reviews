# 02_consistency_checks.R — Secondi et al. 2026, Animal Behaviour (P003)
#
# Stage 1 checks: what the paper prints against (i) itself and (ii) the public dataset the
# paper cites (Zenodo 10.5281/zenodo.18200379, CC BY 4.0). No model is fitted here: refitting
# the authors' models is stage 2.
# Inputs : data/raw/table1_lrt.csv, data/raw/text_numbers.csv, data/raw/pairwise_significant.csv
#          (transcribed from the PDF, see data/raw/EXTRACTION_LOG.md);
#          data/raw/tableS2_S3_contrasts.csv (block I; local, not in the repository: a complete
#          copy of two supplementary tables, written by R/00_parse_supplement.R from the supplement);
#          data/raw/authors/2026-11-25_zenodo_18200380_dataset.xlsx (unchanged, see RECEIVED_LOG.md)
# Outputs: output/tables/consistency_*.csv (one file per block) and
#          output/tables/consistency_summary.csv (one row per check, read by review.qmd)
# Run    : from the nix shell, any working directory inside the repo:
#          Rscript AnimBehav_humic_acid_newt_predator_cues_Secondi_2026/R/02_consistency_checks.R

suppressPackageStartupMessages({ library(dplyr); library(tidyr); library(readr); library(readxl) })
art <- here::here("AnimBehav_humic_acid_newt_predator_cues_Secondi_2026")
rd  <- function(p) read_csv(file.path(art, p), show_col_types = FALSE, progress = FALSE)
out <- function(x, name) { write_csv(x, file.path(art, "output/tables", name)); invisible(x) }
summary_rows <- list()
add <- function(block, check, result, detail)
  summary_rows[[length(summary_rows) + 1]] <<- tibble(block = block, check = check, result = result, detail = detail)

lrt <- rd("data/raw/table1_lrt.csv")
tx  <- rd("data/raw/text_numbers.csv")
TX  <- function(q) as.numeric(tx$value[tx$quantity == q])
pw  <- rd("data/raw/pairwise_significant.csv")

xl  <- file.path(art, "data/raw/authors/2026-11-25_zenodo_18200380_dataset.xlsx")
d   <- read_excel(xl, sheet = 1, na = "NA")
names(d) <- trimws(names(d))
d <- d |>
  mutate(across(where(is.character), trimws),
         Capture_date = as.Date(Capture_date), Date_Test = as.Date(Date_Test),
         colour = sub("^[0-9]\\.", "", Color_Treatment), fish = Fish_Treatment)
dict <- read_excel(xl, sheet = 2, col_names = c("variable", "description"))
newts <- d |> distinct(NewtID, SiteID, Capture_date, Date_Test, Trial_Day, Arena, colour, fish)
stopifnot(nrow(newts) == n_distinct(d$NewtID))

# ---- A. Table 1: P from the likelihood ratio statistic and its df -------------------------------
A <- lrt |>
  mutate(p_recomputed = pchisq(lrt, df, lower.tail = FALSE),
         p_rounded    = round(p_recomputed, 3),
         consistent   = abs(p_rounded - p_reported) <= 0.0011)
out(A, "consistency_A_table1_lrt.csv")
add("A", "Table 1 P values from the statistic and df", ifelse(all(A$consistent), "consistent", "inconsistent"),
    sprintf("%d of %d rows reproduce to the third decimal", sum(A$consistent), nrow(A)))
a_txt <- A$lrt[A$source == "Results text"]; a_tab <- A$lrt[A$source == "Table 1" & A$response == "Total distance"]
add("A", "Triple interaction statistic for total distance, text against Table 1",
    ifelse(isTRUE(all.equal(a_txt, a_tab)), "consistent", "inconsistent"),
    sprintf("text %.3f, Table 1 %.3f; same df and P", a_txt, a_tab))

# ---- B. Sequences: counts, discards, missing values by variable -------------------------------
n_newt <- n_distinct(d$NewtID); n_slot <- n_distinct(d$Trial)
B_counts <- tibble(
  quantity = c("newts", "slots per newt (dataset)", "rows (dataset)", "sequences as reported", "sequences per newt as reported",
               "newts x reported sequences per newt", "discarded as reported", "percent discarded as reported",
               "distance missing (dataset)", "distance to feeder missing (dataset)", "time moving missing (dataset)",
               "all three missing (dataset)", "distance equal to zero (dataset)", "time moving missing where distance is zero"),
  value = c(n_newt, n_slot, nrow(d), TX("n_sequences_total"), TX("n_sequences_per_newt_text"),
            n_newt * TX("n_sequences_per_newt_text"), TX("n_sequences_discarded"), TX("pct_sequences_discarded"),
            sum(is.na(d$D.tot)), sum(is.na(d$DF.mean)), sum(is.na(d$Mov.cum)),
            sum(is.na(d$D.tot) & is.na(d$DF.mean) & is.na(d$Mov.cum)), sum(d$D.tot == 0, na.rm = TRUE),
            sum(is.na(d$Mov.cum) & !is.na(d$D.tot) & d$D.tot == 0)))
out(B_counts, "consistency_B_sequences.csv")
BV <- function(q) B_counts$value[B_counts$quantity == q]
add("B", "Number of sequences: 53 x 20 as printed against 1166", ifelse(n_newt * TX("n_sequences_per_newt_text") == TX("n_sequences_total"), "consistent", "inconsistent"),
    sprintf("53 x 20 = %d; 53 x %d = %d, the 1166 of the text and of the dataset", n_newt * TX("n_sequences_per_newt_text"), n_slot, n_newt * n_slot))
add("B", "Discarded sequences: 39 (3.3 %) against missing values in the dataset",
    ifelse(BV("distance missing (dataset)") == TX("n_sequences_discarded") & BV("time moving missing (dataset)") == TX("n_sequences_discarded"), "consistent", "inconsistent"),
    sprintf("missing: distance %d, distance to feeder %d, time moving %d (%.1f %% of 1166)", BV("distance missing (dataset)"),
            BV("distance to feeder missing (dataset)"), BV("time moving missing (dataset)"), 100 * BV("time moving missing (dataset)") / nrow(d)))
add("B", "Time moving is missing, not zero, in every sequence with zero distance",
    ifelse(BV("time moving missing where distance is zero") == BV("distance equal to zero (dataset)"), "confirmed in the dataset", "not confirmed"),
    sprintf("%d sequences with distance 0; time moving missing in %d of them; smallest non-zero distance %.2f", BV("distance equal to zero (dataset)"),
            BV("time moving missing where distance is zero"), min(d$D.tot[d$D.tot > 0], na.rm = TRUE)))

# missing and zero sequences by treatment cell and by newt
B_cell <- d |> group_by(colour, fish) |>
  summarise(newts = n_distinct(NewtID), sequences = n(), not_tracked = sum(is.na(D.tot)), zero_distance = sum(D.tot == 0, na.rm = TRUE),
            time_moving_missing = sum(is.na(Mov.cum)), pct_time_moving_missing = 100 * mean(is.na(Mov.cum)),
            median_distance = median(D.tot, na.rm = TRUE), mean_distance = mean(D.tot, na.rm = TRUE),
            median_time_moving = median(Mov.cum, na.rm = TRUE),
            mean_time_moving_as_analysed = mean(Mov.cum, na.rm = TRUE),
            mean_time_moving_zero_filled = mean(ifelse(is.na(Mov.cum) & !is.na(D.tot) & D.tot == 0, 0, Mov.cum), na.rm = TRUE), .groups = "drop") |>
  mutate(colour = factor(colour, c("Clear", "Medium", "Dark"))) |> arrange(colour, fish)
out(B_cell, "consistency_B_missing_by_cell.csv")
B_fish <- d |> group_by(fish) |> summarise(sequences = n(), not_tracked = sum(is.na(D.tot)), zero_distance = sum(D.tot == 0, na.rm = TRUE),
                                           time_moving_missing = sum(is.na(Mov.cum)), .groups = "drop")
out(B_fish, "consistency_B_missing_by_fish.csv")
B_newt <- d |> group_by(NewtID, colour, fish) |> summarise(not_tracked = sum(is.na(D.tot)), zero_distance = sum(D.tot == 0, na.rm = TRUE), .groups = "drop") |>
  filter(not_tracked > 0 | zero_distance > 0) |> arrange(desc(not_tracked + zero_distance))
out(B_newt, "consistency_B_missing_by_newt.csv")
add("B", "Untracked sequences by fish treatment", "descriptive",
    paste(sprintf("%s: %d of %d", B_fish$fish, B_fish$not_tracked, B_fish$sequences), collapse = "; "))
add("B", "Sequences dropped from the time-moving analysis by fish treatment", "descriptive",
    paste(sprintf("%s: %d of %d", B_fish$fish, B_fish$time_moving_missing, B_fish$sequences), collapse = "; "))

# ---- C. Units and ranges ----------------------------------------------------------------------
diag_cm <- sqrt(TX("arena_length")^2 + TX("arena_width")^2)
C <- tibble(
  variable = c("D.tot", "DF.mean", "Mov.cum"),
  unit_in_paper = c("mm", "mm", "s"),
  unit_in_dataset_dictionary = c(sub(".*\\((.*)\\).*", "\\1", dict$description[dict$variable == "D.tot"]),
                                 sub(".*\\((.*)\\).*", "\\1", dict$description[dict$variable == "DF.mean"]),
                                 sub(".*\\((.*)\\).*", "\\1", dict$description[dict$variable == "Mov.cum"])),
  min = c(min(d$D.tot, na.rm = TRUE), min(d$DF.mean, na.rm = TRUE), min(d$Mov.cum, na.rm = TRUE)),
  median = c(median(d$D.tot, na.rm = TRUE), median(d$DF.mean, na.rm = TRUE), median(d$Mov.cum, na.rm = TRUE)),
  max = c(max(d$D.tot, na.rm = TRUE), max(d$DF.mean, na.rm = TRUE), max(d$Mov.cum, na.rm = TRUE)),
  bound = c(NA, diag_cm, 1800),
  bound_is = c(NA, "arena diagonal, cm (30 x 25 cm)", "sequence length, s"))
out(C, "consistency_C_units_ranges.csv")
add("C", "Unit of the two distances: paper (mm) against dataset dictionary (cm)", "inconsistent",
    sprintf("distance to feeder: median %.1f, max %.1f; the arena diagonal is %.1f cm, so the values are on the cm scale of the arena", C$median[2], C$max[2], diag_cm))
# time moving against distance: how much "moving" time goes with almost no displacement
both <- d |> filter(!is.na(D.tot), !is.na(Mov.cum))
C_mov <- tibble(
  quantity = c("sequences with both variables", "Spearman correlation, distance and time moving",
               "share of sequences with time moving above 90 % of the sequence", "median time moving, s",
               "sequences with distance below 10 units", "of which time moving above 600 s", "median time moving in those, s"),
  value = c(nrow(both), cor(both$D.tot, both$Mov.cum, method = "spearman"), mean(both$Mov.cum > 0.9 * 1800), median(both$Mov.cum),
            sum(both$D.tot < 10), sum(both$D.tot < 10 & both$Mov.cum > 600), median(both$Mov.cum[both$D.tot < 10])))
out(C_mov, "consistency_C_time_moving_vs_distance.csv")
add("C", "Time spent moving against distance travelled", "descriptive",
    sprintf("median time moving %.0f s of 1800; %d sequences travel less than 10 distance units, %d of them with more than 600 s 'moving'",
            median(both$Mov.cum), sum(both$D.tot < 10), sum(both$D.tot < 10 & both$Mov.cum > 600)))

# ---- D. Dates: capture, test, interval, day labels ---------------------------------------------
D_newt <- newts |> mutate(days_capture_to_test = as.numeric(Date_Test - Capture_date))
D <- tibble(
  quantity = c("first capture date (dataset)", "last capture date (dataset)", "first capture date (paper)", "last capture date (paper)"),
  value = c(format(min(newts$Capture_date)), format(max(newts$Capture_date)), tx$value[tx$quantity == "capture_first"], tx$value[tx$quantity == "capture_last"]))
out(D, "consistency_D_dates.csv")
D_int <- tibble(source = c("paper", "dataset, one value per newt", "dataset, one value per sequence"),
                mean = c(TX("capture_to_test_mean"), mean(D_newt$days_capture_to_test), mean(as.numeric(d$Date_Test - d$Capture_date))),
                sd   = c(TX("capture_to_test_sd"), sd(D_newt$days_capture_to_test), sd(as.numeric(d$Date_Test - d$Capture_date))),
                min  = c(TX("capture_to_test_min"), min(D_newt$days_capture_to_test), NA), max = c(TX("capture_to_test_max"), max(D_newt$days_capture_to_test), NA))
out(D_int, "consistency_D_capture_to_test.csv")
add("D", "Days between capture and test: 4.89 +/- 1.83 against the dataset",
    ifelse(abs(D_int$mean[2] - D_int$mean[1]) < 0.005 & abs(D_int$sd[2] - D_int$sd[1]) < 0.005, "consistent", "inconsistent"),
    sprintf("dataset, per newt: %.2f +/- %.2f (range %d-%d)", D_int$mean[2], D_int$sd[2], D_int$min[2], D_int$max[2]))
D_days <- newts |> count(Date_Test, Trial_Day, name = "newts") |> arrange(Date_Test) |>
  mutate(rank_by_date = row_number(), label_number = as.integer(sub("Day", "", Trial_Day)), label_follows_date = rank_by_date == label_number,
         gap_days_from_previous = as.numeric(Date_Test - lag(Date_Test)))
out(D_days, "consistency_D_test_days.csv")
add("D", "Test-day labels against test dates", ifelse(all(D_days$label_follows_date), "consistent", "inconsistent"),
    paste(sprintf("%s %s (%d)", format(D_days$Date_Test, "%d %b"), D_days$Trial_Day, D_days$newts), collapse = "; "))

# ---- E. The design as the dataset shows it ----------------------------------------------------
E_cell <- newts |> count(colour, fish, name = "newts") |> mutate(colour = factor(colour, c("Clear", "Medium", "Dark"))) |> arrange(colour, fish)
out(E_cell, "consistency_E_newts_per_cell.csv")
out(newts |> count(SiteID, colour, fish, name = "newts") |> pivot_wider(names_from = c(colour, fish), values_from = newts, values_fill = 0), "consistency_E_newts_site_by_cell.csv")
out(newts |> count(Date_Test, Trial_Day, colour, fish, name = "newts") |> pivot_wider(names_from = c(colour, fish), values_from = newts, values_fill = 0), "consistency_E_newts_day_by_cell.csv")
out(newts |> count(Arena, colour, fish, name = "newts") |> pivot_wider(names_from = c(colour, fish), values_from = newts, values_fill = 0), "consistency_E_newts_arena_by_cell.csv")
out(newts |> count(SiteID, name = "newts"), "consistency_E_newts_per_site.csv")
n_cells <- nrow(E_cell) * n_slot
add("E", "Newts per treatment cell", "descriptive",
    sprintf("%d to %d newts in each of the %d colour x fish cells; the full model has %d cell-by-slot means (%d fixed-effect parameters) for %d newts",
            min(E_cell$newts), max(E_cell$newts), nrow(E_cell), n_cells, n_cells, n_newt))

# ---- F. Number of pairwise tests behind the asterisks -----------------------------------------
n_col <- n_distinct(d$colour); n_fish <- n_distinct(d$fish)
F_tests <- tibble(
  family = c("fish vs no fish, within colour and slot", "colour pairs, within fish treatment and slot", "both families, one response", "both families, two responses"),
  tests  = c(n_col * n_slot, choose(n_col, 2) * n_fish * n_slot, n_col * n_slot + choose(n_col, 2) * n_fish * n_slot, 2 * (n_col * n_slot + choose(n_col, 2) * n_fish * n_slot)),
  expected_false_positives_at_0.05 = tests * 0.05)
F_rep <- pw |> filter(!is.na(slot)) |> mutate(family = ifelse(comparison == "fish vs no fish", "fish vs no fish", "colour pairs")) |> count(response, family, name = "reported_significant")
out(F_tests, "consistency_F_pairwise_tests.csv"); out(F_rep, "consistency_F_pairwise_reported.csv")
add("F", "Pairwise comparisons by time slot", "descriptive",
    sprintf("%d slot-wise comparisons per response (%d + %d), %d for the two responses; %d reported as significant at P < 0.05; %.0f expected at that level per response if no difference existed and tests were unadjusted across slots",
            F_tests$tests[3], F_tests$tests[1], F_tests$tests[2], F_tests$tests[4], sum(F_rep$reported_significant), F_tests$expected_false_positives_at_0.05[3]))

# ---- G. Hours of reduced activity quoted in the Discussion ------------------------------------
G <- pw |> filter(response == "distance", comparison == "fish vs no fish") |> count(within, name = "significant_slots") |>
  left_join(tibble(within = c("clear", "dark"), hours_in_discussion = c(TX("hours_reduced_clear"), TX("hours_reduced_dark"))), by = "within")
out(G, "consistency_G_hours_reduced.csv")
add("G", "Discussion: reduced over 6 h in dark water and 3 h in clear water", "consistent with the count of significant slots",
    paste(sprintf("%s: %d significant slots", G$within, G$significant_slots), collapse = "; "))

# ---- raw cell-by-slot medians, for the review's first look at the data (no model) ---------------
H <- d |> group_by(colour, fish, Trial, Trial_Time) |>
  summarise(n = sum(!is.na(D.tot)), median_distance = median(D.tot, na.rm = TRUE), mean_log10_distance_plus1 = mean(log10(D.tot + 1), na.rm = TRUE),
            zero_distance = sum(D.tot == 0, na.rm = TRUE), .groups = "drop") |> arrange(colour, fish, Trial)
out(H, "consistency_H_cell_by_slot.csv")
H_first <- d |> mutate(block = cut(Trial, c(0, 6, 22), labels = c("slots 1-6 (15:30 to 21:00)", "slots 7-22"))) |>
  group_by(colour, fish, block) |> summarise(median_distance = median(D.tot, na.rm = TRUE), .groups = "drop") |>
  pivot_wider(names_from = fish, values_from = median_distance)
out(H_first, "consistency_H_first_six_slots.csv")

# ---- I. Supplementary Tables S2 and S3 (contrasts by slot) --------------------------------------
# S2 is captioned as distance travelled, S3 as proportion of time spent moving. Parsed from the
# supplement by R/00_parse_supplement.R (data/raw/tableS2_S3_contrasts.csv, local; see
# EXTRACTION_LOG.md); z and P as printed. The outputs of this block are summaries and the rows
# the concerns cite, never the two tables whole (protocol/copyright.md §3).
if (!file.exists(file.path(art, "data/raw/tableS2_S3_contrasts.csv")))
  stop("data/raw/tableS2_S3_contrasts.csv is missing: run R/00_parse_supplement.R first (it needs the supplement in paper/)")
ct <- rd("data/raw/tableS2_S3_contrasts.csv") |> mutate(family = ifelse(contrast == "fish - no fish", "fish vs no fish", "colour pairs"))
stopifnot(nrow(ct) == 2 * F_tests$tests[3], all(count(ct, table, family)$n == rep(c(F_tests$tests[2], F_tests$tests[1]), 2)))
I_pair <- ct |> select(table, family, contrast, within, hour, slot, estimate, se, p_value) |>
  pivot_wider(names_from = table, values_from = c(estimate, se, p_value)) |>
  mutate(abs_diff_estimate = abs(estimate_S2 - estimate_S3))
I_same <- tibble(rows = nrow(I_pair), within_0.005 = sum(I_pair$abs_diff_estimate <= 0.0051), within_0.02 = sum(I_pair$abs_diff_estimate <= 0.02),
                 max_abs_diff = max(I_pair$abs_diff_estimate), correlation = cor(I_pair$estimate_S2, I_pair$estimate_S3))
out(I_same, "consistency_I_S2_against_S3_summary.csv")
out(I_pair |> filter(abs_diff_estimate > 0.02) |> arrange(desc(abs_diff_estimate)), "consistency_I_S2_against_S3_differing.csv")
add("I", "Table S3 (captioned time spent moving) against Table S2 (distance travelled)", "inconsistent",
    sprintf("%d of %d estimates agree within 0.02 (%d within 0.005), correlation %.3f, largest difference %.2f; two different responses on two different scales would not agree",
            I_same$within_0.02, I_same$rows, I_same$within_0.005, I_same$correlation, I_same$max_abs_diff))

# which slots each table marks at P < 0.05, against the Results text (pairwise_significant.csv)
slot_of <- function(hhmm) match(as.integer(hhmm) %/% 100, c(15:23, 0:12))
txt_fish <- pw |> filter(comparison == "fish vs no fish", !is.na(slot)) |> mutate(s = slot_of(slot)) |>
  group_by(response, within) |> summarise(text_slots = paste(sort(s), collapse = ","), .groups = "drop")
tab_fish <- ct |> filter(family == "fish vs no fish", p_value < 0.05) |>
  group_by(table, within) |> summarise(slots = paste(sort(slot), collapse = ","), .groups = "drop") |>
  pivot_wider(names_from = table, values_from = slots, names_prefix = "table_")
I_slots <- txt_fish |> pivot_wider(names_from = response, values_from = text_slots, names_prefix = "text_") |> left_join(tab_fish, by = "within")
names(I_slots) <- gsub(" ", "_", names(I_slots))
out(I_slots, "consistency_I_significant_slots.csv")
add("I", "Fish vs no fish, slots at P < 0.05: Results text against Tables S2 and S3",
    ifelse(all(I_slots$text_distance == I_slots$table_S2) && !all(I_slots$text_time_moving == I_slots$table_S3), "S2 matches the text for distance; S3 does not match the text for time moving", "see detail"),
    paste(sprintf("%s: text distance %s, S2 %s; text time moving %s, S3 %s", I_slots$within, I_slots$text_distance, I_slots$table_S2, I_slots$text_time_moving, I_slots$table_S3), collapse = " | "))

# adjustment actually applied: P as printed against the unadjusted two-sided normal P of the printed z
I_adj <- ct |> mutate(p_unadjusted = 2 * pnorm(-abs(z_ratio))) |> group_by(table, family) |>
  summarise(tests = n(), max_abs_diff_printed_vs_unadjusted = max(abs(p_value - p_unadjusted)),
            significant_printed = sum(p_value < 0.05), significant_unadjusted = sum(p_unadjusted < 0.05),
            significant_holm_over_slots = sum(p.adjust(p_unadjusted, "holm") < 0.05), .groups = "drop")
out(I_adj, "consistency_I_adjustment.csv")
# the fish against no fish contrasts printed below 0.05 in either table, with their Holm-adjusted P
I_sig <- ct |> filter(family == "fish vs no fish") |> group_by(table) |>
  mutate(p_unadjusted = 2 * pnorm(-abs(z_ratio)), p_holm_over_slots = p.adjust(p_unadjusted, "holm")) |> ungroup() |>
  filter(p_value < 0.05) |> select(table, within, hour, slot, estimate, se, z_ratio, p_value, p_holm_over_slots) |> arrange(table, within, slot)
out(I_sig, "consistency_I_significant_contrasts.csv")
i2 <- I_adj |> filter(table == "S2", family == "fish vs no fish")
holm_which <- ct |> filter(table == "S2", family == "fish vs no fish") |> mutate(p = p.adjust(2 * pnorm(-abs(z_ratio)), "holm")) |> filter(p < 0.05)
add("I", "Fish vs no fish comparisons: are the printed P values adjusted?", "not adjusted",
    sprintf("Table S2: the %d printed P values equal the unadjusted normal P of the printed z (largest difference %.3f, rounding of z); %d below 0.05 as printed; %d after a Holm adjustment over the %d slot-wise tests, from the rounded z (%s)",
            i2$tests, i2$max_abs_diff_printed_vs_unadjusted, i2$significant_printed, i2$significant_holm_over_slots, i2$tests,
            paste(sprintf("%s %02d00", holm_which$within, holm_which$hour), collapse = ", ")))

summary <- bind_rows(summary_rows)
out(summary, "consistency_summary.csv")
print(as.data.frame(summary), right = FALSE)
cat("\n"); print(as.data.frame(B_cell), digits = 4); cat("\n"); print(as.data.frame(D_days)); cat("\n"); print(as.data.frame(A), digits = 4)
cat("\n"); print(as.data.frame(H_first), digits = 4); cat("\n"); print(as.data.frame(C), digits = 4); cat("\n"); print(as.data.frame(C_mov), digits = 4)
