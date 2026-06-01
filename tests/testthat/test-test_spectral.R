set.seed(9)
df_test <- data.frame(
  aoi_id = rep(1:2, each = 10),
  blue = c(runif(10, 0.1, 0.4), runif(10, 0.4, 0.7)),
  green = c(runif(10, 0.2, 0.5), runif(10, 0.5, 0.8)),
  red = c(runif(10, 0.3, 0.6), runif(10, 0.6, 0.9))
)

test_that('calculate_cv works', {
  cv <- calculate_cv(df_test,
                     wavelengths = colnames(df_test[, 2:4]),
                     rarefaction = F)
  expect_equal(round(cv$CV[1], 3),  0.296)
  expect_equal(round(cv$CV[2], 3), 0.143)
})

test_that('calculate_sv works', {
  sv <- calculate_sv(df_test,
                     wavelengths = colnames(df_test[, 2:4]))
  expect_equal(round(sv$SV[1], 5), 0.02631)
  expect_equal(round(sv$SV[2], 5), 0.02660)
})

test_that('calculate_chv_nopca works', {
  chv <- calculate_chv_nopca(df_test,
                             wavelengths = colnames(df_test[, 2:4]),
                             rarefaction = F)
  expect_equal(round(chv$CHV[1], 5), 0.00612)
  expect_equal(round(chv$CHV[2], 5), 0.00663)
})

test_that('calculate_spectral_metrics works', {
  metrics <- calculate_spectral_metrics(df_test,
                                        wavelengths = colnames(df_test[, 2:4]))
  expect_equal(round(metrics$CV[1], 3),  0.296)
  expect_equal(round(metrics$CV[2], 3), 0.143)
  expect_equal(round(metrics$SV[1], 5), 0.02631)
  expect_equal(round(metrics$SV[2], 5), 0.02660)
  expect_equal(round(metrics$CHV[1], 5), 0.00612)
  expect_equal(round(metrics$CHV[2], 5), 0.00663)
  expect_true(metrics$aoi_id[1] == 1)
  expect_true(metrics$aoi_id[2] == 2)
  expect_true(all(metrics$image_type == 'masked'))
  expect_true(all(metrics$site == 'site1'))
})

test_that('calculate_spectral_metrics works with rarefaction', {
  metrics <- calculate_spectral_metrics(df_test,
                                        wavelengths = colnames(df_test[, 2:4]),
                                        rarefaction = TRUE,
                                        min_points = 10, n=100)
  expect_equal(round(metrics$CV[1], 3),  0.296)
  expect_equal(round(metrics$CV[2], 3), 0.143)
  expect_equal(round(metrics$SV[1], 5), 0.02631)
  expect_equal(round(metrics$SV[2], 5), 0.02660)
  expect_equal(round(metrics$CHV[1], 5), 0.00612)
  expect_equal(round(metrics$CHV[2], 5), 0.00663)
  expect_true(metrics$aoi_id[1] == 1)
  expect_true(metrics$aoi_id[2] == 2)
  expect_true(all(metrics$image_type == 'masked'))
  expect_true(all(metrics$site == 'site1'))
})

test_that('seed makes rarefaction reproducible', {
  # df_test has 10 rows per aoi; sampling min_points = 5 forces a strict subset
  # so RNG state matters (unlike min_points = 10 which would be degenerate).
  args <- list(df_test, wavelengths = colnames(df_test[, 2:4]),
               rarefaction = TRUE, min_points = 5, n = 20)

  a <- do.call(calculate_spectral_metrics, c(args, list(seed = 42)))
  b <- do.call(calculate_spectral_metrics, c(args, list(seed = 42)))
  c <- do.call(calculate_spectral_metrics, c(args, list(seed = 7)))

  # same seed -> identical CV and CHV (SV is unseeded — no sampling)
  expect_equal(a$CV, b$CV)
  expect_equal(a$CHV, b$CHV)
  # different seed -> different rarefaction draws -> different CV / CHV
  expect_false(isTRUE(all.equal(a$CV, c$CV)))
  expect_false(isTRUE(all.equal(a$CHV, c$CHV)))
})

test_that('rarefaction requires n and min_points', {
  expect_error(
    calculate_spectral_metrics(df_test, wavelengths = colnames(df_test[, 2:4]),
                               rarefaction = TRUE),
    "n and min_points must be provided"
  )
  expect_error(
    calculate_spectral_metrics(df_test, wavelengths = colnames(df_test[, 2:4]),
                               rarefaction = TRUE, n = 5),
    "n and min_points must be provided"
  )
})

test_that('min_points exceeding available pixels errors clearly', {
  expect_error(
    calculate_spectral_metrics(df_test, wavelengths = colnames(df_test[, 2:4]),
                               rarefaction = TRUE, n = 5, min_points = 10000),
    "exceeds number of rows"
  )
})

test_that('calculate_spectral_metrics keeps sites separate', {
  multi_site <- rbind(
    cbind(site_name = "siteA", df_test),
    cbind(site_name = "siteB", df_test)
  )
  metrics <- calculate_spectral_metrics(
    multi_site, wavelengths = colnames(df_test[, 2:4])
  )
  # one row per site x aoi_id (2 sites x 2 aois)
  expect_equal(nrow(metrics), 4)
  expect_setequal(unique(metrics$site), c("siteA", "siteB"))
  # identical input per site -> identical metrics across the two sites
  a <- metrics[metrics$site == "siteA", ][order(metrics[metrics$site == "siteA", ]$aoi_id), ]
  b <- metrics[metrics$site == "siteB", ][order(metrics[metrics$site == "siteB", ]$aoi_id), ]
  expect_equal(a$CV, b$CV)
  expect_equal(a$SV, b$SV)
})



