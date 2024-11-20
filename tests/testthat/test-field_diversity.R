ausplot.pi.data <- ausplotsR::get_ausplots(my.Plot_IDs=
                                             c("NTASTU0002"), veg.PI=TRUE)$veg.PI

test_that('field_diversity works', {
field_diversity <- calculate_field_diversity(ausplot.pi.data)
expect_true(
field_diversity$taxonomic_diversity$species_richness==
  length(na.omit(unique(ausplot.pi.data$standardised_name)))
)
})
