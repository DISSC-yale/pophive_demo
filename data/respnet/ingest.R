library(dcf)
library(tidyverse)


process <- dcf::dcf_process_record()

all_fips <- vroom::vroom('../../resources/all_fips.csv.gz')

#RSV only
raw_state_rsv <- dcf::dcf_download_cdc(
  "29hc-w46k",
  "raw",
  process$raw_state_rsv
)


#covid only
raw_state_covid <- dcf::dcf_download_cdc(
  "6jg4-xsqq",
  "raw",
  process$raw_state_covid
)


raw_state <- paste0( raw_state_rsv, raw_state_covid)

if (!identical(process$raw_state, raw_state)) {
  
  data1 <- vroom::vroom('./raw/29hc-w46k.csv.xz')%>%
    filter(Type=='Crude Rate' & Sex=='All' & Race == 'All') %>%
    rename(time = `Week ending date`,
           respnet_rate_rsv = Rate
           ) %>%
    mutate( State = if_else(State=='RSV-NET', 'United States',State )
            ) %>%
    left_join(all_fips, by=c('State'='geography_name')) %>%
    dplyr::select(geography, time, respnet_rate_rsv) 
  
  data2 <- vroom::vroom('./raw/6jg4-xsqq.csv.xz') %>%
    filter(Type=='Crude Rate' & Sex_Label=='All' & Race_Label == 'All' & AgeCategory_Legend == 'All') %>%
    rename(time = `_WeekendDate`,
           respnet_rate_covid = WeeklyRate
    ) %>%
    mutate( State = if_else(State=='COVID-NET', 'United States',State )
    ) %>%
    left_join(all_fips, by=c('State'='geography_name')) %>%
    dplyr::select(geography, time, respnet_rate_covid) 
    
  data_all <- full_join(data1, data2)

  #Write standard data
  vroom::vroom_write(
    data_all,
    "standard/data.csv.gz",
    ","
  )
  
  process$raw_state_rsv <- raw_state_rsv
  process$raw_state_covid <- raw_state_covid
  dcf::dcf_process_record(updated = process)
  
}