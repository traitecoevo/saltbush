#' @title Calculate field diversity
#' @description Takes ausplot survey data, calculates field diversity for each site
#' @param survey_data a df obtained from ausplotsR package with survey data for appropriate sites
#' @return a list, containing 'field diversity' - values of species richness, shannon's index, simpsons index, exponential shannon's, inverse simpson, pielou's evenness, and 'community matrices'
#' @examples
#' twentyfour_field_diversity <- calculate_field_diversity(twentyfour_field_survey_data)
#' @export
#' @import dplyr

calculate_field_diversity <- function(survey_data){
  # get unique site names
  ausplot_sites <- unique(survey_data$site_location_name)
  ausplot_sites <- ausplot_sites[ausplot_sites != ""]

  # list to store results for all lists
  all_site_results <- list()

  # list to store community matrices - useful to check that community matrices are correct :)
  community_matrices <- list()

  # loop thru each unique site
  for (site in ausplot_sites) {
    # Filter data for the current site
    site_survey_data <- survey_data %>%
      filter(site_location_name == site)

    # extract only direction of the transect (no numbers)
    site_survey_data$transect_direction <- gsub('[[:digit:]]+', '', site_survey_data$transect)

    # extract only number of the transect (no direction)
    site_survey_data$transect_number <- as.numeric(gsub(".*?([0-9]+).*", "\\1", site_survey_data$transect))

    # create variable for fixed transect direction (to order them all transects in the same direction)
    site_survey_data$transect_direction2 <- NA

    # create variable for fixed point number (inverse in some cases as if they had been collected in the same direction)
    site_survey_data$point_number2 <- NA

    # create XY empty variables for plot XY coordinates
    site_survey_data$X_plot <- NA
    site_survey_data$Y_plot <- NA

    site_survey_data <- site_survey_data %>%
      mutate(
        point_number2 = case_when(
          transect_direction == "E-W" ~ 100 - point_number,
          transect_direction == "N-S" ~ 100 - point_number,
          TRUE ~ point_number
        ),
        transect_direction2 = case_when(
          transect_direction %in% c("W-E", "E-W") ~ "W-E",
          transect_direction %in% c("N-S", "S-N") ~ "S-N"
        )
      )

    # assign plotXY coordinates based on 'transect_direction2' and 'transect_number'
    site_survey_data <- site_survey_data %>%
      mutate(
        X_plot = case_when(
          transect_direction2 == "W-E" ~ point_number2,
          transect_direction2 == "S-N" & transect_number == 1 ~ 10,
          transect_direction2 == "S-N" & transect_number == 2 ~ 30,
          transect_direction2 == "S-N" & transect_number == 3 ~ 50,
          transect_direction2 == "S-N" & transect_number == 4 ~ 70,
          transect_direction2 == "S-N" & transect_number == 5 ~ 90
        ),
        Y_plot = case_when(
          transect_direction2 == "S-N" ~ point_number2,
          transect_direction2 == "W-E" & transect_number == 1 ~ 10,
          transect_direction2 == "W-E" & transect_number == 2 ~ 30,
          transect_direction2 == "W-E" & transect_number == 3 ~ 50,
          transect_direction2 == "W-E" & transect_number == 4 ~ 70,
          transect_direction2 == "W-E" & transect_number == 5 ~ 90
        )
      )

    # subplot rows and columns - +1 ensures 0 point values fall into correct subplot,
    # pmin ensures 100 point values falls in correct subplot given +1
    #site_survey_data$subplot_row <- pmin(ceiling((site_survey_data$Y_plot + 1) / 20), 5)
    #site_survey_data$subplot_col <- pmin(ceiling((site_survey_data$X_plot + 1) / 20), 5)

    # single ID for subplot row and column
    #site_survey_data$subplot_id <- paste(site_survey_data$subplot_row, site_survey_data$subplot_col, sep = "_")

    subplot_diversity <- site_survey_data %>%
      drop_na(standardised_name) %>%
      filter(!standardised_name %in% c('Dead grass', 'Dead shrub')) %>%
      #group_by(subplot_id) %>%
      summarise(species_richness = n_distinct(standardised_name))

    community_matrix <- site_survey_data %>%
      drop_na(standardised_name) %>%
      filter(!standardised_name %in% c('Dead grass', 'Dead shrub')) %>%
      #count(subplot_id, standardised_name) %>%
      count(standardised_name) %>%
      spread(standardised_name, n, fill = 0)

    # store the community matrix  in the list
    community_matrices[[site]] <- community_matrix

    # calculate diversity indices
    shannon_diversity <- diversity(community_matrix[, -1], index = "shannon")
    simpson_diversity <- diversity(community_matrix[, -1], index = "simpson")
    inv_simpson <- diversity(community_matrix[, -1], index = 'invsimpson')

    subplot_diversity <- subplot_diversity %>%
      mutate(shannon_diversity = shannon_diversity,
             simpson_diversity = simpson_diversity,
             pielou_evenness = shannon_diversity / log(species_richness),
             exp_shannon = exp(shannon_diversity),
             inv_simpson = inv_simpson,
             site = site)

    # store  result for  current site
    all_site_results[[site]] <- subplot_diversity
  }

  # combine into one df
  field_diversity <- bind_rows(all_site_results, .id = "site")

  return(list(
    field_diversity = field_diversity,
    community_matrices = community_matrices
  ))
}
