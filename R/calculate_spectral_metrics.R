#' @title Calculate Spectral Metrics
#' @description Calculates CV, SV, and CHV from a pixel values dataframe with columns for each wavelength, `site_name`, and `aoi_id`.
#' This help file applies to the functions `calculate_cv`, `calculate_sv`, `calculate_chv`, `calculate_chv_nopca`, and `calculate_spectral_metrics`.
#' @param pixel_values_df A data frame containing pixel values, typically obtained from the `extract_pixel_values` function.
#' @param wavelengths A list of wavelengths that correspond to column names in `pixel_values_df`.
#' @param rarefaction Logical; if TRUE, applies a rarefaction step that increases processing time.
#' @param min_points Integer; minimum number of pixels per `aoi` to standardize uneven pixel numbers across sites (used if `rarefaction = TRUE`).
#' @param n Integer; number of subset permutations if `rarefaction = TRUE`.
#' @return A dataframe containing spectral metrics for each `aoi` within each site/raster.
#' @aliases calculate_cv calculate_sv calculate_chv calculate_chv_nopca calculate_spectral_metrics
#' @export
#' @import data.table
#' @examples
#' set.seed(123)
#' df <- data.frame(
#'   site_name = rep(c("site_one", "site_two", "site_three", "site_four"), each = 5000),
#'   aoi_id = 1,
#'   blue = runif(20000, min = 0, max = 1),
#'   green = runif(20000, min = 0, max = 1),
#'   red = runif(20000, min = 0, max = 1),
#'   red_edge = runif(20000, min = 0, max = 1),
#'   nir = runif(20000, min = 0, max = 1))
#' spectral_metrics <- calculate_spectral_metrics(df,
#'    wavelengths = c('blue','green','red','red_edge','nir'),
#'    rarefaction = TRUE, min_points = 50, n = 5)

calculate_cv <- function(pixel_values_df,
                         wavelengths,
                         rarefaction = FALSE,
                         min_points = NULL,
                         n = NULL) {

  # convert to a data.table for efficiency
  data.table::setDT(pixel_values_df)

  if (rarefaction) {
    # initialize a list to store CV values for each replication
    cv_list <- vector("list", n)

    # resample and calculate CV for each iteration
    for (i in seq_len(n)) {
      # sample to the minimum number of points per aoi
      sampled_df <- pixel_values_df[, .SD[sample(.N, min_points)], by = aoi_id, .SDcols = wavelengths]

      # calculate CV for each wavelength within each aoi
      cv_data <- sampled_df[, lapply(.SD, function(x) sd(x) / abs(mean(x, na.rm = TRUE))), by = aoi_id]

      # sum across wavelengths and normalize by the number of bands (ignoring NAs)
      cv_data[, CV := rowSums(.SD, na.rm = TRUE) / (length(wavelengths) - rowSums(is.na(.SD))), .SDcols = wavelengths]

      # store CV values along with aoi_id
      cv_list[[i]] <- cv_data[, .(aoi_id, CV)]
    }

    # collapse the list of CV data tables into a single data table and calculate the average CV for each aoi
    cv <- rbindlist(cv_list)[, .(CV = mean(CV, na.rm = TRUE)), by = aoi_id]

  } else {
    # if rarefaction is FALSE, directly calculate the CV without resampling
    cv <- pixel_values_df[, lapply(.SD, function(x) sd(x) / abs(mean(x, na.rm = TRUE))), by = aoi_id, .SDcols = wavelengths]

    # sum across wavelengths and normalize by the number of bands (ignoring NAs)
    cv[, CV := rowSums(.SD, na.rm = TRUE) / (length(wavelengths) - rowSums(is.na(.SD))), .SDcols = wavelengths]

    # keep aoi_id in the output
    cv <- cv[, .(aoi_id, CV)]
  }

  return(cv)
}



# sv function
#' @import data.table
#' @export
calculate_sv <- function(pixel_values_df, wavelengths) {
  # convert pixel_values_df to data.table for better performance
  setDT(pixel_values_df)

  # calculate the number of points per aoi
  spectral_points <- pixel_values_df[, .(points = .N), by = aoi_id]

  # calculate spectral variance (SV)
  sv <- pixel_values_df[, lapply(.SD, function(x) sum((x - mean(x, na.rm = TRUE))^2)),
                        .SDcols = wavelengths,
                        by = aoi_id]

  # cum across wavelengths
  sv[, SS := rowSums(.SD), .SDcols = wavelengths]

  # join with the spectral points
  sv <- sv[spectral_points, on = "aoi_id"]

  # calculate SV
  sv[, SV := SS / (points - 1)]

  return(sv[, .(aoi_id, SV)])
}


# chv function
#' @import data.table
#' @export
calculate_chv <- function(df, dim) {
  CHV_df <- df |>
    select(1:dim)

  # convert to matrix
  CHV_matrix <- as.matrix(CHV_df)

  # calculate chv
  CHV <- geometry::convhulln(CHV_matrix, option = "FA")
  return(CHV)
}

# function to calculate chv for each aoi
#' @import data.table
#' @export
calculate_chv_nopca <- function(df,
                                wavelengths,
                                rarefaction = FALSE,
                                min_points = NULL,
                                n = NULL) {

  # convert to data.table for better performance
  setDT(df)

  results <- data.table::data.table(aoi_id = double(), CHV_nopca = double())

  # loop through each aoi_id
  for (aoi in unique(df$aoi_id)) {
    # subset data for current aoi_id
    aoi_sample <- df[aoi_id == aoi, ..wavelengths]

    if (rarefaction) {
      # resample CHV n times and calculate the mean
      chv_values <- replicate(n, {
        resampled <- aoi_sample[sample(.N, min_points, replace = FALSE)]

        # convert to matrix for convex hull calculation
        CHV_matrix <- as.matrix(resampled)

        # calculate CHV
        chv_out <- geometry::convhulln(CHV_matrix, option = "FA")
        return(chv_out$vol)
      })

      mean_chv <- mean(chv_values)
    } else {
      # calculate CHV without rarefaction
      CHV_matrix <- as.matrix(aoi_sample)
      chv_out <- geometry::convhulln(CHV_matrix, option = "FA")
      mean_chv <- chv_out$vol
    }

    # store results in data.table
    results <- rbind(results, data.table::data.table(aoi_id = aoi, CHV_nopca = mean_chv), fill = TRUE)
  }

  return(results)
}


#' @export
calculate_spectral_metrics <- function(pixel_values_df,
                                       masked = TRUE,
                                       wavelengths,
                                       rarefaction = FALSE,
                                       min_points = NULL,
                                       n = NULL) {
  results <- list()
  if (!"site_name" %in% colnames(pixel_values_df)) {
    pixel_values_df$site_name <- "site1"
  }
   for (site in unique(pixel_values_df$site_name)) {
    site_pixel_values <- pixel_values_df |> dplyr::filter(site_name == site)

    # calculate metrics, pass rarefaction where needed
    cv <- calculate_cv(site_pixel_values, wavelengths = wavelengths, rarefaction = rarefaction, n = n, min_points = min_points)
    sv <- calculate_sv(site_pixel_values, wavelengths = wavelengths)
    chv <- calculate_chv_nopca(site_pixel_values, wavelengths, rarefaction = rarefaction, n = n, min_points = min_points)

    results[[site]] <- list(CV = cv, SV = sv, CHV = chv)
  }

  combined_cv <- dplyr::bind_rows(lapply(results, function(x) x$CV), .id = 'site')
  combined_sv <- dplyr::bind_rows(lapply(results, function(x) x$SV), .id = 'site')
  combined_chv <- dplyr::bind_rows(lapply(results, function(x) x$CHV), .id = 'site')

  # create a data frame for combined metrics
  combined_metrics <- combined_cv |>
    dplyr::left_join(combined_sv, by = c("site", "aoi_id")) |>
    dplyr::left_join(combined_chv, by = c("site", "aoi_id"))

  combined_metrics <- combined_metrics |>
    dplyr::mutate(image_type = ifelse(masked, 'masked', 'unmasked'))

  return(combined_metrics)
}
