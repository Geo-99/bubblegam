#' Create bubble geodataframe according to a column
#'
#' `create_bubbles` allows the user to create a bubble geodataframe in an individually customizable and iterative way.
#' The size of the bubbles depends on a column in the input geodataframe.
#'
#' @param merged_gdf The geodataframe which contains the column on which the size of the bubbles should depend (sf data.frame)
#' @param col_name The name of the column on which the size of the bubbles should depend (character)
#' @param geom_name The name of the geometry column in merged_gdf (default: "geometry")
#' @param circle_share The initial share of the total area of all bubbles created to the original area of merged_gdf (default: 1)
#' @param change_parameter A relative parameter that determines the change in circle_share when resizing the bubbles (default: 0.05)
#'
#' @return The bubble geodataframe
#'
#' @importFrom dplyr filter mutate rename arrange
#' @importFrom sf st_sf st_buffer st_centroid
#' @importFrom ggplot2 ggplot geom_sf
#'
#'
#' @author Georg Starz
#'
#' @export



create_bubbles <- function(merged_gdf, col_name,
                           geom_name="geometry", circle_share = 1, change_parameter = 0.05){

  merged_gdf <- merged_gdf %>%
    rename(geometry=geom_name)

  # Delete all rows that have NA in the col_name column
  # create new area column
  start <- merged_gdf %>%
    filter(!is.na(merged_gdf[[col_name]])) %>%
    mutate(area = st_area(geometry))

  # create share column
  start <- start %>%
    mutate(share = start[[col_name]] / sum(start[[col_name]]))

  satisfied <- 0

  while (satisfied == 0){
    # calculate new area
    start <- start %>%
      mutate(new_area = round(share * circle_share * sum(start$area))) %>%
      mutate(radius = round(sqrt(new_area / pi)))

    # create end
    end <- st_sf(start, geometry = st_buffer(st_centroid(start$geometry, of_largest_polygon = TRUE), dist = start$radius))
    end_plot <- end %>%
      arrange(desc(new_area))

    # Plot end together with geodata
    print(merged_gdf %>%
            ggplot() +
            geom_sf() +
            geom_sf(data = end_plot, fill = "darkgrey"))

    # Ask user if he is satisfied with the circle sizes
    question1 <- readline(prompt = "Are you satisfied with the size of the circles? (y/n)")
    if (question1 == "y") {satisfied <- 1}
    else {

      question2 <- readline(prompt = "To increase the size of the circles, enter +, to decrease enter -\n(Multiple symbols possible -> e.g., +++ will increase the size by 3 steps)")
      if ("+" %in% strsplit(question2, "")[[1]]) {circle_share <- circle_share + (nchar(question2)*change_parameter)}
      else if ("-" %in% strsplit(question2, "")[[1]]) {circle_share <- circle_share - (nchar(question2)*change_parameter)}
      else {
        print("Please enter + or -")
        circle_share <- circle_share
      }
    }
  }

  return(end_plot)
}
