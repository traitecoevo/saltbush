# Calculate spectral metrics

Calculates CV, SV, and CHV for each area of interest (AOI) directly from
multiband rasters, without first extracting every pixel into a data
frame. Each raster is cropped and masked to each AOI polygon; CV and SV
are calculated from per-band summary statistics
([`terra::global()`](https://rspatial.github.io/terra/reference/global.html)),
and CHV from the matrix of pixel values within the AOI.

Spectral variance (SV) is standardized by the number of spectral points,
so it is not rarefied; `rarefaction` applies to CV and CHV only.

## Usage

``` r
calculate_spectral_metrics(
  raster_files,
  aoi_files,
  wavelengths,
  aoi_id_col = NULL,
  masked = TRUE,
  rarefaction = FALSE,
  min_points = NULL,
  n = NULL,
  seed = NULL
)
```

## Arguments

- raster_files:

  Character vector of multiband raster file paths. The site name is
  taken from the start of each file name, up to the first `_` or `.` (or
  the whole name, minus extension, if there is neither), so
  `NSABHC0009_ortho.tif`, `NSABHC0009.ortho.tif` and `NSABHC0009.tif`
  all give the site `NSABHC0009`.

- aoi_files:

  Character vector of AOI file paths: shapefiles (`.shp`), GeoJSON
  (`.geojson`/`.json`) or GeoPackage (`.gpkg`), each containing one or
  more AOI polygons. Each raster is matched to the AOI file with the
  same site name, found the same way (e.g. `NSABHC0009_aoi.shp`). Files
  with other extensions (e.g. a shapefile's `.dbf`) are ignored. If an
  AOI's coordinate system differs from its raster's, the AOI is
  reprojected to match.

- wavelengths:

  Character vector naming the wavelength of each raster layer, in layer
  order.

- aoi_id_col:

  Optional character; name of a column in the AOI file to use as the
  `aoi_id`. When `NULL` (default), AOIs are numbered `1:n`.

- masked:

  Logical; labels the output `image_type` as `"masked"` or `"unmasked"`.
  It does not mask the image.

- rarefaction:

  Logical; if `TRUE`, CV and CHV are averaged over `n` random subsamples
  of `min_points` pixels per AOI, which standardizes uneven pixel
  numbers across AOIs and increases processing time.

- min_points:

  Integer; pixels sampled per AOI when `rarefaction = TRUE`.

- n:

  Integer; number of subsamples when `rarefaction = TRUE`.

- seed:

  Integer or `NULL`; if provided, `set.seed(seed)` is called once at the
  start so the rarefaction sampling is reproducible.

## Value

A data frame with one row per AOI per raster, and columns `site`,
`aoi_id`, `CV`, `SV`, `CHV` and `image_type`.

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
metrics <- calculate_spectral_metrics(
  raster_files, aoi_files,
  wavelengths = c("blue", "green", "red", "red_edge", "nir"),
  masked = FALSE
)
metrics
#>        site aoi_id        CV          SV          CHV image_type
#> 1 multiband      1 0.3355707 0.004328054 3.053635e-09   unmasked
#> 2 multiband      2 0.3642174 0.003440723 3.238245e-09   unmasked
#> 3 multiband      3 0.4671316 0.003904554 3.234787e-09   unmasked
#> 4 multiband      4 0.3758902 0.001296762 1.625732e-09   unmasked
```
