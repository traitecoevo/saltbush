# Extract pixel values

Extracts pixel values from each layer of multiband image and creates
pixel value df

## Usage

``` r
extract_pixel_values(
  raster_files,
  aoi_files,
  wavelength_names,
  aoi_id_col = NULL
)
```

## Arguments

- raster_files:

  directory of input raster files

- aoi_files:

  area of interest file - shapefile containing one or more site polygons
  for each raster

- wavelength_names:

  the wavelength corresponding to each layer of the raster_files

- aoi_id_col:

  Optional character; name of a column in the AOI shapefile to use as
  the per-feature `aoi_id`. When `NULL` (default), the loop index
  (`1:nrow(aois)`) is used, preserving the prior behaviour.

## Value

a df with pixel values for each of the image layers

## Examples

``` r
aoi_files <- list.files(
  system.file("extdata/aoi", package = "saltbush"),
  pattern = "image_aoi\\.shp$", full.names = TRUE
)
raster_files <- list.files(
  system.file("extdata/multiband_image", package = "saltbush"),
  pattern = "\\.tif$", full.names = TRUE
)
pixelvalues <- extract_pixel_values(
  raster_files, aoi_files,
  c("blue", "green", "red", "red_edge", "nir")
)
head(pixelvalues)
#>   site_name       blue      green        red   red_edge        nir aoi_id
#> 1 multiband 0.03053215 0.02762508 0.03422303 0.03204655 0.04544833      1
#> 2 multiband 0.02969479 0.02802257 0.03633698 0.03352161 0.04693317      1
#> 3 multiband 0.03249682 0.03136711 0.03844569 0.03942563 0.05642904      1
#> 4 multiband 0.03493863 0.03310391 0.03810677 0.04214884 0.05958011      1
#> 5 multiband 0.02884123 0.02728638 0.03460838 0.03393935 0.04832237      1
#> 6 multiband 0.02880337 0.02600810 0.03278240 0.02990507 0.04222868      1
```
