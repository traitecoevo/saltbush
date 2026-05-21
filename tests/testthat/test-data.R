test_that("synthetic_survey dataset is present and well-formed", {
  expect_s3_class(synthetic_survey, "data.frame")
  expect_equal(nrow(synthetic_survey), 12)
  expect_true(all(
    c("site_unique", "site_location_name", "subplot_id", "standardised_name")
    %in% names(synthetic_survey)
  ))
  # Two distinct sites
  expect_equal(length(unique(synthetic_survey$site_unique)), 2)
})

test_that("ausplots_NSABHC0009 dataset is present and well-formed", {
  expect_s3_class(ausplots_NSABHC0009, "data.frame")
  expect_true(all(
    c("site_unique", "site_location_name", "site_location_visit_id",
      "transect", "point_number", "standardised_name")
    %in% names(ausplots_NSABHC0009)
  ))
  # All rows are from site NSABHC0009
  expect_true(all(ausplots_NSABHC0009$site_location_name == "NSABHC0009"))
  # There are at least two visits worth of points
  expect_true(length(unique(ausplots_NSABHC0009$site_location_visit_id)) >= 2)
})
