# Extract/tidy the paper's reported numbers (or received data) and write JSON for CmdStan.
# Input : data/raw/*.csv   (see data/raw/EXTRACTION_LOG.md for provenance)
# Output: data/derived/*.csv, data/derived/<model>_data.json
library(tidyverse)
library(jsonlite)
here_art <- function(...) here::here("<ARTICLE_DIR>", ...)

# raw <- read_csv(here_art("data/raw/table2.csv"))
# stan_data <- list(N = nrow(raw), y = raw$y)
# write_json(stan_data, here_art("data/derived/<model>_data.json"), auto_unbox = TRUE, digits = NA)
