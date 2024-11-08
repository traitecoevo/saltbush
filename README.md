 <!-- badges: start -->
  [![R-CMD-check](https://github.com/traitecoevo/saltbush/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/traitecoevo/saltbush/actions/workflows/R-CMD-check.yaml)
  <!-- badges: end -->

# saltbush
*saltbush* processes  drone and ausplot field survey data to calculate spectral + taxonomic diversity values
for assessment of the 'spectral variability hypothesis'.

Spectral diversity metrics:
+ co-efficient of variance (CV)
+ spectral variance (SV)
+ convex hull volume (CHV)

Taxonomic diversity metrics:
+ species richness
+ shannon's diversity index
+ simpson's diversity index
+ pielou's evenness
+ exponential shannon's index
+ inverse simpson's index

# Installation
```r
 install.packages("remotes")
 remotes::install_github("traitecoevo/saltbush")
