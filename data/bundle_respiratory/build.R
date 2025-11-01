process <- dcf::dcf_process_record()
standard_files <- paste0("../", names(process$source_files))

start_time <- "2020"
data <- lapply(standard_files, function(file) {
  d <- vroom::vroom(file, show_col_types = FALSE)
  if ("age" %in% colnames(d)) {
    d <- d[d$age == "Total", ]
    d$age <- NULL
  }
  d[!is.na(d$time) & as.character(d$time) > start_time, ]
})

combined <- Reduce(
  function(a, b) merge(a, b, by = c("geography", "time"), all = TRUE),
  data
)
colnames(combined) <- sub("n_", "epic_", colnames(combined), fixed = TRUE)
arrow::write_parquet(combined, "dist/data.parquet")
