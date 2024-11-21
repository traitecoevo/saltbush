#' @title Processing spectral data for tests of the spectral variability hypothesis
#'
#' @description
#' Drone data is complex and extracting spectral diversity values requires several processing steps. This package is designed to be part of the workflow for analyzing these images
#'
#' @name saltbush
#' @docType package
#' @references If you have any questions, comments or suggestions, please
#' submit an issue at our
#' [GitHub repository](https://github.com/traitecoevo/saltbush/issues)
#' @keywords internal
#' @section Functions:
#' **Spectral diversity**
#'
#' * [calculate_cv]
#' * [calculate_sv]
#' * [calculate_chv_nopca]
#' * [calculate_spectral_metrics]
#' * [create_masked_raster]
#' * [create_multiband_image]
#' * [extract_pixel_values]
#'
#' **On the ground diversity**
#'
#' * [calculate_field_diversity]
#'
"_PACKAGE"

## usethis namespace: start
## usethis namespace: end
NULL
utils::globalVariables(
  c(
    ".", "select", "aoi_id", "..wavelengths", "CV", "site_unique",
    "dplyr", "drop_na", "standardised_name", "filter", "summarise",
    "n_distinct", "count", "spread", "n", "diversity", "mutate",
    "species_richness", "bind_rows", "site_name", "left_join", "SS",
    "SV", "points", "file_path_sans_ext", "str_extract", "read_sf",
    "as", "crop", "mask", "getValues", "na.omit", "sd","site_location_name","everything"
  )
)

