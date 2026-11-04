# lib_simulate_conditions.R — Bukhari 2026: generator of per-donkey condition data consistent with
# everything the paper and the digitised figures pin down. Sourced by 06_condition_contrasts.R and
# by the stage 3–4 scripts if the authors' data never arrive.
#
# Known per outcome: condition means and SDs (Table 2); the 34 unsigned changes |control − treatment|
# per treatment (Figures 3–4, data/derived/deltas_*.csv). Unknown: the sign of each change, the
# pairing of control values with changes, the pairing of the two changes of the same donkey.
#
# Facts that do not depend on the unknown signs (used by 06 before any simulation):
#   mean of the signed changes d = control − treatment  = mu_control − mu_treatment      (Table 2)
#   sum of d²                                            = sum of |d|²                    (figures)
#   hence SD(d), the paired t and the control–treatment correlation are exactly determined.
#   The signs enter only through the "reversed sum": the |d| of donkeys that moved against the
#   group direction must add up to R = (sum|d| − n·|mu_d|)/2. Which donkeys is a subset-sum problem.

# ---- subset-sum dynamic programme on an integer grid ----------------------------------------
# Tm[[i + 1]][k + 1, s + 1] = number of subsets of v[1:i] with k elements and sum s (v integer ≥ 1).
subset_dp <- function(v) {
  stopifnot(all(v >= 1), all(v == round(v)))
  n <- length(v); S <- sum(v)
  M <- matrix(0, n + 1, S + 1); M[1, 1] <- 1
  Tm <- vector("list", n + 1); Tm[[1]] <- M
  for (i in seq_len(n)) {
    vi <- v[i]; M2 <- M
    M2[2:(n + 1), (vi + 1):(S + 1)] <- M2[2:(n + 1), (vi + 1):(S + 1)] + M[1:n, 1:(S + 1 - vi)]
    M <- M2; Tm[[i + 1]] <- M
  }
  Tm
}

# Number of admissible subsets by size, for sums in [lo, hi] (grid units).
subset_counts_by_size <- function(Tm, lo, hi) {
  M <- Tm[[length(Tm)]]; S <- ncol(M) - 1
  lo <- max(ceiling(lo), 0); hi <- min(floor(hi), S)
  if (hi < lo) return(setNames(rep(0, nrow(M)), 0:(nrow(M) - 1)))
  setNames(rowSums(M[, (lo + 1):(hi + 1), drop = FALSE]), 0:(nrow(M) - 1))
}

# One subset drawn uniformly among all subsets with sum in [lo, hi]. Returns a logical vector.
sample_subset <- function(Tm, v, lo, hi) {
  n <- length(v); M <- Tm[[n + 1]]; S <- ncol(M) - 1
  lo <- max(ceiling(lo), 0); hi <- min(floor(hi), S)
  if (hi < lo) return(NULL)
  cols <- (lo + 1):(hi + 1); W <- M[, cols, drop = FALSE]
  if (sum(W) == 0) return(NULL)
  idx <- sample.int(length(W), 1, prob = as.vector(W))
  k <- (idx - 1) %% nrow(W); s <- cols[(idx - 1) %/% nrow(W) + 1] - 1
  inc <- logical(n)
  for (i in n:1) {
    if (k == 0) break
    tot <- Tm[[i + 1]][k + 1, s + 1]
    with_i <- if (s - v[i] >= 0) Tm[[i]][k, s - v[i] + 1] else 0
    if (runif(1) < with_i / tot) { inc[i] <- TRUE; k <- k - 1; s <- s - v[i] }
  }
  inc
}

# Interval for the reversed sum R, in data units: rounding of the two condition means (±0.005 each)
# plus an allowance for the plotting rounding of the unsigned values (0 when the data are exact).
reversed_sum_interval <- function(S1, n, mu_d, tol_plot) {
  c(lo = (S1 - n * (abs(mu_d) + 0.01)) / 2 - tol_plot,
    hi = (S1 - n * (abs(mu_d) - 0.01)) / 2 + tol_plot)
}

# ---- signed changes: unsigned values with a uniformly drawn admissible sign pattern ----------
# a: unsigned changes; mu_d: mean of control − treatment; step: data grid; tol_plot: see above.
# Zeros carry no sign and are excluded from the subset-sum.
signed_changes <- function(a, mu_d, step, tol_plot, Tm = NULL) {
  n <- length(a); nz <- a > 0; v <- round(a[nz] / step)
  if (is.null(Tm)) Tm <- subset_dp(v)
  R <- reversed_sum_interval(sum(a), n, mu_d, tol_plot) / step
  inc <- sample_subset(Tm, v, R["lo"], R["hi"])
  if (is.null(inc)) stop("no admissible sign pattern: reversed sum in [", R["lo"], ", ", R["hi"], "] grid units")
  rev <- logical(n); rev[nz] <- inc
  d <- sign(mu_d) * a; d[rev] <- -d[rev]
  list(d = d, reversed = rev, n_reversed = sum(rev), Tm = Tm)
}

# ---- permutation tuning ---------------------------------------------------------------------
# Rank coupling alone hits a target correlation only within sampling noise (SE ≈ 0.17 at n = 34),
# which would scatter the simulated treatment SDs around Table 2. Random pairwise swaps within d_pos
# and within d_neg (marginals unchanged) are accepted when they bring the three correlations
# (c–d_pos, c–d_neg, d_pos–d_neg) closer to their targets.
tune_pairing <- function(ctrl, d_pos, d_neg, target, iter = 3000, tol = 0.01) {
  obj <- function(p, q) sum((c(cor(ctrl, p), cor(ctrl, q), cor(p, q)) - target)^2)
  cur <- obj(d_pos, d_neg); n <- length(ctrl)
  for (it in seq_len(iter)) {
    if (cur < tol^2) break
    ij <- sample.int(n, 2)
    if (it %% 2 == 1) { p <- d_pos; p[ij] <- p[rev(ij)]; new <- obj(p, d_neg); if (new < cur) { d_pos <- p; cur <- new } }
    else              { q <- d_neg; q[ij] <- q[rev(ij)]; new <- obj(d_pos, q); if (new < cur) { d_neg <- q; cur <- new } }
  }
  list(d_pos = d_pos, d_neg = d_neg, objective = cur)
}

# ---- full dataset for one outcome ----------------------------------------------------------
# absd: list(positive = <34 unsigned Δ>, negative = <34 unsigned Δ>)
# cond: data frame with columns condition, mean, sd for this outcome (control, positive, negative)
# rho_dd: assumed correlation between a donkey's two changes (unknown; scenario parameter)
# Returns a long data frame (donkey, condition, order, y) with attributes "check" and "targets".
simulate_conditions <- function(absd, cond, rho_dd = 0, step, tol_plot, dp = NULL) {
  g <- function(cn, what) cond[[what]][cond$condition == cn]
  n <- length(absd$positive)
  mu_c <- g("control", "mean"); sd_c <- g("control", "sd")
  trt <- c("positive", "negative")
  sg <- lapply(trt, function(tn) signed_changes(absd[[tn]], mu_c - g(tn, "mean"), step, tol_plot, dp[[tn]]))
  names(sg) <- trt
  d <- lapply(sg, `[[`, "d")
  # target correlations between control and each signed change, from Var(treatment) = Var(c) + Var(d) − 2 Cov(c, d)
  r_cd <- vapply(trt, function(tn) {
    vd <- var(d[[tn]]); cov_cd <- (sd_c^2 + vd - g(tn, "sd")^2) / 2
    max(-0.99, min(0.99, cov_cd / (sd_c * sqrt(vd))))
  }, numeric(1))
  Sigma <- matrix(c(1, r_cd[1], r_cd[2],  r_cd[1], 1, rho_dd,  r_cd[2], rho_dd, 1), 3, 3)
  pd_fixed <- FALSE
  if (min(eigen(Sigma, symmetric = TRUE, only.values = TRUE)$values) <= 1e-8) {
    Sigma <- as.matrix(Matrix::nearPD(Sigma, corr = TRUE)$mat); pd_fixed <- TRUE
  }
  Z <- MASS::mvrnorm(n, rep(0, 3), Sigma)
  ctrl <- mu_c + sd_c * as.numeric(scale(Z[, 1]))                # exact control mean and SD
  d_pos <- sort(d$positive)[rank(Z[, 2], ties.method = "first")]  # rank coupling to the Gaussian scores …
  d_neg <- sort(d$negative)[rank(Z[, 3], ties.method = "first")]
  tuned <- tune_pairing(ctrl, d_pos, d_neg, c(r_cd[1], r_cd[2], Sigma[2, 3]))   # … then permuted to hit the targets
  d_pos <- tuned$d_pos; d_neg <- tuned$d_neg
  wide <- data.frame(donkey = seq_len(n), control = ctrl, positive = ctrl - d_pos, negative = ctrl - d_neg)
  ord <- t(replicate(n, sample(3)))                                # random sequence per donkey
  long <- data.frame(
    donkey    = rep(wide$donkey, 3),
    condition = factor(rep(c("control", "positive", "negative"), each = n), levels = c("control", "positive", "negative")),
    order     = factor(c(ord[, 1], ord[, 2], ord[, 3])),
    y         = c(wide$control, wide$positive, wide$negative))
  check <- data.frame(condition = c("control", "positive", "negative"),
                      mean_target = c(mu_c, g("positive", "mean"), g("negative", "mean")),
                      mean_sim = c(mean(wide$control), mean(wide$positive), mean(wide$negative)),
                      sd_target = c(sd_c, g("positive", "sd"), g("negative", "sd")),
                      sd_sim = c(sd(wide$control), sd(wide$positive), sd(wide$negative)))
  attr(long, "check") <- check
  attr(long, "targets") <- list(r_cd = r_cd, rho_dd = rho_dd, pd_fixed = pd_fixed,
                                n_reversed = vapply(sg, `[[`, integer(1), "n_reversed"),
                                r_cd_achieved = c(positive = cor(ctrl, d_pos), negative = cor(ctrl, d_neg)),
                                rho_dd_achieved = cor(d_pos, d_neg))
  attr(long, "dp") <- lapply(sg, `[[`, "Tm")
  long
}
