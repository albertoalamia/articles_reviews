# 05_gof_authors_models.R — Bukhari 2026, stage 2: goodness of fit of the Table 3 and Table 4 models
#
# Inputs : data/derived/deltas_fig3.csv   (ΔRMSSD, ΔSBR, treatment; 68 reconstructed rows)
#          data/derived/deltas_fig4.csv   (ΔRMSSD, ΔET,  treatment; 68 reconstructed rows)
#          data/raw/tables3_4_regressions.csv (reported coefficients, for the fits plot)
# Outputs: output/tables/gof_fit_summary.csv        one row per table: R², LOO error, partial R², VIF, negative predictions
#          output/tables/gof_residual_tests.csv     normality, heteroscedasticity, functional form, interaction
#          output/tables/gof_by_group.csv           slope, r and R² of ΔRMSSD on x within each treatment
#          output/tables/gof_model_comparison.csv   authors' model vs 6 alternatives (AICc, BIC, LOO RMSE)
#          output/tables/gof_influence.csv          rows with high Cook's D / leverage / |studentised residual|
#          output/figures/gof_fig3_diagnostics.png, gof_fig4_diagnostics.png   base-R residual plots
#          output/figures/gof_fig3_fits.png,        gof_fig4_fits.png          data with common- and separate-slope fits
# Run    : Rscript SciRep_emotions_in_working_donkeys_Bukhari_2026/R/05_gof_authors_models.R
#
# The authors' model (Tables 3–4) is ΔRMSSD ~ x + treatment with a donkey random intercept. On the
# reconstructed data OLS reproduces it to the second decimal (04_reconcile_digitised.R), so the
# random intercept is ≈ 0 and OLS is the model under test. Donkey identity is unknown, so nothing
# here can test the random-effect part; everything else about the model is testable.
#
# Caveats carried over from the reconstruction: ΔRMSSD is rounded to 1 ms and ΔET to 0.1 °C for
# plotting; ΔSBR is exact. All values are unsigned changes (≥ 0), see notes/03_concerns.md C1.

suppressPackageStartupMessages({ library(tidyverse); library(broom) })
here_art <- function(...) here::here("SciRep_emotions_in_working_donkeys_Bukhari_2026", ...)
out_tab <- here_art("output/tables");  dir.create(out_tab, showWarnings = FALSE, recursive = TRUE)
out_fig <- here_art("output/figures"); dir.create(out_fig, showWarnings = FALSE, recursive = TRUE)

load_fig <- function(file, xvar) {
  read_csv(here_art("data/derived", file), show_col_types = FALSE) |>
    transmute(treatment = factor(series, levels = c("negative", "positive")),   # reference = negative, as in Tables 3–4
              x = .data[[xvar]], y = dRMSSD)
}
D <- list(`3` = list(dat = load_fig("deltas_fig3.csv", "dSBR"), xname = "dSBR", xlab = "ΔSBR (blinks/min)"),
          `4` = list(dat = load_fig("deltas_fig4.csv", "dET"),  xname = "dET",  xlab = "ΔET (°C)"))
regs <- read_csv(here_art("data/raw/tables3_4_regressions.csv"), show_col_types = FALSE)

# ---- helpers ---------------------------------------------------------------------------------
pr <- function(m, nd) {                                   # response-scale prediction for lm / gls / glm
  if (inherits(m, "glm")) as.numeric(predict(m, newdata = nd, type = "response"))
  else as.numeric(predict(m, newdata = nd))
}
loo_rmse <- function(fit_fun, dat) {                      # explicit leave-one-out, n = 68 so it is cheap
  pred <- vapply(seq_len(nrow(dat)), function(i) pr(fit_fun(dat[-i, ]), dat[i, , drop = FALSE]), numeric(1))
  c(loo_rmse = sqrt(mean((dat$y - pred)^2)), loo_r2 = 1 - sum((dat$y - pred)^2) / sum((dat$y - mean(dat$y))^2))
}
aicc <- function(m, n) { ll <- logLik(m); k <- attr(ll, "df"); AIC(m) + 2 * k * (k + 1) / (n - k - 1) }

bp_koenker <- function(m) {                               # Breusch–Pagan, Koenker's studentised form
  e2 <- resid(m)^2; Z <- model.matrix(m)[, -1, drop = FALSE]
  r2 <- summary(lm(e2 ~ Z))$r.squared; stat <- length(e2) * r2; df <- ncol(Z)
  tibble(statistic = stat, df = df, p = pchisq(stat, df, lower.tail = FALSE))
}
brown_forsythe <- function(e, g) {                        # Levene with group medians, on the residuals
  z <- abs(e - ave(e, g, FUN = median)); a <- anova(lm(z ~ g))
  tibble(statistic = a$`F value`[1], df = paste(a$Df, collapse = ","), p = a$`Pr(>F)`[1])
}
reset <- function(m, dat) {                               # Ramsey RESET with fitted² and fitted³
  dat$f2 <- fitted(m)^2; dat$f3 <- fitted(m)^3
  a <- anova(m, update(m, . ~ . + f2 + f3, data = dat))
  tibble(statistic = a$F[2], df = paste(a$Df[2], a$Res.Df[2], sep = ","), p = a$`Pr(>F)`[2])
}

fit_summary <- list(); res_tests <- list(); by_group <- list(); comparison <- list(); influence <- list()

for (tb in names(D)) {
  dat <- D[[tb]]$dat; n <- nrow(dat); xname <- D[[tb]]$xname
  cat("\n\n=====================  Table", tb, ":  dRMSSD ~", xname, "+ treatment  (n =", n, ") =====================\n")

  # ---- A. authors' model: fit, in-sample and out-of-sample fit ------------------------------
  m0 <- lm(y ~ treatment, data = dat)                     # treatment only
  m1 <- lm(y ~ x + treatment, data = dat)                 # authors' model (fixed part)
  m2 <- lm(y ~ x * treatment, data = dat)                 # separate slopes
  s1 <- summary(m1)
  sse <- function(m) sum(resid(m)^2)
  mx  <- lm(y ~ x, data = dat)                            # x only, for the partial R² of treatment
  loo1 <- loo_rmse(function(d) lm(y ~ x + treatment, data = d), dat)
  vif_x <- 1 / (1 - summary(lm(x ~ treatment, data = dat))$r.squared)
  b <- coef(m1)
  x0_neg <- -b["(Intercept)"] / b["x"]                    # where the negative-group line crosses zero
  neg_dat <- dat |> filter(treatment == "negative")
  beyond <- if (b["x"] < 0) sum(neg_dat$x > x0_neg) else sum(neg_dat$x < x0_neg)

  fs <- tibble(table = tb, x = xname, n = n,
               r2 = s1$r.squared, adj_r2 = s1$adj.r.squared, sigma = s1$sigma,
               rmse_in = sqrt(sse(m1) / n), loo_rmse = loo1[["loo_rmse"]], loo_r2 = loo1[["loo_r2"]],
               r2_treatment_only = summary(m0)$r.squared,
               partial_r2_x_given_treatment = (sse(m0) - sse(m1)) / sse(m0),
               partial_r2_treatment_given_x = (sse(mx) - sse(m1)) / sse(mx),
               vif_x_vs_treatment = vif_x,
               sd_x_negative = sd(neg_dat$x), sd_x_positive = sd(dat$x[dat$treatment == "positive"]),
               smd_x_between_treatments = diff(tapply(dat$x, dat$treatment, mean)) / sqrt(mean(tapply(dat$x, dat$treatment, var))),
               n_fitted_below_0 = sum(fitted(m1) < 0), min_fitted = min(fitted(m1)),
               zero_crossing_x_negative_group = unname(x0_neg), n_negative_obs_beyond_crossing = beyond,
               resid_sd_negative = sd(resid(m1)[dat$treatment == "negative"]),
               resid_sd_positive = sd(resid(m1)[dat$treatment == "positive"]))
  fit_summary[[tb]] <- fs
  cat("\n-- A. fit of the authors' model --\n"); print(as.data.frame(t(fs)), right = FALSE)

  # ---- B. residual tests ---------------------------------------------------------------------
  rs <- rstudent(m1)
  rt <- bind_rows(
    tibble(test = "Shapiro-Wilk, studentised residuals", statistic = shapiro.test(rs)$statistic, df = NA, p = shapiro.test(rs)$p.value),
    bp_koenker(m1) |> mutate(test = "Breusch-Pagan (Koenker) on x + treatment", df = as.character(df)),
    brown_forsythe(resid(m1), dat$treatment) |> mutate(test = "Brown-Forsythe: residual variance by treatment"),
    tibble(test = "F ratio of residual variances, positive / negative",
           statistic = var(resid(m1)[dat$treatment == "positive"]) / var(resid(m1)[dat$treatment == "negative"]),
           df = "33,33", p = var.test(resid(m1) ~ dat$treatment, ratio = 1)$p.value),
    reset(m1, dat) |> mutate(test = "RESET (fitted^2, fitted^3): functional form"),
    { a <- anova(m1, m2); tibble(test = "x × treatment interaction (F vs authors' model)", statistic = a$F[2], df = paste(a$Df[2], a$Res.Df[2], sep = ","), p = a$`Pr(>F)`[2]) },
    tibble(test = "Spearman |studentised residual| vs fitted (variance grows with mean)",
           statistic = cor(abs(rs), fitted(m1), method = "spearman"), df = NA,
           p = cor.test(abs(rs), fitted(m1), method = "spearman", exact = FALSE)$p.value)
  ) |> mutate(table = tb, .before = 1) |> mutate(df = as.character(df))
  res_tests[[tb]] <- rt
  cat("\n-- B. residual tests --\n"); print(rt |> mutate(across(c(statistic, p), ~ signif(.x, 3))), n = 20, width = 160)

  # ---- C. the relation within each treatment -------------------------------------------------
  bg <- dat |> group_by(treatment) |> group_modify(function(d, k) {
    m <- lm(y ~ x, data = d); ct <- cor.test(d$x, d$y)
    tibble(n = nrow(d), mean_x = mean(d$x), sd_x = sd(d$x), mean_y = mean(d$y), sd_y = sd(d$y),
           slope = coef(m)[2], se = summary(m)$coefficients[2, 2],
           ci_low = confint(m)[2, 1], ci_high = confint(m)[2, 2], p_slope = summary(m)$coefficients[2, 4],
           r = ct$estimate, r_ci_low = ct$conf.int[1], r_ci_high = ct$conf.int[2], r2_within = summary(m)$r.squared,
           resid_sd = summary(m)$sigma)
  }) |> ungroup() |> mutate(table = tb, x = xname, .before = 1)
  slopes <- bind_rows(bg |> select(treatment, slope, se, ci_low, ci_high, p_slope),
                      tibble(treatment = "common (authors')", slope = coef(m1)["x"], se = s1$coefficients["x", 2],
                             ci_low = confint(m1)["x", 1], ci_high = confint(m1)["x", 2], p_slope = s1$coefficients["x", 4]),
                      tibble(treatment = "marginal (ignoring treatment)", slope = coef(mx)[2], se = summary(mx)$coefficients[2, 2],
                             ci_low = confint(mx)[2, 1], ci_high = confint(mx)[2, 2], p_slope = summary(mx)$coefficients[2, 4]))
  by_group[[tb]] <- bg
  cat("\n-- C. within-treatment relation --\n"); print(bg |> mutate(across(where(is.numeric), ~ signif(.x, 3))), width = 200)
  cat("\n   slopes:\n"); print(slopes |> mutate(across(where(is.numeric), ~ signif(.x, 3))))

  # ---- D. model comparison -------------------------------------------------------------------
  fits <- list(
    "M0 treatment only (lm)"                       = function(d) lm(y ~ treatment, data = d),
    "M1 authors: x + treatment (lm)"               = function(d) lm(y ~ x + treatment, data = d),
    "M2 x * treatment (lm)"                        = function(d) lm(y ~ x * treatment, data = d),
    "M3 x + treatment, variance by treatment (gls)" = function(d) nlme::gls(y ~ x + treatment, data = d, weights = nlme::varIdent(form = ~ 1 | treatment), method = "ML"),
    "M4 x * treatment, variance by treatment (gls)" = function(d) nlme::gls(y ~ x * treatment, data = d, weights = nlme::varIdent(form = ~ 1 | treatment), method = "ML"),
    "M5 Gamma log link: x + treatment (glm)"        = function(d) glm(y ~ x + treatment, data = d, family = Gamma(link = "log")),
    "M6 Gamma log link: x * treatment (glm)"        = function(d) glm(y ~ x * treatment, data = d, family = Gamma(link = "log"))
  )
  cmp <- imap(fits, function(f, nm) {
    m <- f(dat); ll <- logLik(m); lo <- loo_rmse(f, dat)
    tibble(model = nm, k = attr(ll, "df"), logLik = as.numeric(ll), AIC = AIC(m), AICc = aicc(m, n), BIC = BIC(m),
           rmse_in = sqrt(mean((dat$y - pr(m, dat))^2)), loo_rmse = lo[["loo_rmse"]], loo_r2 = lo[["loo_r2"]],
           slope_x_negative = if (inherits(m, "glm")) NA_real_ else unname(coef(m)["x"]),
           slope_x_positive = if (inherits(m, "glm")) NA_real_ else unname(coef(m)["x"] + coalesce(coef(m)["x:treatmentpositive"], 0)))
  }) |> list_rbind() |> mutate(dAICc = AICc - min(AICc), dBIC = BIC - min(BIC), table = tb, .before = 1)
  comparison[[tb]] <- cmp
  cat("\n-- D. model comparison (ML log-likelihoods; Gamma models on the same response scale) --\n")
  print(cmp |> select(model, k, AICc, dAICc, BIC, dBIC, rmse_in, loo_rmse, loo_r2, slope_x_negative, slope_x_positive) |>
          mutate(across(where(is.numeric), ~ signif(.x, 4))), width = 200)
  m3 <- fits[[4]](dat)
  cat("   M3 residual SD ratio positive/negative:", signif(coef(m3$modelStruct$varStruct, unconstrained = FALSE), 3), "\n")

  # ---- E. influence --------------------------------------------------------------------------
  p <- length(coef(m1))
  inf <- dat |> mutate(row = row_number(), fitted = fitted(m1), resid = resid(m1), rstudent = rs,
                       leverage = hatvalues(m1), cooks_d = cooks.distance(m1), dfbeta_x = dfbetas(m1)[, "x"]) |>
    filter(cooks_d > 4 / n | leverage > 2 * p / n | abs(rstudent) > 2) |>
    arrange(desc(cooks_d)) |> mutate(table = tb, .before = 1)
  influence[[tb]] <- inf
  top <- inf |> slice_max(cooks_d, n = 3) |> pull(row)
  m1_drop <- lm(y ~ x + treatment, data = dat[-top, ])
  cat("\n-- E. influence: rows flagged (Cook's D > 4/n, leverage > 2p/n or |rstudent| > 2) --\n")
  print(inf |> mutate(across(where(is.numeric), ~ signif(.x, 3))), width = 200)
  cat("   slope of x without the 3 most influential rows:", signif(coef(m1_drop)["x"], 3),
      " (full data", signif(coef(m1)["x"], 3), ")\n")
  fit_summary[[tb]] <- fit_summary[[tb]] |>                 # keep it in the CSV, not only on the console
    mutate(slope_x = unname(coef(m1)["x"]), slope_x_without_top3_cooks = unname(coef(m1_drop)["x"]),
           top3_cooks_rows = paste(top, collapse = ";"))

  # ---- F. figures ----------------------------------------------------------------------------
  png(file.path(out_fig, sprintf("gof_fig%s_diagnostics.png", tb)), width = 1600, height = 1600, res = 200)
  par(mfrow = c(2, 2), mar = c(4, 4, 2.5, 1))
  plot(m1, which = c(1, 2, 3, 5), col = ifelse(dat$treatment == "positive", "#00868B", "#C0392B"), pch = 16,
       sub.caption = sprintf("Table %s model, OLS on reconstructed data (teal = positive, red = negative)", tb))
  dev.off()

  rep_b <- regs |> filter(table == as.integer(tb))
  grid <- expand_grid(treatment = factor(c("negative", "positive"), levels = c("negative", "positive")),
                      x = seq(min(dat$x), max(dat$x), length.out = 50))
  lines <- bind_rows(grid |> mutate(fit = pr(m1, grid), model = "common slope (authors' model, OLS refit)"),
                     grid |> mutate(fit = pr(m2, grid), model = "separate slopes (x × treatment)"),
                     grid |> mutate(fit = pr(fits[[6]](dat), grid), model = "Gamma GLM, log link, additive"))
  g <- ggplot(dat, aes(x, y, colour = treatment)) +
    geom_hline(yintercept = 0, colour = "grey60", linewidth = 0.3) +
    geom_line(data = lines, aes(y = fit, linetype = model), linewidth = 0.7) +
    geom_point(alpha = 0.6, size = 2) +
    scale_colour_manual(values = c(negative = "#C0392B", positive = "#00868B")) +
    labs(x = D[[tb]]$xlab, y = "ΔRMSSD (ms)", colour = "treatment", linetype = NULL,
         title = sprintf("Table %s model on the reconstructed Figure %s data (n = 68)", tb, tb),
         subtitle = sprintf("common-slope line: fitted %s = %.2f·x + %.2f (+ %.2f positive)",
                            "ΔRMSSD", coef(m1)["x"], coef(m1)["(Intercept)"], coef(m1)["treatmentpositive"])) +
    theme_minimal(base_size = 11) + theme(legend.position = "bottom", legend.box = "vertical")
  ggsave(file.path(out_fig, sprintf("gof_fig%s_fits.png", tb)), g, width = 7.5, height = 6, dpi = 200)
}

write_csv(list_rbind(fit_summary), file.path(out_tab, "gof_fit_summary.csv"))
write_csv(list_rbind(res_tests),   file.path(out_tab, "gof_residual_tests.csv"))
write_csv(list_rbind(by_group),    file.path(out_tab, "gof_by_group.csv"))
write_csv(list_rbind(comparison),  file.path(out_tab, "gof_model_comparison.csv"))
write_csv(list_rbind(influence),   file.path(out_tab, "gof_influence.csv"))
cat("\nWritten: output/tables/gof_*.csv; output/figures/gof_fig{3,4}_{diagnostics,fits}.png\n")
