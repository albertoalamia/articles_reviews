library(testthat)

nodes <- data.frame(name  = c("y", "mu", "sigma", "m0"),
                    label = c("y[i]", "mu", "sigma", "0"),
                    x = c(1, 0.5, 1.5, 0.5), y = c(0, 1, 1, 2),
                    type = c("data", "param", "param", "const"))
edges <- data.frame(from = c("mu", "sigma", "m0"), to = c("y", "y", "mu"))
plates <- data.frame(name = "i", label = "i == 1 * ',' * ldots * ',' * N", x0 = 0.6, y0 = -0.5, x1 = 1.4, y1 = 0.5)

test_that("plate_diagram returns a ggplot and builds without error", {
  p <- plate_diagram(nodes, edges, plates)
  expect_s3_class(p, "ggplot")
  expect_silent(b <- ggplot2::ggplot_build(p))
  expect_true(length(b$data) >= 4)
})

test_that("plate_diagram rejects unknown node types and dangling edges", {
  bad <- nodes; bad$type[1] <- "obs"
  expect_error(plate_diagram(bad, edges))
  expect_error(plate_diagram(nodes, data.frame(from = "mu", to = "zzz")))
})

test_that("plate_diagram works without plates and with dashed edges", {
  e <- edges; e$lty <- c("solid", "solid", "dashed")
  expect_s3_class(plate_diagram(nodes, e), "ggplot")
})
