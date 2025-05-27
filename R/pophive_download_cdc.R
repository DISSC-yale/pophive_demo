#' Download Data from the CDC
#'
#' Download data and metadata from the Centers for Disease Control and Prevention (CDC).
#'
#' @param id ID of the resource (e.g., \code{ijqb-a7ye}).
#' @param out_dir Directory in which to save the metadata and data files.
#' @param verbose Logical; if \code{FALSE}, will not display status messages.
#' @returns Nothing; downloads files (\code{<id>.json} and \code{<id>.csv.xz}) to \code{out_dir}
#' @section \code{data.cdc.gov} URLs:
#'
#' For each resource ID, there are 3 relevant CDC URLs:
#' \itemize{
#'   \item \strong{\code{resource/<id>}}: This redirects to the resource's main page,
#'     with displayed metadata and a data preview
#'     (e.g., \code{\href{https://data.cdc.gov/resource/ijqb-a7ye}{data.cdc.gov/resource/ijqb-a7ye}}).
#'   \item \strong{\code{api/views/<id>}}: This is a direct link to the underlying
#'     JSON metadata (e.g., \code{\href{https://data.cdc.gov/api/views/ijqb-a7ye}{data.cdc.gov/api/views/ijqb-a7ye}}).
#'   \item \strong{\code{api/views/<id>/rows.csv}}: This is a direct link to the full
#'     CSV dataset (e.g., \code{\href{https://data.cdc.gov/api/views/ijqb-a7ye/rows.csv}{data.cdc.gov/api/views/ijqb-a7ye/rows.csv}}).
#' }
#'
#' @examples
#' \dontrun{
#'   pophive_download_cdc("ijqb-a7ye")
#' }
#' @export

pophive_download_cdc <- function(id, out_dir = "raw", verbose = TRUE) {
  initial_timeout <- options(timeout = 99999)$timeout
  on.exit(options(timeout = initial_timeout))
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
  if (verbose) {
    resource_url <- paste0("https://data.cdc.gov/resource/", id)
    cli::cli_h1(
      "downloading resource {.url {resource_url}}"
    )
  }
  url <- paste0("https://data.cdc.gov/api/views/", id)
  if (verbose) cli::cli_progress_step("metadata: {.url {url}}")
  status <- utils::download.file(
    url,
    paste0(out_dir, "/", id, ".json"),
    quiet = TRUE
  )
  if (status != 0L) cli::cli_abort("failed to download metadata")

  data_url <- paste0(url, "/rows.csv")
  out_path <- paste0(out_dir, "/", id, ".csv")
  if (verbose) cli::cli_progress_step("data: {.url {data_url}}")
  status <- utils::download.file(data_url, out_path, quiet = TRUE)
  if (status != 0L) cli::cli_abort("failed to download data")
  if (verbose) cli::cli_progress_step("compressing data")
  unlink(paste0(out_path, ".xz"))
  status <- system2("xz", c("-f", out_path))
  if (status != 0L) cli::cli_abort("failed to compress data")
  if (verbose) cli::cli_progress_done()
}
