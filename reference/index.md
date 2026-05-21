# Package index

## Drone imagery processing

Build multiband images, mask non-vegetation pixels, and extract per-AOI
pixel values from drone imagery.

- [`create_multiband_image()`](https://traitecoevo.github.io/saltbush/reference/create_multiband_image.md)
  : Create a multiband image from single-band TIF files
- [`create_masked_raster()`](https://traitecoevo.github.io/saltbush/reference/create_masked_raster.md)
  : Create masked raster from multiband image
- [`find_optimum_thresholds()`](https://traitecoevo.github.io/saltbush/reference/find_optimum_thresholds.md)
  : Find optimum thresholds
- [`extract_pixel_values()`](https://traitecoevo.github.io/saltbush/reference/extract_pixel_values.md)
  : Extract pixel values

## Spectral diversity

Calculate coefficient of variation (CV), spectral variance (SV), and
convex hull volume (CHV) from extracted pixel values.

- [`calculate_cv()`](https://traitecoevo.github.io/saltbush/reference/calculate_cv.md)
  : Calculate spectral metrics

## On-the-ground diversity

Compute taxonomic-diversity metrics from AusPlots point-intercept survey
data.

- [`calculate_field_diversity()`](https://traitecoevo.github.io/saltbush/reference/calculate_field_diversity.md)
  : Calculate field diversity

## Example data

Datasets bundled with the package for use in examples, tests, and the
vignette.

- [`synthetic_survey`](https://traitecoevo.github.io/saltbush/reference/synthetic_survey.md)
  : Synthetic point-intercept survey data
- [`ausplots_NSABHC0009`](https://traitecoevo.github.io/saltbush/reference/ausplots_NSABHC0009.md)
  : Cached AusPlots point-intercept data for site NSABHC0009
