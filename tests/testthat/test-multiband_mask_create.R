
output_dir <- tempdir()

test_that('create_multiband_image works', {
  input_dir <- system.file("extdata/create_multiband_image", package = "saltbush")
  out <- create_multiband_image(input_dir,
                         c('blue', 'green', 'red', 'red_edge', 'nir'),
                         output_dir,
                         return_raster=TRUE)
  folder <- "extdata/create_multiband_image"
  output_filename <- file.path(output_dir, paste0(basename(folder), "_multiband_image"))
  file_that_should_exist <- paste0(output_filename, '.tif')
  expect_true(file.exists(file_that_should_exist))
  expect_type(out, "S4")
})

test_that('create_multiband_image processes every folder in a directory', {
  # build a parent dir holding two sub-folders, each with the band TIFs
  band_dir <- system.file("extdata/create_multiband_image", package = "saltbush")
  bands <- list.files(band_dir, pattern = "\\.tif$", full.names = TRUE)

  parent <- file.path(tempfile("multiband_multi_"))
  for (sub in c("plotA", "plotB")) {
    dir.create(file.path(parent, sub), recursive = TRUE)
    file.copy(bands, file.path(parent, sub, basename(bands)))
  }

  out <- create_multiband_image(
    parent,
    c('blue', 'green', 'red', 'red_edge', 'nir'),
    output_dir,
    return_raster = TRUE
  )

  # both folders should produce an output file ...
  expect_true(file.exists(file.path(output_dir, "plotA_multiband_image.tif")))
  expect_true(file.exists(file.path(output_dir, "plotB_multiband_image.tif")))
  # ... and a multi-folder call should return a named list, not just the first
  expect_type(out, "list")
  expect_setequal(names(out), c("plotA", "plotB"))
})

test_that('create_masked_raster works', {
  input <- system.file("extdata/multiband_image", package = "saltbush")
  a <- create_masked_raster(
    input,
    output_dir,
    ndvi_threshold = 0.02,
    nir_threshold = 0.04,
    red_band_index = 3,
    nir_band_index = 5,
    return_raster = TRUE
  )
  expect_type(a, "S4")
})

test_that('create_masked_raster processes every file in a directory', {
  src <- system.file("extdata/multiband_image/multiband_image.tif",
                     package = "saltbush")
  multi_in <- file.path(tempfile("masked_multi_"))
  dir.create(multi_in)
  # two input rasters with distinct site prefixes
  file.copy(src, file.path(multi_in, "alpha_image.tif"))
  file.copy(src, file.path(multi_in, "beta_image.tif"))

  out <- create_masked_raster(
    multi_in,
    output_dir,
    ndvi_threshold = 0.02,
    nir_threshold = 0.04,
    red_band_index = 3,
    nir_band_index = 5,
    return_raster = TRUE
  )

  expect_true(file.exists(file.path(output_dir, "alpha_image_masked.tif")))
  expect_true(file.exists(file.path(output_dir, "beta_image_masked.tif")))
  expect_type(out, "list")
  expect_length(out, 2)
})

test_that('create_masked_raster honours per-site threshold data frames', {
  src <- system.file("extdata/multiband_image/multiband_image.tif",
                     package = "saltbush")
  multi_in <- file.path(tempfile("masked_thresh_"))
  dir.create(multi_in)
  file.copy(src, file.path(multi_in, "alpha_image.tif"))
  file.copy(src, file.path(multi_in, "beta_image.tif"))

  ndvi_df <- data.frame(site = c("alpha", "beta"), threshold = c(0.02, 0.10))
  nir_df  <- data.frame(site = c("alpha", "beta"), threshold = c(0.04, 0.04))

  out <- create_masked_raster(
    multi_in,
    output_dir,
    ndvi_threshold_df = ndvi_df,
    nir_threshold_df = nir_df,
    return_raster = TRUE
  )
  # both site-specific thresholds resolve and produce masked output
  expect_true(file.exists(file.path(output_dir, "alpha_image_masked.tif")))
  expect_true(file.exists(file.path(output_dir, "beta_image_masked.tif")))
  expect_length(out, 2)
})

test_that('create_masked_raster errors when no files are found', {
  empty <- file.path(tempfile("empty_"))
  dir.create(empty)
  expect_error(
    create_masked_raster(empty, output_dir,
                         ndvi_threshold = 0.02, nir_threshold = 0.04),
    "No files found"
  )
})
