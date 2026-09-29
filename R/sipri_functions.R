# sipri_functions.R
# Reusable functions for reading, cleaning, filtering and charting SIPRI data

# European NATO members with armed forces (Iceland excluded)
nato_europe <- c(
  "Albania", "Belgium", "Bulgaria", "Croatia", "Czechia", "Denmark", "Estonia",
  "Finland", "France", "Germany", "Greece", "Hungary", "Italy", "Latvia",
  "Lithuania", "Luxembourg", "Montenegro", "Netherlands", "North Macedonia", "Norway",
  "Poland", "Portugal", "Romania", "Slovakia", "Slovenia", "Spain", "Sweden",
  "Türkiye", "United Kingdom"
)

# Find the SIPRI Excel file in a folder (ignores Excel's ~$ lock files)
find_sipri_file <- function(dir = "data/raw") {
  path <- list.files(dir, pattern = "^[^~].*\\.xlsx$", full.names = TRUE)[1]
  if (is.na(path)) stop("No SIPRI .xlsx file found in ", dir)
  path
}

# Read one sheet of the SIPRI file, starting at the header row
read_sipri <- function(path, sheet_pattern = "share of gdp") {
  sheet <- str_subset(excel_sheets(path), regex(sheet_pattern, ignore_case = TRUE))[1]
  if (is.na(sheet)) stop("No sheet matching '", sheet_pattern, "' in ", path)

  raw        <- read_excel(path, sheet = sheet, col_names = FALSE, col_types = "text")
  header_row <- which(raw[[1]] == "Country")[1]
  if (is.na(header_row)) stop("Could not find a 'Country' header row in sheet ", sheet)

  read_excel(path, sheet = sheet, skip = header_row - 1, col_types = "text")
}

# Turn the wide SIPRI sheet into a tidy country-year table (share of GDP in %)
clean_sipri <- function(raw) {
  raw |>
    rename(country = 1) |>
    select(country, matches("^\\d{4}$")) |>
    pivot_longer(-country, names_to = "year", values_to = "share_gdp") |>
    mutate(
      year      = as.integer(year),
      share_gdp = suppressWarnings(as.numeric(share_gdp)) * 100
    ) |>
    filter(!is.na(country)) |>
    group_by(country) |>
    filter(any(!is.na(share_gdp))) |>
    ungroup()
}

# Keep a set of countries from a start year onwards, dropping missing values
filter_countries <- function(data, countries = nato_europe, from = 2014) {
  data |>
    filter(country %in% countries, year >= from, !is.na(share_gdp))
}

# Line chart of share of GDP, highlighting selected countries
plot_share_gdp <- function(data,
                           highlight = c("United Kingdom" = "#2C5E9E",
                                         "Poland"         = "#C0392B",
                                         "Germany"        = "#D4A017")) {
  data <- data |> mutate(highlighted = country %in% names(highlight))
  first_year  <- min(data$year)
  latest_year <- max(data$year)

  end_labels <- data |>
    filter(highlighted) |>
    group_by(country) |>
    filter(year == max(year)) |>
    ungroup()

  ggplot(data, aes(x = year, y = share_gdp, group = country)) +
    geom_hline(yintercept = c(2, 3.5), linetype = "dashed", colour = "grey45") +
    annotate("text", x = latest_year, y = c(2, 3.5),
             label = c("2% guideline", "3.5% core target by 2035"),
             hjust = 1, vjust = -0.5, size = 3, colour = "grey30") +
    geom_line(data = filter(data, !highlighted), colour = "grey80", linewidth = 0.5) +
    geom_line(data = filter(data, highlighted), aes(colour = country), linewidth = 1.2) +
    ggrepel::geom_text_repel(data = end_labels, aes(label = country, colour = country),
                             direction = "y", hjust = 0, nudge_x = 0.4,
                             size = 3.5, fontface = "bold", segment.colour = NA) +
    scale_colour_manual(values = highlight) +
    scale_x_continuous(breaks = seq(first_year, latest_year, 2),
                       expand = expansion(mult = c(0.02, 0.2))) +
    scale_y_continuous(labels = \(x) paste0(x, "%")) +
    labs(
      title    = paste0("European NATO military spending, ", first_year, "–", latest_year),
      subtitle = "Share of GDP; other European NATO members in grey",
      x = NULL, y = NULL,
      caption  = "Source: SIPRI Military Expenditure Database, 2026 release"
    ) +
    theme_minimal(base_size = 12) +
    theme(legend.position = "none",
          panel.grid.minor = element_blank(),
          plot.title = element_text(face = "bold"))
}

