# Getting started with saltbush

This vignette walks through a complete spectral-diversity workflow using
only data shipped with the package, so it runs offline. The workflow has
two halves that you eventually combine:

1.  **From-the-sky:** turn drone imagery into spectral-diversity metrics
    per area-of-interest (AOI).
2.  **From-the-ground:** turn AusPlots point-intercept data into
    taxonomic-diversity metrics per site.

## 1. Build a multiband image from single-band TIFs

The example data ships with five single-band TIFs from a drone flight
over Fowlers Gap, NSW (`blue`, `green`, `red`, `red_edge`, `nir`).

``` r

input_dir <- system.file("extdata/create_multiband_image",
                         package = "saltbush")

multiband <- create_multiband_image(
  input_dir,
  desired_band_order = c("blue", "green", "red", "red_edge", "nir"),
  output_dir = tempdir(),
  return_raster = TRUE
)
```

## 2. Extract pixel values inside areas of interest

We then combine the multiband image with an area-of-interest shapefile.
The package ships a small aggregated raster and matching AOI for
demonstration:

``` r

raster_files <- list.files(
  system.file("extdata/example", package = "saltbush"),
  pattern = "\\.tif$", full.names = TRUE
)

aoi_files <- list.files(
  system.file("extdata/aoi", package = "saltbush"),
  pattern = "NSABHC0009_aoi\\.shp$", full.names = TRUE
)

pixel_values <- extract_pixel_values(
  raster_files, aoi_files,
  c("blue", "green", "red", "red_edge", "nir")
)
head(pixel_values)
#>    site_name       blue      green        red   red_edge        nir aoi_id
#> 1 NSABHC0009 0.05511368 0.05600401 0.07633078 0.06699516 0.08160288      1
#> 2 NSABHC0009 0.06224341 0.06684195 0.09760323 0.08534835 0.10119278      1
#> 3 NSABHC0009 0.05985198 0.06332091 0.08991133 0.07894940 0.09560681      1
#> 4 NSABHC0009 0.05927841 0.06296582 0.08709560 0.07646009 0.09347322      1
#> 5 NSABHC0009 0.04356062 0.04587397 0.06008397 0.05540059 0.07216450      1
#> 6 NSABHC0009 0.03945594 0.03824322 0.04755034 0.04384791 0.05770193      1
```

## 3. Calculate spectral metrics

[`calculate_spectral_metrics()`](https://traitecoevo.github.io/saltbush/reference/calculate_cv.md)
returns three metrics per AOI:

- **CV** — coefficient of variation
- **SV** — spectral variance
- **CHV** — convex hull volume

``` r

metrics <- calculate_spectral_metrics(
  pixel_values,
  wavelengths = c("blue", "green", "red", "red_edge", "nir"),
  masked = FALSE,
  rarefaction = FALSE
)
metrics
#>          site aoi_id       CV          SV          CHV image_type
#>        <char>  <num>    <num>       <num>        <num>     <char>
#> 1: NSABHC0009      1 0.334488 0.001761305 3.347609e-10   unmasked
```

See the manuscript referenced in
[`?saltbush`](https://traitecoevo.github.io/saltbush/reference/saltbush.md)
for the full definitions and a discussion of when each metric is most
useful.

## 4. Compute on-the-ground taxonomic diversity

For the from-the-ground side, the package ships a cached AusPlots
point-intercept dataset for the same site (`NSABHC0009`) so the worked
example does not need network access:

``` r

field_diversity <- calculate_field_diversity(ausplots_NSABHC0009)
field_diversity$taxonomic_diversity
#>        site_unique site_location_name species_richness shannon_diversity
#> 1 NSABHC0009-58026         NSABHC0009               52          3.056908
#> 2 NSABHC0009-53604         NSABHC0009               38          2.843074
#>   simpson_diversity pielou_evenness exp_shannon inv_simpson
#> 1         0.9203249       0.7736571    21.26171    12.55097
#> 2         0.9043699       0.7815826    17.16846    10.45696
```

The returned metrics are species richness, Shannon’s diversity,
Simpson’s diversity, Pielou’s evenness, exponential Shannon’s, and
inverse Simpson’s.

To pull a fresh query from the AusPlots database (or to query other
plots), use
[`ausplotsR::get_ausplots()`](https://rdrr.io/pkg/ausplotsR/man/get_ausplots.html):

``` r

my.data <- ausplotsR::get_ausplots(
  my.Plot_IDs = c("NSABHC0009"), veg.PI = TRUE
)
calculate_field_diversity(my.data$veg.PI)
```

## 5. Comparing the two

High-resolution drone images are very large; the example data shipped
with the package is intentionally small (just enough to run examples and
tests). To compare spectral and taxonomic diversity meaningfully, run
the above steps on the full-resolution imagery for your own sites.
