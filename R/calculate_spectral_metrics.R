#' @title Calculate spectral metrics
#'
#' @description Calculates CV, SV, and CHV for each area of interest (AOI)
#' directly from multiband rasters, without first extracting every pixel into
#' a data frame. Each raster is cropped and masked to each AOI polygon; CV and
#' SV are calculated from per-band summary statistics (`terra::global()`), and
#' CHV from the matrix of pixel values within the AOI.
#'
#' Spectral variance (SV) is standardized by the number of spectral points, so
#' it is not rarefied; `rarefaction` applies to CV and CHV only.
#'
#' @param raster_files Character vector of multiband raster file paths. The
#'   site name is taken from the start of each file name, up to the first `_`
#'   or `.` (or the whole name, minus extension, if there is neither), so
#'   `NSABHC0009_ortho.tif`, `NSABHC0009.ortho.tif` and `NSABHC0009.tif` all
#'   give the site `NSABHC0009`.
#' @param aoi_files Character vector of AOI file paths: shapefiles (`.shp`),
#'   GeoJSON (`.geojson`/`.json`) or GeoPackage (`.gpkg`), each containing one
#'   or more AOI polygons. Each raster is matched to the AOI file with the same
#'   site name, found the same way (e.g. `NSABHC0009_aoi.shp`). Files with other
#'   extensions (e.g. a shapefile's `.dbf`) are ignored. If an AOI's coordinate
#'   system differs from its raster's, the AOI is reprojected to match.
#' @param wavelengths Character vector naming the wavelength of each raster
#'   layer, in layer order.
#' @param aoi_id_col Optional character; name of a column in the AOI file to
#'   use as the `aoi_id`. When `NULL` (default), AOIs are numbered `1:n`.
#' @param masked Logical; labels the output `image_type` as `"masked"` or
#'   `"unmasked"`. It does not mask the image.
#' @param rarefaction Logical; if `TRUE`, CV and CHV are averaged over `n`
#'   random subsamples of `min_points` pixels per AOI, which standardizes uneven
#'   pixel numbers across AOIs and increases processing time.
#' @param min_points Integer; pixels sampled per AOI when `rarefaction = TRUE`.
#' @param n Integer; number of subsamples when `rarefaction = TRUE`.
#' @param seed Integer or `NULL`; if provided, `set.seed(seed)` is called once
#'   at the start so the rarefaction sampling is reproducible.
#' @return A data frame with one row per AOI per raster, and columns `site`,
#'   `aoi_id`, `CV`, `SV`, `CHV` and `image_type`.
#' @examples
#' aoi_files <- list.files(
#'   system.file("extdata/aoi", package = "saltbush"),
#'   pattern = "image_aoi\\.shp$", full.names = TRUE
#' )
#' raster_files <- list.files(
#'   system.file("extdata/multiband_image", package = "saltbush"),
#'   pattern = "\\.tif$", full.names = TRUE
#' )
#' metrics <- calculate_spectral_metrics(
#'   raster_files, aoi_files,
#'   wavelengths = c("blue", "green", "red", "red_edge", "nir"),
#'   masked = FALSE
#' )
#' metrics
#' @export

calculate_spectral_metrics <- function(raster_files,
                                       aoi_files,
                                       wavelengths,
                                       aoi_id_col = NULL,
                                       masked = TRUE,
                                       rarefaction = FALSE,
                                       min_points = NULL,
                                       n = NULL,
                                       seed = NULL) {

  if (rarefaction && (is.null(n) || is.null(min_points))) {
    stop("if rarefaction = TRUE, n and min_points must be provided")
  }

  # seed once, so each site and AOI gets its own independent draws
  if (!is.null(seed)) set.seed(seed)

  results <- list()

  for (raster_file in raster_files) {

    # identify the string that represents the site name
    site_name <- site_from_path(raster_file)

    # read in raster file and apply consistent band names
    raster_data <- terra::rast(raster_file)
    names(raster_data) <- wavelengths

    aois <- read_aoi(site_name, aoi_files, raster_data, aoi_id_col)

    for (i in seq_along(aois$ids)) {
      aoi_id <- aois$ids[i]
      aoi_vect <- aois$vect[i]

      # an aoi outside the image has no pixels: warn and return NA metrics
      if (is.null(terra::intersect(terra::ext(aoi_vect), terra::ext(raster_data)))) {
        warning(sprintf("aoi '%s' of site '%s' does not overlap the image; metrics are NA",
                        aoi_id, site_name), call. = FALSE)
        results[[length(results) + 1]] <- data.frame(
          site = site_name, aoi_id = aoi_id, CV = NA_real_, SV = NA_real_, CHV = NA_real_
        )
        next
      }

      # crop and mask raster using current aoi
      aoi_raster <- terra::mask(terra::crop(raster_data, aoi_vect), aoi_vect)

      # drop cells that are NA in any band, so every band has the same pixels
      aoi_raster <- terra::mask(aoi_raster, any(is.na(aoi_raster)),
                                maskvalues = TRUE)

      # pixel matrix (one row per pixel, one column per band) for CHV
      pixels <- terra::values(aoi_raster, mat = TRUE)
      pixels <- pixels[stats::complete.cases(pixels), , drop = FALSE]

      if (rarefaction) {
        if (min_points > nrow(pixels)) {
          stop(sprintf("min_points (%s) exceeds the number of pixels (%s) in aoi '%s' of site '%s'",
                       min_points, nrow(pixels), aoi_id, site_name))
        }

        # draw the same subsample for CV and CHV in each iteration
        draws <- replicate(n, {
          sampled <- pixels[sample.int(nrow(pixels), min_points), , drop = FALSE]
          c(CV = cv_from_moments(colMeans(sampled), apply(sampled, 2, stats::sd)),
            CHV = chv_from_matrix(sampled))
        })
        cv <- mean(draws["CV", ], na.rm = TRUE)
        chv <- mean(draws["CHV", ])
      } else {
        cv <- NULL
        chv <- chv_from_matrix(pixels)
        if (is.na(chv)) {
          warning(sprintf("CHV is NA for aoi '%s' of site '%s': its %s pixels cannot form a hull in %s bands (need at least %s, not all in a flat plane)",
                          aoi_id, site_name, nrow(pixels), ncol(pixels), ncol(pixels) + 1),
                  call. = FALSE)
        }
      }

      # per-band mean and sample sd, calculated by terra from the raster
      stats <- terra::global(aoi_raster, c("mean", "sd"), na.rm = TRUE)
      if (is.null(cv)) cv <- cv_from_moments(stats$mean, stats$sd)

      # SV = sum over bands of sum of squared deviations / (points - 1)
      sv <- sum(stats$sd^2)

      results[[length(results) + 1]] <- data.frame(
        site = site_name, aoi_id = aoi_id, CV = cv, SV = sv, CHV = chv
      )
    }
  }

  combined_metrics <- do.call(rbind, results)
  combined_metrics$image_type <- ifelse(masked, "masked", "unmasked")

  return(combined_metrics)
}


# site name: file name without extension, up to the first "_" or "."
site_from_path <- function(path) {
  sub("[_.].*$", "", tools::file_path_sans_ext(basename(path)))
}

# AOI file extensions accepted by calculate_spectral_metrics()
aoi_extensions <- c("shp", "geojson", "json", "gpkg")

# find, read and (if needed) reproject the AOI file for one site
read_aoi <- function(site_name, aoi_files, raster_data, aoi_id_col = NULL) {

  aoi_files <- aoi_files[tolower(tools::file_ext(aoi_files)) %in% aoi_extensions]

  # choose the corresponding aoi file
  aoi_file <- aoi_files[site_from_path(aoi_files) == site_name]

  if (length(aoi_file) == 0) {
    stop(sprintf("No AOI file (%s) found for site '%s'; AOI file names must start with the site name",
                 paste0(".", aoi_extensions, collapse = "/"), site_name))
  }
  if (length(aoi_file) > 1) {
    stop(sprintf("More than one AOI file found for site '%s': %s",
                 site_name, paste(basename(aoi_file), collapse = ", ")))
  }

  # read in aoi file and select the id column if requested
  aois <- sf::read_sf(aoi_file)
  if (!is.null(aoi_id_col)) {
    if (!aoi_id_col %in% names(aois)) {
      stop(sprintf("aoi_id_col '%s' not found in %s", aoi_id_col, basename(aoi_file)))
    }
    aoi_ids <- aois[[aoi_id_col]]
    if (anyDuplicated(aoi_ids)) {
      warning(sprintf("aoi_id_col '%s' in %s has duplicate values, so some rows will share an aoi_id",
                      aoi_id_col, basename(aoi_file)), call. = FALSE)
    }
  } else {
    aoi_ids <- seq_len(nrow(aois))
  }

  aoi_vect <- terra::vect(sf::st_geometry(aois))

  # reproject the aoi if its coordinate system differs from the imagery
  if (terra::crs(aoi_vect) == "" || terra::crs(raster_data) == "") {
    warning(sprintf("Coordinate system missing for %s or its imagery; assuming they match",
                    basename(aoi_file)))
  } else if (!terra::same.crs(aoi_vect, raster_data)) {
    aoi_vect <- terra::project(aoi_vect, raster_data)
    message(sprintf("AOI reprojected to match coordinate system of imagery: %s",
                    basename(aoi_file)))
  }

  list(vect = aoi_vect, ids = aoi_ids)
}

# CV: per-band sd / |mean|, averaged across bands (ignoring NA bands)
cv_from_moments <- function(means, sds) {
  mean(sds / abs(means), na.rm = TRUE)
}

# CHV: volume of the convex hull of the pixels in spectral space
chv_from_matrix <- function(pixels) {
  # NA when there are too few (or degenerate) points to build a hull
  if (nrow(pixels) <= ncol(pixels)) return(NA_real_)
  tryCatch(geometry::convhulln(pixels, option = "FA")$vol,
           error = function(e) NA_real_)
}
