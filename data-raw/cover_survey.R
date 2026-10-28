## Generate the `cover_survey` example dataset.
##
## A small, hand-crafted percent-cover survey for three plots, with species
## typical of chenopod shrubland at Fowlers Gap, NSW. Unlike `synthetic_survey`
## (point-intercept hits, one row per hit), each row here is a species' cover
## estimate in a plot, so it demonstrates `calculate_field_diversity()` with
## `species_col`, `exclude` and `abundance_col`. The values are made up.
##
## Re-run with:
##   Rscript data-raw/cover_survey.R

cover_survey <- data.frame(
  plot_id = rep(c("plot_A", "plot_B", "plot_C"), times = c(6, 5, 4)),
  species = c(
    # plot_A: four species, fairly even cover
    "Atriplex vesicaria", "Maireana pyramidata", "Sclerolaena divaricata",
    "Enneapogon avenaceus", "Bare ground", "Litter",
    # plot_B: three species, dominated by saltbush
    "Atriplex vesicaria", "Maireana pyramidata", "Sclerolaena divaricata",
    "Bare ground", "Litter",
    # plot_C: two species, mostly bare
    "Atriplex vesicaria", "Enneapogon avenaceus", "Bare ground", "Litter"
  ),
  cover_pct = c(
    18, 15, 12, 10, 35, 10,
    40, 5, 3, 42, 10,
    8, 2, 80, 10
  ),
  stringsAsFactors = FALSE
)

usethis::use_data(cover_survey, overwrite = TRUE)
