#' Run Data Sources
#'
#' Optionally run the ingestion script for each data source, and collect metadata.
#'
#' @param name Name of a source project to process. Will
#' @param source_dir Path to the directory containing source projects.
#' @param ingest Logical; if \code{FALSE}, will re-process standardized data without running
#' ingestion scripts.
#' @returns A list with processing results:
#' \itemize{
#'   \item \code{timings}: How many seconds the ingestion script took to run.
#'   \item \code{logs}: The captured output of the ingestion script.
#' }
#' Each entry has an entry for each source.
#'
#' A `datapackage.json` file is also created / update in each source's `standard` directory.
#' @examples
#' \dontrun{
#'   # run from a directory containing a `data` directory containing the source
#'   pophive_process("source_name")
#'
#'   # run without executing the ingestion script
#'   pophive_process("source_name", ingest = FALSE)
#' }
#' @export

pophive_process <- function(
  name = NULL,
  source_dir = "data",
  ingest = TRUE
) {
  sources <- if (is.null(name)) {
    list.files(
      source_dir,
      "ingest\\.R",
      recursive = TRUE,
      full.names = TRUE
    )
  } else {
    ingest_files <- paste0(source_dir, "/", name, "/ingest.R")
    if (any(!file.exists(ingest_files))) {
      cli::cli_abort(
        "missing ingest file{?/s}: {.emph {ingest_files[!file.exists(ingest_files)]}}"
      )
    }
    ingest_files
  }
  timings <- list()
  logs <- list()
  for (s in sources) {
    st <- proc.time()[[3]]
    base_dir <- dirname(s)
    name <- basename(base_dir)
    file_ref <- if (ingest) paste0(" ({.file ", s, "})") else NULL
    cli::cli_progress_step(
      paste0("processing {.strong ", name, "}", file_ref),
      msg_failed = paste0("failed to process {.strong ", name, "}", file_ref),
      spinner = TRUE
    )
    status <- if (ingest) {
      tryCatch(
        list(
          log = utils::capture.output(
            source(s, chdir = TRUE),
            type = "message"
          ),
          success = TRUE
        ),
        error = function(e) list(log = e$message, success = FALSE)
      )
    } else list(log = "", success = TRUE)
    logs[[name]] <- status$log
    if (status$success) timings[[name]] <- proc.time()[[3]] - st
    data_files <- list.files(
      paste0(base_dir, "/standard"),
      "\\.(?:csv|parquet)"
    )
    if (length(data_files)) {
      measure_info <- community::data_measure_info(
        paste0(base_dir, "/measure_info.json"),
        include_empty = FALSE,
        render = TRUE,
        write = FALSE,
        open_after = FALSE,
        verbose = FALSE
      )
      measure_sources <- list()
      for (info in measure_info) {
        for (s in info$sources) {
          if (
            !is.null(s$location) &&
              !(s$location %in% names(sources))
          ) {
            measure_sources[[s$location]] <- s
          }
        }
      }
      community::data_add(
        data_files,
        meta = list(
          source = unname(measure_sources),
          ids = "geography",
          time = "time",
          variables = measure_info
        ),
        dir = paste0(base_dir, "/standard"),
        pretty = TRUE,
        summarize_ids = TRUE,
        verbose = FALSE
      )
      cli::cli_progress_done(result = if (status$success) "done" else "failed")
    } else {
      cli::cli_progress_update(
        "no standard data files found in {.path {s}}"
      )
      cli::cli_progress_done(result = "failed")
    }
  }
  invisible(list(timings = timings, logs = logs))
}
