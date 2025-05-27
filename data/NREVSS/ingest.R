#
# Download
#

pophive_download_cdc("3cxc-4k8q")

#
# Reformat
#

data <- vroom::vroom("raw/3cxc-4k8q.csv.xz", show_col_types = FALSE)

data$posted <- as.Date(data$posted, "%m/%d/%Y")
data <- data[data$level != "National" & data$posted == max(data$posted), ]
data$geography <- sub("Region ", "hhs_", data$level, fixed = TRUE)
data$time <- as.Date(data$mmwrweek_end, "%m/%d/%Y")
data$nrevss <- data$pcr_detections

report_time <- MMWRweek::MMWRweek(as.Date(data$mmwrweek_end, "%m/%d/%Y"))
data$nrevss_week <- report_time$MMWRweek

vroom::vroom_write(
  data[, c("geography", "time", "nrevss_week", "nrevss")],
  "standard/data.csv.gz",
  ","
)
