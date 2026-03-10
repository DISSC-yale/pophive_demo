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

common_cols <- c("geography", "time", "epic_all_encounters")

flu <- tidyr::pivot_longer(
  combined[, c(
    common_cols,
    grep("flu", colnames(combined), fixed = TRUE, value = TRUE)
  )],
  !geography & !time,
  names_to = "measure",
  values_drop_na = TRUE
) |>
  dplyr::group_by(measure) |>
  dplyr::mutate(
    value_scaled = value - min(value, na.rm = TRUE),
    value_scaled = value_scaled / max(value_scaled, na.rm = TRUE) * 100
  )
arrow::write_parquet(flu, "dist/flu.parquet")

rsv <- tidyr::pivot_longer(
  combined[, c(
    common_cols,
    grep("rsv", colnames(combined), fixed = TRUE, value = TRUE)
  )],
  !geography & !time,
  names_to = "measure",
  values_drop_na = TRUE
) |>
  dplyr::group_by(measure) |>
  dplyr::mutate(
    value_scaled = value - min(value, na.rm = TRUE),
    value_scaled = value_scaled / max(value_scaled, na.rm = TRUE) * 100
  )
arrow::write_parquet(rsv, "dist/rsv.parquet")
