# 01_sipri_chart.R
# Purpose: European NATO military spending as % of GDP, 2014–2025
# Data:    SIPRI Military Expenditure Database, 2026 release (downloaded DD/MM/2026)
# Output:  outputs/nato_europe_share_gdp.png

library(tidyverse)
library(readxl)
source("R/sipri_functions.R")

sipri_gdp <- find_sipri_file() |>
  read_sipri() |>
  clean_sipri()

plot_data <- filter_countries(sipri_gdp)

p <- plot_share_gdp(plot_data)
p

ggsave("outputs/nato_europe_share_gdp.png", p,
       width = 9, height = 5.5, dpi = 300, bg = "white")
