# run.R: rebuilds the whole project from the raw SIPRI file
# Usage (from the project folder): source("run.R")

message("1/3 Running tests...")
testthat::test_dir("tests/testthat", stop_on_failure = TRUE)

message("2/3 Building chart...")
source("R/01_sipri_chart.R")

message("3/3 Rendering report...")
quarto::quarto_render("sipri_report.qmd")

message("Done. Chart in outputs/, report in sipri_report.html")
