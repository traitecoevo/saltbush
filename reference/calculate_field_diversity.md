# Calculate field diversity

Takes species survey data and calculates field diversity at the grouping
specified by `aoi_cols`. The defaults suit AusPlots point-intercept data
from ausplotsR: grouping by `site_unique` (one row per survey visit),
species in `standardised_name`, dead material excluded, and each row
counted as one hit. Other survey data can be used by changing
`species_col`, `exclude` and `abundance_col`.

## Usage

``` r
calculate_field_diversity(
  survey_data,
  aoi_cols = "site_unique",
  species_col = "standardised_name",
  exclude = c("Dead grass", "Dead shrub"),
  abundance_col = NULL,
  group_by_cols = NULL
)
```

## Arguments

- survey_data:

  a data frame of survey records, e.g. AusPlots point-intercept data
  from ausplotsR, with one row per record.

- aoi_cols:

  character vector of column names in `survey_data` that identify each
  area of interest (AOI), i.e. the unit diversity is calculated for.
  Defaults to `"site_unique"`, which gives one row per survey visit.
  Pass e.g. `c("site_unique", "subplot_id")` to compute diversity per
  subplot within each site, to match subplot AOIs in
  [`calculate_spectral_metrics()`](https://traitecoevo.github.io/saltbush/reference/calculate_spectral_metrics.md).
  (Previously `group_by_cols`.)

- species_col:

  name of the column holding species names. Defaults to
  `"standardised_name"` (ausplotsR).

- exclude:

  values of `species_col` to leave out, such as dead material. Defaults
  to `c("Dead grass", "Dead shrub")`; use `NULL` to keep everything.

- abundance_col:

  optional name of a numeric column holding the abundance of each record
  (e.g. counts or percent cover). When `NULL` (default), each row counts
  as one hit, as in point-intercept data. Records with zero abundance
  are treated as absent; negative or missing values are an error.

- group_by_cols:

  deprecated; use `aoi_cols`.

## Value

a list, containing 'taxonomic_diversity' - values of species richness,
shannon's index, simpsons index, exponential shannon's, inverse simpson,
pielou's evenness, with one row per unique combination of `aoi_cols`,
and 'community_matrices' - a list of per-group community matrices keyed
by the grouping values; each matrix has the `aoi_cols` as leading id
columns followed by one column per species.

## Examples

``` r
# Default: one row per survey visit, using the bundled synthetic data.
site_div <- calculate_field_diversity(synthetic_survey)
site_div$taxonomic_diversity
#>   site_unique site_location_name species_richness shannon_diversity
#> 1   SITE1-001          SITE1-001                4          1.242453
#> 2   SITE2-002          SITE2-002                3          1.011404
#>   simpson_diversity pielou_evenness exp_shannon inv_simpson
#> 1         0.6666667       0.8962406    3.464102    3.000000
#> 2         0.6111111       0.9206198    2.749459    2.571429

# Subplot-level diversity within each visit:
subplot_div <- calculate_field_diversity(
  synthetic_survey,
  aoi_cols = c("site_unique", "subplot_id")
)
subplot_div$taxonomic_diversity
#>   site_unique subplot_id site_location_name species_richness shannon_diversity
#> 1   SITE1-001        1_1          SITE1-001                3         1.0986123
#> 2   SITE1-001        1_2          SITE1-001                2         0.6365142
#> 3   SITE2-002        1_1          SITE2-002                1         0.0000000
#> 4   SITE2-002        1_2          SITE2-002                2         0.6365142
#>   simpson_diversity pielou_evenness exp_shannon inv_simpson
#> 1         0.6666667       1.0000000    3.000000         3.0
#> 2         0.4444444       0.9182958    1.889882         1.8
#> 3         0.0000000             NaN    1.000000         1.0
#> 4         0.4444444       0.9182958    1.889882         1.8

# Cached real AusPlots point-intercept data for site NSABHC0009:
field_diversity_real <- calculate_field_diversity(ausplots_NSABHC0009)
field_diversity_real$taxonomic_diversity
#>        site_unique site_location_name species_richness shannon_diversity
#> 1 NSABHC0009-58026         NSABHC0009               52          3.056908
#> 2 NSABHC0009-53604         NSABHC0009               38          2.843074
#>   simpson_diversity pielou_evenness exp_shannon inv_simpson
#> 1         0.9203249       0.7736571    21.26171    12.55097
#> 2         0.9043699       0.7815826    17.16846    10.45696

# To pull fresh data from the AusPlots database (requires network):
if (FALSE) { # \dontrun{
ausplot.pi.data <- ausplotsR::get_ausplots(
  my.Plot_IDs = c("SATFLB0004", "QDAMGD0022", "NTASTU0002"),
  veg.PI = TRUE
)$veg.PI
calculate_field_diversity(ausplot.pi.data)
} # }
```
