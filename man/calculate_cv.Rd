% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/calculate_spectral_metrics.R
\name{calculate_cv}
\alias{calculate_cv}
\alias{calculate_sv}
\alias{calculate_chv_nopca}
\alias{calculate_spectral_metrics}
\title{Calculate spectral metrics}
\usage{
calculate_cv(
  pixel_values_df,
  wavelengths,
  rarefaction = FALSE,
  min_points = NULL,
  n = NULL
)
}
\arguments{
\item{pixel_values_df}{A data frame containing pixel values, typically obtained from the \code{extract_pixel_values} function.}

\item{wavelengths}{A list of wavelengths that correspond to column names in \code{pixel_values_df}.}

\item{rarefaction}{Logical; if TRUE, applies a rarefaction step that increases processing time.}

\item{min_points}{Integer; minimum number of pixels per \code{aoi} to standardize uneven pixel numbers across sites (used if \code{rarefaction = TRUE}).}

\item{n}{Integer; number of subset permutations if \code{rarefaction = TRUE}.}
}
\value{
A dataframe containing spectral metrics for each \code{aoi} within each site/raster.
}
\description{
Calculates CV, SV, and CHV from a pixel values dataframe with columns for each wavelength, \code{site_name}, and \code{aoi_id}.
This help file applies to the functions \code{calculate_cv}, \code{calculate_sv}, \code{calculate_chv_nopca}, and \code{calculate_spectral_metrics}.
}
\examples{
set.seed(123)
df <- data.frame(
  site_name = rep(c("site_one", "site_two", "site_three", "site_four"), each = 5000),
  aoi_id = 1,
  blue = runif(20000, min = 0, max = 1),
  green = runif(20000, min = 0, max = 1),
  red = runif(20000, min = 0, max = 1),
  red_edge = runif(20000, min = 0, max = 1),
  nir = runif(20000, min = 0, max = 1))
spectral_metrics <- calculate_spectral_metrics(df,
   wavelengths = c('blue','green','red','red_edge','nir'),
   rarefaction = TRUE, min_points = 50, n = 5)
}
