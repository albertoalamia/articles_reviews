# Internal-consistency checks on numbers reported in a paper.
# Pure functions, no side effects. Loaded with source(here::here("lib/consistency.R")).
# Tests: lib/tests/test_consistency.R  (run: Rscript lib/tests/run_tests.R)

#' Paired/one-sample t statistic and p-value from a reported mean difference, its SD and n.
#' This is what a paper's "change = M (SD)" lets you recompute (statcheck logic).
#' @return data.frame with t, df, p_two_sided, se
t_from_summary <- function(mean_diff, sd_diff, n) {
  se <- sd_diff / sqrt(n)
  t  <- mean_diff / se
  df <- n - 1
  data.frame(t = t, df = df, se = se,
             p_two_sided = 2 * stats::pt(-abs(t), df))
}

#' The |t| that would be needed to produce a reported two-sided p at the given df.
#' Useful to show how far a reported p is from the descriptives.
t_needed_for_p <- function(p, df) stats::qt(1 - p / 2, df)

#' Two-sample (Welch) t from two group summaries.
t_welch_from_summary <- function(m1, sd1, n1, m2, sd2, n2) {
  se <- sqrt(sd1^2 / n1 + sd2^2 / n2)
  t  <- (m1 - m2) / se
  df <- se^4 / ((sd1^2 / n1)^2 / (n1 - 1) + (sd2^2 / n2)^2 / (n2 - 1))
  data.frame(t = t, df = df, se = se, p_two_sided = 2 * stats::pt(-abs(t), df))
}

#' GRIM test (Brown & Heathers 2017): is a reported mean of integer-valued data possible for n?
#' @param mean reported mean; @param n sample size; @param decimals decimals the mean is reported to
#' @param items number of items averaged (1 for a single integer variable)
#' @return TRUE if some integer sum reproduces the mean at the reported precision
grim_consistent <- function(mean, n, decimals = 2, items = 1) {
  N <- n * items
  candidates <- round(mean * N) + c(-1, 0, 1)
  any(abs(round(candidates / N, decimals) - round(mean, decimals)) < 10^(-decimals) / 2)
}

#' Check reported change scores against the condition means they should derive from.
#' delta_definition: "a_minus_b" or "b_minus_a". Returns the expected signed delta, the
#' reported one, whether they match in value, and whether the report matches |expected| instead
#' (the signature of absolute-value or mislabelled deltas).
check_delta <- function(mean_a, mean_b, reported_delta,
                        delta_definition = c("a_minus_b", "b_minus_a"), tol = 0.05) {
  delta_definition <- match.arg(delta_definition)
  expected <- if (delta_definition == "a_minus_b") mean_a - mean_b else mean_b - mean_a
  data.frame(
    expected_signed  = expected,
    reported         = reported_delta,
    matches_signed   = abs(reported_delta - expected) <= tol,
    matches_absolute = abs(reported_delta - abs(expected)) <= tol & expected < 0,
    sign_lost        = sign(reported_delta) != sign(expected) & abs(abs(reported_delta) - abs(expected)) <= tol
  )
}

#' Does a reported p-value fall in the right bin for a recomputed one?
#' Papers often report thresholds ("p < 0.001") or rounded values; compare at the stated precision.
p_consistent <- function(p_reported, p_recomputed, reported_as = c("exact", "less_than"), decimals = 3) {
  reported_as <- match.arg(reported_as)
  if (reported_as == "less_than") return(p_recomputed < p_reported)
  round(p_recomputed, decimals) == round(p_reported, decimals)
}
