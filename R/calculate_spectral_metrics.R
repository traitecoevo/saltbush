#' @title Calculate spectral metrics
#' @description Calculates continuous spectral metrics (CV, SV, CHV) based on input pixel value df
#' @param df description
#' @return
#' @examples
#' @export
#' @import data.table
#' @import geometry
#' @import vegan
#' @import tidyverse

## CV, CHV, SV metric functions appropriated from https://github.com/ALCrofts/CABO_SVH_Forest_Sites/tree/v1.0

# cv function with rarefaction option
calculate_cv <- function(pixel_values_df, # Dataframe with spectral reflectance values
                  aoi_id, # What you want to calculate spectral diversity for
                  wavelengths, # Cols where spectral reflectance values are
                  rarefaction = F,
                  n = NULL, # Number of random resampling events, if rarefraction = T.
                  min_points = NULL # minimum number of pixels (ie. the min # of pixels in any subplot)
){
  # validate inputs if rarefaction = T
  if (rarefaction == T) {
    if (is.null(n) || is.null(min_points)) {
      stop("Please provide both 'n' and 'min_points' when rarefaction is TRUE.")
    }

    # convert to datatable (more efficient performance)
    setDT(spectral_df)

    # create a list to store CV values for each replication
    cv_list <- vector("list", n)

    # b) calculate CV for each resampling event
    for (i in seq_len(n)) {
      # sample to the minimum number of points per subplot
      sampled_df <- spectral_df[, .SD[sample(.N, min_points)], by = aoi_id, .SDcols = wavelengths]

      # calculate CV for each wavelength within each subplot
      cv_data <- sampled_df[, lapply(.SD, function(x) sd(x) / abs(mean(x, na.rm = TRUE))), by = aoi_id]

      # sum across wavelengths and normalize by the number of bands (ignoring NAs)
      cv_data[, CV := rowSums(.SD, na.rm = TRUE) / (length(wavelengths) - rowSums(is.na(.SD))), .SDcols = wavelengths]

      # store cv values
      cv_list[[i]] <- cv_data[, .(CV), by = aoi_id]
    }

    # c) Collapse list of CV data tables into a single data table and calculate average CV for each area of interest
    CV <- rbindlist(cv_list)[, .(CV = mean(CV, na.rm = TRUE)), by = areas_of_interest]

    return(CV)
  }
 if (rarefaction == F){
   pixel_values_df %>%
     select(c({{aoi_id}}, {{wavelengths}})) %>%
     group_by({{aoi_id}}) %>%
     summarise_all(~sd(.)/abs(mean(.))) %>%
     rowwise({{aoi_id}}) %>%
     summarise(CV = sum(c_across(cols = everything()), na.rm = T) / (ncol(.) - sum(is.na(c_across(everything())))))

   return(cv)
 }

}

# sv function
calculate_sv <- function(pixel_values_df, aoi_id, wavelengths) {
  spectral_points <- pixel_values_df %>%
    group_by({{aoi_id}}) %>%
    summarise(points = n())

  sv <- pixel_values_df %>%
    select(c({{wavelengths}}, {{aoi_id}})) %>%
    group_by({{aoi_id}}) %>%
    summarise_all(~sum((.x - mean(.x))^2)) %>%
    rowwise({{aoi_id}}) %>%
    summarise(SS = sum(c_across(cols = everything()))) %>%
    left_join(spectral_points) %>%
    summarise(SV = SS / (points - 1))

  return(sv)
}

# chv function
calculate_chv <- function(df, dim) {
  CHV_df <- df %>%
    select(1:dim)

  # convert to matrix
  CHV_matrix <- as.matrix(CHV_df)

  # calculate chv
  CHV <- geometry::convhulln(CHV_matrix, option = "FA")
  return(CHV)
}

# function to calculate chv for each subplot
calculate_chv_for_aoi <- function(df, wavelengths, dim = 3, aoi_id = 'aoi_id', rarefraction = TRUE, n = 999) {
  results <- tibble(aoi_id = character(), CHV = double())

  # Perform PCA for specified wavelengths
  PCA <- df %>%
    select(all_of(wavelengths)) %>%
    vegan::rda(scale = FALSE)

  # Add subplot id as column to PCA df
  pca_results <- data.frame(PCA$CA$u) %>%
    bind_cols(aoi_id = df[[aoi_id]])

  # Compute the minimum number of points across all subplots
  min_points <- pca_results %>%
    group_by(aoi_id) %>%
    summarise(points = n()) %>%
    summarise(min_points = min(points)) %>%
    pull(min_points)

  # Loop through each subplot
  for (aoi in unique(df[[aoi_id]])) {
    # Subset data for current subplot
    subplot_sample <- pca_results %>%
      filter(aoi_id == aoi)

    if (rarefraction) {
      # Resample CHV n times and calculate the mean
      chv_values <- replicate(n, {
        resampled <- aoi_sample %>%
          select(-aoi_id) %>%
          sample_n(min_points, replace = FALSE)

        chv_out <- calculate_chv(resampled, dim = dim)
        return(chv_out$vol)
      })

      mean_chv <- mean(chv_values)
    } else {
      # calculate CHV without resampling
      chv_out <- calculate_chv(aoi_sample, dim = dim)
      mean_chv <- chv_out$vol
    }

    # store results
    results <- results %>%
      add_row(aoi_id = aoi, CHV = mean_chv)
  }

  return(results)
}


## FUNCTION FOR CALCULATING ALL METRICS

calculate_spectral_metrics <- function(pixel_values_df, masked = TRUE, wavelengths) {
  results <- list()

  # loop through each site (represented as 'identifier' from file name)
  for (site_name in unique(pixel_values_df$site_name)) {

    # filter pixel values for the current site
    site_pixel_values <- pixel_values_df %>% filter(site_name == !!site_name)

    # calculate metrics (CV, SV, CHV)
    cv <- calculate_cv(site_pixel_values, aoi_id, wavelengths)
    sv <- calculate_sv(site_pixel_values, aoi_id, wavelengths)
    chv <- calculate_chv_for_aoi(site_pixel_values, wavelengths)

    # store results
    results[[site_name]] <- list(CV = cv, SV = sv, CHV = chv, CHV_nopca = chv_nopca)
  }

  # combine metrics into data frames
  combined_cv <- bind_rows(lapply(results, function(x) x$CV), .id = 'site_name')
  combined_sv <- bind_rows(lapply(results, function(x) x$SV), .id = 'site_name')
  combined_chv <- bind_rows(lapply(results, function(x) x$CHV), .id = 'site_name')

  # create a data frame for combined metrics
  combined_metrics <- combined_cv %>%
    left_join(combined_sv, by = c("site_name", "aoi_id")) %>%
    left_join(combined_chv, by = c("site_name", "aoi_id"))

  # add image_type column based on masked argument
  if (masked) {
    combined_metrics <- combined_metrics %>%
      mutate(image_type = 'masked')
  } else {
    combined_metrics <- combined_metrics %>%
      mutate(image_type = 'unmasked')
  }

  return(combined_metrics)
}
