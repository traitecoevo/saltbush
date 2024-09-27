#' @title Create Masked Raster
#' @description Creates a masked raster, removing shadows and non-vegetation pixcels using input ndvi and nir threshold values
#' @param input can be a directory, string of files, or single file.
#' @param output_dir an output directory for the masked raster/s to be saved
#' @param NDVI_Thresh a threshold NDVI threshold to be applied to all rasters
#' @param NIR_Thresh a threshold NIR threshold to be applied to all rasters
#' @param NDVI_Thresh_df optional - a two columned df with 'site' (must match input file name) and  threshold values for each file
#' @param NIR_Thresh_df optional - a two columned df with 'site' (must match input file name) and  threshold values for each file
#' @param red_band_index layer number for red band
#' @param nir_band_index layer number for nir band
#' @return A masked raster image, saved in the output directory
#' @examples
#' create_masked_raster(input = 'data_out/combined_rasters/2024',
#'output_dir = 'data_out/combined_rasters/masked/2024',
#'NDVI_Thresh_df = ndvi_threshold_df_24,
#'NIR_Thresh_df = nir_threshold_df_24,
#'red_band_index = 3,
#'NIR_band_index = 5)
#' @export
#' @import terra

# CREATE_MASKED_RASTER FUNCTION
#input can be directory with a number of files, a single file, or string of files.
#ndvi and nir thresholds can be provided as a df, if there are diff optimum values per site
# or as a single value for all sites
# this function assumes that layers are stacked in WAVELENGTH ORDER
#think about how you can make this more general for users - e.g. it requires the plot id to
# be in the file name currently - think about usability
create_masked_raster <- function(input, output_dir,
                                 NDVI_Thresh = 0.2, NIR_Thresh = 0.2,
                                 NDVI_Thresh_df = NULL, NIR_Thresh_df = NULL,
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
    file_id <- strsplit(basename(file), "_")[[1]][1]

    # check if NDVI_Thresh_df is provided and extract the relevant threshold values
    if (!is.null(NDVI_Thresh_df)) {
      if (file_id %in% NDVI_Thresh_df[[1]]) {
        NDVI_Thresh <- NDVI_Thresh_df[[2]][NDVI_Thresh_df[[1]] == file_id]
      } else {
        stop(paste("No NDVI threshold values found for file", file_id))
      }
    }

    # check if NIR_Thresh_df is provided and extract the relevant threshold values
    if (!is.null(NIR_Thresh_df)) {
      if (file_id %in% NIR_Thresh_df[[1]]) {
        NIR_Thresh <- NIR_Thresh_df[[2]][NIR_Thresh_df[[1]] == file_id]
      } else {
        stop(paste("No NIR threshold values found for site", file_id))
      }
    }

    # Read the raster stack
    raster_data <- stack(file)

    # Identify the bands for Red and NIR
    red <- raster_data[[red_band_index]]
    nir <- raster_data[[NIR_band_index]]

    # Calculate NDVI
    ndvi <- (nir - red) / (nir + red)

    # Create a mask based on NDVI and NIR thresholds
    mask <- (ndvi < NDVI_Thresh) | (nir < NIR_Thresh)

    # Apply the mask to the raster data
    raster_data_masked <- terra::mask(raster_data, mask, maskvalue = TRUE, updatevalue = NA)

    # Save the masked raster
    masked_filename <- file.path(output_dir, paste0(file_path_sans_ext(basename(file)), '_masked.tif'))
    terra::writeRaster(raster_data_masked, filename = masked_filename, format = "GTiff", overwrite = TRUE)

    print(paste("Masked raster saved to:", masked_filename))
  }
}

