% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/create_masked_raster.R
\name{create_masked_raster}
\alias{create_masked_raster}
\title{Create masked raster from multiband image}
\usage{
create_masked_raster(
  input,
  output_dir = tempdir(),
  ndvi_threshold = NULL,
  nir_threshold = NULL,
  ndvi_threshold_df = NULL,
  nir_threshold_df = NULL,
  red_band_index = 3,
  nir_band_index = 5,
  make_plot = FALSE,
  return_raster = FALSE
)
}
\arguments{
\item{input}{A directory containing multiple ENVI or TIF files, a single file, or a character vector of file paths.}

\item{output_dir}{A directory where the masked raster(s) will be saved.}

\item{ndvi_threshold}{Numeric. NDVI threshold for masking (pixels with NDVI values below this are masked as non-vegetation).}

\item{nir_threshold}{Numeric. NIR threshold for masking (pixels with NIR values below this are masked as shadows).}

\item{ndvi_threshold_df}{Optional. A data frame with two columns: \code{site} (site identifiers) and \code{threshold}
(NDVI threshold values for each site). The \code{site} values must match the beginning of the input file names.}

\item{nir_threshold_df}{Optional. A data frame with two columns: \code{site} (site identifiers) and \code{threshold}
(NIR threshold values for each site). The \code{site} values must match the beginning of the input file names.}

\item{red_band_index}{Integer. The index (layer number) of the red band in the input raster. Default is 3.}

\item{nir_band_index}{Integer. The index (layer number) of the NIR band in the input raster. Default is 5.}

\item{make_plot}{Logical. If \code{TRUE}, a plot of the masked raster is generated for verification. Default is \code{FALSE}.}

\item{return_raster}{Logical. If \code{TRUE}, the masked raster object is returned. Default is \code{FALSE}.}
}
\value{
Saves masked raster(s) as TIF files in the specified \code{output_dir}.
If \code{return_raster = TRUE}, the function returns the masked raster object as a \code{terra} raster.
}
\description{
This function creates a masked raster by removing non-vegetation pixels based on NDVI and NIR threshold values.
It supports processing single files, multiple files in a directory, or a list of file paths. Threshold values
can be specified as single values or as a data frame with site-specific thresholds. The function assumes that
the input layers are stacked in wavelength order and saves the masked raster to the specified output directory.
}
\examples{

input <- system.file("extdata/multiband_image", package = "saltbush")
output_dir <- tempdir()
create_masked_raster(input,
                    output_dir,
                    ndvi_threshold = 0.02,
                   nir_threshold = 0.04,
                     red_band_index = 3,
                     nir_band_index = 5)

}
