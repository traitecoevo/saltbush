wavelengths <- c('blue', 'green', 'red', 'red_edge', 'nir')
raster_file <- system.file("extdata/multiband_image/multiband_image.tif",
                           package = "saltbush")
aoi_shp <- system.file("extdata/aoi/multiband_image_aoi.shp", package = "saltbush")

# write the bundled AOI to a new file in a fresh directory
write_aoi <- function(aoi, name) {
  dir <- tempfile("aoi_")
  dir.create(dir)
  path <- file.path(dir, name)
  sf::st_write(aoi, path, quiet = TRUE)
  path
}

test_that("GeoJSON and GeoPackage AOIs give the same metrics as a shapefile", {
  shp <- calculate_spectral_metrics(raster_file, aoi_shp, wavelengths)
  aoi <- sf::read_sf(aoi_shp)
  geojson <- calculate_spectral_metrics(
    raster_file, write_aoi(aoi, "multiband_image_aoi.geojson"), wavelengths)
  # GeoPackage reserves the "FID" column name, so write geometry only
  gpkg <- calculate_spectral_metrics(
    raster_file,
    write_aoi(sf::st_sf(geometry = sf::st_geometry(aoi)), "multiband_image_aoi.gpkg"),
    wavelengths)
  expect_equal(geojson, shp)
  expect_equal(gpkg, shp)
})

test_that("AOI in a different coordinate system is reprojected, with a message", {
  shp <- calculate_spectral_metrics(raster_file, aoi_shp, wavelengths)
  aoi_wgs84 <- sf::st_transform(sf::read_sf(aoi_shp), 4326)
  path <- write_aoi(aoi_wgs84, "multiband_image_aoi.geojson")

  expect_message(
    reprojected <- calculate_spectral_metrics(raster_file, path, wavelengths),
    "AOI reprojected to match coordinate system of imagery"
  )
  # round trip through lon/lat shifts edges slightly, so pixel sets can differ
  expect_equal(nrow(reprojected), nrow(shp))
  expect_equal(reprojected$CV, shp$CV, tolerance = 0.01)
})

test_that("AOI in the same coordinate system gives no reprojection message", {
  expect_no_message(calculate_spectral_metrics(raster_file, aoi_shp, wavelengths))
})

test_that("non-AOI files are ignored and unmatched or ambiguous sites error", {
  # a shapefile's sidecar files can be passed along without breaking matching
  aoi_dir <- dirname(aoi_shp)
  all_files <- list.files(aoi_dir, full.names = TRUE)
  expect_no_error(calculate_spectral_metrics(raster_file, all_files, wavelengths))

  expect_error(
    calculate_spectral_metrics(
      raster_file,
      system.file("extdata/aoi/NSABHC0009_aoi.shp", package = "saltbush"),
      wavelengths),
    "No AOI file .* found for site 'multiband'"
  )

  geojson <- write_aoi(sf::read_sf(aoi_shp), "multiband_image_aoi.geojson")
  expect_error(
    calculate_spectral_metrics(raster_file, c(aoi_shp, geojson), wavelengths),
    "More than one AOI file found for site 'multiband'"
  )
})

test_that("calculate_spectral_metrics honours aoi_id_col", {
  # pick whichever non-geometry column the bundled AOI shapefile happens to expose
  aoi_cols <- setdiff(names(sf::read_sf(aoi_shp)), "geometry")
  skip_if(length(aoi_cols) == 0, "bundled AOI shapefile has no attribute columns")
  id_col <- aoi_cols[1]

  metrics <- calculate_spectral_metrics(raster_file, aoi_shp, wavelengths,
                                        aoi_id_col = id_col)
  expect_equal(metrics$aoi_id, sf::read_sf(aoi_shp)[[id_col]])

  # unknown column should error clearly
  expect_error(
    calculate_spectral_metrics(raster_file, aoi_shp, wavelengths,
                               aoi_id_col = "definitely_not_a_column"),
    "not found"
  )
})
