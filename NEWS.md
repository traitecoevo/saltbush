# saltbush (development version)

* `calculate_spectral_metrics()` now calculates CV, SV and CHV directly from
  rasters and AOI files, replacing `extract_pixel_values()`, which is removed.
  Results match the previous pipeline (see `tests/testthat/test-reference_metrics.R`).
* AOI files can be GeoJSON or GeoPackage as well as shapefiles. AOIs in a
  different coordinate system from the imagery are reprojected, with a message.
* Rarefaction now checks `min_points` against each AOI rather than the whole
  site, and `seed` is set once per call so sites get independent draws.
* `find_optimum_thresholds()` now handles several `class_value`s correctly.
* `calculate_cv()`, `calculate_sv()` and `calculate_chv_nopca()` no longer
  convert the caller's data frame to a data.table in place.
* `stringr` is no longer a dependency.

# saltbush 0.1.0

* Initial release.
* From-the-sky spectral diversity: build multiband images from single-band
  drone TIFs (`create_multiband_image()`), mask non-vegetation pixels with
  NDVI/NIR thresholds (`create_masked_raster()`, `find_optimum_thresholds()`),
  extract per-AOI pixel values (`extract_pixel_values()`), and compute spectral
  metrics — coefficient of variation, spectral variance, and convex hull volume
  (`calculate_spectral_metrics()` and the underlying `calculate_cv()`,
  `calculate_sv()`, `calculate_chv_nopca()`).
* From-the-ground taxonomic diversity from AusPlots point-intercept surveys
  (`calculate_field_diversity()`): species richness, Shannon, Simpson, Pielou's
  evenness, exponential Shannon, and inverse Simpson.
* Bundled example data (`synthetic_survey`, `ausplots_NSABHC0009`, and example
  drone rasters) so examples, tests, and the vignette run offline.
