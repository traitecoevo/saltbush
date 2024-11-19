input_dir <- system.file("extdata/create_multiband_image", package = "saltbush")
 output_dir <- tempdir()



 test_that('create_multiband_image works', {
  create_multiband_image(input_dir, c('blue', 'green', 'red', 'red_edge', 'nir'), output_dir)
 folder <- "extdata/create_multiband_image"
 output_filename <- file.path(output_dir, paste0(basename(folder), "_multiband_image"))
 file_that_should_exist<-paste0(output_filename, '.tif')
 expect_true(file.exists(file_that_should_exist))
 })

