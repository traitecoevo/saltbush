#' @title Extract pixel values
#' @description Extracts pixel values from each layer of multiband image and creates pixel value df
#' @param raster_files directory of input raster files
#' @param aoi_files area of interest file - shapefile containing one or more site polygons for each raster
#' @param wavelength_names wavelength names for each band, must match order of stacked layers
#' @return a df with pixel values for each of the image layers
#' @examples
#' unmasked_pixel_values <- extract_pixel_values(raster_files_unmasked, subplot_files, c('blue', 'green', 'red', 'red_edge', 'nir'))
#' @export
#' @import raster
#' @import dplyr
#' @import sf
#' @import stringr

extract_pixel_values <- function(raster_files, aoi_files, wavelength_names){

  all_pixel_values_list <- list()

  for (raster_file in raster_files) {

    # identify the string that represents the site name
    site_name <- str_extract(basename(raster_file), "^[^_]+")

    #choose the corresponding subplot file
    subplot_file <- aoi_files[grep(paste0('^', site_name), basename(aoi_files))]

    # read in subplot file and select geometries
    subplots <- read_sf(subplot_file) %>%
      dplyr::select('geometry')

    # apply subplot ids
    # subplots$subplot_id <- unlist(lapply(1:5, function(i) paste(i, 1:5, sep="_")))

    # read in raster file
    raster_data <- stack(raster_file)

    # apply names - should be saved in wavelength order as per sect 1 of this script
    names(raster_data) <- wavelength_names

    # create empty list
    pixel_values_list <- list()

    for (i in 1:nrow(subplots)){

      # select the i-th subplot and its id
      subplot <- subplots[i, ]
      #subplot_id <- subplot$subplot_id
      subplot_id <- i

      # convert to spatial object
      subplot_sp <- as(subplot, "Spatial")

      # crop and mask raster using current subplot
      cropped_raster <- crop(raster_data, subplot_sp)
      masked_raster <- mask(cropped_raster, subplot_sp)

      # extract pixel values
      pixel_values  <- as.data.frame(getValues(masked_raster))

      # add subplot id to pixel values df
      pixel_values$aoi_id <- subplot_id

      #add to list
      pixel_values_list[[i]] <- pixel_values

    }
    # combined all pixel values into one df for current raster
    all_pixel_values <- bind_rows(pixel_values_list) %>%
      na.omit()

    # add to overall list with all raster data pixel values
    all_pixel_values_list[[site_name]] <- all_pixel_values
  }
  combined_values <- bind_rows(all_pixel_values_list, .id = 'site_name')

  return(combined_values)
}
