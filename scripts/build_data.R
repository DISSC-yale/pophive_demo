library(pophive)

process <- pophive_process()
issues <- pophive_check_sources()
datapackages <- list.files(
  "data",
  "datapackage\\.json",
  recursive = TRUE,
  full.names = TRUE
)
names(datapackages) <- list.dirs("data", recursive = FALSE, full.names = FALSE)

report <- list(
  date = Sys.time(),
  repo = "dissc-yale/pophive_demo",
  source_times = process$timings,
  logs = process$logs,
  issues = issues,
  metadata = lapply(datapackages, jsonlite::read_json)
)
jsonlite::write_json(
  report,
  gzfile("report_site/public/report.json.gz"),
  auto_unbox = TRUE,
  dataframe = "columns"
)
unlink("docs/report/report.json.gz")
file.copy("report_site/public/report.json.gz", "docs/report/report.json.gz")
