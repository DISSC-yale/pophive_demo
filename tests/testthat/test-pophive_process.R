test_that("source workflow works", {
  root_dir <- paste0(tempdir(), "/pophive_test")
  dir.create(root_dir)
  wd <- setwd(root_dir)
  on.exit(setwd(wd))
  source_dir <- "pophive_sources"
  source_name <- "test_source"
  pophive_add_source(source_name, source_dir, open_after = FALSE)
  project_files <- paste0(
    source_dir,
    "/",
    source_name,
    "/",
    c("ingest.R", "measure_info.json")
  )
  expect_true(all(file.exists(project_files)))

  # initial ingest with issues
  writeLines(
    c(
      '# write raw',
      'data <- data.frame(loc = c("a", NA), year = c(2020, NA), value = c(1, NA))',
      'write.csv(data, "raw/data.csv", row.names = FALSE)',
      '',
      '# standardize',
      'data <- read.csv("raw/data.csv")',
      'colnames(data) <- c("geography", "time", "measure_name")',
      'write.csv(data, "standard/data.csv", row.names = FALSE)'
    ),
    project_files[[1L]]
  )
  timings <- pophive_process(source_name, source_dir)$timings
  expect_false(is.null(timings[[source_name]]))
  issues <- pophive_check_sources(source_name, source_dir)
  expect_true(length(issues[[source_name]]) != 0)

  # updated with issues corrected
  unlink(
    paste0(
      source_dir,
      "/",
      source_name,
      "/",
      c("raw", "standard"),
      "/data.csv"
    ),
    force = TRUE
  )
  writeLines(
    c(
      '# write raw',
      'data <- data.frame(loc = c("a", NA), year = c(2020, NA), value = c(1, NA))',
      'write.csv(data, xzfile("raw/data.csv.xz"), row.names = FALSE)',
      '',
      '# standardize',
      'data <- read.csv(xzfile("raw/data.csv.xz"))',
      'colnames(data) <- c("geography", "time", "measure_name")',
      'write.csv(data[!is.na(data$time), ], xzfile("standard/data.csv.xz"), row.names = FALSE)'
    ),
    project_files[[1L]]
  )
  pophive_process(source_name, source_dir)
  community::data_measure_info(
    project_files[[2L]],
    measure_name = list(
      full_name = "measure_name"
    ),
    verbose = FALSE,
    open_after = FALSE
  )
  system2("git", "init")
  system2("git", 'config user.email "temp@example.com"')
  system2("git", 'config user.name "temp user"')
  system2("git", "add -A")
  system2("git", 'commit -m "initial commit"')
  process <- pophive_process(source_name, source_dir, ingest = FALSE)
  package <- jsonlite::read_json(paste0(
    source_dir,
    "/",
    source_name,
    "/standard/datapackage.json"
  ))
  expect_false(is.null(package$resources[[1L]]$versions$hash))
  issues <- pophive_check_sources(source_name, source_dir)
  expect_true(length(issues[[source_name]][[1L]]) == 0L)
})
