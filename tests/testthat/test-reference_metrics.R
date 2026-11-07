# The raster-based calculate_spectral_metrics() must reproduce the metrics from
# the original pixel-extraction pipeline. Reference values are built by
# the original code at commit 0e28d41 (attr(reference, "commit")).

wavelengths <- c("blue", "green", "red", "red_edge", "nir")
ext <- function(...) system.file("extdata", ..., package = "saltbush")
aoi_files <- list.files(ext("aoi"), pattern = "\\.shp$", full.names = TRUE)
reference <- readRDS(test_path("fixtures", "reference_metrics.rds"))

expect_matches_reference <- function(metrics, ref) {
  expect_equal(metrics$site, ref$site)
  expect_equal(as.numeric(metrics$aoi_id), as.numeric(ref$aoi_id))
  # compare as ratios: SV and CHV are tiny (~1e-3, ~1e-9), and an absolute
  # tolerance would let real differences through
  for (metric in c("CV", "SV", "CHV")) {
    expect_equal(metrics[[metric]] / ref[[metric]], rep(1, nrow(ref)),
                 tolerance = 1e-6, label = metric)
  }
  expect_equal(metrics$image_type, ref$image_type)
}

test_that("unmasked rasters reproduce the original pipeline's metrics", {
  metrics <- calculate_spectral_metrics(
    c(ext("multiband_image", "multiband_image.tif"),
      ext("example", "NSABHC0009_aggregated.tif")),
    aoi_files, wavelengths, masked = FALSE
  )
  expect_matches_reference(metrics, reference$unmasked)
})

test_that("masked raster (with NA pixels) reproduces the original pipeline's metrics", {
  masked_dir <- tempfile("reference_masked_")
  dir.create(masked_dir)
  create_masked_raster(ext("multiband_image", "multiband_image.tif"), masked_dir,
                       ndvi_threshold = 0.02, nir_threshold = 0.04)

  metrics <- calculate_spectral_metrics(
    file.path(masked_dir, "multiband_image_masked.tif"),
    aoi_files, wavelengths, masked = TRUE
  )
  expect_matches_reference(metrics, reference$masked)
})
