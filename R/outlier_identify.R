#' Identify/delete spatial outliers in  vector geodata
#'
#' `outlier_identify` looks for spatial outlier features & subfeatures in vector geodata
#' and enables deleting these features/subfeatures or defining them as an outlier
#' in a newly created column (e.g., for Spain, the Canary Islands).
#'
#' @param geodata The geodataframe (sf data.frame)
#' @param id_col The name of the ID column (character) (default: "id")
#' @param search_parameter A relative parameter that defines the minimum distance
#' from the bounding box of the largest single part of geodata from which spatial
#' outliers are searched for by multiplying the square root of the bounding box area
#' with the parameter. If the parameter is increased, outliers are only searched for
#' further away, if it is decreased, closer (default: 0.2)
#' @param geom_name The name of the geometry column in geodata (default: "geometry")
#' @param extra_cols The columns that should be kept in the output gdf (character vector)
#' (default: all columns that were also in geodata)
#'
#' @return The geodataframe without the deleted / with the defined (newly created "outlier" column) spatial outliers
#'
#' @importFrom dplyr rename select setdiff filter mutate left_join
#' @importFrom sf st_union st_sf st_sfc st_cast st_area st_centroid st_bbox st_as_sfc st_point st_crs st_intersects st_distance
#' @importFrom ggplot2 ggplot geom_sf
#'
#' @author Georg Starz
#'
#' @export



outlier_identify <- function(geodata, id_col="id", search_parameter=0.2,
                             geom_name="geometry",
                             extra_cols=names(geodata)[!names(geodata) %in% c(id_col, "geometry")])
  {

  # PART 1: Pre-Processing----
  geodata <- geodata %>%
    rename(id = id_col, geometry = geom_name)

  # Union polygons
  union_pol <- st_union(geodata)

  # Largest part in union & its centroid & its bounding box
  union_pol_cast <- st_sf(st_cast(union_pol, "POLYGON"))
  union_pol_cast <- union_pol_cast %>%
    mutate(area = st_area(union_pol_cast))
  largest_part <- union_pol_cast[which.max(st_area(union_pol_cast)),]
  centroid <- st_centroid(largest_part)
  bbox_polygon <- st_sf(st_as_sfc(st_bbox(largest_part)) %>% st_cast("POLYGON"))
  st_crs(bbox_polygon) <- st_crs(geodata)

  # Define distance of outlier search by PARAMETER & area of largest part
  bbox_polygon <- bbox_polygon %>%
    mutate(area = st_area(bbox_polygon)) %>%
    mutate(sqrt_area = sqrt(area)) %>%
    mutate(distance = sqrt_area * search_parameter)

  # Bounding box points
  bbox_NW <- st_sfc(st_point(c((st_bbox(largest_part))[1], (st_bbox(largest_part))[4])))
  st_crs(bbox_NW) <- st_crs(geodata)
  bbox_NE <- st_sfc(st_point(c((st_bbox(largest_part))[3], (st_bbox(largest_part))[4])))
  st_crs(bbox_NE) <- st_crs(geodata)
  bbox_SE <- st_sfc(st_point(c((st_bbox(largest_part))[3], (st_bbox(largest_part))[2])))
  st_crs(bbox_SE) <- st_crs(geodata)
  bbox_SW <- st_sfc(st_point(c((st_bbox(largest_part))[1], (st_bbox(largest_part))[2])))
  st_crs(bbox_SW) <- st_crs(geodata)

  # Identify outlier polygons
  gd_filter <- geodata %>%
    filter(!st_intersects(geometry, bbox_polygon, sparse = FALSE))

  # Identify outlier polygon parts
  gd_filter_cast <- st_cast(geodata, "POLYGON") %>%
    filter(!st_intersects(geometry, bbox_polygon, sparse = FALSE))
  gd_filter_cast <- gd_filter_cast %>%
    filter(!st_intersects(geometry, st_union(gd_filter), sparse = FALSE))
  # Add "_part" suffix to the id col
  gd_filter_cast <- gd_filter_cast %>%
    mutate(id = paste0(id, "_part"))

  # Combine gd_filter and gd_filter_cast
  gd_filter_combined <- rbind(gd_filter, gd_filter_cast)

  # Calculate the distance to all bbox points and the lowest distance within these 4 and append them as a col to gd_filter
  gd_filter_combined <- gd_filter_combined %>%
    mutate(distance_NW = st_distance(st_centroid(gd_filter_combined), bbox_NW)) %>%
    mutate(distance_NE = st_distance(st_centroid(gd_filter_combined), bbox_NE)) %>%
    mutate(distance_SE = st_distance(st_centroid(gd_filter_combined), bbox_SE)) %>%
    mutate(distance_SW = st_distance(st_centroid(gd_filter_combined), bbox_SW)) %>%
    mutate(distance_bbox = st_distance(st_centroid(gd_filter_combined), bbox_polygon)) %>%
    mutate(lowest_distance = pmin(distance_NW, distance_NE, distance_SE, distance_SW, distance_bbox))

  # Filter out all polygons from gd_filter_combined that have a lower distance than bbox_polygon$distance
  gd_filter_combined <- gd_filter_combined %>%
    filter(lowest_distance > bbox_polygon$distance)
  # Add empty delete col
  gd_filter_combined <- gd_filter_combined %>%
    mutate(delete = NA)
  # Add empty outlier col
  gd_filter_combined <- gd_filter_combined %>%
    mutate(outlier = NA)

  # Create a dataframe and a BBox for all non-outliers
  gd_main_cast <- st_cast(geodata, "POLYGON") %>%
    filter(!st_intersects(geometry, st_union(gd_filter_combined), sparse = FALSE))
  gd_main <- gd_main_cast %>%
    group_by(id) %>%
    summarize(geometry = st_union(geometry)) %>%
    mutate(outlier = FALSE)
  if (!is.na(extra_cols)[1]) {
    join_cols <- as.data.frame(geodata) %>% select(id, extra_cols)
    gd_main <- gd_main %>%
      left_join(join_cols, by = "id")}
  gd_main_bbox <- st_sf(st_as_sfc(st_bbox(gd_main)) %>% st_cast("POLYGON"))

  # PART 2: Loop----
  # For loop over all possible outliers that asks user if it should be defined as an outlier
  for (i in 1:nrow(gd_filter_combined)) {
    # Print the number of features in gd_filter_combined
    print(paste0("Possible outliers: Feature ", i, " of ", nrow(gd_filter_combined)))
    # Plot the current feature
    print(gd_filter_combined[i,] %>%
            ggplot() +
            geom_sf(color = "red") +
            geom_sf(data = st_centroid(gd_filter_combined[i,]), color = "red") +
            geom_sf(data = gd_main_bbox, color = "green") +
            geom_sf(data = gd_main, color = "black") +
            geom_sf(data = bbox_polygon, color = "blue") +
            geom_sf(data = largest_part, color = "black") +
            geom_sf(data = bbox_NW, color = "green") +
            geom_sf(data = bbox_NE, color = "orange") +
            geom_sf(data = bbox_SE, color = "yellow") +
            geom_sf(data = bbox_SW, color = "purple") +
            ggtitle(paste0("id: ", gd_filter_combined[i,]$id, "\n",
                           "distance_NW: ", gd_filter_combined[i,]$distance_NW, "\n",
                           "distance_NE: ", gd_filter_combined[i,]$distance_NE, "\n",
                           "distance_SE: ", gd_filter_combined[i,]$distance_SE, "\n",
                           "distance_SW: ", gd_filter_combined[i,]$distance_SW, "\n",
                           "distance_bbox: ", gd_filter_combined[i,]$distance_bbox, "\n",
                           "lowest_distance: ", gd_filter_combined[i,]$lowest_distance, "\n", "\n",
                           "Distance threshold: ", bbox_polygon$distance))
    )
    # Ask the user if the current feature should be deleted
    delete <- readline(prompt = paste0("Should this feature (", gd_filter_combined[i, "id"], ", see plot) be deleted from the geodata set? (y/n): "))
    if (delete == "y") {
      gd_filter_combined[i,]$delete <- TRUE
    } else {
      gd_filter_combined[i,]$delete <- FALSE
      # Ask the user if the current feature should be defined as an outlier, if y put TRUE in the outlier col, if n put FALSE in the outlier col
      outlier <- readline(prompt = paste0("Should this feature (", gd_filter_combined[i, "id"], ", see plot) be defined as an outlier? (y/n): "))
      if (outlier == "y") {
        gd_filter_combined[i,]$outlier <- TRUE
      } else {
        gd_filter_combined[i,]$outlier <- FALSE
      }
    }


  }

  # PART 3: End----
  # Deltete all features that have delete = TRUE
  gd_filter_combined <- gd_filter_combined %>%
    filter(delete == FALSE)

  # Combine gd_main and gd_filter_combined
  if (!is.na(extra_cols)[1]) {
    gd_filter_combined <- gd_filter_combined %>% select(id, geometry, outlier, extra_cols)
  } else {
    gd_filter_combined <- gd_filter_combined %>% select(id, geometry, outlier)
  }
  gd_combined <- rbind(gd_main, gd_filter_combined)


  return(gd_combined)

}
