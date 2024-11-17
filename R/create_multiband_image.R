#' Create multiband image
#'
#' Combines single reflectance band tifs into a multiband image.
#'
#' @param input_dir Directory containing folders with waveband tifs to be combined, or single folder with waveband tifs to be combined
#' @param desired_band_order Order of files to be combined. should be in wavelength order. provide vector of file basenames in correct order
#' @param output_dir Folder to store combined tif file
#' @examples
#' input_dir <- system.file("extdata/create_multiband_image", package = "saltbush")
#' output_dir <- tempdir()
#' create_multiband_image(input_dir, c('blue', 'green', 'red', 'red_edge', 'nir'), output_dir)
#' @return  combined tif file
#' @export

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

    # stack rasters and assign band names
    combined_image <- terra::rast(rasters)
    band_names <- names(combined_image)

    # reorder the bands based on the desired band order
    combined_image <- combined_image[[match(desired_band_order, band_names)]]

    # create output file as .tif and as .envi
    output_filename <- file.path(output_dir, paste0(basename(folder), "_multiband_image"))
    # write .tif file
    terra::writeRaster(combined_image, filename = paste0(output_filename, '.tif'),
                       filetype = "GTiff", gdal = c("INTERLEAVE=BAND"), overwrite = TRUE)


    # plot image - for checking
    terra::plot(combined_image)
  }
}

