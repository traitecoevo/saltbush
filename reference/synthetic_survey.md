# Synthetic point-intercept survey data

A small, hand-crafted data frame that mimics the shape of the `veg.PI`
table returned by
[`ausplotsR::get_ausplots()`](https://rdrr.io/pkg/ausplotsR/man/get_ausplots.html).
Two sites, each with two subplots and a handful of species hits. Used in
examples, tests, and the package vignette so they can run without an
internet connection.

## Usage

``` r
data(synthetic_survey)
```

## Format

A data frame with 12 rows and 4 columns:

- site_unique:

  Character. Unique site/visit identifier.

- site_location_name:

  Character. Site identifier (the prefix of `site_unique`).

- subplot_id:

  Character. Subplot identifier within the site.

- standardised_name:

  Character. Species name for the point hit.

## Source

Hand-crafted for package examples. See `data-raw/synthetic_survey.R`.
