# Create masked raster from multiband image

This function creates a masked raster by removing non-vegetation pixels
based on NDVI and NIR threshold values. It supports processing single
files, multiple files in a directory, or a list of file paths. Threshold
values can be specified as single values or as a data frame with
site-specific thresholds. The function assumes that the input layers are
stacked in wavelength order and saves the masked raster to the specified
output directory.

## Usage

``` r
create_masked_raster(
  input,
  output_dir = tempdir(),
  ndvi_threshold = NULL,
  nir_threshold = NULL,
  ndvi_threshold_df = NULL,
  nir_threshold_df = NULL,
  red_band_index = 3,
  nir_band_index = 5,
  make_plot = FALSE,
  return_raster = FALSE
)
```

## Arguments

- input:

  A directory containing multiple ENVI or TIF files, a single file, or a
  character vector of file paths.

- output_dir:

  A directory where the masked raster(s) will be saved.

- ndvi_threshold:

  Numeric. NDVI threshold for masking (pixels with NDVI values below
  this are masked as non-vegetation).

- nir_threshold:

  Numeric. NIR threshold for masking (pixels with NIR values below this
  are masked as shadows).

- ndvi_threshold_df:

  Optional. A data frame with two columns: `site` (site identifiers) and
  `threshold` (NDVI threshold values for each site). The `site` values
  must match the beginning of the input file names.

- nir_threshold_df:

  Optional. A data frame with two columns: `site` (site identifiers) and
  `threshold` (NIR threshold values for each site). The `site` values
  must match the beginning of the input file names.

- red_band_index:

  Integer. The index (layer number) of the red band in the input raster.
  Default is 3.

- nir_band_index:

  Integer. The index (layer number) of the NIR band in the input raster.
  Default is 5.

- make_plot:

  Logical. If `TRUE`, a plot of the masked raster is generated for
  verification. Default is `FALSE`.

- return_raster:

  Logical. If `TRUE`, the masked raster object is returned. Default is
  `FALSE`.

## Value

Saves masked raster(s) as TIF files in the specified `output_dir`. If
`return_raster = TRUE`, the function returns the masked raster object as
a `terra` raster.

## Examples

``` r

input <- system.file("extdata/multiband_image", package = "saltbush")
output_dir <- tempdir()
create_masked_raster(input,
                    output_dir,
                    ndvi_threshold = 0.02,
                   nir_threshold = 0.04,
                     red_band_index = 3,
                     nir_band_index = 5)
#> [1] "Files found: /home/runner/work/_temp/Library/saltbush/extdata/multiband_image/multiband_image.tif"
#> [1] "Masked raster saved to: /tmp/RtmphYGLcI/multiband_image_masked.tif"
```
