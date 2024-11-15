test_that("calculate_cv works", {
  set.seed(123)
  df <- data.frame(
  site_name = rep(c("site_one", "site_two", "site_three", "site_four"), each = 5000),
  aoi_id = 1,
  blue = runif(20000, min = 0, max = 1),
  green = runif(20000, min = 0, max = 1),
  red = runif(20000, min = 0, max = 1),
  red_edge = runif(20000, min = 0, max = 1),
  nir = runif(20000, min = 0, max = 1))
  pixelvalues <- calculate_cv(df,
  wavelengths = c('blue','green','red','red_edge','nir'),
  rarefaction = TRUE, min_points = 5000, n = 999)
  expect_true(pixelvalues$CV<0.6)
  expect_true(pixelvalues$aoi_id==1)
})

test_that("extract_pixel_values works", {
 aoi_files <- list.files('../../inst/extdata/fishnet',
    pattern = '_fishnet.shp$', full.names = TRUE)
 raster_files <- list.files('../../inst/extdata/multiband_image',
    pattern = '.tif$', full.names = TRUE)
 pixelvalues <- extract_pixel_values(raster_files, aoi_files,
    c('blue', 'green', 'red', 'red_edge', 'nir'))
 expect_true(dim(pixelvalues)[1]>20000)
 expect_true(mean(pixelvalues[,3])>0.05 & mean(pixelvalues[,3])<0.06)
})

