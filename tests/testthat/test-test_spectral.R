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
  expect_equal(round(chv$CHV_nopca[1], 5), 0.00612)
  expect_equal(round(chv$CHV_nopca[2], 5), 0.00663)
})

test_that('calculate_spectral_metrics works', {
  metrics <- calculate_spectral_metrics(df_test,
                                        wavelengths = colnames(df_test[, 2:4]))
  expect_equal(round(metrics$CV[1], 3),  0.296)
  expect_equal(round(metrics$CV[2], 3), 0.143)
  expect_equal(round(metrics$SV[1], 5), 0.02631)
  expect_equal(round(metrics$SV[2], 5), 0.02660)
  expect_equal(round(metrics$CHV_nopca[1], 5), 0.00612)
  expect_equal(round(metrics$CHV_nopca[2], 5), 0.00663)
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
  expect_equal(round(metrics$CHV_nopca[1], 5), 0.00612)
  expect_equal(round(metrics$CHV_nopca[2], 5), 0.00663)
  expect_true(metrics$aoi_id[1] == 1)
  expect_true(metrics$aoi_id[2] == 2)
  expect_true(all(metrics$image_type == 'masked'))
  expect_true(all(metrics$site == 'site1'))
})



