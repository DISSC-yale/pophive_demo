# Process staging data

raw <- pophive::pophive_process_epic_staging()

# if there was staging data, make new standard version from it

if (!is.null(raw)) {
  files <- list.files("raw", "\\.csv\\.xz", full.names = TRUE)
  data <- lapply(files, function(file) {
    d <- vroom::vroom(file, show_col_types = FALSE, guess_max = Inf)
    pophive::pophive_standardize_epic(d)
  })
  names(data) <- sub("\\..*", "", basename(files))

  vroom::vroom_write(
    Reduce(
      function(a, b) merge(a, b, all = TRUE, sort = FALSE),
      data[c("all_encounters", "covid", "flu", "rsv")]
    ),
    "standard/weekly.csv.xz",
    ","
  )
  vroom::vroom_write(data$self_harm, "standard/state_no_time.csv.xz", ",")
  vroom::vroom_write(data$obesity_county, "standard/county_no_time.csv.xz", ",")
  vroom::vroom_write(data$rsv_tests, "standard/no_geo.csv.xz", ",")
  vroom::vroom_write(data$vaccine_mmr, "standard/children.csv.xz", ",")
}
