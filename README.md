
<!-- README.md is generated from README.Rmd. Please edit that file -->
<!-- badges: start -->

[![](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/traitecoevo/saltbush/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/traitecoevo/saltbush/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/traitecoevo/saltbush/graph/badge.svg)](https://app.codecov.io/gh/traitecoevo/saltbush)
<!-- badges: end -->

# saltbush <img src="man/figures/saltbush_hex.png" align="right" width="220"/>

*saltbush* processes drone imagery and ausplot vegetation survey data to
calculate spectral + taxonomic diversity values for assessment of the
‘spectral variability hypothesis’.

# Installation

``` r
 install.packages("remotes")
 remotes::install_github("traitecoevo/saltbush")
```

## Usage

## Spectral metrics

### Spectral diversity metrics:

- co-efficient of variance (CV)
- spectral variance (SV)
- convex hull volume (CHV)

1.  List raster files and area of interest files

``` r
raster_files <- list.files(system.file("extdata/example", package = "saltbush"),
    pattern = '.tif$', full.names = TRUE)

aoi_files <- list.files(system.file("extdata/aoi", package = "saltbush"),
    pattern = 'NSABHC0009_aoi.shp$', full.names = TRUE)
```

2.  Extract pixel values

``` r
pixel_values <- extract_pixel_values(raster_files, 
                                     aoi_files)

head(pixel_values)  
#>    site_name       blue      green        red   red_edge        nir aoi_id
#> 1 NSABHC0009 0.05511368 0.05600401 0.07633078 0.06699516 0.08160288      1
#> 2 NSABHC0009 0.06224341 0.06684195 0.09760323 0.08534835 0.10119278      1
#> 3 NSABHC0009 0.05985198 0.06332091 0.08991133 0.07894940 0.09560681      1
#> 4 NSABHC0009 0.05927841 0.06296582 0.08709560 0.07646009 0.09347322      1
#> 5 NSABHC0009 0.04356062 0.04587397 0.06008397 0.05540059 0.07216450      1
#> 6 NSABHC0009 0.03945594 0.03824322 0.04755034 0.04384791 0.05770193      1
```

3.  Calculate spectral metrics

``` r
metrics <- calculate_spectral_metrics(pixel_values, masked = F, wavelengths = colnames(pixel_values[, 2:6]), rarefaction = F)

head(metrics)
#>          site aoi_id        CV          SV          CHV image_type
#>        <char>  <num>     <num>       <num>        <num>     <char>
#> 1: NSABHC0009      1 0.3314709 0.001708346 3.302738e-10   unmasked
```

## Taxonomic metrics

### Taxonomic diversity metrics:

- species richness
- shannon’s diversity index
- simpson’s diversity index
- pielou’s evenness
- exponential shannon’s index
- inverse simpson’s index

1.  Download example plot data from AusPlots. The `veg.PI` part extracts
    the point intercept data from the AusPlots data structure.

``` r
my.data <- ausplotsR::get_ausplots(my.Plot_IDs=c("SATFLB0004", "QDAMGD0022", "NTASTU0002"), veg.PI=TRUE)$veg.PI
#> Calling the database. Please wait...
#> downloading (search) [---------------] (  1%) time: 00:00:00downloading (search) [===============] (100%) time: 00:00:00
#> 200
#> User-supplied Plot_IDs located.
#> Calling the database. Please wait...
#> downloading (site) [-----------------] (  1%) time: 00:00:00downloading (site) [=================] (100%) time: 00:00:00
#> 200
#> Calling the database. Please wait...
#> downloading (veg_pi) [---------------] (  1%) time: 00:00:00downloading (veg_pi) [===============] (100%) time: 00:00:00
#> 200
```

2.  Calculate diversity from the point intercepts using different
    diversity metrics. The output is a list which includes taxonomic
    metrics, and also community matrices for checks.

``` r
field_diversity <- calculate_field_diversity(my.data)
field_diversity$taxonomic_diversity
#>        site_unique site_location_name species_richness shannon_diversity
#> 1 SATFLB0004-58658         SATFLB0004               28          2.379688
#> 2 NTASTU0002-58429         NTASTU0002               22          2.200076
#> 3 QDAMGD0022-53501         QDAMGD0022               20          2.179534
#> 4 SATFLB0004-53705         SATFLB0004               18          2.149992
#>   simpson_diversity pielou_evenness exp_shannon inv_simpson
#> 1         0.8649789       0.7141483   10.801533    7.406252
#> 2         0.8509874       0.7117585    9.025696    6.710843
#> 3         0.8242833       0.7275464    8.842187    5.690977
#> 4         0.8375000       0.7438460    8.584786    6.153846
```
