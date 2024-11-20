#' Create Masked Raster from Multiband Image
#'
#' This function creates a masked raster by removing non-vegetation pixels based on NDVI and NIR threshold values.
#' It supports processing single files, multiple files in a directory, or a list of file paths. Threshold values
#' can be specified as single values or as a data frame with site-specific thresholds. The function assumes that
#' the input layers are stacked in wavelength order and saves the masked raster to the specified output directory.
#'
#' @param input A directory containing multiple ENVI or TIF files, a single file, or a character vector of file paths.
#' @param output_dir A directory where the masked raster(s) will be saved.
#' @param ndvi_threshold Numeric. NDVI threshold for masking (pixels with NDVI values below this are masked as non-vegetation).
#' @param nir_threshold Numeric. NIR threshold for masking (pixels with NIR values below this are masked as shadows).
#' @param ndvi_threshold_df Optional. A data frame with two columns: `site` (site identifiers) and `threshold`
#' (NDVI threshold values for each site). The `site` values must match the beginning of the input file names.
#' @param nir_threshold_df Optional. A data frame with two columns: `site` (site identifiers) and `threshold`
#' (NIR threshold values for each site). The `site` values must match the beginning of the input file names.
#' @param red_band_index Integer. The index (layer number) of the red band in the input raster. Default is 3.
#' @param nir_band_index Integer. The index (layer number) of the NIR band in the input raster. Default is 5.
#' @param make_plot Logical. If `TRUE`, a plot of the masked raster is generated for verification. Default is `FALSE`.
#' @param return_raster Logical. If `TRUE`, the masked raster object is returned. Default is `FALSE`.
#'
#' @return Saves masked raster(s) as TIF files in the specified `output_dir`.
#' If `return_raster = TRUE`, the function returns the masked raster object as a `terra` raster.
#'
#' @examples
#'
#' input <- system.file("extdata/multiband_image", package = "saltbush")
#' output_dir <- tempdir()
#' create_masked_raster(input,
#'                     output_dir,
#'                     ndvi_threshold = 0.02,
#'                    nir_threshold = 0.04,
#'                      red_band_index = 3,
#'                      nir_band_index = 5)
#'
#' @export

# CREATE_MASKED_RASTER FUNCTION
#input can be directory with a number of files, a single file, or string of files.
#ndvi and nir thresholds can be provided as a df, if there are diff optimum values per site
# or as a single value for all sites
# this function assumes that layers are stacked in WAVELENGTH ORDER
#think about how you can make this more general for users - e.g. it requires the plot id to
# be in the file name currently - think about usability
create_masked_raster <- function(input,
                                 output_dir,
                                 ndvi_threshold = NULL,
                                 nir_threshold = NULL,
                                 ndvi_threshold_df = NULL,
                                 nir_threshold_df = NULL,
                                 red_band_index = 3,
                                 nir_band_index = 5,
                                 make_plot = FALSE,
                                 return_raster = FALSE) {
  if (dir.exists(input)) {
    # list all ENVI or TIF files in the directory
    files <- list.files(file.path(input),
                        pattern = '\\.(envi|tif)$',
                        full.names = TRUE)
  } else if (file.exists(input) || is.character(input)) {
    # single file input or string of files
    files <- input
  } else {
    stop("Invalid input provided.")
  }

  print(paste("Files found:", files))

  if (length(files) == 0) {
    stop("No files found.")
  }

  for (file in files) {
    # extract the site identifier from file name
    file_name <- basename(file)

    if (!is.null(ndvi_threshold_df)) {
      # Use grepl to search if any site value is found in file_id
      site_id <- ndvi_threshold_df$site[grepl(ndvi_threshold_df$site, file_name)]


      ndvi_threshold <- ndvi_threshold_df$threshold[ndvi_threshold_df$site == site_id]
    }
    if (length(ndvi_threshold) == 0) {
      stop(paste("No NDVI threshold values found for file", file_name))
    }


    if (!is.null(nir_threshold_df)) {
      # Use grepl to search if any site value is found in file_id
      site_id <- nir_threshold_df$site[grepl(nir_threshold_df$site, file_name)]

      nir_threshold <- nir_threshold_df$threshold[nir_threshold_df$site == site_id]
    }
    if (length(nir_threshold) == 0) {
      stop(paste("No NIR threshold values found for file", file_name))
    }

    # read the raster stack
    raster_data <- terra::rast(file)

    # identify the bands for Red and NIR
    red <- raster_data[[red_band_index]]
    nir <- raster_data[[nir_band_index]]

    # calculate NDVI
    ndvi <- (nir - red) / (nir + red)

    # create a mask based on NDVI and NIR thresholds
    mask <- (ndvi < ndvi_threshold) | (nir < nir_threshold)

    # apply the mask to the raster data
    raster_data_masked <- terra::mask(raster_data,
                                      mask,
                                      maskvalue = TRUE,
                                      updatevalue = NA)

    # aave the masked raster
    masked_filename <- file.path(output_dir,
                                 paste0(tools::file_path_sans_ext(basename(file)), '_masked.tif'))
    terra::writeRaster(raster_data_masked,
                       filename = masked_filename,
                       overwrite = TRUE)

    print(paste("Masked raster saved to:", masked_filename))

    if (make_plot)
      terra::plot(raster_data_masked)

    if (return_raster)
      return(raster_data_masked)
    else
      return(NULL)
  }
}
