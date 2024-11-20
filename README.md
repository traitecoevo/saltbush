
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

### Spectral diversity metrics:

- co-efficient of variance (CV)
- spectral variance (SV)
- convex hull volume (CHV)

### Taxonomic diversity metrics:

- species richness
- shannon’s diversity index
- simpson’s diversity index
- pielou’s evenness
- exponential shannon’s index
- inverse simpson’s index

## Usage

## Spectral metrics

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
    diversity metrics

``` r
field_diversity <- calculate_field_diversity(my.data)
field_diversity
#> $field_diversity
#>               site species_richness shannon_diversity simpson_diversity pielou_evenness exp_shannon
#> 1 SATFLB0004-58658               28          2.379688         0.8649789       0.7141483   10.801533
#> 2 NTASTU0002-58429               22          2.200076         0.8509874       0.7117585    9.025696
#> 3 QDAMGD0022-53501               20          2.179534         0.8242833       0.7275464    8.842187
#> 4 SATFLB0004-53705               18          2.149992         0.8375000       0.7438460    8.584786
#>   inv_simpson           survey
#> 1    7.406252 SATFLB0004-58658
#> 2    6.710843 NTASTU0002-58429
#> 3    5.690977 QDAMGD0022-53501
#> 4    6.153846 SATFLB0004-53705
#> 
#> $community_matrices
#> $community_matrices$`SATFLB0004-58658`
#>   Acacia pravifolia Alectryon oleifolius subsp. canescens Arthropodium
#> 1                 2                                     1           13
#>   Bursaria spinosa subsp. spinosa Callitris glaucophylla Carrichtera annua Cassinia laevis
#> 1                              12                    110                23              17
#>   Daucus glochidiatus Dodonaea viscosa subsp. angustissima Eremophila deserti Eucalyptus intertexta
#> 1                   1                                   37                  1                   115
#>   Hakea leucoptera subsp. leucoptera Leiocarpa semicalva subsp. semicalva
#> 1                                 42                                    1
#>   Lomandra multiflora subsp. dura Millotia Na Olearia decurrens Oxalis perennans
#> 1                               1        3  7                18                1
#>   Pauridia glabella var. glabella Poaceae Ptilotus obovatus Rhagodia parabolica Scleranthus pungens
#> 1                               8       2                22                  49                   3
#>   Sida petrophila Triodia Wahlenbergia Wurmbea Xanthorrhoea quadrangulata
#> 1               2       1            1       1                          2
#> 
#> $community_matrices$`NTASTU0002-58429`
#>   Atalaya hemiglauca Bauhinia cunninghamii Brachychiton diversifolius subsp. diversifolius
#> 1                  1                     2                                               3
#>   Brachychiton paradoxus Chrysopogon fallax Corymbia confertiflora Corymbia polycarpa
#> 1                      1                 77                     21                 47
#>   Corymbia terminalis Dichanthium fecundum Dodonaea oxyptera Dolichandrone filiformis
#> 1                 103                   98                 2                        2
#>   Erythrophleum chlorostachys Eucalyptus chlorophylla Eucalyptus pruinosa Eulalia aurea
#> 1                          25                      29                  26             6
#>   Flueggea virosa subsp. melanthesoides Gardenia ewartii subsp. ewartii Glycine tomentella Na
#> 1                                     1                               3                  6  2
#>   Schizachyrium fragile Terminalia canescens Themeda triandra
#> 1                     1                    8              168
#> 
#> $community_matrices$`QDAMGD0022-53501`
#>   Amaranthus mitchellii Aristida latifolia Astrebla elymoides Astrebla pectinata
#> 1                     1                  7                 27                 57
#>   Boerhavia schomburgkiana Bothriochloa ewartiana Cenchrus ciliaris Chloris pectinata
#> 1                        1                      6                32                 1
#>   Cynodon convergens Cyperus gilesii Dactyloctenium radulans Eulalia aurea Iseilema vaginiflorum Na
#> 1                  1               3                       4             3                     2  2
#>   Neptunia dimorphantha Poaceae Sida fibulifera Sida goniocarpa Sporobolus actinocladus
#> 1                     1      11               4               4                       5
#>   Vachellia farnesiana
#> 1                    3
#> 
#> $community_matrices$`SATFLB0004-53705`
#>   Acacia ligulata Alectryon oleifolius Bursaria spinosa subsp. spinosa Callitris glaucophylla
#> 1               1                    7                               4                    108
#>   Carrichtera annua Cassinia laevis Dodonaea viscosa subsp. angustissima Eremophila deserti
#> 1                 5              19                                   16                  7
#>   Eucalyptus intertexta Hakea leucoptera Olearia decurrens Ptilotus obovatus Rhagodia parabolica
#> 1                    97               32                10                31                  43
#>   Scleranthus pungens Senna artemisioides subsp. x artemisioides Sida petrophila Triodia
#> 1                   1                                          1              15       1
#>   Xanthorrhoea quadrangulata
#> 1                          3
```
