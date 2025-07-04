#' Check Data Sources
#'
#' Check the data files and measure info of source projects.
#'
#' @param names Name or names of source projects.
#' @param source_dir Path to the directory containing the source projects.
#' @param verbose Logical; if \code{FALSE}, will not print status messages.
#' @returns A list with an entry for each source, containing a character vector
#'   including any issue codes:
#' \itemize{
#'   \item \code{not_compressed}: The file does not appear to be compressed.
#'   \item \code{cant_read}: Failed to read the file in.
#'   \item \code{geography_missing}: File does not contain a \code{geography} column.
#'   \item \code{geography_nas}: The file's \code{geography} column contains NAs.
#'   \item \code{time_missing}: File does not contain a \code{time} column.
#'   \item \code{time_nas}: The file's \code{time} column contains NAs.
#'   \item \code{missing_info: {column_name}}: The file's indicated column does not have
#'     a matching entry in \code{measure_info.json}.
#' }
#' @examples
#' \dontrun{
#'   pophive_check_sources("gtrends")
#' }
#' @export

pophive_check_sources <- function(
  names = list.dirs("data", recursive = FALSE, full.names = FALSE),
  source_dir = "data",
  verbose = TRUE
) {
  issues <- list()
  for (name in names) {
    base_dir <- paste0(source_dir, "/", name, "/")
    if (!dir.exists(base_dir))
      cli::cli_abort("specify the name of an existing data source")
    process_file <- paste0(base_dir, "process.json")
    pophive_add_source(name, source_dir, FALSE)
    if (!file.exists(process_file)) {
      cli::cli_abort("{name} does not appear to be a data source project")
    }
    process <- pophive_source_process(process_file)
    info_file <- paste0(base_dir, "measure_info.json")
    info <- tryCatch(
      community::data_measure_info(
        info_file,
        render = TRUE,
        write = FALSE,
        verbose = FALSE,
        open_after = FALSE
      ),
      error = function(e) NULL
    )
    if (is.null(info)) cli::cli_abort("{.file {info_file}} is malformed")
    if (verbose)
      cli::cli_bullets(c("", "Checking data source {.strong {name}}"))
    data_files <- list.files(
      paste0(base_dir, "standard/"),
      "\\.(?:csv|parquet)",
      full.names = TRUE
    )
    source_issues <- list()
    for (file in list.files(
      paste0(base_dir, "raw/"),
      "csv$",
      full.names = TRUE
    )) {
      source_issues[[file]] <- list(data = "not_compressed")
    }
    if (length(data_files)) {
      for (file in data_files) {
        issue_messages <- NULL
        if (verbose) {
          cli::cli_progress_step("checking file {.file {file}}", spinner = TRUE)
        }
        data_issues <- NULL
        measure_issues <- NULL
        data <- tryCatch(
          if (grepl("parquet$", file))
            dplyr::collect(arrow::read_parquet(file)) else {
            con <- gzfile(file)
            on.exit(con)
            vroom::vroom(con, show_col_types = FALSE)
          },
          error = function(e) NULL
        )
        if (is.null(data)) {
          data_issues <- c(data_issues, "cant_read")
        } else {
          if (grepl("csv$", file)) {
            data_issues <- c(data_issues, "not_compressed")
            if (verbose)
              issue_messages <- c(
                issue_messages,
                "file is not compressed"
              )
          }
          if (!("geography" %in% colnames(data))) {
            data_issues <- c(data_issues, "geography_missing")
            if (verbose)
              issue_messages <- c(
                issue_messages,
                "missing {.emph geography} column"
              )
          } else if (anyNA(data$geography)) {
            data_issues <- c(data_issues, "geography_nas")
            if (verbose)
              issue_messages <- c(
                issue_messages,
                "{.emph geography} column contains NAs"
              )
          }
          if (!("time" %in% colnames(data))) {
            data_issues <- c(data_issues, "time_missing")
            if (verbose)
              issue_messages <- c(
                issue_messages,
                "missing {.emph time} column"
              )
          } else if (anyNA(data$time)) {
            data_issues <- c(data_issues, "time_nas")
            if (verbose)
              issue_messages <- c(
                issue_messages,
                "{.emph time} column contains NAs"
              )
          }
          for (col in colnames(data)) {
            if (!(col %in% c("geography", "time")) && !(col %in% names(info))) {
              measure_issues <- c(measure_issues, paste("missing_info:", col))
              if (verbose)
                issue_messages <- c(
                  issue_messages,
                  paste0(
                    "{.emph ",
                    col,
                    "} column does not have an entry in measure_info"
                  )
                )
            }
          }
        }
        file_issues <- list()
        if (length(data_issues)) file_issues$data <- data_issues
        if (length(measure_issues)) file_issues$measures <- measure_issues
        source_issues[[file]] <- file_issues
        if (verbose) {
          if (length(issue_messages)) {
            cli::cli_progress_done(result = "failed")
            cli::cli_bullets(structure(
              issue_messages,
              names = rep(" ", length(issue_messages))
            ))
          } else {
            cli::cli_progress_done()
          }
        }
      }
    } else {
      if (verbose) cli::cli_alert_info("no standard data files found to check")
    }
    if (!identical(process$check_results, source_issues)) {
      process$checked <- Sys.time()
      process$check_results <- source_issues
      pophive_source_process(process_file, process)
    }
    issues[[name]] <- source_issues
  }

  invisible(issues)
}
