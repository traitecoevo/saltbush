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

test_that("aoi_cols supports subplot-level granularity", {
  res <- calculate_field_diversity(
    synthetic_survey,
    aoi_cols = c("site_unique", "subplot_id")
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

test_that("unknown aoi_cols column errors clearly", {
  expect_error(
    calculate_field_diversity(synthetic_survey,
                              aoi_cols = c("site_unique", "no_such_col")),
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

# generic (non-AusPlots) survey data -----------------------------------------

toy_cover <- data.frame(
  plot  = c("A", "A", "B", "B", "B", "B"),
  taxon = c("sp1", "sp2", "sp1", "sp1", "sp3", "bare"),
  cover = c(50, 50, 30, 10, 0, 60)
)

test_that("species_col, exclude and abundance_col work on generic data", {
  res <- calculate_field_diversity(toy_cover, aoi_cols = "plot",
                                   species_col = "taxon", exclude = "bare",
                                   abundance_col = "cover")
  div <- res$taxonomic_diversity

  # plot A: two species with equal cover
  a <- div[div$plot == "A", ]
  expect_equal(a$species_richness, 2)
  expect_equal(a$shannon_diversity, log(2))
  expect_equal(a$simpson_diversity, 0.5)

  # plot B: sp1's two records are summed, zero-cover sp3 is absent,
  # and "bare" is excluded, leaving a single species
  b <- div[div$plot == "B", ]
  expect_equal(b$species_richness, 1)
  expect_equal(b$shannon_diversity, 0)
  expect_equal(res$community_matrices$B$sp1, 40)
  expect_false("sp3" %in% names(res$community_matrices$B))
  expect_false("bare" %in% names(res$community_matrices$B))
})

test_that("without abundance_col each row is one hit", {
  hits <- calculate_field_diversity(toy_cover, "plot", species_col = "taxon",
                                    exclude = NULL)
  # plot B: sp1 has 2 rows, sp3 and bare 1 row each
  expect_equal(hits$taxonomic_diversity$species_richness[2], 3)
  expect_equal(hits$community_matrices$B$sp1, 2L)

  # an abundance column of all 1s gives the same result
  ones <- calculate_field_diversity(transform(toy_cover, one = 1), "plot",
                                    species_col = "taxon", exclude = NULL,
                                    abundance_col = "one")
  expect_equal(ones$taxonomic_diversity, hits$taxonomic_diversity)
})

test_that("bad species_col or abundance_col errors clearly", {
  expect_error(calculate_field_diversity(toy_cover, "plot", species_col = "nope"),
               "species_col 'nope' not found")
  expect_error(calculate_field_diversity(toy_cover, "plot", species_col = "taxon",
                                         abundance_col = "nope"),
               "abundance_col 'nope' not found")
  expect_error(calculate_field_diversity(toy_cover, "plot", species_col = "taxon",
                                         abundance_col = "plot"),
               "must be numeric")
  negative <- transform(toy_cover, cover = -cover)
  expect_error(calculate_field_diversity(negative, "plot", species_col = "taxon",
                                         abundance_col = "cover"),
               "missing or negative")
})

test_that("bundled cover_survey works with the generic options", {
  res <- calculate_field_diversity(cover_survey, aoi_cols = "plot_id",
                                   species_col = "species",
                                   exclude = c("Bare ground", "Litter"),
                                   abundance_col = "cover_pct")
  div <- res$taxonomic_diversity
  expect_equal(div$plot_id, c("plot_A", "plot_B", "plot_C"))
  expect_equal(div$species_richness, c(4, 3, 2))
  # plot_A's cover is the most even, so it is the most diverse
  expect_equal(which.max(div$shannon_diversity), 1)
})

test_that("deprecated group_by_cols still works, with a warning", {
  expect_warning(
    old <- calculate_field_diversity(synthetic_survey,
                                     group_by_cols = c("site_unique", "subplot_id")),
    "deprecated"
  )
  new <- calculate_field_diversity(synthetic_survey,
                                   aoi_cols = c("site_unique", "subplot_id"))
  expect_identical(old, new)
})
