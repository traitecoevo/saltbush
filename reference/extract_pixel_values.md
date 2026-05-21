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
#> 1 multiband 0.03750095 0.03304399 0.03984483 0.03645324 0.04979400      1
#> 2 multiband 0.03798384 0.03373412 0.03947096 0.03652928 0.05102636      1
#> 3 multiband 0.03175478 0.02842239 0.03414677 0.03178068 0.04547324      1
#> 4 multiband 0.02911395 0.02666309 0.03321973 0.03026468 0.04321014      1
#> 5 multiband 0.02750703 0.02511015 0.03399214 0.03055668 0.04304870      1
#> 6 multiband 0.02555116 0.02415056 0.03301881 0.03088302 0.04350081      1
```
