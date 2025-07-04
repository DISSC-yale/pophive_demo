#' Adds a source project structure
#'
#' Establishes a new data source project, used to collect and prepare data from a new source.
#'
#' @param name Name of the source.
#' @param base_dir Path to the directory containing sources.
#' @param open_after Logical; if \code{FALSE}, will not open the project.
#' @returns Nothing; creates default files and directories.
#' @section Project:
#'
#' Within a source project, there are two files to edits:
#' \itemize{
#'   \item \strong{\code{ingest.R}}: This is the primary script, which is automatically rerun.
#'     It should store raw data and resources in \code{raw/} where possible,
#'     then use what's in \code{raw/} to produce standard-format files in \code{standard/}.
#'     This file is sourced from its location during processing, so any system paths
#'     must be relative to itself.
#'   \item \strong{\code{measure_info.json}}: This is where you can record information
#'     about the variables included in the standardized data files.
#'     See \code{\link[community]{data_measure_info}}.
#' }
#'
#' @examples
#' data_source_dir <- tempdir()
#' pophive_add_source("source_name", data_source_dir)
#' list.files(paste0(data_source_dir, "/source_name"))
#'
#' @export

pophive_add_source <- function(
  name,
  base_dir = "data",
  open_after = interactive()
) {
  if (missing(name)) cli::cli_abort("specify a name")
  name <- gsub("[^A-Za-z0-9]+", "_", name)
  base_path <- paste0(base_dir, "/", name, "/")
  dir.create(base_path, showWarnings = FALSE, recursive = TRUE)
  dir.create(paste0(base_path, "raw"), showWarnings = FALSE, recursive = TRUE)
  dir.create(
    paste0(base_path, "standard"),
    showWarnings = FALSE,
    recursive = TRUE
  )
  paths <- paste0(
    base_path,
    c(
      "measure_info.json",
      "ingest.R",
      "project.Rproj",
      "standard/datapackage.json",
      "process.json",
      "README.md"
    )
  )
  if (!file.exists(paths[[1]])) {
    community::data_measure_info(
      paths[[1]],
      example_variable = list(),
      verbose = FALSE,
      open_after = FALSE
    )
  }
  if (!file.exists(paths[[2]])) {
    writeLines(
      paste0(
        c(
          "#",
          "# Download",
          "#",
          "",
          "# add files to the `raw` directory",
          "",
          "#",
          "# Reformat",
          "#",
          "",
          "# read from the `raw` directory, and write to the `standard` directory",
          ""
        ),
        collapse = "\n"
      ),
      paths[[2]]
    )
  }
  if (!file.exists(paths[[3]])) {
    writeLines("Version: 1.0\n", paths[[3]])
  }
  if (!file.exists(paths[[4]]))
    community::init_data(
      name,
      dir = paste0(base_path, "standard"),
      quiet = TRUE
    )

  if (!file.exists(paths[[5]]))
    jsonlite::write_json(
      list(
        name = name,
        scripts = list(
          list(
            path = "ingest.R",
            manual = FALSE,
            frequency = 0L,
            last_run = "",
            run_time = "",
            last_status = list(log = "", success = TRUE)
          )
        ),
        checked = "",
        check_results = list()
      ),
      paths[[5]],
      auto_unbox = TRUE,
      pretty = TRUE
    )
  if (!file.exists(paths[[6]])) {
    writeLines(
      paste0(
        c(
          paste("#", name),
          "",
          "This is a PopHIVE data source project, initialized with `pophive::pophive_add_source`.",
          "",
          "You can us the `pophive` package to check the project:",
          "",
          "```R",
          paste0('pophive_check_source("', name, '", "..")'),
          "```",
          "",
          "And process it:",
          "",
          "```R",
          paste0('pophive_process("', name, '", "..")'),
          "```"
        ),
        collapse = "\n"
      ),
      paths[[6]]
    )
  }
  if (open_after) rstudioapi::openProject(paths[[3]], newSession = TRUE)
}
