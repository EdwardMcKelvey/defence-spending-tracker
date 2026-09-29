# 03_proximity_event_study.R
# Purpose: Year-by-year spending gap between near-Russia and other European NATO members,
#          relative to 2021, to check pre-trends and trace the post-2022 response
# Method:  Event study with country and year fixed effects, SEs clustered by country
# Output:  outputs/event_study_proximity.png

library(tidyverse)
library(readxl)
library(fixest)
source("R/sipri_functions.R")

panel <- find_sipri_file() |>
  read_sipri() |>
  clean_sipri() |>
  filter_countries() |>
  build_proximity_panel()

es <- feols(share_gdp ~ i(year, near_russia, ref = 2021) | country + year,
  data = panel, cluster = ~country
)
print(etable(es))

# Joint test that all pre-period coefficients (2014-2020) are zero
print(wald(es, keep = "year::20(1[4-9]|20):"))

# Tidy coefficients for plotting; add the 2021 reference year at zero
es_coefs <- coeftable(es) |>
  as.data.frame() |>
  rownames_to_column("term") |>
  transmute(
    year     = as.integer(str_extract(term, "\\d{4}")),
    estimate = Estimate,
    se       = `Std. Error`
  ) |>
  add_row(year = 2021L, estimate = 0, se = 0) |>
  arrange(year)

p <- ggplot(es_coefs, aes(x = year, y = estimate)) +
  geom_hline(yintercept = 0, colour = "grey45") +
  geom_vline(xintercept = 2021.5, linetype = "dashed", colour = "grey45") +
  geom_errorbar(aes(ymin = estimate - 1.96 * se, ymax = estimate + 1.96 * se),
    width = 0.2, colour = "#2C5E9E"
  ) +
  geom_point(size = 2.5, colour = "#2C5E9E") +
  annotate("text",
    x = 2021.6, y = max(es_coefs$estimate + 1.96 * es_coefs$se),
    label = "Russia invades Ukraine", hjust = 0, size = 3, colour = "grey30"
  ) +
  scale_x_continuous(breaks = 2014:2025) +
  scale_y_continuous(labels = \(x) paste0(x, "pp")) +
  labs(
    title = "Countries near Russia vs other European NATO members",
    subtitle = "Gap in military spending (% of GDP) vs 2021, with 95% confidence intervals",
    x = NULL, y = NULL,
    caption = paste0(
      "Near Russia: capital within 1,300 km of Moscow (6 countries). ",
      "Country and year fixed effects; SEs clustered by country.\n",
      "Source: SIPRI Military Expenditure Database, 2026 release"
    )
  ) +
  theme_minimal(base_size = 12) +
  theme(panel.grid.minor = element_blank(), plot.title = element_text(face = "bold"))

print(p)
ggsave("outputs/event_study_proximity.png", p,
  width = 9, height = 5.5, dpi = 300, bg = "white"
)
