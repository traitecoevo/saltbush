#' @title Create Masked Raster
#' @description Creates a masked raster, non-vegetation pixels using input ndvi & nir threshold values
#' @param input can be a directory containing multiple tif/envi files, string of files, or single file.
#' @param output_dir an output directory for the masked raster/s to be saved
#' @param ndvi_threshold NDVI threshold (values beneath this contain non-veg pixels and should be masked)
#' @param nir_threshold NIR threshold (values beneath this contain shadows and should be masked)
#' @param ndvi_threshold_df optional - a two columned df with 'site' col (site values must match first string of input file name) and  threshold values for each file
#' @param nir_threshold_df optional - a two columned df with 'site' col (site values must match first string of input file name) and  threshold values for each file
#' @param red_band_index layer number for red band
#' @param nir_band_index layer number for nir band
#' @return A masked raster image, saved in the output directory
#' @examples
#' create_masked_raster(input = 'data_out/combined_rasters/2024',
#'output_dir = 'data_out/combined_rasters/masked/2024',
#'ndvi_threshold_df = ndvi_threshold_df_24,
#'nir_threshold_df = nir_threshold_df_24,
#'red_band_index = 3,
#'NIR_band_index = 5)
#' @export
#' @import terra
#' @import tools
#' @import stringr

# CREATE_MASKED_RASTER FUNCTION
#input can be directory with a number of files, a single file, or string of files.
#ndvi and nir thresholds can be provided as a df, if there are diff optimum values per site
# or as a single value for all sites
# this function assumes that layers are stacked in WAVELENGTH ORDER
#think about how you can make this more general for users - e.g. it requires the plot id to
# be in the file name currently - think about usability
create_masked_raster <- function(input, output_dir,
                                 ndvi_threshold = NULL, nir_threshold = NULL,
                                 ndvi_threshold_df = NULL, nir_threshold_df = NULL,
                                 red_band_index = 3, NIR_band_index = 5) {

  if (dir.exists(input)) {
    # list all ENVI or TIF files in the directory
    files <- list.files(file.path(input), pattern = '\\.(envi|tif)$', full.names = TRUE)
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
    file_name <- strsplit(basename(file))

    if (!is.null(ndvi_threshold_df)) {

      # Use grepl to search if any site value is found in file_id
      site_id <- ndvi_threshold_df$site[grepl(ndvi_threshold_df$site, file_name)]


        ndvi_threshold <- ndvi_threshold_df$threshold[ndvi_threshold_df$site == site_id]
      } else {
        stop(paste("No NDVI threshold values found for file", file_name))
    }


    if (!is.null(nir_threshold_df)) {

      # Use grepl to search if any site value is found in file_id
      site_id <- nir_threshold_df$site[grepl(nir_threshold_df$site, file_name)]

        nir_threshold <- nir_threshold_df$threshold[nir_threshold_df$site == site_id]
      } else {
        stop(paste("No NIR threshold values found for file", file_name))
    }

    # read the raster stack
    raster_data <- stack(file)

    # identify the bands for Red and NIR
    red <- raster_data[[red_band_index]]
    nir <- raster_data[[NIR_band_index]]

    # calculate NDVI
    ndvi <- (nir - red) / (nir + red)

    # create a mask based on NDVI and NIR thresholds
    mask <- (ndvi < ndvi_threshold) | (nir < nir_threshold)

    # apply the mask to the raster data
    raster_data_masked <- terra::mask(raster_data, mask, maskvalue = TRUE, updatevalue = NA)

    # aave the masked raster
    masked_filename <- file.path(output_dir, paste0(file_path_sans_ext(basename(file)), '_masked.tif'))
    terra::writeRaster(raster_data_masked, filename = masked_filename, format = "GTiff", overwrite = TRUE)

    print(paste("Masked raster saved to:", masked_filename))
  }
}

