test_that("calculate_cv works", {
  set.seed(123)
  df <- data.frame(
  site_name = rep(c("site_one", "site_two", "site_three", "site_four"), each = 5000),
  aoi_id = 1,
  blue = runif(20000, min = 0, max = 1),
  green = runif(20000, min = 0, max = 1),
  red = runif(20000, min = 0, max = 1),
  red_edge = runif(20000, min = 0, max = 1),
  nir = runif(20000, min = 0, max = 1))
  pixelvalues <- calculate_cv(df,
  wavelengths = c('blue','green','red','red_edge','nir'),
  rarefaction = TRUE, min_points = 5000, n = 999)
})
