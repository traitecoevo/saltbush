#' Synthetic point-intercept survey data
#'
#' A small, hand-crafted data frame that mimics the shape of the `veg.PI`
#' table returned by [ausplotsR::get_ausplots()]. Two sites, each with two
#' subplots and a handful of species hits. Used in examples, tests, and the
#' package vignette so they can run without an internet connection.
#'
#' @format A data frame with 12 rows and 4 columns:
#' \describe{
#'   \item{site_unique}{Character. Unique site/visit identifier.}
#'   \item{site_location_name}{Character. Site identifier (the prefix of
#'     `site_unique`).}
#'   \item{subplot_id}{Character. Subplot identifier within the site.}
#'   \item{standardised_name}{Character. Species name for the point hit.}
#' }
#' @source Hand-crafted for package examples. See
#'   `data-raw/synthetic_survey.R`.
"synthetic_survey"


#' Cached AusPlots point-intercept data for site NSABHC0009
#'
#' A cached subset of the point-intercept (`veg.PI`) table for AusPlots site
#' `NSABHC0009` at Fowlers Gap, NSW. Saved as a package dataset so the
#' worked example and tests do not require live access to the AusPlots
#' database.
#'
#' Only the columns used by saltbush plus a few useful identifiers are
#' retained — taxonomy columns and free-text fields are dropped to keep the
#' file small.
#'
#' @format A data frame with one row per point-intercept hit:
#' \describe{
#'   \item{site_unique}{Character. Unique site/visit identifier.}
#'   \item{site_location_name}{Character. Site identifier.}
#'   \item{site_location_visit_id}{Integer. AusPlots visit identifier.}
#'   \item{transect}{Character. Transect identifier within the visit.}
#'   \item{point_number}{Integer. Point number along the transect.}
#'   \item{standardised_name}{Character. Standardised species name.}
#' }
#' @source Cached from [ausplotsR::get_ausplots()] with
#'   `my.Plot_IDs = "NSABHC0009"`. See `data-raw/ausplots_NSABHC0009.R`.
"ausplots_NSABHC0009"
