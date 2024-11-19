
<!-- README.md is generated from README.Rmd. Please edit that file -->
<!-- badges: start -->

[![](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/traitecoevo/saltbush/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/traitecoevo/saltbush/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/traitecoevo/saltbush/graph/badge.svg)](https://app.codecov.io/gh/traitecoevo/saltbush)
<!-- badges: end -->

# saltbush <img src="man/figures/saltbush_hex.png" align="right" width="150"/>

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
#>   species_richness shannon_diversity simpson_diversity
#> 1               28          2.379688         0.8649789
#> 2               22          2.200076         0.8509874
#> 3               20          2.179534         0.8242833
#> 4               18          2.149992         0.8375000
#>   pielou_evenness exp_shannon inv_simpson             site
#> 1       0.7141483   10.801533    7.406252 SATFLB0004-58658
#> 2       0.7117585    9.025696    6.710843 NTASTU0002-58429
#> 3       0.7275464    8.842187    5.690977 QDAMGD0022-53501
#> 4       0.7438460    8.584786    6.153846 SATFLB0004-53705
#> 
#> $community_matrices
#> $community_matrices$`SATFLB0004-58658`
#>   Acacia pravifolia Alectryon oleifolius subsp. canescens
#> 1                 2                                     1
#>   Arthropodium Bursaria spinosa subsp. spinosa Callitris glaucophylla
#> 1           13                              12                    110
#>   Carrichtera annua Cassinia laevis Daucus glochidiatus
#> 1                23              17                   1
#>   Dodonaea viscosa subsp. angustissima Eremophila deserti
#> 1                                   37                  1
#>   Eucalyptus intertexta Hakea leucoptera subsp. leucoptera
#> 1                   115                                 42
#>   Leiocarpa semicalva subsp. semicalva
#> 1                                    1
#>   Lomandra multiflora subsp. dura Millotia Na Olearia decurrens
#> 1                               1        3  7                18
#>   Oxalis perennans Pauridia glabella var. glabella Poaceae
#> 1                1                               8       2
#>   Ptilotus obovatus Rhagodia parabolica Scleranthus pungens
#> 1                22                  49                   3
#>   Sida petrophila Triodia Wahlenbergia Wurmbea
#> 1               2       1            1       1
#>   Xanthorrhoea quadrangulata
#> 1                          2
#> 
#> $community_matrices$`NTASTU0002-58429`
#>   Atalaya hemiglauca Bauhinia cunninghamii
#> 1                  1                     2
#>   Brachychiton diversifolius subsp. diversifolius
#> 1                                               3
#>   Brachychiton paradoxus Chrysopogon fallax Corymbia confertiflora
#> 1                      1                 77                     21
#>   Corymbia polycarpa Corymbia terminalis Dichanthium fecundum
#> 1                 47                 103                   98
#>   Dodonaea oxyptera Dolichandrone filiformis
#> 1                 2                        2
#>   Erythrophleum chlorostachys Eucalyptus chlorophylla
#> 1                          25                      29
#>   Eucalyptus pruinosa Eulalia aurea
#> 1                  26             6
#>   Flueggea virosa subsp. melanthesoides
#> 1                                     1
#>   Gardenia ewartii subsp. ewartii Glycine tomentella Na
#> 1                               3                  6  2
#>   Schizachyrium fragile Terminalia canescens Themeda triandra
#> 1                     1                    8              168
#> 
#> $community_matrices$`QDAMGD0022-53501`
#>   Amaranthus mitchellii Aristida latifolia Astrebla elymoides
#> 1                     1                  7                 27
#>   Astrebla pectinata Boerhavia schomburgkiana Bothriochloa ewartiana
#> 1                 57                        1                      6
#>   Cenchrus ciliaris Chloris pectinata Cynodon convergens
#> 1                32                 1                  1
#>   Cyperus gilesii Dactyloctenium radulans Eulalia aurea
#> 1               3                       4             3
#>   Iseilema vaginiflorum Na Neptunia dimorphantha Poaceae
#> 1                     2  2                     1      11
#>   Sida fibulifera Sida goniocarpa Sporobolus actinocladus
#> 1               4               4                       5
#>   Vachellia farnesiana
#> 1                    3
#> 
#> $community_matrices$`SATFLB0004-53705`
#>   Acacia ligulata Alectryon oleifolius
#> 1               1                    7
#>   Bursaria spinosa subsp. spinosa Callitris glaucophylla
#> 1                               4                    108
#>   Carrichtera annua Cassinia laevis
#> 1                 5              19
#>   Dodonaea viscosa subsp. angustissima Eremophila deserti
#> 1                                   16                  7
#>   Eucalyptus intertexta Hakea leucoptera Olearia decurrens
#> 1                    97               32                10
#>   Ptilotus obovatus Rhagodia parabolica Scleranthus pungens
#> 1                31                  43                   1
#>   Senna artemisioides subsp. x artemisioides Sida petrophila Triodia
#> 1                                          1              15       1
#>   Xanthorrhoea quadrangulata
#> 1                          3
```
