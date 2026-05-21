# Calculate spectral metrics

Calculates CV, SV, and CHV from a pixel values dataframe with columns
for each wavelength, `site_name`, and `aoi_id`. This help file applies
to the functions `calculate_cv`, `calculate_sv`, `calculate_chv_nopca`,
and `calculate_spectral_metrics`.

## Usage

``` r
calculate_cv(
  pixel_values_df,
  wavelengths,
  rarefaction = FALSE,
  min_points = NULL,
  n = NULL,
  seed = NULL
)
```

## Arguments

- pixel_values_df:

  A data frame containing pixel values, typically obtained from the
  `extract_pixel_values` function.

- wavelengths:

  A list of wavelengths that correspond to column names in
  `pixel_values_df`.

- rarefaction:

  Logical; if TRUE, applies a rarefaction step that increases processing
  time.

- min_points:

  Integer; minimum number of pixels per `aoi` to standardize uneven
  pixel numbers across sites (used if `rarefaction = TRUE`).

- n:

  Integer; number of subset permutations if `rarefaction = TRUE`.

- seed:

  Integer or NULL; if provided, `set.seed(seed)` is called once at the
  start of the function so the rarefaction sampling is reproducible.
  Default `NULL` preserves the prior unseeded behaviour.

## Value

A dataframe containing spectral metrics for each `aoi` within each
site/raster.

## Examples

``` r
set.seed(123)
df <- data.frame(
  site_name = rep(c("site_one", "site_two", "site_three", "site_four"), each = 5000),
  aoi_id = 1,
  blue = runif(20000, min = 0, max = 1),
  green = runif(20000, min = 0, max = 1),
  red = runif(20000, min = 0, max = 1),
  red_edge = runif(20000, min = 0, max = 1),
  nir = runif(20000, min = 0, max = 1))
spectral_metrics <- calculate_spectral_metrics(df,
   wavelengths = c('blue','green','red','red_edge','nir'),
   rarefaction = TRUE, min_points = 50, n = 5)
```
