#' Interact with a Source Process File
#'
#' Read or update the current source process file.
#'
#' @param path Path to the process JSON file.
#' @param updated An update version of the process definition. If specified, will
#' write this as the new process file, rather than reading any existing file.
#' @returns The process definition of the source project.
#' @examples
#' epic_process_file <- "../../epic/process.json"
#' if (file.exists(epic_process_file)) {
#'   pophive_source_process(path = epic_process_file)
#' }
#' @export

pophive_source_process <- function(path = "process.json", updated = NULL) {
  if (is.null(updated)) {
    if (!file.exists(path)) cli::cli_abort("process file {path} does not exist")
    jsonlite::read_json(path)
  } else {
    jsonlite::write_json(updated, path, auto_unbox = TRUE, pretty = TRUE)
    updated
  }
}
