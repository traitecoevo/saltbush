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
