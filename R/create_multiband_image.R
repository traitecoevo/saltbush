  #' Create a Multiband Image from Single-Band TIF Files
  #'
  #' This function combines single reflectance band TIF files into a multiband image.
  #' By default, it saves the combined multiband image to a file rather than returning an object.
  #' The function supports reordering bands according to a specified wavelength order and
  #' optionally creates a plot to visualize the output.
  #'
  #' @param input_dir A directory containing folders with waveband TIF files to be combined,
  #' or a single folder with waveband TIF files to be combined.
  #' @param desired_band_order A character vector specifying the desired order of the bands.
  #' The order should match the file basenames (excluding extensions) and represent
  #' the wavelength order.
  #' @param output_dir A directory where the combined multiband TIF file will be saved.
  #' @param make_plot Logical. If `TRUE`, a plot is generated to visualize the output for verification.
  #' Default is `FALSE`.
  #' @param return_raster Logical. If `TRUE`, the combined raster object is returned.
  #' Default is `FALSE`.
  #'
  #' @return Saves a combined multiband TIF file in the specified `output_dir`.
  #' If `return_raster = TRUE`, the function returns a `terra` raster object representing
  #' the combined multiband image.
  #'
  #' @examples
  #'
  #' input_dir <- system.file("extdata/create_multiband_image", package = "saltbush")
  #' output_dir <- tempdir()
  #' create_multiband_image(input_dir, c('blue', 'green', 'red', 'red_edge', 'nir'), output_dir)
  #'
  #' @export


create_multiband_image <- function(input_dir,
                                   desired_band_order,
                                   output_dir,
                                   make_plot = FALSE,
                                   return_raster = FALSE) {
  # folder list | recursive = won't pick folders within folders
  folders <- list.dirs(input_dir, full.names = T, recursive = FALSE)

  if (length(folders) == 0) {
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
    terra::writeRaster(
      combined_image,
      filename = paste0(output_filename, '.tif'),
      filetype = "GTiff",
      gdal = c("INTERLEAVE=BAND"),
      overwrite = TRUE
    )


    # plot image - for checking
    if (make_plot)
      terra::plot(combined_image)

    #logic for what to return
    if (return_raster)
      return(combined_image)
    else
      return(NULL)
  }
}
