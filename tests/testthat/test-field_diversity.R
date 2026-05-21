test_that("calculate_field_diversity works on bundled synthetic data", {
  res <- calculate_field_diversity(synthetic_survey)
  expect_equal(nrow(res$taxonomic_diversity), 2)
  expect_true(all(
    c("site_unique", "site_location_name", "species_richness",
      "shannon_diversity", "simpson_diversity", "pielou_evenness",
      "exp_shannon", "inv_simpson")
    %in% names(res$taxonomic_diversity)
  ))
  # SITE1-001 has 4 distinct species (sp_a, sp_b, sp_c, sp_d)
  s1 <- res$taxonomic_diversity[
    res$taxonomic_diversity$site_unique == "SITE1-001", ]
  expect_equal(s1$species_richness, 4)
  # SITE2-002 has 3 distinct species (sp_e, sp_f, sp_g)
  s2 <- res$taxonomic_diversity[
    res$taxonomic_diversity$site_unique == "SITE2-002", ]
  expect_equal(s2$species_richness, 3)
  # one community matrix per site
  expect_equal(length(res$community_matrices), 2)
})

test_that("group_by_cols supports subplot-level granularity", {
  res <- calculate_field_diversity(
    synthetic_survey,
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

test_that("unknown group_by_cols column errors clearly", {
  expect_error(
    calculate_field_diversity(synthetic_survey,
                              group_by_cols = c("site_unique", "no_such_col")),
    "no_such_col"
  )
})

test_that("calculate_field_diversity works on cached ausplots data", {
  res <- calculate_field_diversity(ausplots_NSABHC0009)
  # NSABHC0009 has two visits in the cached dataset
  expect_equal(nrow(res$taxonomic_diversity), 2)
  expect_true(all(res$taxonomic_diversity$site_location_name == "NSABHC0009"))
  # species_richness matches a direct count from the source data
  total_richness <- length(
    na.omit(unique(ausplots_NSABHC0009$standardised_name))
  )
  expect_true(
    sum(res$taxonomic_diversity$species_richness) >= total_richness
  )
})

test_that("calculate_field_diversity matches a live ausplotsR query", {
  skip_if_not_installed("ausplotsR")
  skip_if_offline("ausplots.tern.org.au")

  ausplot.pi.data <- ausplotsR::get_ausplots(
    my.Plot_IDs = c("NTASTU0002"), veg.PI = TRUE
  )$veg.PI
  res <- calculate_field_diversity(ausplot.pi.data)

  expect_true(
    res$taxonomic_diversity$species_richness ==
      length(na.omit(unique(ausplot.pi.data$standardised_name)))
  )
})
