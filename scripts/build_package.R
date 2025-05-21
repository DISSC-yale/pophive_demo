# check and rebuild package
spelling::spell_check_package()
devtools::document()
pkgdown::build_site(lazy = TRUE)

devtools::check()
covr::report(covr::package_coverage(quiet = FALSE), "docs/coverage.html")

# update lock file if needed

## from ingestion files
extra <- unique(
  renv::dependencies(list.files(
    "data",
    "ingest\\.R",
    recursive = TRUE,
    full.names = TRUE
  ))$Package
)
not_installed <- !(extra %in% rownames(installed.packages()))
if (any(not_installed)) install.packages(extra[not_installed])
renv::snapshot(packages = extra, update = TRUE)

## from the package
renv::snapshot(type = "explicit", update = TRUE)
