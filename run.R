# run.R: rebuilds the whole project from the raw SIPRI file
# Usage (from the project folder): source("run.R")

message("1/5 Running tests...")
testthat::test_dir("tests/testthat", stop_on_failure = TRUE)

message("2/5 Building chart...")
source("R/01_sipri_chart.R")

message("3/5 Estimating TWFE proximity model...")
source("R/02_proximity_twfe.R")

message("4/5 Estimating event study...")
source("R/03_proximity_event_study.R")

message("5/5 Rendering report...")
quarto::quarto_render("sipri_report.qmd")

message("Done. Charts in outputs/, report in sipri_report.html")
