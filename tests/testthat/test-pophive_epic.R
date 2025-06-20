test_that("reading works", {
  raw_dir <- paste0(tempdir(), "/raw")
  stage_dir <- paste0(raw_dir, "/staging")
  dir.create(stage_dir, FALSE, TRUE)

  path <- paste0(stage_dir, "/RSV.csv")
  raw_lines <- c(
    "metadata field,metadata value,,",
    ",,,",
    ",,Measures,Value Name",
    "Year,Age,RSV,",
    "2020,6 years or more,m1,1",
    ",Total: all,m2,2",
    "2021,65 years or more,m1,3",
    ",No value,m2,4"
  )
  writeLines(raw_lines, path)
  writeLines(raw_lines, paste0(stage_dir, "/RSV2.csv"))

  read <- pophive_process_epic_staging(stage_dir, raw_dir)
  expect_identical(read$metadata$rsv[[1L]]$`metadata field`, "metadata value")
  expect_identical(
    as.character(unlist(read$data$rsv)),
    c(
      "2020",
      "2020",
      "2021",
      "2021",
      "6+ Years",
      "Total",
      "65+ Years",
      NA_character_,
      "m1",
      "m2",
      "m1",
      "m2",
      1L:4L
    )
  )
})
