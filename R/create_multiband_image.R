#' Create multiband image
#'
#' Combines single reflectance band tifs into a multiband image.
#'
#' @param mosaics_dir Folder which contains single band tifs to be combined
#' @param desired_band_order Order of files to be combined. should be in wavelength order. provide list of file basenames in correct order
#' @param output_dir Folder to store combined tif file
#' @return  combined tif file
#' @examples
#' create_multiband_image('001_site_mosaics', c('blue', 'green', 'red', 'red_edge', 'nir'), 'data_out/001_site')
#' @export
#' @import tools
#' @import terra
#'
create_multiband_image <- function(mosaics_dir, desired_band_order, output_dir){
  # folder list | recursive = won't pick folders within folders
  folders <- list.dirs(mosaics_dir, full.names = FALSE, recursive = FALSE)

  ## NOTE: spectral band image tif file names must be named after their band (e.g., blue, nir, etc),
  #  otherwise change 'desired_band_order' to match file names
  #  should be combined in wavelength order

  # loop thru each folder
  for (folder in folders) {
    # create path
    folder_path <- file.path(mosaics_dir, folder)

    # list of tif files
    tif_files <- list.files(folder_path, pattern = "\\.tif$", full.names = TRUE)

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
    output_filename <- file.path(output_dir, paste0(folder, "_combined_image"))
    # write .tif file
    terra::writeRaster(combined_image, filename = paste0(output_filename, '.tif'),
                       filetype = "GTiff", gdal = c("INTERLEAVE=BAND"), overwrite = TRUE)

    # plot image - for checking
    plot(combined_image)
  }
}
