#
# Download
#

dcf::dcf_download_wisqars(
  "raw/violence.csv.xz",
  intent = "violence",
  group_by = c("MECH", "AGEGP", "STATE", "YEAR")
)
dcf::dcf_download_wisqars(
  "raw/accident.csv.xz",
  intent = "unintentional",
  group_by = c("MECH", "AGEGP", "STATE", "YEAR")
)

#
# Reformat
#

raw_state <- as.list(tools::md5sum(list.files(
  "raw",
  "csv",
  full.names = TRUE
)))
process <- dcf::dcf_process_record()

# process raw if state has changed
if (!identical(process$raw_state, raw_state)) {
  violence <- vroom::vroom("raw/violence.csv.xz")
  accident <- vroom::vroom("raw/accident.csv.xz")

  violence$intent <- "violence"
  accident$intent <- "accident"

  data <- rbind(violence, accident) |>
    dplyr::mutate(
      age = agegp,
      geography = state,
      time = year,
      CrudeRate = as.numeric(sub("[*-]+", "", CrudeRate)),
      mechanism = paste(
        intent,
        tolower(gsub("[^A-za-z0-9]+", "_", Mechlbl)),
        sep = "_"
      )
    ) |>
    dplyr::group_by(mechanism) |>
    dplyr::filter(sum(!is.na(CrudeRate)) > 100, age != "Unknown") |>
    tidyr::pivot_wider(
      id_cols = c("geography", "time", "age"),
      names_prefix = "wisqars_",
      names_from = "mechanism",
      values_from = "CrudeRate"
    )

  vroom::vroom_write(data, "standard/data.csv.gz", ",")

  process$raw_state <- raw_state
  dcf::dcf_process_record(updated = process)
}
