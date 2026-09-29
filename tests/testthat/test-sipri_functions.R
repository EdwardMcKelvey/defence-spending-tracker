# test-sipri_functions.R

# A tiny fake version of SIPRI's "Share of GDP" sheet, including its quirks:
# a region heading row, placeholder codes, a notes column and a blank row
fake_raw <- tibble(
  Country = c("Europe", "United Kingdom", "Poland", "Atlantis", NA),
  Notes   = c(NA, NA, "§", NA, NA),
  `2014`  = c(NA, "0.021", "0.019", "...", NA),
  `2015`  = c(NA, "0.02", "...", "xxx", NA)
)

test_that("clean_sipri returns country, year and share_gdp with the right types", {
  out <- clean_sipri(fake_raw)
  expect_named(out, c("country", "year", "share_gdp"))
  expect_type(out$country, "character")
  expect_type(out$year, "integer")
  expect_type(out$share_gdp, "double")
})

test_that("clean_sipri returns one row per country-year", {
  out <- clean_sipri(fake_raw)
  expect_equal(nrow(distinct(out, country, year)), nrow(out))
})

test_that("clean_sipri returns no negative values", {
  out <- clean_sipri(fake_raw)
  expect_true(all(out$share_gdp >= 0, na.rm = TRUE))
})

test_that("clean_sipri converts fractions to percentages", {
  out <- clean_sipri(fake_raw)
  uk_2014 <- out |>
    filter(country == "United Kingdom", year == 2014) |>
    pull(share_gdp)
  expect_equal(uk_2014, 2.1)
})

test_that("clean_sipri turns placeholder codes into NA", {
  out <- clean_sipri(fake_raw)
  pl_2015 <- out |>
    filter(country == "Poland", year == 2015) |>
    pull(share_gdp)
  expect_true(is.na(pl_2015))
})

test_that("clean_sipri drops region headings, empty rows and countries with no data", {
  out <- clean_sipri(fake_raw)
  expect_setequal(unique(out$country), c("United Kingdom", "Poland"))
})

test_that("filter_countries keeps only chosen countries from the start year", {
  out <- clean_sipri(fake_raw) |> filter_countries(countries = "United Kingdom", from = 2015)
  expect_equal(unique(out$country), "United Kingdom")
  expect_true(all(out$year >= 2015))
})

test_that("find_sipri_file gives a clear error when no file exists", {
  empty_dir <- file.path(tempdir(), "no_sipri_here")
  dir.create(empty_dir, showWarnings = FALSE)
  expect_error(find_sipri_file(empty_dir), "No SIPRI .xlsx file found")
})

test_that("add_distance_moscow matches every European NATO member", {
  fake_panel <- tibble(country = nato_europe, year = 2022L, share_gdp = 2)
  out <- add_distance_moscow(fake_panel)
  expect_equal(nrow(out), nrow(fake_panel))
  expect_false(anyNA(out$dist_moscow_km))
})

test_that("add_distance_moscow returns sensible distances in km", {
  fake_panel <- tibble(
    country = c("United Kingdom", "Lithuania"),
    year = 2022L, share_gdp = 2
  )
  out <- add_distance_moscow(fake_panel)
  uk <- out |>
    filter(country == "United Kingdom") |>
    pull(dist_moscow_km)
  lt <- out |>
    filter(country == "Lithuania") |>
    pull(dist_moscow_km)
  expect_gt(uk, 2400)
  expect_lt(uk, 2600)
  expect_gt(lt, 700)
  expect_lt(lt, 900)
})

test_that("build_proximity_panel codes near_russia, post and treated correctly", {
  fake_panel <- tibble(
    country   = rep(c("Lithuania", "United Kingdom"), each = 2),
    year      = rep(c(2021L, 2022L), times = 2),
    share_gdp = 2
  )
  out <- build_proximity_panel(fake_panel)
  expect_equal(out$near_russia, c(1L, 1L, 0L, 0L))
  expect_equal(out$post,        c(0L, 1L, 0L, 1L))
  expect_equal(out$treated,     c(0L, 1L, 0L, 0L))
})
