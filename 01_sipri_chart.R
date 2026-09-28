# 01_sipri_chart.R
# Purpose: European NATO military spending as % of GDP, 2014–2025
# Data:    SIPRI Military Expenditure Database, 2026 release (downloaded DD/MM/2026)
# Output:  outputs/nato_europe_share_gdp.png

usethis::use_git()
renv::init()
install.packages(c("tidyverse", "readxl"))
dir.create("data/raw", recursive = TRUE, showWarnings = FALSE)
dir.create("R", showWarnings = FALSE)
dir.create("outputs", showWarnings = FALSE)
usethis::use_git_ignore("data/raw/")
usethis::use_readme_md(open = FALSE)
system("git add -A && git commit -m 'Set up project structure'")
usethis::use_github()

#read and reshape data into a tidy country by year table
library(tidyverse)
library(readxl)

# 1. Read the "Share of GDP" sheet ----
path  <- path <- list.files("data/raw", pattern = "^[^~].*\\.xlsx$", full.names = TRUE)[1]
sheet <- str_subset(excel_sheets(path), regex("share of gdp", ignore_case = TRUE))[1]

# Find the row where the table header starts (the cell that says "Country")
raw        <- read_excel(path, sheet = sheet, col_names = FALSE, col_types = "text")
header_row <- which(raw[[1]] == "Country")[1]

# 2-4. Read properly, reshape to long, clean values ----
sipri_gdp <- read_excel(path, sheet = sheet, skip = header_row - 1, col_types = "text") |>
  rename(country = 1) |>                              # first column = country
  select(country, matches("^\\d{4}$")) |>             # keep only year columns (drops Notes)
  pivot_longer(-country, names_to = "year", values_to = "share_gdp") |>
  mutate(
    year      = as.integer(year),
    share_gdp = suppressWarnings(as.numeric(share_gdp))   # "..." and "xxx" become NA
  ) |>
  filter(!is.na(country)) |>
  group_by(country) |>
  filter(any(!is.na(share_gdp))) |>                   # drops region headings and footnotes
  ungroup() |>
  mutate(share_gdp = share_gdp * 100)   # SIPRI stores shares as fractions
# SIPRI stores 2.3% as 0.023; convert to %

# Quick checks ----
glimpse(sipri_gdp)
sipri_gdp |> filter(country == "United Kingdom", year >= 2014)

# 5. Filter: European NATO members, 2014 onwards ----
nato_europe <- c(
  "Albania", "Belgium", "Bulgaria", "Croatia", "Czechia", "Denmark", "Estonia",
  "Finland", "France", "Germany", "Greece", "Hungary", "Italy", "Latvia",
  "Lithuania", "Luxembourg", "Montenegro", "Netherlands", "North Macedonia", "Norway",
  "Poland", "Portugal", "Romania", "Slovakia", "Slovenia", "Spain", "Sweden",
  "Türkiye", "United Kingdom"
)

# Check: any names that don't match SIPRI's spelling?
setdiff(nato_europe, sipri_gdp$country)

highlight <- c("United Kingdom", "Poland", "Germany")

plot_data <- sipri_gdp |>
  filter(country %in% nato_europe, year >= 2014, !is.na(share_gdp)) |>
  mutate(highlighted = country %in% highlight)

latest_year <- max(plot_data$year)

end_labels <- plot_data |>
  filter(highlighted) |>
  group_by(country) |>
  filter(year == max(year)) |>
  ungroup()

# 6. Chart ----
p <- ggplot(plot_data, aes(x = year, y = share_gdp, group = country)) +
  geom_hline(yintercept = c(2, 3.5), linetype = "dashed", colour = "grey45") +
  annotate("text", x = latest_year, y = c(2, 3.5),
           label = c("2% guideline", "3.5% core target by 2035"),
           hjust = 0, vjust = -0.5, size = 3, colour = "grey30") +
  geom_line(data = filter(plot_data, !highlighted), colour = "grey80", linewidth = 0.5) +
  geom_line(data = filter(plot_data, highlighted), aes(colour = country), linewidth = 1.2) +
  ggrepel::geom_text_repel(data = end_labels, aes(label = country, colour = country),
                           direction = "y", hjust = 1, nudge_x = 0.4,
                           size = 3.5, fontface = "bold", segment.colour = NA) +
  scale_colour_manual(values = c("United Kingdom" = "#2C5E9E",
                                 "Poland"         = "#C0392B",
                                 "Germany"        = "#D4A017")) +
  scale_x_continuous(breaks = seq(2014, latest_year, 2),
                     expand = expansion(mult = c(0.02, 0.2))) +
  scale_y_continuous(labels = \(x) paste0(x, "%")) +
  labs(
    title    = paste0("European NATO military spending, 2014–", latest_year),
    subtitle = "Share of GDP; other European NATO members in grey",
    x = NULL, y = NULL,
    caption  = "Source: SIPRI Military Expenditure Database, 2026 release"
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "none",
        panel.grid.minor = element_blank(),
        plot.title = element_text(face = "bold"))

p

# 7. Save chart to outputs/ ----
ggsave("outputs/nato_europe_share_gdp.png", p,
       width = 9, height = 5.5, dpi = 300, bg = "white")
