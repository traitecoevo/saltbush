#' @title Find Optimum Thresholds
#' @description Takes input ground truth data to find optimum thresholds for image masking.
#' @param df Input must be a df with columns for site name, pixel value, class
#' @param site_col name of site column - which indicates where pixel values + class data are obtained from
#' @param band_or_index_col name of column where pixel values are stored - e.g. 'ndvi' or 'nir_values'
#' @param class_col name of column where object class are stored
#' @param class_value value/s of class that should be masked - e.g. for ndvi, 'non-veg' or c('bare_ground','rocks'), for nir, 'shadow'
#' @return a df with optimum thresholds for each site
#' @export
#' @examples
#' rnorm(500)
#' @import pROC
#' @import dplyr

# add a for loop so nir and ndvi ground truth values can be given in the same df instead of seperately :)
# FIND OPTIMUM THRESHOLDS FUNCTION

find_optimum_thresholds <- function(df, class_col, band_or_index_col, site_col, class_value) {
  # create empty df
  threshold_df <- data.frame(site = character(), threshold = numeric())

  # iterate over sites
  for (site_name in unique(df[[site_col]])) {

    # filter current location
    site_data <- subset(df, df[[site_col]] == site_name)

    # binary outcome variable for veg and non-veg
    site_data$binary_class <- ifelse(site_data[[class_col]] == class_value, 1, 0)

    # ROC curve
    roc_result <- pROC::roc(site_data$binary_class, site_data[[band_or_index_col]])

    # find optimum threshold
    best_threshold <- pROC::coords(roc_result, 'best')$threshold

    # append to the result data frame
    threshold_df <- rbind(threshold_df, data.frame(site = site_name, threshold = best_threshold))
  }

  return(threshold_df)
}
