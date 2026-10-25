# Run from the repo root inside nix-shell:  Rscript lib/tests/run_tests.R
`%||%` <- function(a, b) if (is.null(a)) b else a
source("lib/consistency.R")
library(testthat)
res <- test_file("lib/tests/test_consistency.R", reporter = "summary")
df <- as.data.frame(res)
if (sum(df$failed) > 0 || sum(df$error) > 0) quit(status = 1)
