# Cached AusPlots point-intercept data for site NSABHC0009

A cached subset of the point-intercept (`veg.PI`) table for AusPlots
site `NSABHC0009` at Fowlers Gap, NSW. Saved as a package dataset so the
worked example and tests do not require live access to the AusPlots
database.

## Usage

``` r
data(ausplots_NSABHC0009)
```

## Format

A data frame with one row per point-intercept hit:

- site_unique:

  Character. Unique site/visit identifier.

- site_location_name:

  Character. Site identifier.

- site_location_visit_id:

  Integer. AusPlots visit identifier.

- transect:

  Character. Transect identifier within the visit.

- point_number:

  Integer. Point number along the transect.

- standardised_name:

  Character. Standardised species name.

## Source

Cached from
[`ausplotsR::get_ausplots()`](https://rdrr.io/pkg/ausplotsR/man/get_ausplots.html)
with `my.Plot_IDs = "NSABHC0009"`. See `data-raw/ausplots_NSABHC0009.R`.

## Details

Only the columns used by saltbush plus a few useful identifiers are
retained — taxonomy columns and free-text fields are dropped to keep the
file small.
