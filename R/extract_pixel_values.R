#' @title Extract pixel values
#'
#' @description Extracts pixel values from each layer of multiband image and creates pixel value df
#'
#' @param raster_files directory of input raster files
#' @param aoi_files area of interest file - shapefile containing one or more site polygons for each raster
#' @param wavelength_names the wavelength corresponding to each layer of the raster_files
#' @return a df with pixel values for each of the image layers
#' @examples
#' aoi_files <- list.files('inst/extdata/aoi',
#'    pattern = 'image_aoi.shp$', full.names = TRUE)
#' raster_files <- list.files('inst/extdata/multiband_image',
#'    pattern = '.tif$', full.names = TRUE)
#' pixelvalues <- extract_pixel_values(raster_files, aoi_files, c('blue','green','red','red_edge','nir'))
#' @export

extract_pixel_values <- function(raster_files, aoi_files, wavelength_names){

  all_pixel_values_list <- list()

  for (raster_file in raster_files) {

    # identify the string that represents the site name
    site_name <- stringr::str_extract(basename(raster_file), "^[^_]+")

    #choose the corresponding subplot file
    aoi_file <- aoi_files[grep(paste0('^', site_name), basename(aoi_files))]

    # read in aoi file and select geometries
    aois <- sf::read_sf(aoi_file) |>
      dplyr::select('geometry')

    # read in raster file
    raster_data <- raster::stack(raster_file)

    # apply consistent band names to each raster
    names(raster_data) <- wavelength_names

    # create empty list
    pixel_values_list <- list()

    for (i in 1:nrow(aois)){

      # select the i-th aoi and its id
      aoi <- aois[i, ]

      #aoi_id <- subplot$subplot_id
      aoi_id <- i

      # convert to spatial object
      aoi_sp <- as(aoi, "Spatial")

      # crop and mask raster using current subplot
      cropped_raster <- raster::crop(raster_data, aoi_sp)
      masked_raster <- raster::mask(cropped_raster, aoi_sp)

      # extract pixel values
      pixel_values  <- as.data.frame(raster::getValues(masked_raster))

      # add subplot id to pixel values df
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
