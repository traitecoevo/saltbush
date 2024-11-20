#' @title Calculate field diversity
#' @description Takes ausplot survey data, calculates field diversity for each site
#' @param survey_data a df obtained from ausplotsR package with survey data for appropriate sites
#' @return a list, containing 'field diversity' - values of species richness, shannon's index, simpsons index, exponential shannon's, inverse simpson, pielou's evenness, and 'community matrices'
#' @export
#' @examples
#' ausplot.pi.data <- ausplotsR::get_ausplots(my.Plot_IDs=
#'     c("SATFLB0004", "QDAMGD0022", "NTASTU0002"), veg.PI=TRUE)$veg.PI
#' field_diversity <- calculate_field_diversity(ausplot.pi.data)
#'

calculate_field_diversity <- function(survey_data){
  # get unique site names
  ausplot_surveys <- unique(survey_data$site_unique)
  ausplot_surveys <- ausplot_surveys[ausplot_surveys != ""]

  # list to store results for all lists
  all_site_results <- list()

  # list to store community matrices - useful to check that community matrices are correct :)
  community_matrices <- list()

  # loop thru each unique site
  for (survey in ausplot_surveys) {
    # filter data for the current site
    site_survey_data <- survey_data |>
      dplyr::filter(site_unique == survey)

    subplot_diversity <- site_survey_data |>
      tidyr::drop_na(standardised_name) |>
      dplyr::filter(!standardised_name %in% c('Dead grass', 'Dead shrub')) |>
      #group_by(subplot_id) |>
      dplyr::summarise(species_richness = dplyr::n_distinct(standardised_name))

    community_matrix <- site_survey_data |>
      tidyr::drop_na(standardised_name) |>
      dplyr::filter(!standardised_name %in% c('Dead grass', 'Dead shrub')) |>
      #count(subplot_id, standardised_name) |>
      dplyr::count(standardised_name) |>
      tidyr::spread(standardised_name, n, fill = 0)

    # store the community matrix  in the list
    community_matrices[[survey]] <- community_matrix

    # calculate diversity indices
    shannon_diversity <- vegan::diversity(community_matrix[, -1], index = "shannon")
    simpson_diversity <- vegan::diversity(community_matrix[, -1], index = "simpson")
    inv_simpson <- vegan::diversity(community_matrix[, -1], index = 'invsimpson')

    subplot_diversity <- subplot_diversity |>
      dplyr::mutate(site_location_name = substr(survey, 1, 10),
             shannon_diversity = shannon_diversity,
             simpson_diversity = simpson_diversity,
             pielou_evenness = shannon_diversity / log(species_richness),
             exp_shannon = exp(shannon_diversity),
             inv_simpson = inv_simpson)

    # order columns
    subplot_diversity <- subplot_diversity |>
      dplyr::select(site_location_name, everything())


    # store  result for  current site
    all_site_results[[survey]] <- subplot_diversity
  }

  # combine into one df
  field_diversity <- dplyr::bind_rows(all_site_results, .id = "site_unique")

  return(list(
    field_diversity = field_diversity,
    community_matrices = community_matrices
  ))
}
