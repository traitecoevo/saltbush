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
#'   site name is taken from the start of each file name, up to the first `_`.
#' @param aoi_files Character vector of AOI file paths: shapefiles (`.shp`),
#'   GeoJSON (`.geojson`/`.json`) or GeoPackage (`.gpkg`), each containing one
#'   or more AOI polygons. Each raster is matched to the AOI file whose name
#'   starts with the same site name followed by `_`. Files with other
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
    site_name <- sub("_.*$", "", basename(raster_file))

    # read in raster file and apply consistent band names
    raster_data <- terra::rast(raster_file)
    names(raster_data) <- wavelengths

    aois <- read_aoi(site_name, aoi_files, raster_data, aoi_id_col)

    for (i in seq_along(aois$ids)) {
      aoi_id <- aois$ids[i]
      aoi_vect <- aois$vect[i]

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


# AOI file extensions accepted by calculate_spectral_metrics()
aoi_extensions <- c("shp", "geojson", "json", "gpkg")

# find, read and (if needed) reproject the AOI file for one site
read_aoi <- function(site_name, aoi_files, raster_data, aoi_id_col = NULL) {

  aoi_files <- aoi_files[tolower(tools::file_ext(aoi_files)) %in% aoi_extensions]

  # choose the corresponding aoi file: site name followed by "_" or the extension
  aoi_names <- basename(aoi_files)
  aoi_file <- aoi_files[startsWith(aoi_names, paste0(site_name, "_")) |
                          tools::file_path_sans_ext(aoi_names) == site_name]

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
  geometry::convhulln(pixels, option = "FA")$vol
}


#' @title Calculate spectral metrics from a pixel-value data frame
#'
#' @description Calculates CV, SV, or CHV from a data frame of pixel values
#' with one column per wavelength and an `aoi_id` column. For calculating
#' metrics directly from rasters, use [calculate_spectral_metrics()].
#'
#' @param pixel_values_df,df A data frame of pixel values, one row per pixel.
#' @param wavelengths Column names in the data frame holding the band values.
#' @param rarefaction Logical; if TRUE, applies a rarefaction step that increases processing time.
#' @param min_points Integer; pixels sampled per `aoi_id` (used if `rarefaction = TRUE`).
#' @param n Integer; number of subset permutations if `rarefaction = TRUE`.
#' @param seed Integer or NULL; if provided, `set.seed(seed)` is called once at the
#'   start of the function so the rarefaction sampling is reproducible.
#' @return A data.table with `aoi_id` and the metric (`CV`, `SV` or `CHV`).
#' @rdname spectral_metrics_df
#' @export
#' @import data.table
#' @examples
#' set.seed(123)
#' df <- data.frame(
#'   aoi_id = rep(1:2, each = 500),
#'   blue = runif(1000), green = runif(1000), red = runif(1000))
#' calculate_cv(df, wavelengths = c("blue", "green", "red"))
#' calculate_sv(df, wavelengths = c("blue", "green", "red"))
#' calculate_chv_nopca(df, wavelengths = c("blue", "green", "red"),
#'                     rarefaction = TRUE, min_points = 50, n = 5)

calculate_cv <- function(pixel_values_df,
                         wavelengths,
                         rarefaction = FALSE,
                         min_points = NULL,
                         n = NULL,
                         seed = NULL) {

  if (!is.null(seed)) set.seed(seed)

  # copy to a data.table, leaving the caller's data frame unchanged
  pixel_values_df <- data.table::as.data.table(pixel_values_df)

  if (rarefaction) {
    check_min_points(pixel_values_df, min_points)

    # initialize a list to store CV values for each replication
    cv_list <- vector("list", n)

    # resample and calculate CV for each iteration
    for (i in seq_len(n)) {
      # sample to the minimum number of points per aoi
      sampled_df <- pixel_values_df[, .SD[sample(.N, min_points)], by = aoi_id, .SDcols = wavelengths]

      # calculate CV for each wavelength within each aoi
      cv_data <- sampled_df[, lapply(.SD, function(x) sd(x) / abs(mean(x, na.rm = TRUE))), by = aoi_id]

      # sum across wavelengths and normalize by the number of bands (ignoring NAs)
      cv_data[, CV := rowSums(.SD, na.rm = TRUE) / (length(wavelengths) - rowSums(is.na(.SD))), .SDcols = wavelengths]

      # store CV values along with aoi_id
      cv_list[[i]] <- cv_data[, .(aoi_id, CV)]
    }

    # collapse the list of CV data tables into a single data table and calculate the average CV for each aoi
    cv <- rbindlist(cv_list)[, .(CV = mean(CV, na.rm = TRUE)), by = aoi_id]

  } else {
    # if rarefaction is FALSE, directly calculate the CV without resampling
    cv <- pixel_values_df[, lapply(.SD, function(x) sd(x) / abs(mean(x, na.rm = TRUE))), by = aoi_id, .SDcols = wavelengths]

    # sum across wavelengths and normalize by the number of bands (ignoring NAs)
    cv[, CV := rowSums(.SD, na.rm = TRUE) / (length(wavelengths) - rowSums(is.na(.SD))), .SDcols = wavelengths]

    # keep aoi_id in the output
    cv <- cv[, .(aoi_id, CV)]
  }

  return(cv)
}



# sv function
#' @rdname spectral_metrics_df
#' @export
calculate_sv <- function(pixel_values_df, wavelengths) {
  # copy to a data.table, leaving the caller's data frame unchanged
  pixel_values_df <- data.table::as.data.table(pixel_values_df)

  # calculate the number of points per aoi
  spectral_points <- pixel_values_df[, .(points = .N), by = aoi_id]

  # calculate spectral variance (SV)
  sv <- pixel_values_df[, lapply(.SD, function(x) sum((x - mean(x, na.rm = TRUE))^2)),
                        .SDcols = wavelengths,
                        by = aoi_id]

  # cum across wavelengths
  sv[, SS := rowSums(.SD), .SDcols = wavelengths]

  # join with the spectral points
  sv <- sv[spectral_points, on = "aoi_id"]

  # calculate SV
  sv[, SV := SS / (points - 1)]

  return(sv[, .(aoi_id, SV)])
}




# function to calculate chv for each aoi
#' @rdname spectral_metrics_df
#' @export
calculate_chv_nopca <- function(df,
                                wavelengths,
                                rarefaction = FALSE,
                                min_points = NULL,
                                n = NULL,
                                seed = NULL) {

  if (!is.null(seed)) set.seed(seed)

  # copy to a data.table, leaving the caller's data frame unchanged
  df <- data.table::as.data.table(df)

  if (rarefaction) check_min_points(df, min_points)

  results <- data.table::data.table(aoi_id = double(), CHV = double())

  # loop through each aoi_id
  for (aoi in unique(df$aoi_id)) {
    # subset data for current aoi_id
    aoi_sample <- df[aoi_id == aoi, ..wavelengths]

    if (rarefaction) {
      # resample CHV n times and calculate the mean
      chv_values <- replicate(n, {
        resampled <- aoi_sample[sample(.N, min_points, replace = FALSE)]

        # convert to matrix for convex hull calculation
        CHV_matrix <- as.matrix(resampled)

        # calculate CHV
        chv_out <- geometry::convhulln(CHV_matrix, option = "FA")
        return(chv_out$vol)
      })

      mean_chv <- mean(chv_values)
    } else {
      # calculate CHV without rarefaction
      CHV_matrix <- as.matrix(aoi_sample)
      chv_out <- geometry::convhulln(CHV_matrix, option = "FA")
      mean_chv <- chv_out$vol
    }

    # store results in data.table
    results <- rbind(results, data.table::data.table(aoi_id = aoi, CHV = mean_chv), fill = TRUE)
  }

  return(results)
}

# error clearly if any aoi has fewer pixels than min_points
check_min_points <- function(dt, min_points) {
  if (is.null(min_points)) stop("if rarefaction = TRUE, n and min_points must be provided")
  counts <- dt[, .N, by = aoi_id]
  too_small <- counts[N < min_points]
  if (nrow(too_small) > 0) {
    stop(sprintf("min_points (%s) exceeds the number of pixels in aoi: %s",
                 min_points,
                 paste0(too_small$aoi_id, " (", too_small$N, ")", collapse = ", ")))
  }
}
