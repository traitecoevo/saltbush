#'
#' @title Calculate field diversity
#'
#' @description Takes ausplot survey data and calculates field diversity at the
#' grouping specified by `group_by_cols`. The default groups by `site_unique`
#' (one row per survey visit, matching the prior behaviour); passing
#' `c("site_unique", "subplot_id")` (or any other vector of column names in
#' `survey_data`) computes diversity at that finer granularity.
#'
#' @param survey_data a df obtained from ausplotsR package with survey data for appropriate sites
#' @param group_by_cols character vector of column names in `survey_data` to
#'   group by. Defaults to `"site_unique"`, which gives one row per survey visit.
#'   Pass e.g. `c("site_unique", "subplot_id")` to compute diversity per subplot
#'   within each site.
#' @return a list, containing 'taxonomic_diversity' - values of species richness,
#'   shannon's index, simpsons index, exponential shannon's, inverse simpson,
#'   pielou's evenness, with one row per unique combination of `group_by_cols`,
#'   and 'community_matrices' - a list of per-group community matrices keyed by
#'   the grouping values; each matrix has the `group_by_cols` as leading id
#'   columns followed by one column per species.
#' @export
#' @examples
#' # Default: one row per survey visit, using the bundled synthetic data.
#' site_div <- calculate_field_diversity(synthetic_survey)
#' site_div$taxonomic_diversity
#'
#' # Subplot-level diversity within each visit:
#' subplot_div <- calculate_field_diversity(
#'   synthetic_survey,
#'   group_by_cols = c("site_unique", "subplot_id")
#' )
#' subplot_div$taxonomic_diversity
#'
#' # Cached real AusPlots point-intercept data for site NSABHC0009:
#' field_diversity_real <- calculate_field_diversity(ausplots_NSABHC0009)
#' field_diversity_real$taxonomic_diversity
#'
#' # To pull fresh data from the AusPlots database (requires network):
#' \dontrun{
#' ausplot.pi.data <- ausplotsR::get_ausplots(
#'   my.Plot_IDs = c("SATFLB0004", "QDAMGD0022", "NTASTU0002"),
#'   veg.PI = TRUE
#' )$veg.PI
#' calculate_field_diversity(ausplot.pi.data)
#' }

calculate_field_diversity <- function(survey_data, group_by_cols = "site_unique"){

  # validate inputs
  missing_cols <- setdiff(group_by_cols, names(survey_data))
  if (length(missing_cols) > 0) {
    stop(sprintf("group_by_cols not found in survey_data: %s",
                 paste(missing_cols, collapse = ", ")))
  }

  # build the unique grouping keys, dropping rows where any key col is "" or NA
  grouping_keys <- survey_data |>
    dplyr::select(dplyr::all_of(group_by_cols)) |>
    dplyr::distinct() |>
    dplyr::filter(dplyr::if_all(dplyr::everything(),
                                ~ !is.na(.) & . != ""))

  all_results <- list()
  community_matrices <- list()

  for (i in seq_len(nrow(grouping_keys))) {
    key <- grouping_keys[i, , drop = FALSE]

    # filter survey rows to this group
    group_data <- survey_data |>
      dplyr::semi_join(key, by = group_by_cols)

    cleaned <- group_data |>
      tidyr::drop_na(standardised_name) |>
      dplyr::filter(!standardised_name %in% c('Dead grass', 'Dead shrub'))

    # community matrix: leading group_by_cols id columns + one column per species
    community_matrix <- cleaned |>
      dplyr::count(dplyr::across(dplyr::all_of(group_by_cols)),
                   standardised_name) |>
      tidyr::pivot_wider(names_from = standardised_name,
                         values_from = n, values_fill = 0)

    # key the community matrix by concatenating the group key values
    key_id <- paste(unlist(key), collapse = "_")
    community_matrices[[key_id]] <- community_matrix

    species_richness <- dplyr::n_distinct(cleaned$standardised_name)

    if (species_richness == 0) {
      next
    }

    # strip the id columns; the rest are species counts (numeric)
    counts <- community_matrix |>
      dplyr::select(-dplyr::all_of(group_by_cols))

    shannon_diversity <- as.numeric(vegan::diversity(counts, index = "shannon"))
    simpson_diversity <- as.numeric(vegan::diversity(counts, index = "simpson"))
    inv_simpson       <- as.numeric(vegan::diversity(counts, index = "invsimpson"))

    plot_diversity <- dplyr::bind_cols(
      key,
      data.frame(
        species_richness  = species_richness,
        shannon_diversity = shannon_diversity,
        simpson_diversity = simpson_diversity,
        pielou_evenness   = shannon_diversity / log(species_richness),
        exp_shannon       = exp(shannon_diversity),
        inv_simpson       = inv_simpson
      )
    )

    # preserve the original output shape when grouping by site_unique:
    # surface site_location_name (parsed from site_unique) and order columns
    if ("site_unique" %in% group_by_cols) {
      plot_diversity$site_location_name <- substr(key$site_unique, 1, 10)
      plot_diversity <- plot_diversity |>
        dplyr::select(dplyr::all_of(group_by_cols),
                      "site_location_name",
                      dplyr::everything())
    }

    all_results[[key_id]] <- plot_diversity
  }

  taxonomic_diversity <- dplyr::bind_rows(all_results)

  return(list(
    taxonomic_diversity = taxonomic_diversity,
    community_matrices = community_matrices
  ))
}
