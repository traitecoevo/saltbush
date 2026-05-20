test_that('field_diversity works', {
  skip_if_not_installed("ausplotsR")
  ausplot.pi.data <- ausplotsR::get_ausplots(my.Plot_IDs=
                                               c("NTASTU0002"), veg.PI=TRUE)$veg.PI
  field_diversity <- calculate_field_diversity(ausplot.pi.data)
  expect_true(
    field_diversity$taxonomic_diversity$species_richness ==
      length(na.omit(unique(ausplot.pi.data$standardised_name)))
  )
})

# Synthetic survey data — covers two site visits, each with two subplots, each
# with three species hits. Lets us test group_by_cols without an ausplotsR API
# call (the test above needs network access; this one runs anywhere).
make_synthetic_survey <- function() {
  data.frame(
    site_unique = c(rep("SITE1-001", 6), rep("SITE2-002", 6)),
    subplot_id  = c(rep(c("1_1", "1_2"), each = 3),
                    rep(c("1_1", "1_2"), each = 3)),
    standardised_name = c(
      # SITE1-001 / 1_1: 3 species
      "sp_a", "sp_b", "sp_c",
      # SITE1-001 / 1_2: 2 species (one repeat)
      "sp_a", "sp_a", "sp_d",
      # SITE2-002 / 1_1: 1 species
      "sp_e", "sp_e", "sp_e",
      # SITE2-002 / 1_2: 2 species
      "sp_f", "sp_g", "sp_g"
    ),
    stringsAsFactors = FALSE
  )
}

test_that('default group_by_cols gives one row per site_unique', {
  res <- calculate_field_diversity(make_synthetic_survey())
  expect_equal(nrow(res$taxonomic_diversity), 2)
  expect_true(all(c("site_unique", "site_location_name", "species_richness")
                  %in% names(res$taxonomic_diversity)))
  # SITE1-001 has 4 distinct species (sp_a, sp_b, sp_c, sp_d)
  s1 <- res$taxonomic_diversity[res$taxonomic_diversity$site_unique == "SITE1-001", ]
  expect_equal(s1$species_richness, 4)
  # SITE2-002 has 3 distinct species (sp_e, sp_f, sp_g)
  s2 <- res$taxonomic_diversity[res$taxonomic_diversity$site_unique == "SITE2-002", ]
  expect_equal(s2$species_richness, 3)
})

test_that('group_by_cols supports subplot-level granularity', {
  res <- calculate_field_diversity(
    make_synthetic_survey(),
    group_by_cols = c("site_unique", "subplot_id")
  )
  # 2 sites x 2 subplots = 4 rows
  expect_equal(nrow(res$taxonomic_diversity), 4)
  expect_true(all(c("site_unique", "subplot_id", "species_richness")
                  %in% names(res$taxonomic_diversity)))
  # SITE1-001 / 1_1 has 3 distinct species
  one_one <- res$taxonomic_diversity[
    res$taxonomic_diversity$site_unique == "SITE1-001" &
      res$taxonomic_diversity$subplot_id == "1_1", ]
  expect_equal(one_one$species_richness, 3)
  # SITE2-002 / 1_1 has 1 species
  two_one <- res$taxonomic_diversity[
    res$taxonomic_diversity$site_unique == "SITE2-002" &
      res$taxonomic_diversity$subplot_id == "1_1", ]
  expect_equal(two_one$species_richness, 1)
})

test_that('unknown group_by_cols column errors clearly', {
  expect_error(
    calculate_field_diversity(make_synthetic_survey(),
                              group_by_cols = c("site_unique", "no_such_col")),
    "no_such_col"
  )
})
