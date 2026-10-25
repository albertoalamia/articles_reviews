library(testthat)

test_that("t from summary reproduces a textbook paired t", {
  r <- t_from_summary(mean_diff = 2, sd_diff = 4, n = 16)
  expect_equal(r$t, 2)
  expect_equal(r$df, 15)
  expect_equal(r$p_two_sided, 2 * pt(-2, 15))
})

test_that("Bukhari 2026 positive-treatment SBR: descriptives imply t ~ 17, not p = 0.002", {
  r <- t_from_summary(19.0, 6.6, 34)
  expect_gt(r$t, 16)
  expect_lt(r$p_two_sided, 1e-10)
  expect_lt(t_needed_for_p(0.002, 33), 3.5)
})

test_that("GRIM accepts possible and rejects impossible means", {
  expect_true(grim_consistent(2.50, n = 10))
  expect_false(grim_consistent(2.53, n = 10))
  expect_true(grim_consistent(3.33, n = 3))
})

test_that("check_delta flags absolute-value deltas", {
  # control 47.3, negative 57.4, change defined control - treatment, reported as +10.1
  d <- check_delta(47.3, 57.4, 10.1, "a_minus_b", tol = 0.05)
  expect_false(d$matches_signed)
  expect_true(d$matches_absolute)
  expect_true(d$sign_lost)
  # a correctly signed report
  d2 <- check_delta(47.3, 57.4, -10.1, "a_minus_b")
  expect_true(d2$matches_signed)
})

test_that("p_consistent handles thresholds and exact values", {
  expect_true(p_consistent(0.001, 1e-5, "less_than"))
  expect_false(p_consistent(0.002, 1e-5, "exact"))
  expect_true(p_consistent(0.045, 0.0451, "exact", decimals = 3))
})
