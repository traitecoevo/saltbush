# Find optimum thresholds

Takes input ground truth data to find optimum thresholds for image
masking.

## Usage

``` r
find_optimum_thresholds(
  df,
  class_col,
  band_or_index_col,
  site_col,
  class_value
)
```

## Arguments

- df:

  Input must be a df with columns for site name, pixel value, class

- class_col:

  name of column where object class are stored

- band_or_index_col:

  name of column where pixel values are stored - e.g. 'ndvi' or
  'nir_values'

- site_col:

  name of site column - which indicates where pixel values + class data
  are obtained from

- class_value:

  value/s of class that should be masked - e.g. for ndvi, 'non-veg' or
  c('bare_ground','rocks'), for nir, 'shadow'

## Value

a df with optimum thresholds for each site

## Examples

``` r
ndvi_values <- data.frame(site = rep(c("site_one", "site_two"), each = 100),
point = rep(1:100, times = 2),
ndvi = runif(200, min = -1, max = 1),
class = sample(rep(c('veg', 'non-veg'), each = 100)))
ndvi_thresholds <- find_optimum_thresholds(ndvi_values,
class_col = 'class', band_or_index_col = 'ndvi',
site_col = 'site', class_value = 'non-veg')
#> Setting levels: control = 0, case = 1
#> Setting direction: controls > cases
#> Setting levels: control = 0, case = 1
#> Setting direction: controls < cases
```
