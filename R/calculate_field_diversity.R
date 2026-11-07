#'
#' @title Calculate field diversity
#'
#' @description Takes species survey data and calculates field diversity at the
#' grouping specified by `aoi_cols`. The defaults suit AusPlots
#' point-intercept data from ausplotsR: grouping by `site_unique` (one row per
#' survey visit), species in `standardised_name`, dead material excluded, and
#' each row counted as one hit. Other survey data can be used by changing
#' `species_col`, `exclude` and `abundance_col`.
#'
#' @param survey_data a data frame of survey records, e.g. AusPlots
#'   point-intercept data from ausplotsR, with one row per record.
#' @param aoi_cols character vector of column names in `survey_data` that
#'   identify each area of interest (AOI), i.e. the unit diversity is calculated
#'   for. Defaults to `"site_unique"`, which gives one row per survey visit.
#'   Pass e.g. `c("site_unique", "subplot_id")` to compute diversity per subplot
#'   within each site, to match subplot AOIs in [calculate_spectral_metrics()].
#'   (Previously `group_by_cols`.)
#' @param species_col name of the column holding species names. Defaults to
#'   `"standardised_name"` (ausplotsR).
#' @param exclude values of `species_col` to leave out, such as dead material.
#'   Defaults to `c("Dead grass", "Dead shrub")`; use `NULL` to keep everything.
#' @param abundance_col optional name of a numeric column holding the abundance
#'   of each record (e.g. counts or percent cover). When `NULL` (default), each
#'   row counts as one hit, as in point-intercept data. Records with zero
#'   abundance are treated as absent; negative or missing values are an error.
#' @param group_by_cols deprecated; use `aoi_cols`.
#' @return a list, containing 'taxonomic_diversity' - values of species richness,
#'   shannon's index, simpsons index, exponential shannon's, inverse simpson,
#'   pielou's evenness, with one row per unique combination of `aoi_cols`,
#'   and 'community_matrices' - a list of per-group community matrices keyed by
#'   the grouping values; each matrix has the `aoi_cols` as leading id
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
#'   aoi_cols = c("site_unique", "subplot_id")
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

calculate_field_diversity <- function(survey_data,
                                      aoi_cols = "site_unique",
                                      species_col = "standardised_name",
                                      exclude = c("Dead grass", "Dead shrub"),
                                      abundance_col = NULL,
                                      group_by_cols = NULL){

  if (!is.null(group_by_cols)) {
    warning("`group_by_cols` is deprecated; use `aoi_cols` instead.", call. = FALSE)
    aoi_cols <- group_by_cols
  }

  # validate inputs
  missing_cols <- setdiff(aoi_cols, names(survey_data))
  if (length(missing_cols) > 0) {
    stop(sprintf("aoi_cols not found in survey_data: %s",
                 paste(missing_cols, collapse = ", ")))
  }
  for (arg in c("species_col", "abundance_col")) {
    col <- get(arg)
    if (!is.null(col) && !col %in% names(survey_data)) {
      stop(sprintf("%s '%s' not found in survey_data", arg, col))
    }
  }

  # drop records with no species name or an excluded one (e.g. dead material)
  species <- survey_data[[species_col]]
  records <- survey_data[!is.na(species) & !species %in% exclude, ]

  # abundance of each record: one hit per row, or the abundance column
  if (is.null(abundance_col)) {
    records$.abundance <- 1L
  } else {
    abundance <- records[[abundance_col]]
    if (!is.numeric(abundance)) {
      stop(sprintf("abundance_col '%s' must be numeric", abundance_col))
    }
    if (anyNA(abundance) || any(abundance < 0)) {
      stop(sprintf("abundance_col '%s' has missing or negative values", abundance_col))
    }
    records$.abundance <- abundance
    # zero abundance means the species is absent
    records <- records[records$.abundance > 0, ]
  }

  # build the unique grouping keys, dropping rows where any key col is "" or NA
  grouping_keys <- survey_data |>
    dplyr::select(dplyr::all_of(aoi_cols)) |>
    dplyr::distinct() |>
    dplyr::filter(dplyr::if_all(dplyr::everything(),
                                ~ !is.na(.) & . != ""))

  all_results <- list()
  community_matrices <- list()

  for (i in seq_len(nrow(grouping_keys))) {
    key <- grouping_keys[i, , drop = FALSE]

    # filter survey records to this group
    cleaned <- records |>
      dplyr::semi_join(key, by = aoi_cols)

    # community matrix: leading aoi_cols id columns + one column per species
    community_matrix <- cleaned |>
      dplyr::group_by(dplyr::across(dplyr::all_of(c(aoi_cols, species_col)))) |>
      dplyr::summarise(n = sum(.abundance), .groups = "drop") |>
      tidyr::pivot_wider(names_from = dplyr::all_of(species_col),
                         values_from = n, values_fill = 0)

    # key the community matrix by concatenating the group key values
    key_id <- paste(unlist(key), collapse = "_")
    community_matrices[[key_id]] <- community_matrix

    species_richness <- dplyr::n_distinct(cleaned[[species_col]])

    if (species_richness == 0) {
      next
    }

    # strip the id columns; the rest are species counts (numeric)
    counts <- community_matrix |>
      dplyr::select(-dplyr::all_of(aoi_cols))

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
    if ("site_unique" %in% aoi_cols) {
      plot_diversity$site_location_name <- substr(key$site_unique, 1, 10)
      plot_diversity <- plot_diversity |>
        dplyr::select(dplyr::all_of(aoi_cols),
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
