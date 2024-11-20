
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
