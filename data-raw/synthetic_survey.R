## Generate the `synthetic_survey` example dataset.
##
## A small, hand-crafted point-intercept-style data frame that mimics the
## shape of `ausplotsR::get_ausplots()$veg.PI`. Used in function examples,
## tests, and the package vignette so they can run without network access.
##
## Re-run with:
##   Rscript data-raw/synthetic_survey.R

synthetic_survey <- data.frame(
  site_unique = c(rep("SITE1-001", 6), rep("SITE2-002", 6)),
  site_location_name = c(rep("SITE1", 6), rep("SITE2", 6)),
  subplot_id = c(
    rep(c("1_1", "1_2"), each = 3),
    rep(c("1_1", "1_2"), each = 3)
  ),
  standardised_name = c(
    # SITE1-001 / 1_1: 3 species
    "sp_a", "sp_b", "sp_c",
    # SITE1-001 / 1_2: 2 distinct species (sp_a repeated)
    "sp_a", "sp_a", "sp_d",
    # SITE2-002 / 1_1: 1 species
    "sp_e", "sp_e", "sp_e",
    # SITE2-002 / 1_2: 2 species
    "sp_f", "sp_g", "sp_g"
  ),
  stringsAsFactors = FALSE
)

usethis::use_data(synthetic_survey, overwrite = TRUE)
