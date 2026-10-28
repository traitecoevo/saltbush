  #' @title Create a multiband image from single-band TIF files
  #'
  #' @description This function combines single reflectance band TIF files into a multiband image.
  #' It saves the combined multiband image to a file and, by default, also returns
  #' it and plots it for checking. Bands are ordered by the specified wavelength
  #' order. All bands in a folder must
  #' share the same extent, resolution and coordinate reference system (CRS);
  #' otherwise the function stops and lists the bands that differ.
  #'
  #' @param input_dir A directory containing folders with waveband TIF files to be combined,
  #' or a single folder with waveband TIF files to be combined.
  #' @param desired_band_order A character vector of band names, in wavelength
  #' order. Each band is matched to the TIF whose file name (excluding extension)
  #' is the band name or ends with it after a separator, so both `blue.tif` and
  #' Pix4D output such as `NSABHC0009_transparent_reflectance_blue.tif` match
  #' `"blue"`. Matching ignores case, and treats spaces, hyphens and dots as
  #' underscores (`"red edge"` matches `"red_edge"`). Other TIFs in the folder
  #' are ignored. The output layers are named by these band names.
  #' @param output_dir A directory where the combined multiband TIF file will be saved.
  #' @param make_plot Logical. If `TRUE`, a plot is generated to visualize the output for verification.
  #' Default is `TRUE`.
  #' @param return_raster Logical. If `TRUE`, the combined raster object is returned.
  #' Default is `TRUE`.
  #'
  #' @return Saves a combined multiband TIF file in the specified `output_dir`.
  #' If `return_raster = TRUE` (default), the function also returns the combined
  #' multiband image as a `terra` raster, or a named list of rasters when
  #' `input_dir` holds several folders.
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
                                   output_dir = tempdir(),
                                   make_plot = TRUE,
                                   return_raster = TRUE) {
  # folder list | recursive = won't pick folders within folders
  folders <- list.dirs(input_dir, full.names = T, recursive = FALSE)

  if (length(folders) == 0) {
    folders <- input_dir
  }
  ## NOTE: 'desired_band_order' must match file names
  #  should be combined in wavelength order

  combined_images <- list()

  # loop thru each folder
  for (folder in folders) {
    # list of tif files, one per band, in the desired band order
    tif_files <- list.files(folder, pattern = "\\.tif$", full.names = TRUE)
    tif_files <- match_band_files(tif_files, desired_band_order, folder)

    # load as raster
    rasters <- lapply(tif_files, terra::rast)

    # bands must share extent, resolution and CRS to be stacked
    check_bands_align(rasters, tif_files, folder)

    # stack rasters and name layers by band
    combined_image <- terra::rast(rasters)
    names(combined_image) <- desired_band_order

    # create output file as .tif
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

    combined_images[[basename(folder)]] <- combined_image
  }

  # logic for what to return: a single raster for one folder, else a named list
  if (return_raster) {
    if (length(combined_images) == 1) return(combined_images[[1]])
    return(combined_images)
  }

  return(invisible(NULL))
}

# find the TIF for each band: the file name (without extension) must be the
# band name, or end with it after a separator, e.g. "blue.tif" or Pix4D's
# "NSABHC0009_transparent_reflectance_blue.tif". Case is ignored, and spaces,
# hyphens and dots count as underscores, so "red edge" matches "red_edge".
match_band_files <- function(tif_files, bands, folder) {
  normalise <- function(x) tolower(gsub("[ ._-]+", "_", x))
  file_names <- normalise(tools::file_path_sans_ext(basename(tif_files)))

  matched <- character(length(bands))
  for (i in seq_along(bands)) {
    band <- normalise(bands[i])
    hits <- which(file_names == band | endsWith(file_names, paste0("_", band)))

    if (length(hits) == 0) {
      stop(sprintf("No TIF file for band '%s' in '%s'. File names must be the band name or end with it, e.g. 'blue.tif' or 'site_reflectance_blue.tif'.",
                   bands[i], basename(folder)), call. = FALSE)
    }
    if (length(hits) > 1) {
      stop(sprintf("More than one TIF file for band '%s' in '%s': %s",
                   bands[i], basename(folder),
                   paste(basename(tif_files[hits]), collapse = ", ")),
           call. = FALSE)
    }
    matched[i] <- tif_files[hits]
  }

  matched
}

# error clearly if any band differs from the first in extent, resolution or CRS
check_bands_align <- function(rasters, tif_files, folder) {
  ref <- rasters[[1]]
  ref_name <- basename(tif_files[1])
  problems <- character()

  for (i in seq_along(rasters)[-1]) {
    r <- rasters[[i]]
    name <- basename(tif_files[i])

    if (!terra::same.crs(r, ref)) {
      problems <- c(problems, sprintf("  %s: CRS differs from %s", name, ref_name))
    }
    if (!isTRUE(all.equal(terra::res(r), terra::res(ref)))) {
      problems <- c(problems, sprintf("  %s: resolution %s differs from %s (%s)",
                                      name, paste(signif(terra::res(r), 6), collapse = " x "),
                                      ref_name, paste(signif(terra::res(ref), 6), collapse = " x ")))
    }
    if (!isTRUE(all.equal(as.vector(terra::ext(r)), as.vector(terra::ext(ref))))) {
      problems <- c(problems, sprintf("  %s: extent %s differs from %s (%s)",
                                      name, format_ext(r), ref_name, format_ext(ref)))
    }
  }

  if (length(problems) > 0) {
    stop(sprintf("Bands in '%s' cannot be stacked because they do not align:\n%s",
                 basename(folder), paste(problems, collapse = "\n")),
         call. = FALSE)
  }
}

format_ext <- function(r) {
  paste(signif(as.vector(terra::ext(r)), 10), collapse = ", ")
}
