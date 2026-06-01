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
    raster_files, aoi_files, c('blue','green','red','red_edge','nir')
  )
  expect_true(dim(pixelvalues)[1] > 50000)
  expect_true(mean(pixelvalues[,3]) > 0.05 & mean(pixelvalues[,3]) < 0.06)
})

test_that("extract_pixel_values honours aoi_id_col", {
  aoi_files <- list.files(
    system.file("extdata/aoi", package = "saltbush"),
    pattern = 'image_aoi.shp$', full.names = TRUE
  )
  raster_files <- list.files(
    system.file("extdata/multiband_image", package = "saltbush"),
    pattern = '.tif$', full.names = TRUE
  )

  # pick whichever non-geometry column the bundled AOI shapefile happens to expose
  aoi_cols <- setdiff(names(sf::read_sf(aoi_files[1])), "geometry")
  skip_if(length(aoi_cols) == 0, "bundled AOI shapefile has no attribute columns")
  id_col <- aoi_cols[1]

  pv <- extract_pixel_values(
    raster_files, aoi_files, c('blue','green','red','red_edge','nir'),
    aoi_id_col = id_col
  )
  expected_ids <- sf::read_sf(aoi_files[1])[[id_col]]
  expect_true(all(unique(pv$aoi_id) %in% expected_ids))

  # unknown column should error clearly
  expect_error(
    extract_pixel_values(raster_files, aoi_files,
                         c('blue','green','red','red_edge','nir'),
                         aoi_id_col = "definitely_not_a_column"),
    "not found"
  )
})
