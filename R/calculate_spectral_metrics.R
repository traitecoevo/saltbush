#rarefraction cv function
calculate_cv <- function(pixel_values_df,
                         subplots = 'subplot_id',
                         wavelengths,
                         rarefaction = TRUE,
                         min_points = NULL,
                         n = 999) {

  # Convert the dataframe to a data.table for efficiency
  setDT(pixel_values_df)

  if (rarefaction) {
    # Initialize a list to store CV values for each replication
    cv_list <- vector("list", n)

    # Resample and calculate CV for each iteration
    for (i in seq_len(n)) {
      # Sample to the minimum number of points per subplot
      sampled_df <- pixel_values_df[, .SD[sample(.N, min_points)], by = subplots, .SDcols = wavelengths]

      # Calculate CV for each wavelength within each subplot
      cv_data <- sampled_df[, lapply(.SD, function(x) sd(x) / abs(mean(x, na.rm = TRUE))), by = subplots]

      # Sum across wavelengths and normalize by the number of bands (ignoring NAs)
      cv_data[, CV := rowSums(.SD, na.rm = TRUE) / (length(wavelengths) - rowSums(is.na(.SD))), .SDcols = wavelengths]

      # Store CV values along with subplots
      cv_list[[i]] <- cv_data[, .(subplot_id = subplots, CV), by = subplots]  # Ensure subplot_id is included
    }

    # Collapse the list of CV data tables into a single data table and calculate the average CV for each subplot
    cv <- rbindlist(cv_list)[, .(CV = mean(CV, na.rm = TRUE)), by = subplots]

  } else {
    # If rarefaction is FALSE, directly calculate the CV without resampling
    cv <- pixel_values_df[, lapply(.SD, function(x) sd(x) / abs(mean(x, na.rm = TRUE))), by = subplots, .SDcols = wavelengths]

    # Sum across wavelengths and normalize by the number of bands (ignoring NAs)
    cv[, CV := rowSums(.SD, na.rm = TRUE) / (length(wavelengths) - rowSums(is.na(.SD))), .SDcols = wavelengths]

    # Ensure subplot_id is included in the output
    cv <- cv[, .(subplot_id = subplots, CV)]
  }

  return(cv)
}



# sv function
calculate_sv <- function(pixel_values_df, subplots = 'subplot_id', wavelengths) {
  # Convert pixel_values_df to data.table for better performance
  setDT(pixel_values_df)

  # Calculate the number of points per subplot
  spectral_points <- pixel_values_df[, .(points = .N), by = subplots]

  # Calculate spectral variance (SV)
  sv <- pixel_values_df[, lapply(.SD, function(x) sum((x - mean(x, na.rm = TRUE))^2)),
                        .SDcols = wavelengths,
                        by = subplots]

  # Sum across wavelengths
  sv[, SS := rowSums(.SD), .SDcols = wavelengths]

  # Join with the spectral points
  sv <- sv[spectral_points, on = subplots]

  # Calculate SV
  sv[, SV := SS / (points - 1)]

  return(sv[, .(subplot_id = get(subplots), SV)])
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
calculate_chv_nopca <- function(df,
                                wavelengths,
                                subplots = 'subplot_id',
                                rarefaction = TRUE,
                                min_points = NULL,
                                n = 999) {

  # Convert df to data.table for better performance
  setDT(df)

  results <- data.table(subplot_id = character(), CHV_nopca = double())

  # Loop through each subplot
  for (subplot in unique(df[[subplots]])) {
    # Subset data for current subplot
    subplot_sample <- df[get(subplots) == subplot, ..wavelengths]

    if (rarefaction) {
      # Resample CHV n times and calculate the mean
      chv_values <- replicate(n, {
        resampled <- subplot_sample[sample(.N, min_points, replace = FALSE)]

        # Convert to matrix for convex hull calculation
        CHV_matrix <- as.matrix(resampled)

        # Calculate CHV
        chv_out <- geometry::convhulln(CHV_matrix, option = "FA")
        return(chv_out$vol)
      })

      mean_chv <- mean(chv_values)
    } else {
      # Calculate CHV without resampling
      CHV_matrix <- as.matrix(subplot_sample)
      chv_out <- geometry::convhulln(CHV_matrix, option = "FA")
      mean_chv <- chv_out$vol
    }

    # Store results in data.table
    results <- rbind(results, data.table(subplot_id = subplot, CHV_nopca = mean_chv), fill = TRUE)
  }

  return(results)
}

## FUNCTION FOR CALCULATING ALL METRICS
calculate_spectral_metrics <- function(pixel_values_df,
                                       masked = TRUE,
                                       wavelengths,
                                       min_points,
                                       n = 999,
                                       rarefaction = TRUE) {  # Add rarefaction here
  results <- list()

  for (identifier in unique(pixel_values_df$identifier)) {
    site_pixel_values <- pixel_values_df %>% filter(identifier == !!identifier)

    # Calculate metrics, pass rarefaction where needed
    cv <- calculate_cv(site_pixel_values, wavelengths = wavelengths, rarefaction = rarefaction, n = n, min_points = min_points)
    sv <- calculate_sv(site_pixel_values, wavelengths = wavelengths)
    chv <- calculate_chv_nopca(site_pixel_values, wavelengths, rarefaction = rarefaction, min_points = min_points)

    results[[identifier]] <- list(CV = cv, SV = sv, CHV = chv)
  }

  combined_cv <- bind_rows(lapply(results, function(x) x$CV), .id = 'identifier')
  combined_sv <- bind_rows(lapply(results, function(x) x$SV), .id = 'identifier')
  combined_chv <- bind_rows(lapply(results, function(x) x$CHV), .id = 'identifier')

  # create a data frame for combined metrics
  combined_metrics <- combined_cv %>%
    left_join(combined_sv, by = c("identifier", "subplot_id")) %>%
    left_join(combined_chv, by = c("identifier", "subplot_id"))

  combined_metrics <- combined_metrics %>%
    mutate(image_type = ifelse(masked, 'masked', 'unmasked'))

  return(combined_metrics)
}
