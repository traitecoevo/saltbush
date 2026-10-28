# saltbush (development version)

* `calculate_spectral_metrics()` now calculates CV, SV and CHV directly from
  rasters and AOI files, replacing `extract_pixel_values()`, which is removed.
  Results match the previous pipeline (see `tests/testthat/test-reference_metrics.R`).
* AOI files can be GeoJSON or GeoPackage as well as shapefiles. AOIs in a
  different coordinate system from the imagery are reprojected, with a message.
* AOI files can hold several polygons (one row of metrics each). An AOI outside
  the image, or with too few pixels for a convex hull, now gives NA metrics and
  a warning instead of stopping the run; duplicate `aoi_id_col` values warn.
* Rarefaction now checks `min_points` against each AOI rather than the whole
  site, uses the same subsample for CV and CHV in each draw, and sets `seed`
  once per call so sites get independent draws.
* `find_optimum_thresholds()` now handles several `class_value`s correctly.
* `create_multiband_image()` checks that all bands share extent, resolution
  and CRS before stacking, and lists any that differ.
* `create_multiband_image()` matches band files whose names end with the band
  name, so Pix4D output (e.g. `NSABHC0009_transparent_reflectance_blue.tif`)
  works without renaming. Other TIFs in the folder are ignored.
* The data-frame helpers `calculate_cv()`, `calculate_sv()` and
  `calculate_chv_nopca()` are removed; use `calculate_spectral_metrics()`.
* `calculate_field_diversity()`: `group_by_cols` is renamed `aoi_cols`; the old
  name still works with a deprecation warning.
* `calculate_field_diversity()` gains `species_col`, `exclude` and
  `abundance_col`, so it works on survey data beyond AusPlots point-intercepts
  (e.g. cover or count data). Defaults reproduce the previous results exactly.
* `data.table` and `stringr` are no longer dependencies.

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
