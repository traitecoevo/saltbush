
<!-- README.md is generated from README.Rmd. Please edit that file -->
<!-- badges: start -->

[![](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/traitecoevo/saltbush/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/traitecoevo/saltbush/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/traitecoevo/saltbush/graph/badge.svg)](https://app.codecov.io/gh/traitecoevo/saltbush)
<!-- badges: end -->

# saltbush

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

1.  Download example plot data from AusPlots. The `veg.PI` part extracts
    the point intercept data from the AusPlots data structure.

``` r
my.data <- ausplotsR::get_ausplots(my.Plot_IDs=c("SATFLB0004", "QDAMGD0022", "NTASTU0002"), veg.PI=TRUE)$veg.PI
#> Calling the database. Please wait...
#> 200
#> User-supplied Plot_IDs located.
#> Calling the database. Please wait...
#> 200
#> Calling the database. Please wait...
#> 200
```

2.  Calculate diversity from the point intercepts using different
    diversity metrics

``` r
field_diversity <- calculate_field_diversity(my.data)
field_diversity
#> $field_diversity
#>   species_richness shannon_diversity simpson_diversity pielou_evenness
#> 1               28          2.379688         0.8649789       0.7141483
#> 2               22          2.200076         0.8509874       0.7117585
#> 3               20          2.179534         0.8242833       0.7275464
#> 4               18          2.149992         0.8375000       0.7438460
#>   exp_shannon inv_simpson             site
#> 1   10.801533    7.406252 SATFLB0004-58658
#> 2    9.025696    6.710843 NTASTU0002-58429
#> 3    8.842187    5.690977 QDAMGD0022-53501
#> 4    8.584786    6.153846 SATFLB0004-53705
#> 
#> $community_matrices
#> $community_matrices$`SATFLB0004-58658`
#>   Acacia pravifolia Alectryon oleifolius subsp. canescens Arthropodium
#> 1                 2                                     1           13
#>   Bursaria spinosa subsp. spinosa Callitris glaucophylla Carrichtera annua
#> 1                              12                    110                23
#>   Cassinia laevis Daucus glochidiatus Dodonaea viscosa subsp. angustissima
#> 1              17                   1                                   37
#>   Eremophila deserti Eucalyptus intertexta Hakea leucoptera subsp. leucoptera
#> 1                  1                   115                                 42
#>   Leiocarpa semicalva subsp. semicalva Lomandra multiflora subsp. dura Millotia
#> 1                                    1                               1        3
#>   Na Olearia decurrens Oxalis perennans Pauridia glabella var. glabella Poaceae
#> 1  7                18                1                               8       2
#>   Ptilotus obovatus Rhagodia parabolica Scleranthus pungens Sida petrophila
#> 1                22                  49                   3               2
#>   Triodia Wahlenbergia Wurmbea Xanthorrhoea quadrangulata
#> 1       1            1       1                          2
#> 
#> $community_matrices$`NTASTU0002-58429`
#>   Atalaya hemiglauca Bauhinia cunninghamii
#> 1                  1                     2
#>   Brachychiton diversifolius subsp. diversifolius Brachychiton paradoxus
#> 1                                               3                      1
#>   Chrysopogon fallax Corymbia confertiflora Corymbia polycarpa
#> 1                 77                     21                 47
#>   Corymbia terminalis Dichanthium fecundum Dodonaea oxyptera
#> 1                 103                   98                 2
#>   Dolichandrone filiformis Erythrophleum chlorostachys Eucalyptus chlorophylla
#> 1                        2                          25                      29
#>   Eucalyptus pruinosa Eulalia aurea Flueggea virosa subsp. melanthesoides
#> 1                  26             6                                     1
#>   Gardenia ewartii subsp. ewartii Glycine tomentella Na Schizachyrium fragile
#> 1                               3                  6  2                     1
#>   Terminalia canescens Themeda triandra
#> 1                    8              168
#> 
#> $community_matrices$`QDAMGD0022-53501`
#>   Amaranthus mitchellii Aristida latifolia Astrebla elymoides
#> 1                     1                  7                 27
#>   Astrebla pectinata Boerhavia schomburgkiana Bothriochloa ewartiana
#> 1                 57                        1                      6
#>   Cenchrus ciliaris Chloris pectinata Cynodon convergens Cyperus gilesii
#> 1                32                 1                  1               3
#>   Dactyloctenium radulans Eulalia aurea Iseilema vaginiflorum Na
#> 1                       4             3                     2  2
#>   Neptunia dimorphantha Poaceae Sida fibulifera Sida goniocarpa
#> 1                     1      11               4               4
#>   Sporobolus actinocladus Vachellia farnesiana
#> 1                       5                    3
#> 
#> $community_matrices$`SATFLB0004-53705`
#>   Acacia ligulata Alectryon oleifolius Bursaria spinosa subsp. spinosa
#> 1               1                    7                               4
#>   Callitris glaucophylla Carrichtera annua Cassinia laevis
#> 1                    108                 5              19
#>   Dodonaea viscosa subsp. angustissima Eremophila deserti Eucalyptus intertexta
#> 1                                   16                  7                    97
#>   Hakea leucoptera Olearia decurrens Ptilotus obovatus Rhagodia parabolica
#> 1               32                10                31                  43
#>   Scleranthus pungens Senna artemisioides subsp. x artemisioides
#> 1                   1                                          1
#>   Sida petrophila Triodia Xanthorrhoea quadrangulata
#> 1              15       1                          3
```
