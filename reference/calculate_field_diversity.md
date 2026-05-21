# Calculate field diversity

Takes ausplot survey data and calculates field diversity at the grouping
specified by `group_by_cols`. The default groups by `site_unique` (one
row per survey visit, matching the prior behaviour); passing
`c("site_unique", "subplot_id")` (or any other vector of column names in
`survey_data`) computes diversity at that finer granularity.

## Usage

``` r
calculate_field_diversity(survey_data, group_by_cols = "site_unique")
```

## Arguments

- survey_data:

  a df obtained from ausplotsR package with survey data for appropriate
  sites

- group_by_cols:

  character vector of column names in `survey_data` to group by.
  Defaults to `"site_unique"`, which gives one row per survey visit.
  Pass e.g. `c("site_unique", "subplot_id")` to compute diversity per
  subplot within each site.

## Value

a list, containing 'taxonomic_diversity' - values of species richness,
shannon's index, simpsons index, exponential shannon's, inverse simpson,
pielou's evenness, with one row per unique combination of
`group_by_cols`, and 'community_matrices' - a list of per-group
community matrices keyed by the grouping values; each matrix has the
`group_by_cols` as leading id columns followed by one column per
species.

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
  group_by_cols = c("site_unique", "subplot_id")
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
