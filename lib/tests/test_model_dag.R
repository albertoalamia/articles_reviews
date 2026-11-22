library(testthat)

nodes <- data.frame(name  = c("h", "mu", "sigma", "x", "y"),
                    label = c("N*'(0, 1)'", "mu", "sigma", "x[i]", "y[i]"),
                    group = c("hyperparameter", "parameter", "parameter", "covariate", "observed"),
                    x = c(0, 1, 1, 1.5, 2.5), y = c(1, 1, 0, 2, 1))
edges <- data.frame(from = c("h", "mu", "sigma", "x"), to = c("mu", "y", "y", "y"))

test_that("model_dag returns a ggplot that builds", {
  p <- model_dag(nodes, edges, title = "test")
  expect_s3_class(p, "ggplot")
  b <- ggplot2::ggplot_build(p)
  expect_true(length(b$data) >= 4)
})

test_that("model_dag rejects unknown groups, dangling edges and duplicated names", {
  bad <- nodes; bad$group[1] <- "prior"
  expect_error(model_dag(bad, edges))
  expect_error(model_dag(nodes, data.frame(from = "mu", to = "zzz")))
  dup <- rbind(nodes, nodes[1, ])
  expect_error(model_dag(dup, edges))
})
