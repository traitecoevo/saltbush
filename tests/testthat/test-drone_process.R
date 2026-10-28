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

test_that("site name is the whole file name when it has no underscore", {
  dir <- tempfile("no_underscore_")
  dir.create(dir)
  file.copy(raster_file, file.path(dir, "siteA.tif"))
  sf::st_write(sf::read_sf(aoi_shp), file.path(dir, "siteA_aoi.geojson"), quiet = TRUE)

  metrics <- calculate_spectral_metrics(
    file.path(dir, "siteA.tif"), file.path(dir, "siteA_aoi.geojson"), wavelengths)
  expect_true(all(metrics$site == "siteA"))
})

test_that("site name also ends at a '.'", {
  dir <- tempfile("dot_names_")
  dir.create(dir)
  file.copy(raster_file, file.path(dir, "siteB.ortho.tif"))
  sf::st_write(sf::read_sf(aoi_shp), file.path(dir, "siteB.aoi.geojson"), quiet = TRUE)
  # a different site sharing the prefix must not match
  sf::st_write(sf::read_sf(aoi_shp), file.path(dir, "siteBB_aoi.geojson"), quiet = TRUE)

  metrics <- calculate_spectral_metrics(
    file.path(dir, "siteB.ortho.tif"),
    list.files(dir, pattern = "geojson$", full.names = TRUE),
    wavelengths)
  expect_true(all(metrics$site == "siteB"))
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

test_that("calculate_spectral_metrics handles several polygons and awkward AOIs", {
  raster_file <- system.file("extdata/example/NSABHC0009_aggregated.tif", package = "saltbush")
  wavelengths <- c("blue", "green", "red", "red_edge", "nir")
  r <- terra::rast(raster_file)
  e <- as.vector(terra::ext(r))
  cx <- mean(e[1:2]); cy <- mean(e[3:4])
  sq <- function(x, y, s) sf::st_polygon(list(rbind(c(x, y), c(x + s, y), c(x + s, y + s),
                                                    c(x, y + s), c(x, y))))

  write_aoi <- function(geoms, ids) {
    dir <- tempfile("aoi_multi_"); dir.create(dir)
    path <- file.path(dir, "NSABHC0009_aoi.gpkg")
    sf::st_write(sf::st_sf(id = ids, geometry = sf::st_sfc(geoms, crs = terra::crs(r))),
                 path, quiet = TRUE)
    path
  }

  # normal, outside the image, and a single pixel (too few for a hull)
  aoi <- write_aoi(list(sq(cx - 20, cy - 20, 15), sq(e[2] + 100, cy, 15), sq(cx, cy, 1)),
                   c("normal", "outside", "tiny"))
  expect_warning(
    expect_warning(
      metrics <- calculate_spectral_metrics(raster_file, aoi, wavelengths,
                                            masked = FALSE, aoi_id_col = "id"),
      "'outside'.*does not overlap"),
    "CHV is NA for aoi 'tiny'")

  expect_equal(metrics$aoi_id, c("normal", "outside", "tiny"))
  expect_false(anyNA(metrics[1, c("CV", "SV", "CHV")]))
  expect_true(all(is.na(metrics[2, c("CV", "SV", "CHV")])))
  expect_true(is.na(metrics$CHV[3]))

  # duplicate ids warn
  dup <- write_aoi(list(sq(cx - 20, cy - 20, 15), sq(cx + 5, cy + 5, 15)), c("a", "a"))
  expect_warning(calculate_spectral_metrics(raster_file, dup, wavelengths, aoi_id_col = "id"),
                 "duplicate values")
})
