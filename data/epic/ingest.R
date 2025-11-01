# Process staging data

raw <- dcf::dcf_process_epic_staging()

# if there was staging data, make new standard version from it

if (!is.null(raw)) {
  process <- dcf::dcf_process_record()
  meta_files <- list.files("raw", "json", full.names = TRUE)
  raw_vintages <- lapply(
    structure(
      meta_files,
      names = gsub(".*/|\\..*", "", meta_files)
    ),
    function(meta_file) {
      meta <- jsonlite::read_json(meta_file)[[1L]]
      as.character(as.Date(meta[["Date of Export"]], "%m/%d/%Y"))
    }
  )

  files <- list.files("raw", "\\.csv\\.xz", full.names = TRUE)
  data <- lapply(files, function(file) {
    d <- vroom::vroom(file, show_col_types = FALSE, guess_max = Inf)
    dcf::dcf_standardize_epic(d)
  })
  names(data) <- sub("\\..*", "", basename(files))

  vroom::vroom_write(
    Reduce(
      function(a, b) merge(a, b, all = TRUE, sort = FALSE),
      data[c("all_encounters", "covid", "flu", "rsv")]
    ),
    "standard/weekly.csv.gz",
    ","
  )
  vroom::vroom_write(data$self_harm, "standard/state_no_time.csv.gz", ",")
  vroom::vroom_write(data$obesity_county, "standard/county_no_time.csv.gz", ",")
  vroom::vroom_write(data$rsv_tests, "standard/no_geo.csv.gz", ",")
  vroom::vroom_write(data$vaccine_mmr, "standard/children.csv.gz", ",")

  process$vintages <- list(
    weekly.csv.gz = max(unlist(raw_vintages[c(
      "all_encounters",
      "covid",
      "flu",
      "rsv"
    )])),
    state_no_time.csv.gz = raw_vintages$self_harm,
    county_no_time.csv.gz = raw_vintages$obesity_county,
    no_geo.csv.gz = raw_vintages$rsv_tests,
    children.csv.gz = raw_vintages$vaccine_mmr
  )
  dcf::dcf_process_record(updated = process)
}
