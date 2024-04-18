#' Restructure geodataframe after outlier_identify / outlier_moving
#'
#' `outlier_restructure` includes parts of features (name suffix "_part") that were previously
#' defined / moved as spatial outliers in outlier_identify / outlier_moving back into the respective feature
#'
#' @param geodata The geodataframe (sf data.frame)
#'
#' @return The restructured geodataframe
#'
#' @importFrom dplyr filter group_by summarize
#' @importFrom sf st_union
#' @importFrom ggplot2 ggplot geom_sf
#'
#' @author Georg Starz
#'
#' @export



outlier_restructure <- function(geodata) {

  part_rows <- geodata %>%
    filter(grepl("_part", id))
  part_rows_comb <- part_rows %>%
    group_by(id) %>%
    summarize(
      geometry = st_union(geometry)
    )

  result <- geodata %>%
    filter(!grepl("_part", id))

  for (i in 1:nrow(result)) {
    current_id <- result$id[i]
    part_id <- paste0(current_id, "_part")

    if (part_id %in% part_rows_comb$id) {
      geom_part <- part_rows_comb$geometry[part_rows_comb$id == part_id]
      result$geometry[i] <- st_union(result$geometry[i], geom_part)
    }
  }


  return(result)
}
