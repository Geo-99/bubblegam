#' Create transition between two geodataframes with different geometries
#'
#' `create_transition` creates the transition (using tween_sf) for a subsequent animation between two geodataframes with different geometries, but partly the same IDs.
#'
#' @param gdf The initial geodataframe (sf data.frame)
#' @param bubble_gdf The (bubble) geodataframe which should be displayed at the end of the animation
#' @param color_col The name of the column in gdf and bubble_gdf that is used for coloring in the subsequent animation (character)
#' (column must have the same name in both geodataframes!)
#' @param bubble_col The name of the column in bubble_gdf that was used to create the new (bubble) geometries (character)
#' @param id_col The name of the ID column in gdf and bubble_gdf (column must have the same name in both geodataframes!) (default: "id")
#' @param frame_number The number of frames in the transition (default: 40)
#' @param gdf_geom_name The name of the geometry column in gdf (default: "geometry")
#' @param bubble_geom_name The name of the geometry column in bubble_gdf (default: "geometry")
#'
#' @return A data.frame containing intermediary states of the transition
#'
#' @importFrom dplyr filter mutate rename arrange
#' @importFrom sf st_sf st_buffer st_centroid
#' @importFrom ggplot2 ggplot geom_sf
#'
#'
#' @author Georg Starz
#'
#' @export



create_transition <- function(gdf, bubble_gdf, color_col, bubble_col,
                              id_col = "id", frame_number=40,
                              gdf_geom_name = "geometry", bubble_geom_name = "geometry"){

  gdf_0 <- gdf %>%
    rename(id = id_col) %>%
    rename(geometry = gdf_geom_name)
  bubble_gdf <- bubble_gdf %>%
    rename(id = id_col) %>%
    rename(geometry = bubble_geom_name)

  # Delete all rows that have Na in the bubble_col column
  gdf_1 <- gdf_0 %>%
    filter(!is.na(gdf_0[[bubble_col]]))

  # Rename color_col to v_plot1
  gdf_1 <- gdf_1 %>%
    rename(v_plot1 = color_col)
  bubble_gdf <- bubble_gdf %>%
    rename(v_plot1 = color_col)

  # Bring in same order
  gdf_1 <- gdf_1[match(bubble_gdf$id, gdf_1$id),]

  # Only keep the largest polygon for each feature in gdf_1 -> Very important!! Otherwise tween_sf takes forever!
  gdf_cast <- st_cast(gdf_1)
  gdf_cast <- st_cast(gdf_cast, "POLYGON")
  gdf_cast <- gdf_cast %>%
    mutate(area = st_area(geometry))
  gdf_cast <- gdf_cast %>%
    group_by(id) %>%
    filter(area == max(area)) %>%
    ungroup()

  # Select columns
  gdf_1 <- gdf_1 %>%
    select(id, v_plot1, geometry)
  gdf_cast <- gdf_cast %>%
    select(id, v_plot1, geometry)
  bubble_gdf <- bubble_gdf %>%
    select(id, v_plot1, geometry)

  # Tween
  td <- tween_sf(gdf_cast, bubble_gdf, ease = "cubic-in-out", nframes = frame_number, id = id)

  # Create .frame col in gdf_2 and put 0 in it
  gdf_2 <- gdf %>%
    rename(id = id_col, v_plot1 = color_col, geometry = gdf_geom_name) %>%
    select(id, v_plot1, geometry)
  gdf_2$.frame <- 0
  td <- bind_rows(gdf_2, td)

  return(td)
}
