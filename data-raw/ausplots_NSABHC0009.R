## Generate the `ausplots_NSABHC0009` example dataset.
##
## Caches a single ausplotsR point-intercept query so that examples,
## vignette, and tests can run offline. We keep only the `veg.PI` table
## (and trim it to the columns the package actually uses) to stay small.
##
## Re-run with:
##   Rscript data-raw/ausplots_NSABHC0009.R

stopifnot(requireNamespace("ausplotsR", quietly = TRUE))

raw <- ausplotsR::get_ausplots(
  my.Plot_IDs = c("NSABHC0009"),
  veg.PI = TRUE
)$veg.PI

# Keep only the columns used by saltbush plus a few useful identifiers
# (transect, point_number) so users can experiment with finer-grained
# groupings. Drops large free-text taxonomy columns to keep the .rda small.
keep_cols <- c("site_unique", "site_location_name", "site_location_visit_id",
               "transect", "point_number", "standardised_name")
missing <- setdiff(keep_cols, names(raw))
if (length(missing)) {
  stop("ausplotsR veg.PI is missing expected columns: ",
       paste(missing, collapse = ", "))
}
ausplots_NSABHC0009 <- raw[, keep_cols]

usethis::use_data(ausplots_NSABHC0009, overwrite = TRUE)
