# Run from the repo root inside nix-shell:  Rscript lib/tests/run_tests.R
`%||%` <- function(a, b) if (is.null(a)) b else a
source("lib/consistency.R")
source("lib/quality_table.R")
library(testthat)
failed <- 0
for (f in c("lib/tests/test_consistency.R", "lib/tests/test_quality_table.R")) {
  df <- as.data.frame(test_file(f, reporter = "summary"))
  failed <- failed + sum(df$failed) + sum(df$error)
}
if (failed > 0) quit(status = 1)
