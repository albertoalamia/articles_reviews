# Recompute what can be recomputed from the reported numbers. Produces output/tables/consistency.csv
# which review.qmd reads. Functions from lib/consistency.R.
source(here::here("lib/consistency.R"))
library(tidyverse)
here_art <- function(...) here::here("<ARTICLE_DIR>", ...)

# Example
# checks <- bind_rows(
#   t_from_summary(mean_diff = , sd_diff = , n = ) |> mutate(what = "SBR change, positive"),
# )
# write_csv(checks, here_art("output/tables/consistency.csv"))
