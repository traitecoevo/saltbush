#' @title Extract pixel values
#'
#' @description Extracts pixel values from each layer of multiband image and creates pixel value df
#'
#' @param raster_files directory of input raster files
#' @param aoi_files area of interest file - shapefile containing one or more site polygons for each raster
#' @param wavelength_names the wavelength corresponding to each layer of the raster_files
#' @param aoi_id_col Optional character; name of a column in the AOI shapefile
#'   to use as the per-feature `aoi_id`. When `NULL` (default), the loop index
#'   (`1:nrow(aois)`) is used, preserving the prior behaviour.
#' @return a df with pixel values for each of the image layers
#' @examples
#' aoi_files <- list.files('inst/extdata/aoi',
#'    pattern = 'image_aoi.shp$', full.names = TRUE)
#' raster_files <- list.files('inst/extdata/multiband_image',
#'    pattern = '.tif$', full.names = TRUE)
#' pixelvalues <- extract_pixel_values(raster_files, aoi_files, c('blue','green','red','red_edge','nir'))
#' @export

extract_pixel_values <- function(raster_files, aoi_files, wavelength_names, aoi_id_col = NULL){

  all_pixel_values_list <- list()

  for (raster_file in raster_files) {

    # identify the string that represents the site name
    site_name <- stringr::str_extract(basename(raster_file), "^[^_]+")

    #choose the corresponding subplot file
    aoi_file <- aoi_files[grep(paste0('^', site_name), basename(aoi_files))]

    # read in aoi file and select geometries (and the id column if requested)
    aois <- sf::read_sf(aoi_file)
    if (!is.null(aoi_id_col)) {
      if (!aoi_id_col %in% names(aois)) {
        stop(sprintf("aoi_id_col '%s' not found in %s", aoi_id_col, basename(aoi_file)))
      }
      aoi_ids <- aois[[aoi_id_col]]
    } else {
      aoi_ids <- seq_len(nrow(aois))
    }
    aois <- dplyr::select(aois, 'geometry')

    # read in raster file
    raster_data <- terra::rast(raster_file)

    # apply consistent band names to each raster
    names(raster_data) <- wavelength_names

    # create empty list
    pixel_values_list <- list()

    for (i in seq_len(nrow(aois))){

      # select the i-th aoi and its id
      aoi <- aois[i, ]
      aoi_id <- aoi_ids[i]

      # convert sf to SpatVector for mask() to work with rast()
      aoi_vect <- terra::vect(aoi)

      # crop and mask raster using current aoi
      cropped_raster <- terra::crop(raster_data, aoi_vect)
      masked_raster <- terra::mask(cropped_raster, aoi_vect)

      # extract pixel values
      pixel_values <- as.data.frame(masked_raster)

      # add aoi id to pixel values df
      pixel_values$aoi_id <- aoi_id

      #add to list
      pixel_values_list[[i]] <- pixel_values

    }
    # combined all pixel values into one df for current raster
    all_pixel_values <- dplyr::bind_rows(pixel_values_list) |>
      na.omit()

    # add to overall list with all raster data pixel values
    all_pixel_values_list[[site_name]] <- all_pixel_values
  }
  combined_values <- dplyr::bind_rows(all_pixel_values_list, .id = 'site_name')

  return(combined_values)
}
