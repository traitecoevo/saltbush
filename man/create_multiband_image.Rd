% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/create_multiband_image.R
\name{create_multiband_image}
\alias{create_multiband_image}
\title{Create a multiband image from single-band TIF files}
\usage{
create_multiband_image(
  input_dir,
  desired_band_order,
  output_dir = tempdir(),
  make_plot = FALSE,
  return_raster = FALSE
)
}
\arguments{
\item{input_dir}{A directory containing folders with waveband TIF files to be combined,
or a single folder with waveband TIF files to be combined.}

\item{desired_band_order}{A character vector specifying the desired order of the bands.
The order should match the file basenames (excluding extensions) and represent
the wavelength order.}

\item{output_dir}{A directory where the combined multiband TIF file will be saved.}

\item{make_plot}{Logical. If \code{TRUE}, a plot is generated to visualize the output for verification.
Default is \code{FALSE}.}

\item{return_raster}{Logical. If \code{TRUE}, the combined raster object is returned.
Default is \code{FALSE}.}
}
\value{
Saves a combined multiband TIF file in the specified \code{output_dir}.
If \code{return_raster = TRUE}, the function returns a \code{terra} raster object representing
the combined multiband image.
}
\description{
This function combines single reflectance band TIF files into a multiband image.
By default, it saves the combined multiband image to a file rather than returning an object.
The function supports reordering bands according to a specified wavelength order and
optionally creates a plot to visualize the output.
}
\examples{

input_dir <- system.file("extdata/create_multiband_image", package = "saltbush")
output_dir <- tempdir()
create_multiband_image(input_dir, c('blue', 'green', 'red', 'red_edge', 'nir'), output_dir)

}
