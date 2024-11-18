
<!-- README.md is generated from README.Rmd. Please edit that file -->
<!-- badges: start -->

[![](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/traitecoevo/saltbush/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/traitecoevo/saltbush/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/traitecoevo/saltbush/graph/badge.svg)](https://app.codecov.io/gh/traitecoevo/saltbush)
<!-- badges: end --> \# saltbush

*saltbush* processes drone imagery and ausplot vegetation survey data to
calculate spectral + taxonomic diversity values for assessment of the
‘spectral variability hypothesis’.

# Installation

``` r
 install.packages("remotes")
 remotes::install_github("traitecoevo/saltbush")
```

Spectral diversity metrics: + co-efficient of variance (CV) + spectral
variance (SV) + convex hull volume (CHV)

Taxonomic diversity metrics: + species richness + shannon’s diversity
index + simpson’s diversity index + pielou’s evenness + exponential
shannon’s index + inverse simpson’s index
