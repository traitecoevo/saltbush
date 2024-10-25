#' Create multiband image
#'
#' Combines single reflectance band tifs into a multiband image.
#'
#' @param input_dir Directory containing folders with waveband tifs to be combined, or single folder with waveband tifs to be combined
#' @param desired_band_order Order of files to be combined. should be in wavelength order. provide vector of file basenames in correct order
#' @param output_dir Folder to store combined tif file
#' @return  combined tif file
#' @examples
#' create_multiband_image('2024_band_rasters', c('blue', 'green', 'red', 'red_edge', 'nir'), 'data_out/2024_rasters')
#' @export
#' @import tools
#' @import terra

create_multiband_image <- function(input_dir, desired_band_order, output_dir){
  # folder list | recursive = won't pick folders within folders
  folders <- list.dirs(input_dir, full.names = T, recursive = FALSE)

  if (length(folders) == 0){
    folders <- input_dir
  }
  ## NOTE: 'desired_band_order' must match file names
  #  should be combined in wavelength order

  # loop thru each folder
  for (folder in folders) {

    # list of tif files
    tif_files <- list.files(folder, pattern = "\\.tif$", full.names = TRUE)

    # load as raster
    rasters <- lapply(tif_files, terra::rast)

    # extract band names from file names
    band_names <- tools::file_path_sans_ext(basename(tif_files))

    # stack rasters and assign band names
    combined_image <- terra::rast(rasters)
    names(combined_image) <- band_names

    # reorder the bands based on the desired band order
    combined_image <- combined_image[[match(desired_band_order, band_names)]]

    # create output file as .tif and as .envi
    output_filename <- file.path(output_dir, paste0(basename(folder), "_combined_image"))
    # write .tif file
    terra::writeRaster(combined_image, filename = paste0(output_filename, '.tif'),
                       filetype = "GTiff", gdal = c("INTERLEAVE=BAND"), overwrite = TRUE)

    # plot image - for checking
    plot(combined_image)
  }
}
