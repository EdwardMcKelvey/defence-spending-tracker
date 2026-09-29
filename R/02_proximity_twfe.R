# 02_proximity_twfe.R
# Purpose: Did European NATO members near Russia raise military spending more after 2022?
# Method:  Two-way fixed effects (country and year), SEs clustered by country
# Data:    SIPRI Military Expenditure Database, 2026 release

library(tidyverse)
library(readxl)
library(fixest)
source("R/sipri_functions.R")

panel <- find_sipri_file() |>
  read_sipri() |>
  clean_sipri() |>
  filter_countries() |>
  build_proximity_panel()

# Checks: 29 countries, 6 of them near Russia
print(n_distinct(panel$country))
print(panel |> distinct(country, near_russia) |> count(near_russia))

# The 2x2 by hand: mean share of GDP by group, before and after 2022
means <- panel |>
  group_by(near_russia, post) |>
  summarise(mean_share = mean(share_gdp), .groups = "drop")
print(means)

# Main estimate: country and year fixed effects, clustered by country
twfe_main <- feols(share_gdp ~ treated | country + year,
  data = panel, cluster = ~country
)

# Robustness: 2022 budgets were mostly set before the invasion, so start "post" in 2023
twfe_2023 <- feols(share_gdp ~ treated | country + year,
  data = build_proximity_panel(filter_countries(clean_sipri(
    read_sipri(find_sipri_file())
  )), post_from = 2023),
  cluster = ~country
)

print(etable(twfe_main, twfe_2023, headers = c("Post from 2022", "Post from 2023")))
