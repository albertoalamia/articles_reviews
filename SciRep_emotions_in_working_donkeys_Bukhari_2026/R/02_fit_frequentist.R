# 02_fit_frequentist.R — Bukhari 2026, stage 3: the planned models fitted with glmmTMB
#
# Plan   : notes/04_analysis_plan.md v1.1 — sections 3 (model), 4 (stage 3 specifics), 7 (deviations), 8 (schedule)
# Inputs : data/derived/stage3/ensemble_conditions.csv.gz   long: rho_dd, rep, outcome, donkey, condition, order, y
#          data/derived/stage3/ensemble_e4_pairs.csv.gz     long: rho_dd, rep, treatment, figure, x_name, x, dRMSSD
#          data/raw/table2_conditions.csv                   Table 2 means and SDs (for the moment check only)
#          output/tables/gof_by_group.csv                   stage 2 within-treatment slopes on the unsigned data (E4 sign check)
# Sections (one command-line flag each; later sections are added at their step of the schedule):
#   A  --example   (S2)  the three condition models and the two E4 models on the example replicate
#                        (scenario rho_dd = 0, replicate 1): estimands, DHARMa diagnostics, model comparison
#   B  --ensemble  (S3)  E1–E3 on the 600 replicates, Rubin pooling, diagnostics summary, model comparison,
#                        share of replicates with Cov(c, c') > Var(c); --cores N (default: all but two); --reps N (smoke test)
#   C  --e4 --bootstrap (S4)  E4 on the ensemble; parametric bootstrap of E1–E2 on one replicate
# Outputs (A): output/tables/stage3_example_estimands.csv        E1, E2, E3 per outcome, link and response scale, Wald 95 %
#              output/tables/stage3_example_dispersion.csv       variance parameters by condition (sigma_c, alpha_c, phi), planned vs comparison fits
#              output/tables/stage3_example_diagnostics.csv      convergence, optimiser, Pearson ratio (SBR), DHARMa tests, random-effect normality
#              output/tables/stage3_example_model_comparison.csv AICc and E1 of every compared model (log-normal fits with the Jacobian)
#              output/tables/stage3_example_random_structure.csv within-donkey covariance of the condition values: example data vs model
#              output/tables/stage3_example_moments.csv          observed condition means/SDs of the example vs model-implied (marginal)
#              output/tables/stage3_example_e4.csv               E4: a_t, b_t, s_t, r_t per treatment, slope difference, per-group OLS check
#              output/figures/stage3_example_dharma_<outcome>.png, stage3_example_e4.png
# Outputs (B): output/tables/stage3_ensemble_estimands.csv          E1–E3 pooled by Rubin's rules per scenario (K = 200), Wald 95 %
#              output/tables/stage3_ensemble_check_vs_exact.csv     pooled E1 differences (rho_dd = 0) vs the exact paired results of stage 2
#              output/tables/stage3_ensemble_diagnostics.csv        shares of replicates failing each diagnostic, per scenario and outcome
#              output/tables/stage3_ensemble_model_comparison.csv   share of replicates preferring each model by AICc, median E1 per model
#              output/tables/stage3_ensemble_random_structure.csv   share of replicates with Cov(c, c') > min Var, mean correlations
#              output/tables/stage3_ensemble_per_replicate_{estimands,diagnostics,model_comparison,random_structure}.csv.gz
#              output/tables/stage3_ensemble_errors.csv             only if a replicate failed
# Run    : Rscript SciRep_emotions_in_working_donkeys_Bukhari_2026/R/02_fit_frequentist.R --example     (seconds)
#          Rscript SciRep_emotions_in_working_donkeys_Bukhari_2026/R/02_fit_frequentist.R --ensemble    (≈ 10–20 min on 10 cores)
#
# Models (plan §3, v1.1):
#   SBR    y ~ NB2 (Poisson if phi is not identified), log link, condition + order, shared donkey intercept.
#   ET     (y_i1, y_i2, y_i3) ~ MVN(eta_i, Sigma): condition + order fixed, unstructured 3 x 3 donkey covariance,
#          no separate residual (three observations per donkey; glmmTMB: us(0 + condition | donkey), dispformula = ~ 0).
#   RMSSD  the same on log y. Ratios of arithmetic means exp(d_beta + (sigma_c^2 - sigma_ref^2) / 2), averaged over
#          donkeys (primary), and the median-donkey ratio exp(d_beta) alongside. Gamma with shared intercept is sensitivity (ii).
# Conventions (plan §1–3): condition reference = control, order reference = 1, treatment reference = negative;
# contrasts averaged over the three order positions with equal weights; changes are treatment − control.
# E3: SBR tau and ICC on the latent (log) scale, sigma²_latent = trigamma(phi) + 1/mu_control (1/mu_control for Poisson);
# ET and RMSSD: the three donkey-level SDs and the three within-donkey correlations between conditions.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) args <- "--example"
if (any(c("--e4", "--bootstrap") %in% args)) stop("--e4 --bootstrap (S4) is added at its step")
opt_cores <- match("--cores", args); opt_reps <- match("--reps", args)
allowed <- c("--example", "--ensemble", "--cores", "--reps", if (!is.na(opt_cores)) args[opt_cores + 1], if (!is.na(opt_reps)) args[opt_reps + 1])
if (!all(args %in% allowed)) stop("unknown argument(s): ", paste(setdiff(args, allowed), collapse = " "))
RUN_EXAMPLE  <- "--example" %in% args
RUN_ENSEMBLE <- "--ensemble" %in% args
if (!RUN_EXAMPLE && !RUN_ENSEMBLE) stop("nothing to do: use --example and/or --ensemble")

suppressPackageStartupMessages({ library(tidyverse); library(glmmTMB); library(emmeans); library(DHARMa) })
emm_options(msg.interaction = FALSE)      # E4 intercepts at x = 0 are wanted despite the treatment × x interaction
here_art <- function(...) here::here("SciRep_emotions_in_working_donkeys_Bukhari_2026", ...)
out_tab <- here_art("output/tables"); out_fig <- here_art("output/figures")
dir.create(out_tab, showWarnings = FALSE, recursive = TRUE); dir.create(out_fig, showWarnings = FALSE, recursive = TRUE)

EXAMPLE      <- list(rho_dd = 0, rep = 1L)
N_SIM_DHARMA <- 250L
SEED_DHARMA  <- 20261107L
OUTCOMES     <- c("SBR", "ET", "RMSSD")
COND_LEVELS  <- c("control", "positive", "negative")
FIXEF_NAMES  <- c("(Intercept)", "conditionpositive", "conditionnegative", "order2", "order3")
N_CORES      <- if (is.na(opt_cores)) max(1L, parallel::detectCores() - 2L) else as.integer(args[opt_cores + 1])
N_REPS       <- if (is.na(opt_reps)) Inf else as.integer(args[opt_reps + 1])      # --reps N: first N replicates per scenario (smoke test)

cond_t2 <- read_csv(here_art("data/raw/table2_conditions.csv"), show_col_types = FALSE)
ens     <- read_csv(here_art("data/derived/stage3/ensemble_conditions.csv.gz"), show_col_types = FALSE)
e4pairs <- read_csv(here_art("data/derived/stage3/ensemble_e4_pairs.csv.gz"), show_col_types = FALSE)
gof_grp <- read_csv(here_art("output/tables/gof_by_group.csv"), show_col_types = FALSE)
exact   <- read_csv(here_art("output/tables/contrasts_exact.csv"), show_col_types = FALSE)   # stage 2: exact paired results (d = control − treatment)

# ---- data handling ---------------------------------------------------------------------------
prep_condition <- function(d) d |>
  mutate(condition = factor(condition, levels = COND_LEVELS), order = factor(order, levels = 1:3),
         donkey = factor(donkey)) |>
  arrange(donkey, condition)
prep_e4 <- function(p) p |> mutate(treatment = factor(treatment, levels = c("negative", "positive")))

# ---- the planned models and their comparison fits (plan §3, §4) ---------------------------------
# Every fit carries three attributes: family_used (label), structure ("us" = unstructured donkey covariance,
# "intercept" = shared donkey intercept), response_log (TRUE when the response is log(y)).
tag <- function(fit, family_used, structure, response_log) {
  attr(fit, "family_used") <- family_used; attr(fit, "structure") <- structure; attr(fit, "response_log") <- response_log
  fit
}
# re_structure = "us" is the planned structure for ET and RMSSD (SBR always has the shared intercept);
# "intercept" with dispersion/family_alt gives the v1.0 and pooled-dispersion comparison fits.
fit_condition <- function(d, outcome, re_structure = c("us", "intercept"), dispersion = c("by_condition", "pooled"), family_alt = NULL) {
  re_structure <- match.arg(re_structure); dispersion <- match.arg(dispersion)
  f  <- y ~ condition + order + (1 | donkey)
  df <- if (dispersion == "by_condition") ~ condition else ~ 1
  if (outcome == "SBR") {
    if (identical(family_alt, "poisson")) return(tag(glmmTMB(f, data = d, family = poisson()), "poisson", "intercept", FALSE))
    fit <- suppressWarnings(glmmTMB(f, data = d, family = nbinom2()))
    # plan §3: Poisson is the limit phi -> Inf and is reported when phi is not identified (non-PD Hessian or phi > 1e3)
    if (!converged(fit) || sigma(fit) > 1e3) return(tag(glmmTMB(f, data = d, family = poisson()), "poisson (NB2 phi not identified)", "intercept", FALSE))
    return(tag(fit, "nbinom2", "intercept", FALSE))
  }
  if (re_structure == "us") {
    raw <- outcome == "ET" || identical(family_alt, "gaussian_raw")     # RMSSD on the raw scale: comparison fit only (§4)
    f_us <- if (raw) y ~ condition + order + us(0 + condition | donkey) else log(y) ~ condition + order + us(0 + condition | donkey)
    lab  <- if (outcome == "ET") "gaussian MVN (unstructured donkey covariance)" else if (raw) "gaussian MVN on y (raw-scale check)" else "log-normal MVN (unstructured donkey covariance)"
    return(tag(fit_retry(f_us, d, gaussian(), ~ 0), lab, "us", !raw))   # dispformula ~ 0: residual variance fixed at ~0
  }
  if (outcome == "ET") return(tag(fit_retry(f, d, gaussian(), df), "gaussian", "intercept", FALSE))
  if (identical(family_alt, "lognormal"))
    return(tag(fit_retry(log(y) ~ condition + order + (1 | donkey), d, gaussian(), df), "log-normal", "intercept", TRUE))
  tag(fit_retry(f, d, Gamma(link = "log"), df), "Gamma(log)", "intercept", FALSE)
}
# glmmTMB's default optimiser (nlminb) can stop at a boundary local optimum of a variance model (ET v1.0 model on
# the example: sigma_control -> 0, non-PD Hessian, while the maximum has sigma_control = 0.26 — checked against
# nlme::lme and a direct profile); BFGS from the same start finds it. Try default, then BFGS; record which.
fit_retry <- function(formula, d, family, df) {
  fit <- suppressWarnings(glmmTMB(formula, data = d, family = family, dispformula = df))
  if (converged(fit)) return(fit)
  fit2 <- suppressWarnings(glmmTMB(formula, data = d, family = family, dispformula = df,
                                   control = glmmTMBControl(optimizer = optim, optArgs = list(method = "BFGS"))))
  if (converged(fit2)) { attr(fit2, "optimizer") <- "BFGS (nlminb stopped at a boundary)"; return(fit2) }
  fit
}
fit_e4 <- function(p) glmmTMB(dRMSSD ~ treatment * x, dispformula = ~ treatment, data = p)   # a_t + b_t x, SD s_t

converged <- function(fit) isTRUE(fit$fit$convergence == 0) && isTRUE(fit$sdr$pdHess)
family_label    <- function(fit) { fu <- attr(fit, "family_used"); if (is.null(fu)) family(fit)$family else fu }
optimizer_label <- function(fit) if (is.null(attr(fit, "optimizer"))) "nlminb" else attr(fit, "optimizer")
is_us           <- function(fit) identical(attr(fit, "structure"), "us")

# linear predictor per condition for a typical donkey, averaged over the three order positions
eta_conditions <- function(fit) {
  b <- fixef(fit)$cond; stopifnot(identical(names(b), FIXEF_NAMES))
  unname(b[1] + c(0, b[2], b[3]) + mean(c(0, b[4], b[5])))
}

# variance parameters per condition in the plan's parameterisation. Shared-intercept fits: predict type "disp"
# follows sigma.glmmTMB (gaussian → SD; Gamma → 1/sqrt(shape); nbinom2 → theta = phi). MVN fits: the donkey-level SDs.
dispersion_by_condition <- function(fit, outcome, d) {
  if (is_us(fit)) return(tibble(condition = COND_LEVELS,
                                parameter = if (outcome == "ET") "sigma_c (donkey-level SD, degC)" else "sigma_c (donkey-level SD of log y)",
                                value = as.numeric(attr(VarCorr(fit)$cond$donkey, "stddev"))))
  nd <- data.frame(condition = factor(COND_LEVELS, levels = COND_LEVELS), order = factor(1, levels = 1:3),
                   donkey = factor(levels(d$donkey)[1], levels = levels(d$donkey)))
  ds <- if (outcome == "SBR" && family(fit)$family == "poisson") rep(Inf, 3) else predict(fit, newdata = nd, type = "disp", re.form = NA)
  resp_log <- isTRUE(attr(fit, "response_log"))
  tibble(condition = COND_LEVELS,
         parameter = if (outcome == "SBR") "phi" else if (outcome == "ET") "sigma (residual SD, degC)" else if (resp_log) "sigma (residual SD of log y)" else "alpha (Gamma shape)",
         value = if (outcome == "RMSSD" && !resp_log) 1 / ds^2 else ds)
}

# ---- estimands E1–E3, shared-intercept fits (SBR; plan §1, §3) ----------------------------------
# emmeans summaries name the estimate column after the scale (emmean, response, ratio, rate, estimate, …)
tidy_emm <- function(obj, ...) {
  s <- as.data.frame(summary(obj, infer = c(TRUE, TRUE), ...))
  est_col <- intersect(c("ratio", "difference", "estimate", "response", "rate", "emmean", "x.trend"), names(s))[1]
  lo_col  <- intersect(c("lower.CL", "asymp.LCL"), names(s))[1]; hi_col <- intersect(c("upper.CL", "asymp.UCL"), names(s))[1]
  if (anyNA(c(est_col, lo_col, hi_col))) stop("tidy_emm: unrecognised summary columns: ", paste(names(s), collapse = ", "))
  tibble(term = if ("contrast" %in% names(s)) as.character(s$contrast) else as.character(s[[1]]),
         estimate = s[[est_col]], se = s$SE, ci_low = s[[lo_col]], ci_high = s[[hi_col]],
         p = if ("p.value" %in% names(s)) s$p.value else NA_real_)
}
CTR <- list("positive - control" = c(-1, 1, 0), "negative - control" = c(-1, 0, 1), "positive - negative" = c(0, 1, -1))

estimands_intercept <- function(fit, outcome, d) {
  b <- fixef(fit)$cond; V <- vcov(fit)$cond
  L <- rbind("positive - control" = as.numeric(names(b) == "conditionpositive"),
             "negative - control" = as.numeric(names(b) == "conditionnegative"),
             "positive - negative" = as.numeric(names(b) == "conditionpositive") - as.numeric(names(b) == "conditionnegative"),
             "order 2 - 1" = as.numeric(names(b) == "order2"),
             "order 3 - 1" = as.numeric(names(b) == "order3"))
  est <- as.numeric(L %*% b); se <- sqrt(diag(L %*% V %*% t(L)))
  link <- tibble(estimand = c("E1", "E1", "E2", "E3", "E3"), term = rownames(L), scale = "link",
                 estimate = est, se = se, ci_low = est - 1.96 * se, ci_high = est + 1.96 * se, p = 2 * pnorm(-abs(est / se)))
  emm <- emmeans(fit, ~ condition)                                       # link scale, averaged over order, u = 0
  resp <- if (outcome == "ET") {
    tidy_emm(contrast(emm, method = CTR)) |> mutate(scale = "difference (degC)")
  } else {
    bind_rows(tidy_emm(contrast(emm, method = CTR), type = "response") |> mutate(scale = "ratio"),
              tidy_emm(contrast(regrid(emm), method = CTR)) |> mutate(scale = if (outcome == "SBR") "difference (blinks/min)" else "difference (ms)"))
  }
  resp <- resp |> mutate(estimand = if_else(term == "positive - negative", "E2", "E1"))
  means <- tidy_emm(emm, type = "response") |> mutate(estimand = "mean", term = paste("mean", term), scale = "response, u = 0")
  tau <- as.numeric(attr(VarCorr(fit)$cond$donkey, "stddev"))
  disp <- dispersion_by_condition(fit, outcome, d)
  mu_control <- means$estimate[means$term == "mean control"]
  sigma2_latent <- switch(outcome,
    ET    = mean(disp$value^2),
    RMSSD = mean(trigamma(disp$value)),
    SBR   = (if (is.finite(disp$value[1])) trigamma(disp$value[1]) else 0) + 1 / mu_control)
  e3 <- tibble(estimand = "E3", term = c("tau (donkey SD, link scale)", "sigma_latent (residual SD, link scale)", "ICC (latent)"),
               scale = "link", estimate = c(tau, sqrt(sigma2_latent), tau^2 / (tau^2 + sigma2_latent)))
  bind_rows(link, resp, means, e3) |> mutate(outcome = outcome, family_used = family_label(fit), .before = 1)
}

# ---- estimands E1–E3, MVN fits (ET, RMSSD; plan §3 v1.1) -----------------------------------------
# Delta method on the full parameter vector (beta, theta) with the Hessian-based covariance fit$sdr$cov.fixed.
# Sigma is taken from the TMB report (fit$obj$report()$sd, $corr — what VarCorr.glmmTMB uses), so the theta
# parameterisation never has to be reconstructed; the report is checked against VarCorr at the estimate.
num_jacobian <- function(f, p, h = 1e-6) {
  f0 <- f(p); J <- matrix(NA_real_, length(f0), length(p))
  for (k in seq_along(p)) {
    hk <- h * max(1, abs(p[k])); pp <- p; pm <- p; pp[k] <- p[k] + hk; pm[k] <- p[k] - hk
    J[, k] <- (f(pp) - f(pm)) / (2 * hk)
  }
  J
}
estimands_mvn <- function(fit, outcome) {
  log_scale <- outcome == "RMSSD"
  pf <- fit$fit$parfull; rnd <- fit$obj$env$random
  fixed_idx <- setdiff(seq_along(pf), rnd); p0 <- fit$fit$par; V <- fit$sdr$cov.fixed
  stopifnot(length(fixed_idx) == length(p0), nrow(V) == length(p0), identical(names(fixef(fit)$cond), FIXEF_NAMES))
  vc <- VarCorr(fit)$cond$donkey
  stopifnot(identical(rownames(vc), paste0("condition", COND_LEVELS)))
  rep0 <- fit$obj$report(pf)
  stopifnot(isTRUE(all.equal(unname(rep0$sd[[1]]), unname(attr(vc, "stddev")), tolerance = 1e-6)),
            isTRUE(all.equal(unname(rep0$corr[[1]]), unname(attr(vc, "correlation")), tolerance = 1e-6)))
  q <- function(p) {
    full <- pf; full[fixed_idx] <- p
    beta <- unname(p[names(p) == "beta"]); rp <- fit$obj$report(full); s <- rp$sd[[1]]; R <- rp$corr[[1]]
    eta <- beta[1] + c(0, beta[2], beta[3]) + mean(c(0, beta[4], beta[5]))          # typical donkey, order-averaged
    out <- c(eta[2] - eta[1], eta[3] - eta[1], eta[2] - eta[3], beta[4], beta[5],  # link-scale contrasts, order effects
             eta, log(s), atanh(R[c(2, 3, 6)]))                                    # means at u = 0, log SDs, Fisher z of the correlations
    if (log_scale) {
      m <- exp(eta + s^2 / 2)                                                        # arithmetic means averaged over donkeys
      out <- c(out, log(m[2] / m[1]), log(m[3] / m[1]), log(m[2] / m[3]), m[2] - m[1], m[3] - m[1], m[2] - m[3], m)
    }
    out
  }
  ctr <- c("positive - control", "negative - control", "positive - negative")
  lab <- tibble(estimand  = c("E1", "E1", "E2", "E3", "E3", rep("mean", 3), rep("E3", 6)),
                term      = c(ctr, "order 2 - 1", "order 3 - 1", paste("mean", COND_LEVELS),
                              paste0("sigma ", COND_LEVELS, " (donkey-level SD, link scale)"),
                              "corr(control, positive)", "corr(control, negative)", "corr(positive, negative)"),
                scale     = c(rep("link", 5), rep(if (log_scale) "response, u = 0 (median donkey)" else "response", 3), rep("link", 6)),
                transform = c(rep("identity", 5), rep(if (log_scale) "exp" else "identity", 3), rep("exp", 3), rep("tanh", 3)))
  if (log_scale) lab <- bind_rows(lab, tibble(
    estimand  = c("E1", "E1", "E2", "E1", "E1", "E2", rep("mean", 3)),
    term      = c(ctr, ctr, paste("mean", COND_LEVELS)),
    scale     = c(rep("ratio (marginal, arithmetic means)", 3), rep("difference (ms, marginal)", 3), rep("response, marginal", 3)),
    transform = c(rep("exp", 3), rep("identity", 6))))
  qv <- q(p0); stopifnot(length(qv) == nrow(lab))
  J <- num_jacobian(q, p0); se_raw <- sqrt(pmax(diag(J %*% V %*% t(J)), 0))
  tb <- lab |> mutate(est_raw = qv, se_raw = se_raw)
  # response-scale duplicates of the link rows: ET differences in degC (identity), RMSSD median-donkey ratios
  dup <- tb |> filter(scale == "link", estimand %in% c("E1", "E2")) |>
    mutate(scale = if (log_scale) "ratio (conditional, median donkey)" else "difference (degC)", transform = if (log_scale) "exp" else "identity")
  tb <- bind_rows(tb, dup) |>
    mutate(lo_raw = est_raw - 1.96 * se_raw, hi_raw = est_raw + 1.96 * se_raw,
           estimate = case_when(transform == "exp" ~ exp(est_raw), transform == "tanh" ~ tanh(est_raw), TRUE ~ est_raw),
           ci_low   = case_when(transform == "exp" ~ exp(lo_raw),  transform == "tanh" ~ tanh(lo_raw),  TRUE ~ lo_raw),
           ci_high  = case_when(transform == "exp" ~ exp(hi_raw),  transform == "tanh" ~ tanh(hi_raw),  TRUE ~ hi_raw),
           se       = case_when(transform == "exp" ~ estimate * se_raw, transform == "tanh" ~ (1 - estimate^2) * se_raw, TRUE ~ se_raw),
           p        = if_else(estimand %in% c("E1", "E2") | grepl("^order", term), 2 * pnorm(-abs(est_raw / se_raw)), NA_real_)) |>
    select(estimand, term, scale, estimate, se, ci_low, ci_high, p) |>
    mutate(outcome = outcome, family_used = family_label(fit), .before = 1)
  tb
}
estimands_condition <- function(fit, outcome, d) if (is_us(fit)) estimands_mvn(fit, outcome) else estimands_intercept(fit, outcome, d)

# ---- diagnostics (plan §4) -------------------------------------------------------------------
# Scaled residuals by group: KS test of uniformity per level (minimum p) and a Brown–Forsythe
# (median-centred Levene) test of equal spread across levels — what DHARMa::testCategorical does,
# hand-coded because in DHARMa 0.4.7 that function draws on the current device even with plot = FALSE.
group_tests <- function(r, g) {
  g <- droplevels(as.factor(g))
  ks <- vapply(levels(g), function(l) suppressWarnings(ks.test(r[g == l], "punif"))$p.value, numeric(1))
  z <- abs(r - ave(r, g, FUN = median))
  list(ks_p_min = min(ks), levene_p = anova(lm(z ~ g))[["Pr(>F)"]][1])
}
diagnostics_condition <- function(fit, d, outcome, plot_file = NULL, seed = SEED_DHARMA) {
  res <- simulateResiduals(fit, n = N_SIM_DHARMA, seed = seed)              # marginal: new donkey effects in every simulation
  tu <- testUniformity(res, plot = FALSE); td <- testDispersion(res, plot = FALSE); to <- testOutliers(res, plot = FALSE)
  tc <- group_tests(res$scaledResiduals, d$condition); tord <- group_tests(res$scaledResiduals, d$order)
  re <- as.matrix(ranef(fit)$cond$donkey)                                   # one column (intercept) or three (one per condition)
  if (!is.null(plot_file)) {
    png(plot_file, width = 1600, height = 1200, res = 150)
    par(mfrow = c(2, 2), mar = c(4, 4, 3, 1))
    plotQQunif(res, main = paste(outcome, "— QQ of scaled residuals"))
    plotResiduals(res, main = "vs fitted (rank)")
    plotResiduals(res, form = d$condition, main = "by condition")
    plotResiduals(res, form = d$order, main = "by order")
    dev.off()
  }
  tibble(outcome = outcome, family_used = family_label(fit), structure = attr(fit, "structure"), converged = converged(fit),
         optimizer = optimizer_label(fit), n_obs = nobs(fit), n_par = attr(logLik(fit), "df"),
         # Pearson chi²/df is defined for the shared-intercept fits only; with the residual fixed at ~0 and a saturated covariance it is meaningless
         pearson_ratio = if (is_us(fit)) NA_real_ else sum(residuals(fit, type = "pearson")^2) / df.residual(fit),
         dharma_uniformity_p = tu$p.value, dharma_dispersion_ratio = unname(td$statistic), dharma_dispersion_p = td$p.value,
         dharma_outliers_p = to$p.value,
         uniformity_by_condition_p_min = tc$ks_p_min, homogeneity_by_condition_p = tc$levene_p,
         uniformity_by_order_p_min = tord$ks_p_min, homogeneity_by_order_p = tord$levene_p,
         ranef_shapiro_p_min = min(apply(re, 2, function(v) shapiro.test(v)$p.value)),
         ranef_sd_empirical = if (is_us(fit)) NA_real_ else sd(re[, 1]))
}

# ---- model comparison by AICc, with the E1 estimates of each model (plan §4) ---------------------
# For log-normal fits (gaussian on log y) the Jacobian 2 Σ log y puts −2 log L on the scale of y.
aicc <- function(fit, jacobian = 0) {
  ll <- logLik(fit); k <- attr(ll, "df"); n <- nobs(fit)
  -2 * as.numeric(ll) + jacobian + 2 * k + 2 * k * (k + 1) / (n - k - 1)
}
# total variance of log y per condition: donkey part (one or three variances) plus residual part (none for MVN fits)
logscale_var_by_condition <- function(fit) {
  dv <- as.numeric(attr(VarCorr(fit)$cond$donkey, "stddev"))^2; if (length(dv) == 1) dv <- rep(dv, 3)
  if (is_us(fit)) return(dv)
  nd <- data.frame(condition = factor(COND_LEVELS, levels = COND_LEVELS), order = factor(1, levels = 1:3),
                   donkey = factor(fit$frame$donkey[1], levels = levels(fit$frame$donkey)))
  dv + predict(fit, newdata = nd, type = "disp", re.form = NA)^2
}
# E1 on the response scale, averaged over donkeys: ET differences in degC; SBR and Gamma ratios exp(d_beta)
# (a shared intercept cancels); log-normal fits exp(d_beta + (v_c − v_control) / 2) with v the total log-scale variance;
# a Gaussian on raw RMSSD: ratios of the order-averaged condition means
e1_marginal <- function(fit, outcome) {
  b <- fixef(fit)$cond; dlt <- unname(c(b["conditionpositive"], b["conditionnegative"]))
  if (outcome == "ET") return(dlt)
  if (family(fit)$family == "gaussian" && !isTRUE(attr(fit, "response_log"))) { m <- eta_conditions(fit); return(m[2:3] / m[1]) }
  if (isTRUE(attr(fit, "response_log"))) { v <- logscale_var_by_condition(fit); dlt <- dlt + (v[2:3] - v[1]) / 2 }
  exp(dlt)
}
# the comparison set of §4; the first element is the planned model (SBR: the NB2 attempt, see planned_from_comparison)
comparison_fits <- function(d, outcome) {
  switch(outcome,
    SBR   = list("NB2, donkey intercept, one phi (planned)" = tag(suppressWarnings(glmmTMB(y ~ condition + order + (1 | donkey), data = d, family = nbinom2())), "nbinom2", "intercept", FALSE),
                 "Poisson, donkey intercept"                  = fit_condition(d, "SBR", family_alt = "poisson")),
    ET    = list("Gaussian MVN, unstructured donkey covariance (planned)" = fit_condition(d, "ET"),
                 "Gaussian, donkey intercept, sigma by condition (v1.0)"   = fit_condition(d, "ET", "intercept"),
                 "Gaussian, donkey intercept, pooled sigma"                = fit_condition(d, "ET", "intercept", "pooled")),
    RMSSD = list("log-normal MVN, unstructured donkey covariance (planned)"          = fit_condition(d, "RMSSD"),
                 "Gamma(log), donkey intercept, alpha by condition (v1.0; sens. ii)" = fit_condition(d, "RMSSD", "intercept"),
                 "Gamma(log), donkey intercept, pooled alpha"                        = fit_condition(d, "RMSSD", "intercept", "pooled"),
                 "log-normal, donkey intercept, sigma by condition"                  = fit_condition(d, "RMSSD", "intercept", family_alt = "lognormal"),
                 "log-normal, donkey intercept, pooled sigma"                        = fit_condition(d, "RMSSD", "intercept", "pooled", family_alt = "lognormal"),
                 # raw-scale check: the reconstruction draws control RMSSD as normal on y, so the log-normal back-transformation
                 # exp(eta + sigma²/2) overshoots the control mean; this row shows what the log scale costs on such data
                 "Gaussian MVN on y, unstructured donkey covariance (raw-scale check)" = fit_condition(d, "RMSSD", family_alt = "gaussian_raw")))
}
# the planned fit taken from the comparison set (no refit): SBR falls back to Poisson when phi is not identified, as in fit_condition
planned_from_comparison <- function(fits, outcome) {
  if (outcome != "SBR") return(fits[[1]])
  nb2 <- fits[[1]]
  if (converged(nb2) && sigma(nb2) <= 1e3) nb2 else tag(fits[[2]], "poisson (NB2 phi not identified)", "intercept", FALSE)
}
compare_table <- function(fits, d, outcome) {
  jac <- 2 * sum(log(d$y))
  tb <- imap_dfr(fits, function(f, nm) {
    e1 <- e1_marginal(f, outcome)
    tibble(outcome = outcome, model = nm, converged = converged(f), optimizer = optimizer_label(f),
           n_par = attr(logLik(f), "df"), aicc = aicc(f, if (isTRUE(attr(f, "response_log"))) jac else 0),
           e1_positive = e1[1], e1_negative = e1[2])
  })
  tb |> mutate(delta_aicc = aicc - min(aicc, na.rm = TRUE), .after = aicc)     # a non-converged fit has no AICc (SBR NB2)
}
compare_models <- function(d, outcome) compare_table(comparison_fits(d, outcome), d, outcome)

# ---- within-donkey covariance of the condition values: example data vs model -----------------------
# The reconstructed data pin this matrix (Table 2 SDs and the SD of the signed changes). A shared intercept
# implies equal covariances for all pairs, each below both variances; the MVN fit reproduces the sample matrix.
random_structure <- function(fit, d, outcome) {
  # RMSSD on both scales: the structural argument (Cov > Var) is made on the raw scale, the planned model is on log y;
  # the model-implied matrix is given on the scale the model is fitted on
  scales <- if (outcome == "RMSSD") c("y", "log y") else "y"
  model_scale <- if (isTRUE(attr(fit, "response_log"))) "log y" else "y"
  Sm <- if (is_us(fit)) { vc <- VarCorr(fit)$cond$donkey; matrix(as.numeric(vc), 3, 3) } else NULL
  Rm <- if (is_us(fit)) cov2cor(Sm) else NULL
  map_dfr(scales, function(sc) {
    W <- d |> mutate(v = if (sc == "log y") log(y) else y) |> select(donkey, condition, v) |>
      pivot_wider(names_from = condition, values_from = v) |> select(all_of(COND_LEVELS)) |> as.matrix()
    S <- cov(W); Rs <- cov2cor(S); on_model_scale <- is_us(fit) && sc == model_scale
    map_dfr(list(c(1, 2), c(1, 3), c(2, 3)), function(ij) tibble(
      outcome = outcome, scale = sc, pair = paste(COND_LEVELS[ij], collapse = " - "),
      var_a = S[ij[1], ij[1]], var_b = S[ij[2], ij[2]], cov_obs = S[ij[1], ij[2]], corr_obs = Rs[ij[1], ij[2]],
      cov_exceeds_min_var = S[ij[1], ij[2]] > min(S[ij[1], ij[1]], S[ij[2], ij[2]]),
      cov_model = if (on_model_scale) Sm[ij[1], ij[2]] else NA_real_, corr_model = if (on_model_scale) Rm[ij[1], ij[2]] else NA_real_,
      model = family_label(fit)))
  })
}

# ---- moment check: the example's condition means/SDs vs the model, marginal over donkeys --------------
moments_check <- function(fit, d, outcome) {
  obs <- d |> group_by(condition) |> summarise(mean_obs = mean(y), sd_obs = sd(y), .groups = "drop") |>
    mutate(condition = as.character(condition))
  eta <- eta_conditions(fit); oc <- outcome
  if (is_us(fit)) {
    s <- as.numeric(attr(VarCorr(fit)$cond$donkey, "stddev"))
    if (oc == "ET") { m0 <- eta; mm <- eta; sdm <- s }
    else            { m0 <- exp(eta); mm <- exp(eta + s^2 / 2); sdm <- mm * sqrt(exp(s^2) - 1) }   # log-normal moments
  } else {
    stopifnot(!isTRUE(attr(fit, "response_log")))                     # shared-intercept log-normal is not a planned fit
    tau <- as.numeric(attr(VarCorr(fit)$cond$donkey, "stddev")); disp <- dispersion_by_condition(fit, oc, d)$value
    if (oc == "ET") { m0 <- eta; mm <- eta; sdm <- sqrt(tau^2 + disp^2) }
    else {            # log link, log-normal donkey effect: E[mu_i] = mu0 e^{tau²/2}, E[mu_i²] = mu0² e^{2 tau²}; Poisson part for counts
      m0 <- exp(eta); mm <- m0 * exp(tau^2 / 2)
      sdm <- sqrt((if (oc == "SBR") mm else 0) + (1 + 1 / disp) * m0^2 * exp(2 * tau^2) - mm^2)
    }
  }
  tibble(outcome = oc, condition = COND_LEVELS, mean_model_u0 = m0, mean_model_marginal = mm, sd_model_marginal = sdm) |>
    left_join(obs, by = "condition") |>
    left_join(cond_t2 |> select(outcome, condition, mean_table2 = mean, sd_table2 = sd), by = c("outcome", "condition")) |>
    select(outcome, condition, mean_table2, mean_obs, mean_model_u0, mean_model_marginal, sd_table2, sd_obs, sd_model_marginal)
}

# ---- E4: ΔRMSSD on ΔSBR and on ΔET, treatment-specific intercept, slope and SD (plan §3) ---------
estimands_e4 <- function(p, x_name) {
  fit <- fit_e4(p)
  tr <- emtrends(fit, ~ treatment, var = "x")
  slopes <- tidy_emm(tr) |> mutate(quantity = "b (slope)")
  diff   <- tidy_emm(contrast(tr, method = list("positive - negative" = c(-1, 1)))) |> mutate(quantity = "b positive - b negative")
  icpt   <- tidy_emm(emmeans(fit, ~ treatment, at = list(x = 0))) |> mutate(quantity = "a (intercept at x = 0)")
  nd <- data.frame(treatment = factor(c("negative", "positive"), levels = c("negative", "positive")), x = 0)
  s_t <- predict(fit, newdata = nd, type = "disp")
  sds <- p |> group_by(treatment) |> summarise(sd_x = sd(x), sd_y = sd(dRMSSD), n = n(), .groups = "drop")
  ols <- p |> group_by(treatment) |> summarise(b_ols = coef(lm(dRMSSD ~ x))[2], .groups = "drop")   # per-group OLS = ML slopes here
  derived <- tibble(term = c("negative", "positive"), quantity = "s (residual SD)", estimate = s_t) |>
    bind_rows(slopes |> select(term, estimate) |> left_join(sds, by = c("term" = "treatment")) |>
                transmute(term, quantity = "r (within-treatment correlation)", estimate = estimate * sd_x / sd_y))
  bind_rows(icpt, slopes, diff, derived) |>
    left_join(ols, by = c("term" = "treatment")) |> mutate(b_ols = if_else(quantity == "b (slope)", b_ols, NA_real_)) |>
    mutate(x_name = x_name, converged = converged(fit), .before = 1) |>
    select(x_name, quantity, treatment = term, estimate, se, ci_low, ci_high, p, b_ols, converged)
}
plot_e4 <- function(p3, p4, e4tab, file) {
  dat <- bind_rows(p3 |> mutate(x_name = "dSBR"), p4 |> mutate(x_name = "dET"))
  lines <- e4tab |> filter(quantity %in% c("a (intercept at x = 0)", "b (slope)")) |>
    mutate(quantity = if_else(quantity == "b (slope)", "b", "a")) |>
    select(x_name, treatment, quantity, estimate) |> pivot_wider(names_from = quantity, values_from = estimate)
  g <- ggplot(dat, aes(x, dRMSSD, colour = treatment)) + geom_point(alpha = 0.7) +
    geom_abline(data = lines, aes(intercept = a, slope = b, colour = treatment)) +
    geom_hline(yintercept = 0, linetype = 3) + geom_vline(xintercept = 0, linetype = 3) +
    facet_wrap(~ x_name, scales = "free_x", labeller = as_labeller(c(dSBR = "ΔSBR (blinks/min)", dET = "ΔET (°C)"))) +
    labs(x = "signed change, treatment − control", y = "ΔRMSSD (ms), treatment − control",
         title = "E4 on the example replicate: treatment-specific lines, signed changes") + theme_minimal()
  ggsave(file, g, width = 9, height = 4.5, dpi = 150)
}

# ======================================================================================================
# Section A — the example replicate
# ======================================================================================================
if (RUN_EXAMPLE) {
ex <- ens |> filter(rho_dd == EXAMPLE$rho_dd, rep == EXAMPLE$rep)
stopifnot(nrow(ex) == 3 * 102)
est <- list(); diag <- list(); cmp <- list(); mom <- list(); disp <- list(); rs <- list()
for (o in OUTCOMES) {
  d <- prep_condition(ex |> filter(outcome == o))
  fit <- fit_condition(d, o)                                              # planned model (plan §3 v1.1)
  est[[o]]  <- estimands_condition(fit, o, d)
  diag[[o]] <- diagnostics_condition(fit, d, o, plot_file = file.path(out_fig, sprintf("stage3_example_dharma_%s.png", tolower(o))))
  cmp[[o]]  <- compare_models(d, o)
  mom[[o]]  <- moments_check(fit, d, o)
  rs[[o]]   <- random_structure(fit, d, o)
  disp[[o]] <- dispersion_by_condition(fit, o, d) |> mutate(outcome = o, model = if (o == "SBR") "intercept, one phi (planned)" else "MVN, unstructured donkey covariance (planned)")
  if (o != "SBR") disp[[o]] <- bind_rows(disp[[o]],                     # the v1.0 structure, by condition and pooled (M15)
    dispersion_by_condition(fit_condition(d, o, "intercept"), o, d) |> mutate(outcome = o, model = "intercept, dispersion by condition (v1.0)"),
    dispersion_by_condition(fit_condition(d, o, "intercept", "pooled"), o, d) |> mutate(outcome = o, model = "intercept, pooled dispersion"))
}
est <- bind_rows(est); diag <- bind_rows(diag); cmp <- bind_rows(cmp); mom <- bind_rows(mom); disp <- bind_rows(disp); rs <- bind_rows(rs)

p3 <- prep_e4(e4pairs |> filter(rho_dd == EXAMPLE$rho_dd, rep == EXAMPLE$rep, x_name == "dSBR"))
p4 <- prep_e4(e4pairs |> filter(rho_dd == EXAMPLE$rho_dd, rep == EXAMPLE$rep, x_name == "dET"))
stopifnot(nrow(p3) == 68, nrow(p4) == 68)
e4 <- bind_rows(estimands_e4(p3, "dSBR"), estimands_e4(p4, "dET"))
plot_e4(p3, p4, e4, file.path(out_fig, "stage3_example_e4.png"))

write_csv(est,  file.path(out_tab, "stage3_example_estimands.csv"))
write_csv(disp, file.path(out_tab, "stage3_example_dispersion.csv"))
write_csv(diag, file.path(out_tab, "stage3_example_diagnostics.csv"))
write_csv(cmp,  file.path(out_tab, "stage3_example_model_comparison.csv"))
write_csv(rs,   file.path(out_tab, "stage3_example_random_structure.csv"))
write_csv(mom,  file.path(out_tab, "stage3_example_moments.csv"))
write_csv(e4,   file.path(out_tab, "stage3_example_e4.csv"))

# ---- report ----------------------------------------------------------------------------------
options(width = 170, pillar.sigfig = 4)
cat("\n== example replicate: scenario rho_dd =", EXAMPLE$rho_dd, ", rep", EXAMPLE$rep, "==\n")
cat("\n-- convergence and dispersion --\n")
print(diag |> select(outcome, family_used, converged, optimizer, n_par, pearson_ratio, dharma_dispersion_ratio, dharma_dispersion_p, dharma_uniformity_p,
                     dharma_outliers_p, homogeneity_by_condition_p, uniformity_by_condition_p_min, ranef_shapiro_p_min))
cat("\n-- variance parameters by condition: planned vs v1.0 structure vs pooled (M15) --\n")
print(disp |> pivot_wider(names_from = condition, values_from = value))
cat("\n-- within-donkey covariance of the condition values (log y for RMSSD): example data vs MVN fit --\n")
print(rs |> select(-model))
cat("\n-- E1, E2 on the response scale (averaged over order) --\n")
print(est |> filter(estimand %in% c("E1", "E2"), scale != "link") |> select(outcome, estimand, term, scale, estimate, ci_low, ci_high, p))
cat("\n-- link-scale coefficients, order effects, E3 (tau/ICC for SBR; sigma_c and correlations for ET, RMSSD) --\n")
print(est |> filter(scale == "link") |> select(outcome, estimand, term, estimate, se, ci_low, ci_high))
cat("\n-- condition moments: Table 2, example data, model (marginal over donkeys) --\n")
print(mom)
cat("\n-- model comparison (AICc; log-normal with Jacobian) with each model's E1 (ratio, or degC difference for ET) --\n")
print(cmp)
cat("\n-- E4: ΔRMSSD on signed ΔSBR / ΔET, by treatment --\n")
print(e4 |> select(-converged))
cat("\n-- stage 2 unsigned slopes for the sign check (gof_by_group.csv): --\n")
print(gof_grp |> select(x, treatment, slope, se, r, resid_sd))
cat("\nExpected signs on signed data: dSBR negative treatment flips (x < 0, y > 0), the other three keep their sign.\n")
cat("\nwritten: output/tables/stage3_example_{estimands,dispersion,diagnostics,model_comparison,random_structure,moments,e4}.csv;",
    "output/figures/stage3_example_dharma_{sbr,et,rmssd}.png, stage3_example_e4.png\n")
}   # end of section A

# ======================================================================================================
# Section B — the ensemble: E1–E3 on every replicate, pooled by Rubin's rules per scenario (plan §2, §4, S3)
# ======================================================================================================
# The replicates are draws of the unknowns of the reconstruction (sign patterns, pairings) consistent with
# everything the paper reports, so they are treated like multiple imputations: within-replicate variance W
# (mean squared SE), between-replicate variance B, total T = W + (1 + 1/K) B. Pooling is done on the scale on
# which the Wald interval is formed (link / log for ratios and positive parameters, Fisher z for correlations)
# and back-transformed. Rows without an SE (SBR tau, sigma_latent, ICC) get the mean and the between-replicate
# spread only.

# the scale each row is pooled on, recovered from the estimands tables (se on the reported scale is the delta-method
# se, so est_raw and se_raw are exact inverses of what estimands_mvn / emmeans produced)
add_transform <- function(est) est |> mutate(
  transform = case_when(grepl("^corr\\(", term) ~ "tanh",
                        grepl("ratio", scale) | grepl("^sigma .*donkey-level SD", term) |
                          (grepl("^response", scale) & outcome != "ET") ~ "exp",
                        TRUE ~ "identity"),
  est_raw = case_when(transform == "exp" ~ log(estimate), transform == "tanh" ~ atanh(estimate), TRUE ~ estimate),
  se_raw  = case_when(transform == "exp" ~ se / estimate,  transform == "tanh" ~ se / (1 - estimate^2), TRUE ~ se))

back <- function(x, transform) case_when(transform == "exp" ~ exp(x), transform == "tanh" ~ tanh(x), TRUE ~ x)

pool_rubin <- function(per_rep) per_rep |>
  group_by(rho_dd, outcome, estimand, term, scale, transform) |>
  summarise(K = n(), qbar = mean(est_raw), W = mean(se_raw^2), B = var(est_raw),
            between_sd_estimate = sd(estimate), q025_estimate = quantile(estimate, 0.025), q975_estimate = quantile(estimate, 0.975),
            .groups = "drop") |>
  mutate(T = W + (1 + 1 / K) * B, se_total = sqrt(T), fmi = (1 + 1 / K) * B / T, between_within_ratio = B / W,
         estimate = back(qbar, transform), ci_low = back(qbar - 1.96 * se_total, transform), ci_high = back(qbar + 1.96 * se_total, transform),
         p = if_else(estimand %in% c("E1", "E2") | grepl("^order", term), 2 * pnorm(-abs(qbar / se_total)), NA_real_)) |>
  select(rho_dd, outcome, estimand, term, scale, K, estimate, ci_low, ci_high, p, se_total, within_var = W, between_var = B,
         between_within_ratio, fmi, between_sd_estimate, q025_estimate, q975_estimate, transform)

# one replicate: the three planned fits taken from the comparison sets, with estimands, diagnostics, AICc table and covariance table
fit_replicate <- function(rho, k) {
  dd <- ens |> filter(rho_dd == rho, rep == k)
  parts <- lapply(OUTCOMES, function(o) {
    d <- prep_condition(dd |> filter(outcome == o))
    tryCatch({
      fits <- comparison_fits(d, o); fit <- planned_from_comparison(fits, o)
      list(est  = estimands_condition(fit, o, d) |> add_transform(),
           diag = diagnostics_condition(fit, d, o, seed = SEED_DHARMA + k),
           cmp  = compare_table(fits, d, o),
           rs   = random_structure(fit, d, o))
    }, error = function(e) list(err = tibble(outcome = o, error = conditionMessage(e))))
  })
  key <- function(x) if (is.null(x)) NULL else mutate(x, rho_dd = rho, rep = k, .before = 1)
  list(est = key(bind_rows(map(parts, "est"))), diag = key(bind_rows(map(parts, "diag"))),
       cmp = key(bind_rows(map(parts, "cmp"))), rs = key(bind_rows(map(parts, "rs"))), err = key(bind_rows(map(parts, "err"))))
}

share <- function(x) mean(x, na.rm = TRUE)
summarise_diagnostics <- function(diag) diag |> group_by(rho_dd, outcome) |> summarise(
  K = n(), share_converged = share(converged), share_bfgs = share(grepl("BFGS", optimizer)),
  share_poisson_fallback = share(grepl("poisson", family_used)),
  median_dharma_dispersion_ratio = median(dharma_dispersion_ratio), share_dispersion_ratio_outside_0.8_1.2 = share(dharma_dispersion_ratio < 0.8 | dharma_dispersion_ratio > 1.2),
  share_dharma_dispersion_p_lt_0.05 = share(dharma_dispersion_p < 0.05), share_uniformity_p_lt_0.05 = share(dharma_uniformity_p < 0.05),
  share_outliers_p_lt_0.05 = share(dharma_outliers_p < 0.05), share_homogeneity_by_condition_p_lt_0.05 = share(homogeneity_by_condition_p < 0.05),
  share_uniformity_by_condition_p_min_lt_0.05 = share(uniformity_by_condition_p_min < 0.05), share_homogeneity_by_order_p_lt_0.05 = share(homogeneity_by_order_p < 0.05),
  share_ranef_shapiro_p_min_lt_0.05 = share(ranef_shapiro_p_min < 0.05), median_pearson_ratio = median(pearson_ratio), .groups = "drop")
summarise_comparison <- function(cmp) cmp |> group_by(rho_dd, outcome, model) |> summarise(
  K = n(), share_converged = share(converged), share_best_aicc = share(delta_aicc == 0), mean_delta_aicc = mean(delta_aicc, na.rm = TRUE),
  median_delta_aicc = median(delta_aicc, na.rm = TRUE), median_e1_positive = median(e1_positive), median_e1_negative = median(e1_negative),
  q025_e1_positive = quantile(e1_positive, 0.025), q975_e1_positive = quantile(e1_positive, 0.975), .groups = "drop")
summarise_random_structure <- function(rs) rs |> group_by(rho_dd, outcome, scale, pair) |> summarise(
  K = n(), share_cov_exceeds_min_var = share(cov_exceeds_min_var), mean_corr_obs = mean(corr_obs), min_corr_obs = min(corr_obs), max_corr_obs = max(corr_obs),
  mean_corr_model = mean(corr_model), .groups = "drop")

# pooled E1 differences at rho_dd = 0 against the exact paired results of stage 2 (contrasts_exact.csv: d = control − treatment)
check_vs_exact <- function(pooled) {
  ex <- exact |> transmute(outcome, term = paste(treatment, "- control"), exact_diff = -mean_d, exact_ci_low = -ci_high_d, exact_ci_high = -ci_low_d,
                           exact_se = sd_d_signed / sqrt(n))
  pooled |> filter(rho_dd == 0, estimand == "E1", scale %in% c("difference (blinks/min)", "difference (degC)", "difference (ms, marginal)")) |>
    select(outcome, term, scale, estimate, ci_low, ci_high, se_total, between_within_ratio) |>
    left_join(ex, by = c("outcome", "term")) |>
    mutate(diff_minus_exact = estimate - exact_diff, se_ratio = se_total / exact_se)
}

if (RUN_ENSEMBLE) {
  grid <- ens |> distinct(rho_dd, rep) |> filter(rep <= N_REPS) |> arrange(rho_dd, rep)
  if (is.finite(N_REPS)) cat("\n** smoke test: --reps", N_REPS, "— the outputs written now are partial and must not be committed **\n")
  cat(sprintf("\n== ensemble: %d replicates (%d scenarios), %d cores ==\n", nrow(grid), n_distinct(grid$rho_dd), N_CORES))
  t0 <- Sys.time()
  res <- parallel::mclapply(seq_len(nrow(grid)), function(i) fit_replicate(grid$rho_dd[i], grid$rep[i]),
                            mc.cores = N_CORES, mc.preschedule = FALSE)
  failed <- vapply(res, inherits, logical(1), "try-error")
  if (any(failed)) stop("mclapply: ", sum(failed), " replicate(s) returned an error object: ", res[[which(failed)[1]]])
  per_est <- bind_rows(map(res, "est")); per_diag <- bind_rows(map(res, "diag")); per_cmp <- bind_rows(map(res, "cmp"))
  per_rs  <- bind_rows(map(res, "rs"));  errs <- bind_rows(map(res, "err"))
  cat(sprintf("fitted in %.1f min; %d replicate-outcome fits, %d errors\n", as.numeric(difftime(Sys.time(), t0, units = "mins")), nrow(per_diag), nrow(errs)))
  if (nrow(errs) > 0) { write_csv(errs, file.path(out_tab, "stage3_ensemble_errors.csv")); print(errs) }

  pooled   <- pool_rubin(per_est)
  diag_sum <- summarise_diagnostics(per_diag)
  cmp_sum  <- summarise_comparison(per_cmp)
  rs_sum   <- summarise_random_structure(per_rs)
  chk      <- check_vs_exact(pooled)

  write_csv(pooled,   file.path(out_tab, "stage3_ensemble_estimands.csv"))
  write_csv(chk,      file.path(out_tab, "stage3_ensemble_check_vs_exact.csv"))
  write_csv(diag_sum, file.path(out_tab, "stage3_ensemble_diagnostics.csv"))
  write_csv(cmp_sum,  file.path(out_tab, "stage3_ensemble_model_comparison.csv"))
  write_csv(rs_sum,   file.path(out_tab, "stage3_ensemble_random_structure.csv"))
  write_csv(per_est,  file.path(out_tab, "stage3_ensemble_per_replicate_estimands.csv.gz"))
  write_csv(per_diag, file.path(out_tab, "stage3_ensemble_per_replicate_diagnostics.csv.gz"))
  write_csv(per_cmp,  file.path(out_tab, "stage3_ensemble_per_replicate_model_comparison.csv.gz"))
  write_csv(per_rs,   file.path(out_tab, "stage3_ensemble_per_replicate_random_structure.csv.gz"))

  options(width = 170, pillar.sigfig = 4)
  cat("\n-- convergence and diagnostics: shares of replicates --\n")
  print(diag_sum |> select(rho_dd, outcome, K, share_converged, share_bfgs, share_poisson_fallback, median_dharma_dispersion_ratio,
                           share_dispersion_ratio_outside_0.8_1.2, share_dharma_dispersion_p_lt_0.05, share_uniformity_p_lt_0.05,
                           share_homogeneity_by_condition_p_lt_0.05, share_ranef_shapiro_p_min_lt_0.05))
  cat("\n-- S3 check: pooled E1 differences (rho_dd = 0) vs the exact paired results of stage 2 --\n")
  print(chk)
  cat("\n-- E1, E2 pooled over K = 200, response scale, by scenario --\n")
  print(pooled |> filter(estimand %in% c("E1", "E2"), scale != "link", !grepl("^difference", scale) | outcome == "ET") |>
          select(rho_dd, outcome, estimand, term, scale, estimate, ci_low, ci_high, between_within_ratio, fmi) |> arrange(outcome, term, scale, rho_dd), n = 60)
  cat("\n-- E3 pooled, rho_dd = 0 (tau/ICC for SBR; sigma_c and correlations for ET, RMSSD) --\n")
  print(pooled |> filter(rho_dd == 0, estimand == "E3") |> select(outcome, term, estimate, ci_low, ci_high, between_sd_estimate, q025_estimate, q975_estimate), n = 40)
  cat("\n-- within-donkey covariance: share of replicates with Cov(c, c') > min Var, mean correlation --\n")
  print(rs_sum |> select(rho_dd, outcome, pair, share_cov_exceeds_min_var, mean_corr_obs, min_corr_obs, max_corr_obs, mean_corr_model), n = 40)
  cat("\n-- model comparison: share of replicates preferring each model by AICc, median E1 --\n")
  print(cmp_sum |> select(rho_dd, outcome, model, share_converged, share_best_aicc, median_delta_aicc, median_e1_positive, median_e1_negative) |>
          arrange(outcome, rho_dd, median_delta_aicc), n = 60)
  cat("\nwritten: output/tables/stage3_ensemble_{estimands,check_vs_exact,diagnostics,model_comparison,random_structure}.csv;",
      "stage3_ensemble_per_replicate_{estimands,diagnostics,model_comparison,random_structure}.csv.gz\n")
}
