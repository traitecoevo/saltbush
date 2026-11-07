# Synthetic percent-cover survey data

A small, hand-crafted percent-cover survey for three plots, with species
typical of chenopod shrubland at Fowlers Gap, NSW. Each row is one
species' cover estimate in a plot (unlike
[synthetic_survey](https://traitecoevo.github.io/saltbush/reference/synthetic_survey.md),
where each row is a point-intercept hit), and non-plant categories are
included. Used to show
[`calculate_field_diversity()`](https://traitecoevo.github.io/saltbush/reference/calculate_field_diversity.md)
on survey data other than AusPlots, via `species_col`, `exclude` and
`abundance_col`. The values are made up.

## Usage

``` r
cover_survey
```

## Format

A data frame with 15 rows and 3 columns:

- plot_id:

  Character. Plot identifier.

- species:

  Character. Species name, or a non-plant category (`"Bare ground"`,
  `"Litter"`).

- cover_pct:

  Numeric. Percent cover of the species in the plot.

## Source

Hand-crafted for package examples. See `data-raw/cover_survey.R`.

## Examples

``` r
calculate_field_diversity(cover_survey,
                          aoi_cols = "plot_id",
                          species_col = "species",
                          exclude = c("Bare ground", "Litter"),
                          abundance_col = "cover_pct")$taxonomic_diversity
#>   plot_id species_richness shannon_diversity simpson_diversity pielou_evenness
#> 1  plot_A                4         1.3620209         0.7378512       0.9824904
#> 2  plot_B                3         0.5608217         0.2907986       0.5104820
#> 3  plot_C                2         0.5004024         0.3200000       0.7219281
#>   exp_shannon inv_simpson
#> 1    3.904075    3.814628
#> 2    1.752112    1.410037
#> 3    1.649385    1.470588
```
