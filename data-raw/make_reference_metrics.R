# Builds tests/testthat/fixtures/reference_metrics.rds: spectral metrics
# produced by the ORIGINAL pixel-extraction pipeline (extract_pixel_values() +
# data-frame calculate_spectral_metrics()), as of commit 0e28d41.
#
# The raster-based calculate_spectral_metrics() is tested against these values
# so the rewrite can be shown to reproduce the original numbers.
#
# Run from the package root:  Rscript data-raw/make_reference_metrics.R

ref_commit <- "0e28d41"

# export the package as it was at ref_commit and load it as a whole package,
# so the original functions run with their proper namespace and imports
old_pkg <- file.path(tempfile("saltbush_"), "saltbush")
dir.create(old_pkg, recursive = TRUE)
archive <- tempfile(fileext = ".tar")
system2("git", c("archive", "--format=tar", "-o", archive, ref_commit))
utils::untar(archive, exdir = old_pkg)
old <- pkgload::load_all(old_pkg, export_all = FALSE, quiet = TRUE)$env

wavelengths <- c("blue", "green", "red", "red_edge", "nir")
ext <- function(...) file.path(old_pkg, "inst", "extdata", ...)

aoi_files <- list.files(ext("aoi"), pattern = "\\.shp$", full.names = TRUE)

# masked version of the bundled multiband image, so NA handling is covered
masked_dir <- file.path(tempdir(), "reference_masked")
dir.create(masked_dir, showWarnings = FALSE)
old$create_masked_raster(ext("multiband_image", "multiband_image.tif"),
                         masked_dir,
                         ndvi_threshold = 0.02,
                         nir_threshold = 0.04)

inputs <- list(
  unmasked = c(ext("multiband_image", "multiband_image.tif"),
               ext("example", "NSABHC0009_aggregated.tif")),
  masked   = file.path(masked_dir, "multiband_image_masked.tif")
)

reference <- lapply(names(inputs), function(type) {
  pixel_values <- old$extract_pixel_values(inputs[[type]], aoi_files, wavelengths)
  message(type, ": ", nrow(pixel_values), " pixels extracted")
  as.data.frame(old$calculate_spectral_metrics(pixel_values,
                                               masked = type == "masked",
                                               wavelengths = wavelengths))
})
names(reference) <- names(inputs)
attr(reference, "commit") <- ref_commit

pkgload::unload("saltbush")
dir.create("tests/testthat/fixtures", showWarnings = FALSE)
saveRDS(reference, "tests/testthat/fixtures/reference_metrics.rds")
print(reference)
