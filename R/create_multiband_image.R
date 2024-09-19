#' Create multiband image
#'
#' A description of what your function does.
#'
#' @param mosaics_dir Description of the parameter x.
#' @param desired_band_order description
#' @return  combined tif image
#' @export
create_multiband_image <- function(mosaics_dir, desired_band_order){
  # folder list | recursive = won't pick folders within folders
  folders <- list.dirs(mosaics_dir, full.names = FALSE, recursive = FALSE)
  # need to make this part an argument e.g. option to exclude certain folders or include certain folders
  folders <- folders[folders != "point_clouds"]

  ## NOTE: spectral band image tif file names must be named after their band (e.g., blue, nir, etc),
  #  otherwise change 'desired_band_order' to match file names
  #  should be combined in wavelength order, esp for biodivmapR processes (i.e. as above)

  # loop thru each folder
  for (folder in folders) {
    # create path
    folder_path <- file.path(mosaics_dir, folder)

    # list of tif files | \\. represents . (dots need to be escaped w \, \ need to be escaped with  \). $means at end of file name/string
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

    #create output directory folder if it doesn't exist
    output_dir <- file.path("data_out/combined_rasters", substr(basename(mosaics_dir), 1, 4))
    if (!dir.exists(output_dir)) {
      dir.create(output_dir, recursive = TRUE)
    }

    # create output file as .tif and as .envi
    output_filename <- file.path(output_dir, paste0(folder, "_combined_image"))
    # write .tif file
    terra::writeRaster(combined_image, filename = paste0(output_filename, '.tif'),
                       filetype = "GTiff", gdal = c("INTERLEAVE=BAND"), overwrite = TRUE)
    plot(combined_image)
  }
}
