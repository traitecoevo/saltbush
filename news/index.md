# Changelog

## saltbush 0.1.0

- Initial release.
- From-the-sky spectral diversity: build multiband images from
  single-band drone TIFs
  ([`create_multiband_image()`](https://traitecoevo.github.io/saltbush/reference/create_multiband_image.md)),
  mask non-vegetation pixels with NDVI/NIR thresholds
  ([`create_masked_raster()`](https://traitecoevo.github.io/saltbush/reference/create_masked_raster.md),
  [`find_optimum_thresholds()`](https://traitecoevo.github.io/saltbush/reference/find_optimum_thresholds.md)),
  extract per-AOI pixel values
  ([`extract_pixel_values()`](https://traitecoevo.github.io/saltbush/reference/extract_pixel_values.md)),
  and compute spectral metrics — coefficient of variation, spectral
  variance, and convex hull volume
  ([`calculate_spectral_metrics()`](https://traitecoevo.github.io/saltbush/reference/calculate_cv.md)
  and the underlying
  [`calculate_cv()`](https://traitecoevo.github.io/saltbush/reference/calculate_cv.md),
  [`calculate_sv()`](https://traitecoevo.github.io/saltbush/reference/calculate_cv.md),
  [`calculate_chv_nopca()`](https://traitecoevo.github.io/saltbush/reference/calculate_cv.md)).
- From-the-ground taxonomic diversity from AusPlots point-intercept
  surveys
  ([`calculate_field_diversity()`](https://traitecoevo.github.io/saltbush/reference/calculate_field_diversity.md)):
  species richness, Shannon, Simpson, Pielou’s evenness, exponential
  Shannon, and inverse Simpson.
- Bundled example data (`synthetic_survey`, `ausplots_NSABHC0009`, and
  example drone rasters) so examples, tests, and the vignette run
  offline.
