# Read CmdStan draws from $FITS_DIR, compute diagnostics and summaries, save SMALL artefacts.
# Never copy the CSV draws into the project tree.
library(cmdstanr)   # read_cmdstan_csv only; no fitting from R
library(posterior)
library(bayesplot)
library(loo)
library(tidyverse)
here_art <- function(...) here::here("<ARTICLE_DIR>", ...)
fits_dir <- file.path(Sys.getenv("FITS_DIR"), "<ARTICLE_DIR>")
stopifnot(dir.exists(fits_dir))

model <- "<model>"
files <- list.files(fits_dir, pattern = paste0("^", model, "_[0-9]+\\.csv$"), full.names = TRUE)
fit   <- read_cmdstan_csv(files)
draws <- as_draws_df(fit$post_warmup_draws)

diag <- summarise_draws(draws, default_convergence_measures())
stopifnot(all(diag$rhat < 1.01, na.rm = TRUE))
write_csv(summarise_draws(draws), here_art("output/tables", paste0(model, "_summary.csv")))
saveRDS(subset_draws(draws, variable = c("<parameters of interest>")),
        here_art("output/tables", paste0(model, "_draws_subset.rds")))
