
<!-- README.md is generated from README.Rmd. Please edit that file -->
<!-- badges: start -->

[![](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/traitecoevo/saltbush/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/traitecoevo/saltbush/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/traitecoevo/saltbush/graph/badge.svg)](https://app.codecov.io/gh/traitecoevo/saltbush)
<!-- badges: end -->

# saltbush <img src="man/figures/saltbush_hex.png" align="right" width="200"/>

*saltbush* processes drone imagery to calculate spectral diversity
values as part of the assessment of the ‘spectral variability
hypothesis’ or the ‘spectral-biodiversity relationship’. This was
specifically implemented to connect *from-the-sky* diversity with
*on-the-ground* diversity as measured in the AusPlots project. There are
also functions to calculate on-the-ground diversity built on the
[ausplotsR](https://github.com/ternaustralia/ausplotsR) and
[vegan](https://github.com/vegandevs/vegan) packages. The statistical
methods for connecting diversity sampled on the ground to diversity
sampled from the sky are still developing. This package is aimed at
making from-the-sky diversity methods development easier for researchers
across the world.

Specifically we have used this package in a test in the Australian arid
zone. The results suggest that some of the methods below perform much
better than others. See our paper *Placeholder to link to the preprint
once that’s posted.*

## Installation

``` r
 install.packages("remotes")
 remotes::install_github("traitecoevo/saltbush")
```

## Usage

1.  **Direct the package to the input files** in this case we use a
    drone image from Fowlers Gap, NSW, Australia

The example data in this case is 5 bands sampled from a drone

``` r
create_multiband_image("inst/extdata/create_multiband_image/",
                       c('blue', 'green', 'red', 'red_edge', 'nir'), 
                       output_dir = tempdir(),
                       make_plot = TRUE, return_raster = TRUE)
```

<img src="man/figures/README-unnamed-chunk-2-1.png" width="90%" />

The resulting multiband image can be combined with an area of interest
shapefile:

``` r

raster_files <- list.files("inst/extdata/example",
    pattern = '.tif$', full.names = TRUE)

aoi_files <- list.files("inst/extdata/aoi",
    pattern = 'NSABHC0009_aoi.shp$', full.names = TRUE)
```

2.  **Extract pixel values** from the area of interest in the image

``` r

pixel_values <- extract_pixel_values(raster_files, 
                                     aoi_files,
                                     c('blue','green','red','red_edge','nir'))

head(pixel_values)  
#>    site_name       blue      green        red   red_edge        nir aoi_id
#> 1 NSABHC0009 0.05511368 0.05600401 0.07633078 0.06699516 0.08160288      1
#> 2 NSABHC0009 0.06224341 0.06684195 0.09760323 0.08534835 0.10119278      1
#> 3 NSABHC0009 0.05985198 0.06332091 0.08991133 0.07894940 0.09560681      1
#> 4 NSABHC0009 0.05927841 0.06296582 0.08709560 0.07646009 0.09347322      1
#> 5 NSABHC0009 0.04356062 0.04587397 0.06008397 0.05540059 0.07216450      1
#> 6 NSABHC0009 0.03945594 0.03824322 0.04755034 0.04384791 0.05770193      1
```

3.  **Calculate spectral metrics**

``` r

metrics <- calculate_spectral_metrics(pixel_values, 
                                      wavelengths = colnames(pixel_values[, 2:6]),
                                      masked = F,
                                      rarefaction = F)

head(metrics)
#>          site aoi_id        CV          SV          CHV image_type
#>        <char>  <num>     <num>       <num>        <num>     <char>
#> 1: NSABHC0009      1 0.3314709 0.001708346 3.302738e-10   unmasked
```

- co-efficient of variance (CV)
- spectral variance (SV)
- convex hull volume (CHV)

For a full discussion of these metrics see the manuscript

4.  **Download plot data** from AusPlots. The `veg.PI` part extracts the
    point intercept data from the AusPlots data structure. In this case
    we use the same AusplotID as in the drone images above. This gets us
    data for two on-the-ground sampling visits to one particular AusPlot
    where we happen to have drone imagery.

``` r
my.data <- ausplotsR::get_ausplots(my.Plot_IDs=c("NSABHC0009"), veg.PI=TRUE)
my.data$site.info$visit_date
#> [1] "2012-09-03" "2016-09-13"
```

5.  **Calculate on-the-ground diversity** from the point intercepts
    using different diversity metrics. The output is a list which
    includes taxonomic metrics, and also community matrices for checks.
    Not that this takes the `PI` part of the AusPlot object which stands
    for point-intercept. For a general function to calculate
    on-the-ground diversity, see [the diversity function from the vegan
    package](https://rdrr.io/cran/vegan/man/diversity.html).

``` r
field_diversity <- calculate_field_diversity(my.data$veg.PI)
field_diversity$taxonomic_diversity
#>        site_unique site_location_name species_richness shannon_diversity
#> 1 NSABHC0009-58026         NSABHC0009               52          3.041263
#> 2 NSABHC0009-53604         NSABHC0009               38          2.833114
#>   simpson_diversity pielou_evenness exp_shannon inv_simpson
#> 1         0.9195892       0.7696978    20.93167    12.43614
#> 2         0.9039217       0.7788445    16.99831    10.40818
```

2012 was wetter than 2016 and there are a number of rain ephemeral
species at this site so the higher species richness makes sense.

The calculated taxonomic diversity metrics are:

- species richness
- shannon’s diversity index
- simpson’s diversity index
- pielou’s evenness
- exponential shannon’s index
- inverse simpson’s index

6.  **Compare on-the-ground and from-the-sky diversity**

High-resolution drone images are very large, and the example data
included with the package on github are too small to do this
meaningfully. We recommend doing this locally following the above steps.
