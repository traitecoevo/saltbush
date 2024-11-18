set.seed(123)
df <- data.frame(
  site_name = rep(c("site_one", "site_two", "site_three", "site_four"), each = 5000),
  aoi_id = 1,
  blue = runif(20000, min = 0, max = 1),
  green = runif(20000, min = 0, max = 1),
  red = runif(20000, min = 0, max = 1),
  red_edge = runif(20000, min = 0, max = 1),
  nir = runif(20000, min = 0, max = 1))

test_that("calculate_cv works", {
  pixelvalues <- calculate_cv(df,
  wavelengths = c('blue','green','red','red_edge','nir'),
  rarefaction = TRUE, min_points = 100, n = 20)
  expect_type(pixelvalues,"list")
  expect_true(pixelvalues$CV<6)
  expect_true(pixelvalues$aoi_id==1)
})


test_that("calculate_spectral_metrics works", {
  spectral_metrics <- calculate_spectral_metrics(df,
                              wavelengths = c('blue','green','red','red_edge','nir'),
                              rarefaction = TRUE, min_points = 100, n = 20)
  expect_type(spectral_metrics,"list")
   expect_true(all(spectral_metrics$CV<1))
   expect_true(all(spectral_metrics$SV<0.5))
   expect_true(all(spectral_metrics$CHV_nopca<0.4))
   expect_true(all(spectral_metrics$aoi_id==1))
   expect_true(all(spectral_metrics$image_type=='masked'))
   spectral_metrics_no_rare <- calculate_spectral_metrics(df,
                                                  wavelengths = c('blue','green','red','red_edge','nir'),
                                                  rarefaction = FALSE, min_points = 100, n = 20)
   expect_type(spectral_metrics_no_rare,"list")
})

test_that("extract_pixel_values works", {
  aoi_files <- list.files(
    system.file("extdata/fishnet", package = "saltbush"),
    pattern = '_fishnet.shp$', full.names = TRUE
  )
  raster_files <- list.files(
    system.file("extdata/multiband_image", package = "saltbush"),
    pattern = '.tif$', full.names = TRUE
  )
  pixelvalues <- extract_pixel_values(
    raster_files, aoi_files, c('blue', 'green', 'red', 'red_edge', 'nir')
  )
  expect_true(dim(pixelvalues)[1] > 20000)
  expect_true(mean(pixelvalues[,3]) > 0.05 & mean(pixelvalues[,3]) < 0.06)
})

