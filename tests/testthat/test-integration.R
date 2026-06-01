test_that("full pipeline: multiband image -> pixel values -> spectral metrics", {
  wavelengths <- c("blue", "green", "red", "red_edge", "nir")

  # AOI matched by extract_pixel_values via the raster's site-name prefix, so the
  # combined raster must be named so its prefix matches "multiband_image_aoi".
  aoi_files <- list.files(
    system.file("extdata/aoi", package = "saltbush"),
    pattern = "multiband_image_aoi\\.shp$", full.names = TRUE
  )
  n_aoi <- nrow(sf::read_sf(aoi_files[1]))

  # 1. build a multiband image from the bundled single-band TIFs. Put them in a
  #    folder named "multiband" so the output prefix lines up with the AOI.
  bands <- list.files(
    system.file("extdata/create_multiband_image", package = "saltbush"),
    pattern = "\\.tif$", full.names = TRUE
  )
  input_dir <- file.path(tempfile("pipeline_in_"), "multiband")
  dir.create(input_dir, recursive = TRUE)
  file.copy(bands, file.path(input_dir, basename(bands)))

  out_dir <- tempfile("pipeline_out_")
  dir.create(out_dir)
  create_multiband_image(input_dir, wavelengths, out_dir)

  combined <- list.files(out_dir, pattern = "\\.tif$", full.names = TRUE)
  expect_length(combined, 1)

  # 2. extract pixel values inside the AOIs
  pixel_values <- extract_pixel_values(combined, aoi_files, wavelengths)
  expect_true(all(c(wavelengths, "site_name", "aoi_id") %in% names(pixel_values)))
  expect_gt(nrow(pixel_values), 0)

  # 3. compute spectral metrics
  metrics <- calculate_spectral_metrics(
    pixel_values, wavelengths = wavelengths,
    masked = FALSE, rarefaction = FALSE
  )

  # output shape: one row per AOI, with the expected metric columns
  expect_equal(nrow(metrics), n_aoi)
  expect_setequal(
    names(metrics),
    c("site", "aoi_id", "CV", "SV", "CHV", "image_type")
  )
  expect_setequal(metrics$aoi_id, seq_len(n_aoi))
  expect_true(all(metrics$image_type == "unmasked"))

  # metrics are finite, non-negative numbers
  for (col in c("CV", "SV", "CHV")) {
    expect_true(is.numeric(metrics[[col]]))
    expect_true(all(is.finite(metrics[[col]])))
    expect_true(all(metrics[[col]] >= 0))
  }
})
