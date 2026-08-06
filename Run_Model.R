
### Injest run name and run model

# Rscript Run_Model.R Run_Name
start_time <- Sys.time()
library(magrittr)
library(data.table)
library(lubridate)

conflicted::conflicts_prefer(lubridate::yday)
conflicted::conflicts_prefer(lubridate::ymd)


#args = "SQ"

args <- commandArgs(trailingOnly = TRUE)

saved_regs<- read.csv(here::here(paste0("saved_regs/regs_", args[1], ".csv")))


## Massachusetts
if(any(grepl("ma", saved_regs$input))){
  
  save_regs <- saved_regs %>%
    dplyr::filter(grepl("ma", saved_regs$input))
  
  run_state_model(Run_Name, state = "ma")
}

## Rhode Island
if(any(grepl("ri", saved_regs$input))){
  
  save_regs <- saved_regs %>%
    dplyr::filter(grepl("ri", saved_regs$input))
  
  run_state_model(Run_Name, state = "ri")
}

## Connecticut
if(any(grepl("ct", saved_regs$input))){
  
  save_regs <- saved_regs %>%
    dplyr::filter(grepl("ct", saved_regs$input))
  
  run_state_model(Run_Name, state = "ct")
}

## New York
if(any(grepl("ny", saved_regs$input))){
  
  save_regs <- saved_regs %>%
    dplyr::filter(grepl("ny", saved_regs$input))
  
  run_state_model(Run_Name, state = "ny")
}

## New Jersey
if(any(grepl("nj", saved_regs$input))){
  
  save_regs <- saved_regs %>%
    dplyr::filter(grepl("nj", saved_regs$input))
  
  run_state_model(Run_Name, state = "nj")
}

## Deleware
if(any(grepl("de", saved_regs$input))){
  
  save_regs <- saved_regs %>%
    dplyr::filter(grepl("de", saved_regs$input))
  
  run_state_model(Run_Name, state = "de")
}

## Maryland
if(any(grepl("md", saved_regs$input))){
  
  save_regs <- saved_regs %>%
    dplyr::filter(grepl("md", saved_regs$input))
  
  run_state_model(Run_Name, state = "md")
}

## Virginia
if(any(grepl("va", saved_regs$input))){
  
  save_regs <- saved_regs %>%
    dplyr::filter(grepl("va", saved_regs$input))
  
  run_state_model(Run_Name, state = "va")
}

# North Carolina
if(any(grepl("nc", saved_regs$input))){

  save_regs <- saved_regs %>%
    dplyr::filter(grepl("nc", saved_regs$input))

  run_state_model(Run_Name, state = "nc")
}


end_time <- Sys.time()

print(end_time - start_time)

