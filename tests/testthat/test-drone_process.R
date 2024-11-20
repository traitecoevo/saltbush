set.seed(123)
ndvi_values <- data.frame(site = rep(c("site_one", "site_two"), each = 100),
                          point = rep(1:100, times = 2),
                          ndvi = runif(200, min = -1, max = 1),
                          class = sample(rep(c('veg', 'non-veg'), each = 100)))


test_that("find_optimum_thresholds works", {
ndvi_thresholds <- find_optimum_thresholds(ndvi_values,
                                           class_col = 'class', band_or_index_col = 'ndvi',
                                           site_col = 'site', class_value = 'non-veg')
expect_true(ndvi_thresholds$threshold[1] > -1)
expect_true(ndvi_thresholds$threshold[1] < 1)
})



test_that("extract_pixel_values works", {
  aoi_files <- list.files(
    system.file("extdata/aoi", package = "saltbush"),
    pattern = 'image_aoi.shp$', full.names = TRUE
  )
  raster_files <- list.files(
    system.file("extdata/multiband_image", package = "saltbush"),
    pattern = '.tif$', full.names = TRUE
  )
  pixelvalues <- extract_pixel_values(
    raster_files, aoi_files
  )
  expect_true(dim(pixelvalues)[1] > 2000000)
  expect_true(mean(pixelvalues[,3]) > 0.05 & mean(pixelvalues[,3]) < 0.06)
})
