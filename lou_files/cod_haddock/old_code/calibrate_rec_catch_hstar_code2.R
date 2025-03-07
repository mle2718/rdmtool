

MRIP_data2<- readRDS(paste0(input_data_cd, "MRIP_simulated_data.rds")) %>% 
     dplyr::filter(mrip_index==i)



select_mode = unique(MRIP_data2$mode)
select_season = unique(MRIP_data2$open)

MRIP_stats<-MRIP_data2 %>% 
  dplyr::rename(tot_cod_catch_mrip=tot_cod_catch, 
                tot_cod_keep_mrip= tot_cod_keep, 
                tot_cod_rel_mrip=tot_cod_rel, 
                tot_hadd_catch_mrip=tot_hadd_catch, 
                tot_hadd_keep_mrip=tot_hadd_keep, 
                tot_hadd_rel_mrip=tot_hadd_rel, 
                dtrip_mrip=dtrip) 

k<- MRIP_data2$draw

n_drawz = 50
n_catch_draws = 30
set.seed(k)


directed_trips<-read.csv(directed_trips_file_path) %>%
  tibble::tibble() %>%
  dplyr::filter(draw == k,
                mode == select_mode) %>%
  dplyr::mutate(open = dplyr::case_when(cod_bag > 0 ~ 1, TRUE ~ 0))



#Create as an object the minimum size at which fish are illegally harvested.
#1) This floor_subl_harvest size will be 2 inches below the minimum size, by mode. 
#1a) If the minimum size changes across the season, floor_subl_harvest=min(min_size). 
#2) If the fishery is closed the entire season, floor_subl_harvest=mean(catch_length)-0.5*sd(catch_length). 
#1) and #1a) below:

floor_subl_cod_harv<-min(directed_trips$cod_min)-2*2.54
floor_subl_hadd_harv<-min(directed_trips$hadd_min)-2*2.54

#floor_subl_cod_harv<-min(directed_trips$cod_min)-2
#floor_subl_hadd_harv<-min(directed_trips$hadd_min)-2

open<- directed_trips %>%
  dplyr::mutate(day = as.numeric(stringr::str_extract(day, '\\d{2}')),
                period2 = paste0(month, "_", day, "_", mode)) %>%
  dplyr::select(period2, open) %>%
  dplyr::filter(open == select_season)

directed_trips<- directed_trips %>%
  dplyr::mutate(day = as.numeric(stringr::str_extract(day, '\\d{2}')),
                period2 = paste0(month, "_", day, "_", mode)) %>%
  dplyr::filter(open == select_season)


######################################
##   Begin simulating trip outcomes ##
######################################

# Set up an output file for the separately simulated within-season regulatory periods
directed_trips_p <- directed_trips %>%
  dplyr::mutate(month = as.numeric(month)) %>%
  dplyr::mutate(n_draws = n_drawz)%>%
  dplyr::select(!c(month, mode))

regs <- directed_trips_p %>%
  dplyr::select(period2,
                cod_bag,
                cod_min,
                hadd_bag,
                hadd_min)

param_draws <- directed_trips_p %>%
  dplyr::select(period2, n_draws, open) %>%
  tidyr::uncount(n_draws) 


cod_catch_data <- feather::read_feather(paste0(iterative_input_data_cd, "catch_draws", k, "_full.feather")) %>%  
  dplyr::mutate(period2=paste0(month, "_", day1, "_", mode)) %>%  
  dplyr::left_join(open, by = "period2") %>%
  dplyr::filter(open == select_season) %>%
  dplyr::select(!open, !day) %>%
  dplyr::rename(tot_cod_catch = cod_catch,
                tot_had_catch = hadd_catch)  %>%
  dplyr::select(mode,month,tot_cod_catch,tot_had_catch,
                tripid,catch_draw,day, draw, age, days_fished, cost, period2)


trip_costs<-cod_catch_data  %>%
  dplyr::filter(mode == select_mode) %>%
  dplyr::select(cost)

age<-cod_catch_data  %>%
  dplyr::filter(mode == select_mode) %>%
  dplyr::select(age)

avidity<-cod_catch_data  %>%
  dplyr::filter(mode == select_mode) %>%
  dplyr::select(days_fished)

cod_catch_data <- cod_catch_data %>%
  dplyr::mutate(day = as.numeric(stringr::str_extract(day, "\\d+"))) %>%
  dplyr::group_by(period2) %>%
  dplyr::slice_sample(n = n_drawz*n_catch_draws, replace = TRUE)   %>%
  dplyr::mutate(#period = rep(period_vec$period2, each = nsamp),
    catch_draw = rep(1:n_catch_draws, length.out = n_drawz*n_catch_draws),
    tripid = rep(1:n_drawz, each=n_catch_draws)) %>%
  dplyr::ungroup()%>%
  dplyr::select(!c(age, days_fished, cost))%>%
  dplyr::select(!c(month))


if(select_season == 1){
  seas = "open"
}
if(select_season == 0){
  seas = "closed"
}

cod_size_data <- size_data_read %>% 
  dplyr::filter(species == "cod", season == seas) %>% 
  dplyr::filter(!is.na(fitted_prob)) %>% 
  dplyr::select(-observed_prob,-sum_nfish_catch, -nfish_catch_from_fitted, -nfish_catch_from_raw, -domain)

had_size_data <- size_data_read %>% 
  dplyr::filter(species == "hadd", season == seas) %>% 
  dplyr::filter(!is.na(fitted_prob)) %>% 
  dplyr::select(-observed_prob,-sum_nfish_catch, -nfish_catch_from_fitted, -nfish_catch_from_raw, -domain)


cod_had_catch_data <- cod_catch_data


# subset trips with zero catch, as no size draws are required
cod_zero_catch <- dplyr::filter(cod_catch_data, tot_cod_catch == 0)


#Check to see if there is no catch for either species and if so, pipe code around keep/release determination
cod_catch_check<-base::sum(cod_catch_data$tot_cod_catch)
had_catch_check<-base::sum(cod_catch_data$tot_had_catch)


if(cod_catch_check ==0 & had_catch_check==0){
  trip_data<-cod_catch_data
  trip_data<- trip_data %>% 
    dplyr::mutate(domain2 = paste0(period2, "_", catch_draw, "_", tripid)) %>% 
    dplyr::select(-mode)
  
  
  trip_data$tot_keep_cod_new<-0
  trip_data$tot_rel_cod_new<-0
  
  
  trip_data$tot_keep_hadd_new<-0
  trip_data$tot_rel_hadd_new<-0
}


if(cod_catch_check !=0){
  
  #keep trips with positive cod catch
  cod_catch_data <- dplyr::filter(cod_catch_data, tot_cod_catch > 0)
  
  row_inds <- seq_len(nrow(cod_catch_data))
  
  cod_catch_data<-cod_catch_data %>%
    dplyr::slice(rep(row_inds,tot_cod_catch))   %>%
    dplyr::mutate(fishid=dplyr::row_number())
  
  # generate lengths for each fish
  catch_size_data <- cod_catch_data %>%
    dplyr::mutate(fitted_length = sample(cod_size_data$length,
                                         nrow(.),
                                         prob = cod_size_data$fitted_prob,
                                         replace = TRUE)) 
  
  
  
  #Create as an object the minimum size at which fish are illegally harvested.
  #1) This floor_subl_harvest size will be 2 inches below the minimum size, by mode. 
  #1a) If the minimum size changes across the season, floor_subl_harvest=min(min_size). 
  #2) If the fishery is closed the entire season, floor_subl_harvest=mean(catch_length)-0.5*sd(catch_length). 
  #2) below:
  if (floor_subl_cod_harv>=248){

    floor_subl_cod_harv=mean(catch_size_data$fitted_length)-0.5*sd(catch_size_data$fitted_length)

  }
  

  
  # if (floor_subl_cod_harv==98){
  #   
  #   floor_subl_cod_harv=mean(catch_size_data$fitted_length)-0.5*sd(catch_size_data$fitted_length)
  #   
  # }
  
  
  # Impose regulations, calculate keep and release per trip
  # For summer flounder, retain keep- and release-at-length
  ####### Start Here #################
  
  ############# Length #####################################
  catch_size_data <- catch_size_data %>%
    dplyr::left_join(regs, by = c("period2")) %>%
    dplyr::mutate(posskeep = ifelse(fitted_length>=cod_min ,1,0)) %>%
    dplyr::group_by(tripid, period2, catch_draw) %>%
    dplyr::mutate(csum_keep = cumsum(posskeep)) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(
      keep_adj = dplyr::case_when(
        cod_bag > 0 ~ ifelse(csum_keep<=cod_bag & posskeep==1,1,0),
        TRUE ~ 0))
  
  
  catch_size_data <- catch_size_data %>%
    dplyr::mutate_if(is.numeric, tidyr::replace_na, replace = 0)
  
  catch_size_data <- catch_size_data %>%
    dplyr::mutate(keep = keep_adj,
                  release = ifelse(keep==0,1,0))
  
  catch_size_data<- catch_size_data %>%
    dplyr::select(fishid, fitted_length, tripid, keep, release, period2, catch_draw, mode)  %>%
    dplyr::rename(mode1=mode) %>% 
    dplyr::mutate(floor_subl_cod_harv_indicator=case_when(release==1 & fitted_length>=floor_subl_cod_harv~1,TRUE~0))
  
  #length data 
  new_size_data <- catch_size_data %>%
    dplyr::group_by(period2, catch_draw, tripid, fitted_length) %>%
    dplyr::summarize(keep = sum(keep),
                     release = sum(release), .groups = "drop") %>%
    dplyr::ungroup()
  
  keep_size_data <- new_size_data %>%
    dplyr::select(-release) %>%
    tidyr::pivot_wider(names_from = fitted_length, #_length,
                       names_glue = "keep_cod_{fitted_length}",
                       names_sort = TRUE,
                       values_from = keep,
                       values_fill = 0)
  
  release_size_data <- new_size_data %>%
    dplyr::select(-keep) %>%
    tidyr::pivot_wider(names_from = fitted_length, #_length,
                       names_glue = "release_cod_{fitted_length}",
                       names_sort = TRUE,
                       values_from = release,
                       values_fill = 0)
  
  keep_release_cod <- keep_size_data %>%
    dplyr::left_join(release_size_data, by = c("period2",  "tripid", "catch_draw"))
  
  
  
  #trip data 
  trip_data <- catch_size_data %>%
    dplyr::group_by(period2, catch_draw, tripid) %>% 
    dplyr::summarize(tot_keep_cod_new = sum(keep),
                     tot_rel_cod_new = sum(release),
                     floor_subl_cod_harv_indicator=sum(floor_subl_cod_harv_indicator),
                     .groups = "drop") %>%
    dplyr::ungroup()
  
  
  cod_zero_catch<-cod_zero_catch %>%
    dplyr::select(tripid, catch_draw, period2) %>%
    dplyr::mutate(tot_keep_cod_new=0,
                  tot_rel_cod_new=0)
  
  trip_data <- dplyr::bind_rows(trip_data, cod_zero_catch) %>%
    dplyr::mutate_if(is.numeric, tidyr::replace_na, replace = 0) %>%
    dplyr::select(c("period2", "catch_draw","tripid",
                    "tot_keep_cod_new","tot_rel_cod_new", "floor_subl_cod_harv_indicator"))
  
  
  trip_data<- trip_data %>% dplyr::mutate(domain2 = paste0(period2, "_", catch_draw, "_", tripid))
  trip_data<-data.table::as.data.table(trip_data)
  data.table::setkey(trip_data, "domain2")
}


if (cod_catch_check==0 & had_catch_check!=0){
  trip_data<-cod_catch_data
  trip_data<- trip_data %>% 
    dplyr::mutate(domain2 = paste0(period2, "_", catch_draw, "_", tripid)) %>% 
    dplyr::select(-mode) %>% 
    as.data.table()
  
  data.table::setkey(trip_data, "domain2")
  
  trip_data$tot_keep_cod_new<-0
  trip_data$tot_rel_cod_new<-0
}

#########################
###  Haddock  ####
#########################


if (had_catch_check!=0){
  # subset trips with zero catch, as no size draws are required
  had_zero_catch <- dplyr::filter(cod_had_catch_data, tot_had_catch == 0)
  
  #keep trips with positive catch
  had_catch_data <- dplyr::filter(cod_had_catch_data, tot_had_catch > 0)
  
  #expand the sf_catch_data so that each row represents a fish
  row_inds <- seq_len(nrow(had_catch_data))
  
  had_catch_data<- had_catch_data %>%
    dplyr::slice(rep(row_inds,tot_had_catch))
  
  rownames(had_catch_data) <- NULL
  had_catch_data$fishid <- 1:nrow(had_catch_data)
  
  # # generate lengths for each fish
  catch_size_data_had <- had_catch_data %>%
    dplyr::mutate(fitted_length = sample(had_size_data$length,
                                         nrow(.),
                                         prob = had_size_data$fitted_prob,
                                         replace = TRUE)) #%>%    dplyr::arrange(period2, tripid, catch_draw)
  
  
  #Create as an object the minimum size at which fish are illegally harvested.
  #1) This floor_subl_harvest size will be 2 inches below the minimum size, by mode. 
  #1a) If the minimum size changes across the season, floor_subl_harvest=min(min_size). 
  #2) If the fishery is closed the entire season, floor_subl_harvest=mean(catch_length)-0.5*sd(catch_length). 
  #2) below:
  if (floor_subl_hadd_harv>=248){

    floor_subl_hadd_harv=mean(catch_size_data_had$fitted_length)-0.5*sd(catch_size_data_had$fitted_length)

  }

  
  # Impose regulations, calculate keep and release per trip
  # For summer flounder, retain keep- and release-at-length
  ####### Start Here #################
  
  ############# Length #####################################
  catch_size_data_had <- catch_size_data_had %>%
    dplyr::left_join(regs, by = c("period2")) %>%
    dplyr::mutate(posskeep = ifelse(fitted_length>=hadd_min ,1,0)) %>%
    dplyr::group_by(tripid, period2, catch_draw) %>%
    dplyr::mutate(csum_keep = cumsum(posskeep)) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(
      keep_adj = dplyr::case_when(
        hadd_bag > 0 ~ ifelse(csum_keep<=hadd_bag & posskeep==1,1,0),
        TRUE ~ 0))
  
  
  catch_size_data_had <- catch_size_data_had %>%
    dplyr::mutate_if(is.numeric, tidyr::replace_na, replace = 0)
  
  catch_size_data_had <- catch_size_data_had %>%
    dplyr::mutate(keep = keep_adj,
                  release = ifelse(keep==0,1,0))
  
  catch_size_data_had<- catch_size_data_had %>%
    dplyr::select(fishid, fitted_length, tripid, keep, release, period2, catch_draw, mode)  %>%
    dplyr::rename(mode1=mode) %>% 
    dplyr::mutate(floor_subl_hadd_harv_indicator=case_when(release==1 & fitted_length>=floor_subl_hadd_harv~1,TRUE~0))
  
  
  #length data
  new_size_data <- catch_size_data_had %>%
    dplyr::group_by(period2, catch_draw, tripid, fitted_length) %>%
    dplyr::summarize(keep = sum(keep),
                     release = sum(release), .groups = "drop") %>%
    dplyr::ungroup()
  
  keep_size_data <- new_size_data %>%
    dplyr::select(-release) %>%
    tidyr::pivot_wider(names_from = fitted_length, #_length,
                       names_glue = "keep_had_{fitted_length}",
                       names_sort = TRUE,
                       values_from = keep,
                       values_fill = 0)
  
  release_size_data <- new_size_data %>%
    dplyr::select(-keep) %>%
    tidyr::pivot_wider(names_from = fitted_length, #_length,
                       names_glue = "release_had_{fitted_length}",
                       names_sort = TRUE,
                       values_from = release,
                       values_fill = 0)
  
  keep_release_hadd <- keep_size_data %>%
    dplyr::left_join(release_size_data, by = c("period2",  "tripid", "catch_draw"))
  
  
  #trip data
  trip_data_hadd <- catch_size_data_had %>%
    dplyr::group_by(period2, catch_draw, tripid) %>% 
    dplyr::summarize(tot_keep_hadd_new = sum(keep),
                     tot_rel_hadd_new = sum(release),
                     floor_subl_hadd_harv_indicator=sum(floor_subl_hadd_harv_indicator), 
                     .groups = "drop") %>%
    dplyr::ungroup()
  
  
  had_zero_catch<-had_zero_catch %>%
    dplyr::select(tripid, catch_draw, period2) %>%
    dplyr::mutate(tot_keep_hadd_new=0,
                  tot_rel_hadd_new=0)
  
  trip_data_hadd <- dplyr::bind_rows(trip_data_hadd, had_zero_catch) %>%
    dplyr::mutate_if(is.numeric, tidyr::replace_na, replace = 0) %>%
    dplyr::select(c("period2", "catch_draw","tripid",
                    "tot_keep_hadd_new","tot_rel_hadd_new", "floor_subl_hadd_harv_indicator"))
  
  
  trip_data_hadd<- trip_data_hadd %>% dplyr::mutate(domain2 = paste0(period2, "_", catch_draw, "_", tripid)) %>% 
    dplyr::select(-period2, -catch_draw, -tripid)
  trip_data_hadd<-data.table::as.data.table(trip_data_hadd)
  data.table::setkey(trip_data_hadd, "domain2")
  
  # merge the bsb trip data with the rest of the trip data
  #trip_data <-  merge(trip_data,trip_data_bsb,by=c("period2", "catch_draw", "tripid", "state", "mode", "month" ))
  trip_data<-trip_data[trip_data_hadd, on = "domain2"]
  
}


if (had_catch_check==0 & cod_catch_check!=0){
  trip_data_hadd<-cod_had_catch_data  %>% 
    dplyr::mutate(domain2 = paste0(period2, "_", catch_draw, "_", tripid)) %>% 
    dplyr::select(-mode, -period2, -catch_draw, -tripid) %>% 
    as.data.table()
  
  data.table::setkey(trip_data_hadd, "domain2")
  
  trip_data_hadd$tot_keep_hadd_new<-0
  trip_data_hadd$tot_rel_hadd_new<-0
  
  trip_data<-trip_data[trip_data_hadd, on = "domain2"]
  
  
}



# period_vec1 <- param_draws %>%
#   dplyr::mutate(beta_sqrt_cod_keep = rnorm(nrow(param_draws), mean = 1.594, sd = .615),
#                 beta_sqrt_cod_release = rnorm(nrow(param_draws), mean = 0.162 , sd = 0.445),
#                 beta_sqrt_hadd_keep = rnorm(nrow(param_draws), mean = 1.156, sd = 0.603 ),
#                 beta_sqrt_hadd_release = rnorm(nrow(param_draws), mean = 0.094 , sd = 0 ),
#                 beta_sqrt_cod_hadd_keep = rnorm(nrow(param_draws), mean =-0.314  , sd = 0.778 ),
#                 beta_cost = rnorm(nrow(param_draws), mean =-0.015 , sd =0 ),
#                 beta_opt_out = rnorm(nrow(param_draws), mean =-1.871 , sd = 3.208 ),
#                 beta_opt_out_age = rnorm(nrow(param_draws), mean =0.047 , sd = 0 ),
#                 beta_opt_out_likely = rnorm(nrow(param_draws), mean =-1.272 , sd = 0 ),
#                 beta_opt_out_prefer = rnorm(nrow(param_draws), mean =-1.079 , sd = 0 ))%>%
#   dplyr::group_by(period2) %>% dplyr::mutate(tripid = dplyr::row_number(period2))



##Utility parameters Table 9 from Carr-Harris and Steinback */

period_vec1 <- param_draws %>%
  dplyr::mutate(beta_sqrt_cod_keep = rnorm(nrow(param_draws), mean =0.957, sd = 1.092),
                beta_sqrt_cod_release = rnorm(nrow(param_draws), mean = 0.168 , sd = 0.409),
                beta_sqrt_hadd_keep = rnorm(nrow(param_draws), mean = 0.703, sd = 1.014 ),
                beta_sqrt_hadd_release = rnorm(nrow(param_draws), mean = 0.083 , sd = 0 ),
                #beta_sqrt_cod_hadd_keep = rnorm(nrow(param_draws), mean =-0.314  , sd = 0.778 ),
                beta_cost = rnorm(nrow(param_draws), mean =-0.015 , sd =0 ),
                beta_opt_out = rnorm(nrow(param_draws), mean =-2.427 , sd = 3.155 ),
                beta_opt_out_age = rnorm(nrow(param_draws), mean =0.037 , sd = 0 ),
                beta_opt_out_likely = rnorm(nrow(param_draws), mean =-1.453 , sd = 0 ),
                beta_opt_out_prefer = rnorm(nrow(param_draws), mean =-0.901 , sd = 0 ))%>%
  dplyr::group_by(period2) %>% dplyr::mutate(tripid = dplyr::row_number(period2))


trip_data<- trip_data %>% as.data.frame() 



if (cod_catch_check!=0){
  
  #If we need to re-allocate cod releases as harvest, cod_release_2_keep will equal 1 
  if (cod_release_2_keep==1){

  trip_data_cod_hstar<-trip_data %>% 
    dplyr::select(period2, tripid, catch_draw, tot_keep_cod_new, tot_rel_cod_new, floor_subl_cod_harv_indicator) %>% 
    dplyr::group_by(period2, tripid) %>% 
    dplyr::summarise(sum_floor_subl_cod_harv_indicator=sum(floor_subl_cod_harv_indicator), .groups='drop') %>% 
    dplyr::filter(sum_floor_subl_cod_harv_indicator>0) 
  

  n_row_cod_hstar<-nrow(trip_data_cod_hstar)
  
  trip_data_cod_hstar<-trip_data_cod_hstar %>% 
    dplyr::mutate(uniform=runif(n_row_cod_hstar)) %>%
    dplyr::arrange(uniform) %>% 
    dplyr::mutate(tripid2=1:n_row_cod_hstar)
  
  n_occasions_keep_all_cod=round(h_star_cod_release_to_keep_variable*nrow(trip_data_cod_hstar))
  
  trip_data_cod_hstar <-trip_data_cod_hstar %>% 
    dplyr::filter(tripid2<=n_occasions_keep_all_cod) %>% 
    dplyr::mutate(release_to_keep=1) %>% 
    dplyr::select(period2, tripid, release_to_keep)
  

    trip_data<-trip_data %>% 
      dplyr::left_join(trip_data_cod_hstar, by = c("period2","tripid")) %>% 
      dplyr::mutate(across(where(is.numeric), ~replace_na(., 0))) %>% 
      dplyr::mutate(tot_keep_cod_new1=ifelse(release_to_keep==1 & floor_subl_cod_harv_indicator>0,
                                             tot_keep_cod_new+floor_subl_cod_harv_indicator, tot_keep_cod_new), 
                  tot_rel_cod_new1= ifelse(release_to_keep==1 & floor_subl_cod_harv_indicator>0, 
                                           tot_rel_cod_new-floor_subl_cod_harv_indicator, tot_rel_cod_new )) %>% 
      dplyr::mutate(tot_keep_cod_new= tot_keep_cod_new1, 
                    tot_rel_cod_new = tot_rel_cod_new1) %>% 
      dplyr::select(-tot_keep_cod_new1, -tot_rel_cod_new1, -release_to_keep, -floor_subl_cod_harv_indicator)
  
  }
  
  
  #If we need to re-allocate cod harvest as releases, cod_keep_2_release will equal 1 
  if (cod_keep_2_release==1){
    
    #If we need to re-allocate ALL cod harvest as releases, all_cod_keep_2_release will equal 1 
    if (all_cod_keep_2_release==1){
      
      trip_data<-trip_data %>% 
        dplyr::mutate(tot_rel_cod_new1 = tot_keep_cod_new+tot_rel_cod_new, 
                      tot_keep_cod_new1 = 0) %>% 
        dplyr::mutate(tot_keep_cod_new=tot_keep_cod_new1, 
                      tot_rel_cod_new=tot_rel_cod_new1) %>% 
        dplyr::select(-tot_keep_cod_new1, -tot_rel_cod_new1)
      
    }
    
    #If we need to re-allocate some cod harvest as releases, do the following
    
    if (all_cod_keep_2_release==0){
      
    trip_data_cod_hstar<-trip_data %>%
      dplyr::select(period2, tripid, catch_draw, tot_keep_cod_new, tot_rel_cod_new) %>%
      dplyr::group_by(period2, tripid) %>%
      dplyr::summarise(sum_tot_keep_cod_new=sum(tot_keep_cod_new),
                       sum_tot_rel_cod_new=sum(tot_rel_cod_new), .groups='drop') %>%
      dplyr::filter(sum_tot_keep_cod_new>0)
    

    
    n_row_cod_hstar<-nrow(trip_data_cod_hstar)
    
    trip_data_cod_hstar<-trip_data_cod_hstar %>% 
      dplyr::mutate(uniform=runif(n_row_cod_hstar)) %>%
      dplyr::arrange(uniform) %>% 
      dplyr::mutate(tripid2=1:n_row_cod_hstar)
    
    n_occasions_release_all_cod=round(h_star_cod_keep_to_release_variable*nrow(trip_data_cod_hstar))
    
    trip_data_cod_hstar <-trip_data_cod_hstar %>% 
      dplyr::filter(tripid2<=n_occasions_release_all_cod) %>% 
      dplyr::mutate(keep_to_release=1) %>% 
      dplyr::select(period2, tripid, keep_to_release)

    trip_data<-trip_data %>% 
      dplyr::left_join(trip_data_cod_hstar, by = c("period2","tripid")) %>% 
      dplyr::mutate(across(where(is.numeric), ~replace_na(., 0))) %>% 
      dplyr::mutate(tot_rel_cod_new1=ifelse(keep_to_release==1,tot_keep_cod_new+tot_rel_cod_new, tot_rel_cod_new), 
                    tot_keep_cod_new1= ifelse(keep_to_release==1, 0, tot_keep_cod_new )) %>% 
      dplyr::mutate(tot_keep_cod_new= tot_keep_cod_new1, 
                    tot_rel_cod_new = tot_rel_cod_new1) %>% 
      dplyr::select(-tot_keep_cod_new1, -tot_rel_cod_new1, -keep_to_release)
    
    
    }
    
  }
  
  
  
  
}

if (had_catch_check!=0){
  
  #If we need to re-allocate hadd releases as harvest, hadd_release_2_keep will equal 1 
  if (hadd_release_2_keep==1){

    trip_data_hadd_hstar<-trip_data %>% 
      dplyr::select(period2, tripid, catch_draw, tot_keep_hadd_new, tot_rel_hadd_new, floor_subl_hadd_harv_indicator) %>% 
      dplyr::group_by(period2, tripid) %>% 
      dplyr::summarise(sum_floor_subl_hadd_harv_indicator=sum(floor_subl_hadd_harv_indicator), .groups='drop') %>% 
      dplyr::filter(sum_floor_subl_hadd_harv_indicator>0) 
    
    
    n_row_hadd_hstar<-nrow(trip_data_hadd_hstar)
    
    trip_data_hadd_hstar<-trip_data_hadd_hstar %>% 
      dplyr::mutate(uniform=runif(n_row_hadd_hstar)) %>%
      dplyr::arrange(uniform) %>% 
      dplyr::mutate(tripid2=1:n_row_hadd_hstar)
    

    n_occasions_keep_all_hadd=round(h_star_hadd_release_to_keep_variable*nrow(trip_data_hadd_hstar))
  
    trip_data_hadd_hstar <-trip_data_hadd_hstar %>% 
      dplyr::filter(tripid2<=n_occasions_keep_all_hadd) %>% 
      dplyr::mutate(release_to_keep=1) %>% 
      dplyr::select(period2, tripid, release_to_keep)
    
    trip_data<-trip_data %>% 
      dplyr::left_join(trip_data_hadd_hstar, by = c("period2","tripid")) %>% 
      dplyr::mutate(across(where(is.numeric), ~replace_na(., 0))) %>% 
      dplyr::mutate(tot_keep_hadd_new1=ifelse(release_to_keep==1 & floor_subl_hadd_harv_indicator>0,
                                             tot_keep_hadd_new+floor_subl_hadd_harv_indicator, tot_keep_hadd_new), 
                    tot_rel_hadd_new1= ifelse(release_to_keep==1 & floor_subl_hadd_harv_indicator>0, 
                                             tot_rel_hadd_new-floor_subl_hadd_harv_indicator, tot_rel_hadd_new )) %>% 
      dplyr::mutate(tot_keep_hadd_new= tot_keep_hadd_new1, 
                    tot_rel_hadd_new = tot_rel_hadd_new1) %>% 
      dplyr::select(-tot_keep_hadd_new1, -tot_rel_hadd_new1, -release_to_keep, -floor_subl_hadd_harv_indicator)
  }
  
  
  #If we need to re-allocate hadd harvest as releases, hadd_keep_2_release will equal 1 
  if (hadd_keep_2_release==1){
    
    #If we need to re-allocate ALL hadd harvest as releases, all_hadd_keep_2_release will equal 1 
    if (all_hadd_keep_2_release==1){
      
      trip_data<-trip_data %>% 
        dplyr::mutate(tot_rel_hadd_new1 = tot_keep_hadd_new+tot_rel_hadd_new, 
                      tot_keep_hadd_new1 = 0) %>% 
        dplyr::mutate(tot_keep_hadd_new=tot_keep_hadd_new1, 
                      tot_rel_hadd_new=tot_rel_hadd_new1) %>% 
        dplyr::select(-tot_keep_hadd_new1, -tot_rel_hadd_new1)
      

    }
    
    #If we need to re-allocate some hadd harvest as releases, do the following
    
    if (all_hadd_keep_2_release==0){
      
      trip_data_hadd_hstar<-trip_data %>% 
        dplyr::select(period2, tripid, catch_draw, tot_keep_hadd_new, tot_rel_hadd_new) %>% 
        dplyr::group_by(period2, tripid) %>% 
        dplyr::summarise(sum_tot_keep_hadd_new=sum(tot_keep_hadd_new), 
                         sum_tot_rel_hadd_new=sum(tot_rel_hadd_new), .groups='drop') %>% 
        dplyr::filter(sum_tot_keep_hadd_new>0) 
      
      n_row_hadd_hstar<-nrow(trip_data_hadd_hstar)
      
      trip_data_hadd_hstar<-trip_data_hadd_hstar %>% 
        dplyr::mutate(uniform=runif(n_row_hadd_hstar)) %>%
        dplyr::arrange(uniform) %>% 
        dplyr::mutate(tripid2=1:n_row_hadd_hstar)
      
      n_occasions_release_all_hadd=round(h_star_hadd_keep_to_release_variable*nrow(trip_data_hadd_hstar))
      
      trip_data_hadd_hstar <-trip_data_hadd_hstar %>% 
        dplyr::filter(tripid2<=n_occasions_release_all_hadd) %>% 
        dplyr::mutate(keep_to_release=1) %>% 
        dplyr::select(period2, tripid, keep_to_release)

      
      trip_data<-trip_data %>% 
        dplyr::left_join(trip_data_hadd_hstar, by = c("period2","tripid")) %>% 
        dplyr::mutate(across(where(is.numeric), ~replace_na(., 0))) %>% 
        dplyr::mutate(tot_rel_hadd_new1=ifelse(keep_to_release==1,tot_keep_hadd_new+tot_rel_hadd_new, tot_rel_hadd_new), 
                      tot_keep_hadd_new1= ifelse(keep_to_release==1, 0, tot_keep_hadd_new )) %>% 
        dplyr::mutate(tot_keep_hadd_new= tot_keep_hadd_new1, 
                      tot_rel_hadd_new = tot_rel_hadd_new1) %>% 
        dplyr::select(-tot_keep_hadd_new1, -tot_rel_hadd_new1, -keep_to_release)
      
      
    }
  }
  

}

trip_data<- trip_data %>% as.data.frame() %>% 
  dplyr::left_join(period_vec1, by = c("period2","tripid")) %>% 
  dplyr::arrange(period2, tripid, catch_draw) %>% 
  cbind(trip_costs) %>% 
  cbind(age) %>% 
  cbind(avidity)

rm(trip_costs, age, avidity)

# Costs_new_state data sets will retain raw trip outcomes from the baseline scenario.
# We will merge these data to the prediction year outcomes to calculate changes in CS.
costs_new_all <- trip_data %>%
  dplyr::select(c(tripid, cost, catch_draw, tot_keep_cod_new, tot_rel_cod_new,
                  age, days_fished, beta_opt_out_age,  beta_opt_out_likely,  beta_opt_out_prefer,
                  tot_keep_hadd_new,tot_rel_hadd_new,
                  beta_cost, beta_opt_out, beta_sqrt_hadd_keep,
                  beta_sqrt_hadd_release, #beta_sqrt_cod_hadd_keep,
                  beta_sqrt_cod_keep, beta_sqrt_cod_release, period2)) %>%
  dplyr::rename(tot_keep_cod_base = tot_keep_cod_new,
                tot_rel_cod_base = tot_rel_cod_new,
                tot_keep_had_base = tot_keep_hadd_new,
                tot_rel_had_base = tot_rel_hadd_new) %>%
  dplyr::mutate(n_cal_draw = k,
                mode = select_mode,
                open = select_season)


season1<-unique(costs_new_all$open)
mode1<-unique(costs_new_all$mode)
draw1<-unique(costs_new_all$n_cal_draw)

#saveRDS(costs_new_all, file = paste0(input_data_cd, "costs_", i, ".rds"))
write_feather(costs_new_all, paste0(iterative_input_data_cd, "costs_", mode1,"_", season1, "_", draw1, ".feather"))



#  utility (prediction year)
trip_data <-trip_data %>%
  dplyr::mutate(
    vA = beta_sqrt_cod_keep*sqrt(tot_keep_cod_new) +
      beta_sqrt_cod_release*sqrt(tot_rel_cod_new) +
      beta_sqrt_hadd_keep*sqrt(tot_keep_hadd_new) +
      beta_sqrt_hadd_release*sqrt(tot_rel_hadd_new) +
      #beta_sqrt_cod_hadd_keep*(sqrt(tot_keep_cod_new)*sqrt(tot_keep_hadd_new)) +
      beta_cost*cost)

trip_data <- trip_data %>%
  dplyr::mutate(period = as.numeric(as.factor(period2)))

period_names<-subset(trip_data, select=c("period", "period2"))
period_names <- period_names[!duplicated(period_names), ]


mean_trip_data <- trip_data %>% data.table::data.table() #%>% dplyr::arrange(period, tripid, catch_draw)

# Now expand the data to create two alternatives, representing the alternatives available in choice survey
mean_trip_data <- mean_trip_data %>%
  dplyr::mutate(n_alt = rep(2,nrow(.))) %>%
  tidyr::uncount(n_alt) %>%
  dplyr::mutate(alt = rep(1:2,nrow(.)/2),
                opt_out = ifelse(alt == 2, 1, 0))

#Calculate the expected utility of alts 2 parameters of the utility function,
#put the two values in the same column, exponentiate, and calculate their sum (vA_col_sum)
mean_trip_data <- mean_trip_data %>%
  data.table::as.data.table() %>%
  .[, vA_optout := beta_opt_out*opt_out+
      beta_opt_out_age*age + beta_opt_out_likely*days_fished] %>%
  .[alt==1, expon_vA := exp(vA)] %>%
  .[alt==2, expon_vA := exp(vA_optout)]


mean_trip_data <- mean_trip_data %>%
  data.table::as.data.table() %>%
  .[, vA_col_sum := sum(expon_vA), by=list(period, catch_draw, tripid)]

#Calculate probability of each choice occasion
mean_trip_data <- mean_trip_data %>%
  data.table::as.data.table() %>%
  .[, probA :=expon_vA/vA_col_sum]

mean_trip_data<- subset(mean_trip_data, alt==1) %>% 
  dplyr::select(-domain2) %>% 
  dplyr::mutate(tot_cat_cod_new=tot_keep_cod_new+tot_rel_cod_new, 
                tot_cat_hadd_new=tot_keep_hadd_new+tot_rel_hadd_new)


# Get rid of things we don't need.
mean_trip_data <- subset(mean_trip_data, alt==1,select=-c(alt, beta_cost,beta_opt_out, beta_opt_out_age, 
                                                          beta_opt_out_likely, beta_opt_out_prefer, #beta_sqrt_cod_hadd_keep, 
                                                          beta_sqrt_cod_keep, beta_sqrt_cod_release, beta_sqrt_hadd_keep, 
                                                          beta_sqrt_hadd_release, days_fished, open, period, expon_vA,
                                                          opt_out, vA, vA_optout, vA_col_sum, cost, age))

# Multiply the trip probability by each of the catch variables (not the variables below) to get probability-weighted catch
list_names <- colnames(mean_trip_data)[colnames(mean_trip_data) !="tripid" 
                                       & colnames(mean_trip_data) !="period2" 
                                       & colnames(mean_trip_data) !="probA" 
                                       & colnames(mean_trip_data) !="catch_draw"]


mean_trip_data <- mean_trip_data %>%
  data.table::as.data.table() %>%
  .[,as.vector(list_names) := lapply(.SD, function(x) x * probA), .SDcols = list_names] %>%
  .[]



mean_trip_data_prob_catch_draw<-mean_trip_data %>% 
  dplyr::select("period2","tripid", "catch_draw", "probA")


#Take the average outcomes across catch draws
all_vars<-c()
all_vars <- names(mean_trip_data)[!names(mean_trip_data) %in% c("period2","tripid")]

mean_trip_data<-mean_trip_data  %>% data.table::as.data.table() %>%
  .[,lapply(.SD, mean), by = c("period2","tripid"), .SDcols = all_vars]


mean_trip_data <- mean_trip_data %>%
  dplyr::mutate(n_choice_occasions = rep(1,nrow(.))) %>%
  dplyr::left_join(period_names, by = c("period2"))




#Now multiply the trip outcomes (catch, trip probabilities) for each choice occasion in
#mean_trip_pool by the expansion factor (expand), so that  each choice occasion represents a certain number of choice occasions
#calibration_data <- calibration_data  %>%   rename(period2 = period)

sims <- directed_trips_p %>%
  dplyr::select(c(dtrip, period2)) 


mean_trip_data<-mean_trip_data %>% 
  dplyr::select(-period, -tripid)


mean_trip_data <- mean_trip_data %>%
  dplyr::left_join(sims, by="period2")

mean_probs<-mean_trip_data  %>% 
  dplyr::select(period2, probA) %>% 
  dplyr::rename(mean_prob=probA) %>% 
  data.table::as.data.table() %>%
  .[,lapply(.SD, mean), by = c("period2"), .SDcols = "mean_prob"]

mean_trip_data <- mean_trip_data %>%
  dplyr::left_join(mean_probs, by="period2")



mean_trip_data <- mean_trip_data %>%
  dplyr::mutate(sims=dtrip/mean_prob,
                expand=sims/n_drawz) %>% 
  dplyr::rename(tot_keep_cod_model=tot_keep_cod_new, 
                tot_keep_hadd_model=tot_keep_hadd_new, 
                tot_rel_cod_model=tot_rel_cod_new, 
                tot_rel_hadd_model=tot_rel_hadd_new, 
                tot_cat_hadd_model=tot_cat_hadd_new, 
                tot_cat_cod_model=tot_cat_cod_new)

mean_trip_data0<-  mean_trip_data %>% 
  dplyr::select(period2, expand)

list_names = c("tot_keep_cod_model","tot_keep_hadd_model",
               "tot_rel_cod_model","tot_rel_hadd_model",
               "tot_cat_hadd_model","tot_cat_cod_model",
               "probA", "n_choice_occasions")


mean_trip_data <- mean_trip_data %>%
  data.table::as.data.table() %>%
  .[,as.vector(list_names) := lapply(.SD, function(x) x * expand), .SDcols = list_names] %>%
  .[]

aggregate_trip_data <- mean_trip_data %>%
  data.table::as.data.table() %>%
  .[,lapply(.SD, sum), by =c("period2"), .SDcols = list_names]

names(aggregate_trip_data)[names(aggregate_trip_data) == "probA"] = "estimated_trips"

pds_new<-aggregate_trip_data %>%
  dplyr::mutate(draw = k,
                mode = select_mode,
                open = select_season)

season1<-unique(pds_new$open)
mode1<-unique(pds_new$mode)
draw1<-unique(pds_new$draw)

#saveRDS(pds_new, file = paste0(input_data_cd, "pds_new_", i, ".rds"))
write_feather(pds_new, paste0(iterative_input_data_cd, "pds_new_", mode1,"_", season1, "_", draw1, ".feather"))



aggregate_trip_data2=pds_new %>% 
  dplyr::group_by(draw, mode, open) %>% 
  dplyr::summarize(tot_keep_cod_model=sum(tot_keep_cod_model),
                   tot_keep_hadd_model=sum(tot_keep_hadd_model), 
                   tot_rel_cod_model=sum(tot_rel_cod_model), 
                   tot_rel_hadd_model=sum(tot_rel_hadd_model), 
                   tot_cat_hadd_model=sum(tot_cat_hadd_model), 
                   tot_cat_cod_model=sum(tot_cat_cod_model), 
                   estimated_trips=sum(estimated_trips), .groups='drop') %>% 
  dplyr::mutate(mrip_index=i)

comparison<-aggregate_trip_data2 %>% 
  dplyr::left_join(MRIP_stats, by=c("mode", "open", "draw", "mrip_index"))


comparison<-comparison %>% 
  dplyr::mutate(diff_cod_harv=tot_keep_cod_model-tot_cod_keep_mrip, 
                diff_hadd_harv=tot_keep_hadd_model-tot_hadd_keep_mrip, 
                perc_diff_cod_harv = ((tot_keep_cod_model-tot_cod_keep_mrip)/tot_cod_keep_mrip)*100, 
                perc_diff_hadd_harv = ((tot_keep_hadd_model-tot_hadd_keep_mrip)/tot_hadd_keep_mrip)*100, 
                abs_perc_diff_cod_harv = abs(perc_diff_cod_harv), 
                abs_perc_diff_hadd_harv = abs(perc_diff_hadd_harv)) %>% 
  dplyr::mutate(cod_achieved = ifelse(abs(diff_cod_harv)<500 | abs_perc_diff_cod_harv<5, 1, 0), 
                hadd_achieved = ifelse(abs(diff_hadd_harv)<500 | abs_perc_diff_hadd_harv<5, 1, 0)) %>% 
  cbind(h_star_cod_keep_to_release_variable, h_star_hadd_keep_to_release_variable, h_star_cod_release_to_keep_variable, h_star_hadd_release_to_keep_variable, 
        p_cod_rl_2_kp, p_cod_kp_2_rl, p_hadd_rl_2_kp, p_hadd_kp_2_rl)

comparison2<-comparison %>% 
  dplyr::select(- p_cod_rl_2_kp, -p_cod_kp_2_rl, -p_hadd_rl_2_kp, -p_hadd_kp_2_rl)


season1<-unique(comparison2$open)
mode1<-unique(comparison2$mode)
draw1<-unique(comparison2$draw)

#saveRDS(comparison2, file = paste0(input_data_cd, "comparison_", i, ".rds"))
write_feather(comparison2, paste0(iterative_input_data_cd, "comparison_", mode1,"_", season1, "_", draw1, ".feather"))



rm(catch_size_data, catch_size_data_had, cod_catch_data, cod_had_catch_data, costs_new_all, had_catch_data, 
   keep_size_data, new_size_data, param_draws, release_size_data, 
   trip_data, trip_data_hadd)




