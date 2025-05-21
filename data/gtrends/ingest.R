#
# Download
#

base_url <- "https://github.com/DISSC-yale/gtrends_collection/raw/refs/heads/main/data/term="
terms <- c("Naloxone", "overdose", "rsv", "%252Fg%252F11j30ybfx6")
for (term in terms) {
  term_dir <- paste0("raw/term=", term)
  dir.create(term_dir, showWarnings = FALSE)
  download.file(
    paste0(base_url, term, "/part-0.parquet"),
    paste0(term_dir, "/part-0.parquet"),
    mode = "wb"
  )
}

#
# Reformat
#

data <- dplyr::collect(dplyr::filter(
  arrow::open_dataset("raw"),
  grepl("US", location),
  date > 2014
))

# aggregate over repeated samples
data <- dplyr::summarize(
  dplyr::group_by(data, term, location, date),
  value = mean(value),
  .groups = "keep"
)
data$term <- paste0("gtrends_", tolower(data$term))
data$term[data$term == "gtrends_%2fg%2f11j30ybfx6"] <- "gtrends_rsv_vaccine"
data <- tidyr::pivot_wider(
  data,
  id_cols = c("location", "date"),
  names_from = "term"
)
colnames(data)[1L:2L] <- c("geography", "time")

# convert state abbreviations to GEOIDs
state_ids <- vroom::vroom(
  "https://www2.census.gov/geo/docs/reference/codes2020/national_state2020.txt",
  delim = "|",
  col_types = list(STATE = "c", STATEFP = "c")
)
data$geography <- structure(state_ids$STATEFP, names = state_ids$STATE)[sub(
  "US-",
  "",
  data$geography,
  fixed = TRUE
)]

vroom::vroom_write(data, "standard/data.csv.gz", ",")
