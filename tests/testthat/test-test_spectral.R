set.seed(9)
df_test <- data.frame(
  aoi_id = rep(1:2, each = 10),
  blue = c(runif(10, 0.1, 0.4), runif(10, 0.4, 0.7)),
  green = c(runif(10, 0.2, 0.5), runif(10, 0.5, 0.8)),
  red = c(runif(10, 0.3, 0.6), runif(10, 0.6, 0.9))
)

test_that('calculate_cv works', {
  cv <- calculate_cv(df_test,
                     wavelengths = colnames(df_test[, 2:4]),
                     rarefaction = F)
  expect_equal(round(cv$CV[1], 3),  0.296)
  expect_equal(round(cv$CV[2], 3), 0.143)
})

test_that('calculate_sv works', {
  sv <- calculate_sv(df_test,
                     wavelengths = colnames(df_test[, 2:4]))
  expect_equal(round(sv$SV[1], 5), 0.02631)
  expect_equal(round(sv$SV[2], 5), 0.02660)
})

test_that('calculate_chv_nopca works', {
  chv <- calculate_chv_nopca(df_test,
                             wavelengths = colnames(df_test[, 2:4]),
                             rarefaction = F)
  expect_equal(round(chv$CHV[1], 5), 0.00612)
  expect_equal(round(chv$CHV[2], 5), 0.00663)
})

test_that('data frame helpers leave the input unchanged', {
  input <- df_test
  calculate_cv(input, wavelengths = colnames(df_test[, 2:4]))
  calculate_sv(input, wavelengths = colnames(df_test[, 2:4]))
  calculate_chv_nopca(input, wavelengths = colnames(df_test[, 2:4]))
  expect_identical(input, df_test)
  expect_false(data.table::is.data.table(input))
})

test_that('data frame helpers check min_points against every aoi', {
  # aoi 1 has 10 pixels, aoi 3 only 4
  uneven <- rbind(df_test, data.frame(aoi_id = 3, blue = runif(4),
                                      green = runif(4), red = runif(4)))
  expect_error(
    calculate_cv(uneven, wavelengths = colnames(df_test[, 2:4]),
                 rarefaction = TRUE, min_points = 5, n = 2),
    "exceeds the number of pixels in aoi: 3 \\(4\\)"
  )
  expect_error(
    calculate_chv_nopca(uneven, wavelengths = colnames(df_test[, 2:4]),
                        rarefaction = TRUE, min_points = 5, n = 2),
    "exceeds the number of pixels in aoi: 3 \\(4\\)"
  )
})


# raster-based calculate_spectral_metrics ---------------------------------

wavelengths <- c('blue', 'green', 'red', 'red_edge', 'nir')
raster_file <- system.file("extdata/multiband_image/multiband_image.tif",
                           package = "saltbush")
aoi_file <- system.file("extdata/aoi/multiband_image_aoi.shp", package = "saltbush")

test_that('calculate_spectral_metrics works', {
  metrics <- calculate_spectral_metrics(raster_file, aoi_file, wavelengths)
  expect_equal(nrow(metrics), nrow(sf::read_sf(aoi_file)))
  expect_named(metrics, c("site", "aoi_id", "CV", "SV", "CHV", "image_type"))
  expect_true(all(metrics$site == 'multiband'))
  expect_true(all(metrics$image_type == 'masked'))
})

test_that('calculate_spectral_metrics works with rarefaction', {
  full <- calculate_spectral_metrics(raster_file, aoi_file, wavelengths)
  rare <- calculate_spectral_metrics(raster_file, aoi_file, wavelengths,
                                     rarefaction = TRUE, min_points = 500,
                                     n = 5, seed = 1)
  # SV is not rarefied
  expect_equal(rare$SV, full$SV)
  # subsampled CV is close to the full CV; CHV of a subsample is smaller
  expect_equal(rare$CV, full$CV, tolerance = 0.1)
  expect_true(all(rare$CHV <= full$CHV))
})

test_that('seed makes rarefaction reproducible', {
  args <- list(raster_file, aoi_file, wavelengths,
               rarefaction = TRUE, min_points = 50, n = 3)

  a <- do.call(calculate_spectral_metrics, c(args, list(seed = 42)))
  b <- do.call(calculate_spectral_metrics, c(args, list(seed = 42)))
  c <- do.call(calculate_spectral_metrics, c(args, list(seed = 7)))

  # identical(), not all.equal(): CHV is ~1e-9, below all.equal's tolerance
  expect_identical(a$CV, b$CV)
  expect_identical(a$CHV, b$CHV)
  expect_false(identical(a$CV, c$CV))
  expect_false(identical(a$CHV, c$CHV))
})

test_that('rarefaction requires n and min_points', {
  expect_error(
    calculate_spectral_metrics(raster_file, aoi_file, wavelengths,
                               rarefaction = TRUE),
    "n and min_points must be provided"
  )
  expect_error(
    calculate_spectral_metrics(raster_file, aoi_file, wavelengths,
                               rarefaction = TRUE, n = 5),
    "n and min_points must be provided"
  )
})

test_that('min_points exceeding pixels in an aoi errors clearly', {
  expect_error(
    calculate_spectral_metrics(raster_file, aoi_file, wavelengths,
                               rarefaction = TRUE, n = 5, min_points = 1e7),
    "exceeds the number of pixels .* in aoi '1' of site 'multiband'"
  )
})

test_that('calculate_spectral_metrics keeps sites separate', {
  # the same raster under two site names gives identical metrics per site
  dir <- tempfile("two_sites_")
  dir.create(dir)
  file.copy(raster_file, file.path(dir, c("siteA_image.tif", "siteB_image.tif")))
  aoi <- sf::read_sf(aoi_file)
  sf::st_write(aoi, file.path(dir, "siteA_aoi.geojson"), quiet = TRUE)
  sf::st_write(aoi, file.path(dir, "siteB_aoi.geojson"), quiet = TRUE)

  metrics <- calculate_spectral_metrics(
    file.path(dir, c("siteA_image.tif", "siteB_image.tif")),
    list.files(dir, pattern = "geojson$", full.names = TRUE),
    wavelengths
  )
  expect_equal(nrow(metrics), 2 * nrow(aoi))
  expect_setequal(unique(metrics$site), c("siteA", "siteB"))
  expect_equal(metrics$CV[metrics$site == "siteA"], metrics$CV[metrics$site == "siteB"])
  expect_equal(metrics$SV[metrics$site == "siteA"], metrics$SV[metrics$site == "siteB"])
})



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

test_that("find_optimum_thresholds accepts several class values", {
  # bare ground and rocks both have low ndvi, veg is high: threshold sits between
  df <- data.frame(site = "s",
                   ndvi = c(0.05, 0.1, 0.15, 0.2, 0.6, 0.7, 0.8, 0.9),
                   class = c("bare", "rocks", "rocks", "bare",
                             "veg", "veg", "veg", "veg"))
  thr <- suppressMessages(
    find_optimum_thresholds(df, class_col = "class", band_or_index_col = "ndvi",
                            site_col = "site", class_value = c("bare", "rocks"))
  )
  expect_true(thr$threshold > 0.2 & thr$threshold < 0.6)
})
