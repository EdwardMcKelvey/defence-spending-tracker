# European Defence Spending Tracker

How has military spending by European NATO members changed since 2014, and how close are they to NATO's spending targets?

![European NATO military spending as a share of GDP, 2014–2025](outputs/nato_europe_share_gdp.png)

## Key findings

- **Poland** has pulled away from the rest of Europe. Its spending was around 2% of GDP until 2022, then more than doubled to about 4.5% in 2025, well above NATO's new 3.5% core target.
- **Germany** moved from roughly 1.1% of GDP in 2014 to about 2.3% in 2025, with most of the increase coming after Russia's full-scale invasion of Ukraine in 2022.
- **The United Kingdom** stayed close to 2% for most of the period and reached around 2.4% in 2024–25.
- Most European NATO members were below the 2% guideline in 2014. By 2025, most are at or above it, but only a few are near 3.5%.

## Data

- **Source:** [SIPRI Military Expenditure Database](https://www.sipri.org/databases/milex), 2026 release (file `SIPRI-Milex-data-1949-2025_v1.2.xlsx`, downloaded [DD Month 2026]).
- **Measure:** military expenditure as a share of GDP ("Share of GDP" sheet).
- **Countries:** the 29 European NATO members with armed forces. Iceland is excluded because it has no armed forces, so SIPRI records its spending as zero.
- **Licence:** SIPRI data is free for non-commercial use with attribution. The raw file is not included in this repo; see *How to run* below.

## Method

1. Read the "Share of GDP" sheet, detecting the header row automatically.
2. Reshaped the data from wide (one column per year) to long format: country, year, share of GDP.
3. Converted SIPRI's missing-value codes (`...`, `xxx`) to `NA`, and converted shares from fractions to percentages.
4. Removed region headings and footnote rows.
5. Filtered to European NATO members from 2014 (the year of the Wales Summit 2% pledge) onwards.

### SIPRI vs NATO figures

SIPRI and NATO define military spending differently. For example, NATO's definition includes some items, such as certain pensions and paramilitary forces, that SIPRI treats differently. So the figures here will not always match NATO's official estimates. SIPRI is used because it applies one consistent definition across all countries and years.

## How to run

Requires R (4.3 or later) and RStudio or Positron.

1. Clone this repo and open `defence-spending-tracker.Rproj`.
2. Restore the package versions used:
```r
   renv::restore()
```
3. Download the SIPRI Excel file from the link above and save it in `data/raw/`.
4. Run `R/01_sipri_chart.R`. The chart is saved to `outputs/`.

## Project structure

```
defence-spending-tracker/
├── R/
│   └── 01_sipri_chart.R     # read, clean, reshape and chart the data
├── data/raw/                # SIPRI file goes here (not tracked by Git)
├── outputs/                 # saved charts
├── renv.lock                # package versions
└── README.md
```

## Next steps

- Refactor the script into tested functions and a Quarto report (reproducible analytical pipeline).
- Event-study analysis: did spending respond differently in countries closer to Russia after 2022?
- Add real-terms spending (constant US$) alongside share of GDP.

---

*Personal project using publicly available data.*
