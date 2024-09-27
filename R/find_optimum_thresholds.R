#' @title Find Optimum Thresholds
#' @description Takes input ground truth data to find optimum NDVI and NIR Thresholds for image masking. Input must be a df with column for band values and column indicating class (i.e. )
#' @param df description
#' @param class name of column where class/catgegories are stored for
#' @param band description
#' @param site description
#' @param class_value description
#' @return a df with optimum thresholds for each site
#' @examples
#' ndvi_thresholds <- find_optimum_thresholds(ndvi_values, class = 'class', value = 'ndvi', site = 'site', class_value = 'veg')
#' @export
#' @import pROC

# FIND OPTIMUM THRESHOLDS FUNCTION
# class = class column for classifications (e.g. veg, ground etc) (col name)
# value = ndvi, nir - what threshold are you seeking (col name)
# site = plot reference (col name)

find_optimum_thresholds <- function(df, class, band, site, class_value) {
  # empty df
  threshold_df <- data.frame(site = character(), threshold = numeric())

  # iterate over sites
  for (site_name in unique(df[[site]])) {

    # filter current location
    site_data <- subset(df, df[[site]] == site_name)

    # binary outcome variable for veg and non-veg
    site_data$binary_class <- ifelse(site_data[[class]] == class_value, 1, 0)

    # ROC curve
    roc_result <- pROC::roc(site_data$binary_class, site_data[[band]])

    # find optimum threshold
    best_threshold <- pROC::coords(roc_result, 'best')$threshold

    # append to the result data frame
    threshold_df <- rbind(threshold_df, data.frame(site = site_name, threshold = best_threshold))
  }

  return(threshold_df)
}
