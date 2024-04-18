#' Move previously defined spatial outliers in  vector geodata
#'
#' `outlier_moving` allows the user to move all features assigned with True in the
#' "outlier" column in an individually customizable and iterative way
#'
#' @param geodata The geodataframe (sf data.frame)
#' @param move_parameter A relative parameter that determines the step size of the outlier shifts.
#' It refers to the ratio of the size of the bounding boxes of the non-outlier part and the respective outlier.
#' If it is increased, the steps for shifting become larger; if it is decreased, they become smaller (default: 0.025)
#'
#' @return The geodataframe with the modified geometries for the spatial outliers
#'
#' @importFrom dplyr select filter mutate
#' @importFrom sf st_sf st_sfc st_cast st_centroid st_bbox st_as_sfc st_point st_crs st_distance st_as_sf st_coordinates st_geometry st_set_crs
#' @importFrom ggplot2 ggplot geom_sf
#' @importFrom lwgeom st_linesubstring st_endpoint
#'
#'
#' @author Georg Starz
#'
#' @export



outlier_moving <- function(geodata, move_parameter = 0.025){

  # PART 1: Non-Outliers----

  # Extract all non-outliers
  gd_non_outliers <- geodata %>%
    filter(outlier == FALSE)
  non_outliers_bbox_centroid <- st_centroid(st_sf(st_as_sfc(st_bbox(gd_non_outliers)) %>% st_cast("POLYGON")))
  st_crs(non_outliers_bbox_centroid) <- st_crs(geodata)
  non_outliers_NW <- st_sfc(st_point(c((st_bbox(gd_non_outliers))[1], (st_bbox(gd_non_outliers))[4])))
  st_crs(non_outliers_NW) <- st_crs(geodata)
  non_outliers_NE <- st_sfc(st_point(c((st_bbox(gd_non_outliers))[3], (st_bbox(gd_non_outliers))[4])))
  st_crs(non_outliers_NE) <- st_crs(geodata)
  non_outliers_SE <- st_sfc(st_point(c((st_bbox(gd_non_outliers))[3], (st_bbox(gd_non_outliers))[2])))
  st_crs(non_outliers_SE) <- st_crs(geodata)
  non_outliers_SW <- st_sfc(st_point(c((st_bbox(gd_non_outliers))[1], (st_bbox(gd_non_outliers))[2])))
  st_crs(non_outliers_SW) <- st_crs(geodata)

  # Calculate the distance from the centroid of the non-outliers to the 4 points in a list
  non_outliers_distances <- list()
  non_outliers_distances$NW <- st_distance(non_outliers_bbox_centroid, non_outliers_NW)
  non_outliers_distances$NE <- st_distance(non_outliers_bbox_centroid, non_outliers_NE)
  non_outliers_distances$SE <- st_distance(non_outliers_bbox_centroid, non_outliers_SE)
  non_outliers_distances$SW <- st_distance(non_outliers_bbox_centroid, non_outliers_SW)
  # Extract the highest distance from the list
  radius_non_outliers <- max(unlist(non_outliers_distances))


  # PART 2: Outliers----

  # Extract all outliers
  gd_outliers <- geodata %>%
    filter(outlier == TRUE)

  # Add a distance_outlier col to the gd_outliers
  gd_outliers$radius_outlier <- NA
  gd_outliers$radius_non_o_plus_o <- NA
  gd_outliers$distance_centroids <- NA
  gd_outliers$NE <- NA
  gd_outliers$NW <- NA
  gd_outliers$Alaska_problem <- NA


  # Create an empty sf data frame called gd_shifted
  gd_shifted <- data.frame(matrix(nrow = 0, ncol = length(names(gd_outliers))))
  colnames(gd_shifted) = names(gd_outliers)
  gd_shifted <- st_as_sf(gd_shifted, crs = st_crs(geodata), wkt = "geometry")


  # Do the same as for the non-outliers but for every single outlier in a loop and add the distance as a col to the gd_outliers
  for (i in 1:nrow(gd_outliers)) {
    outlier_NW <- st_sfc(st_point(c((st_bbox(gd_outliers[i,]))[1], (st_bbox(gd_outliers[i,]))[4])))
    st_crs(outlier_NW) <- st_crs(geodata)
    outlier_NE <- st_sfc(st_point(c((st_bbox(gd_outliers[i,]))[3], (st_bbox(gd_outliers[i,]))[4])))
    st_crs(outlier_NE) <- st_crs(geodata)

    gd_outliers$NE[i] = st_coordinates(outlier_NE)[, "X"]
    gd_outliers$NW[i] = st_coordinates(outlier_NW)[, "X"]
  }



  # PART 3: Alaska Problem----
  # "Alaska" problem because of negative and positive longitudes
  # If outliers_NE x coordinate is greater than 175 and smaller than 185, and outliers_NW x coordinate is smaller than -175 and greater than -185, perform st_cast on this outlier
  for (i in 1:nrow(gd_outliers)) {
    if ((gd_outliers$NE[i] > 175 & gd_outliers$NE[i] < 185) & (gd_outliers$NW[i] < -175 & gd_outliers$NW[i] > -185)) {
      gd_outliers$Alaska_problem[i] <- TRUE}
    else {
      gd_outliers$Alaska_problem[i] <- FALSE}
  }
  # Print out the outliers with the Alaska problem in a statement, but only if there are True values in the Alaska_problem col
  count_true <- sum(gd_outliers$Alaska_problem == TRUE)
  if (count_true > 0) {
    print(cat("In the following outliers some subfeatures get removed because they are across the 180th meridian. If they're not removed, this would cause problems in the visualization:\n", gd_outliers$id[gd_outliers$Alaska_problem == TRUE], "\n"))
  }
  for (i in 1:nrow(gd_outliers)) {
    if (gd_outliers$Alaska_problem[i] == TRUE) {
      # Remove this outlier from the gd_outliers and store it as a new object
      gd_change <- gd_outliers[i,]
      gd_outliers_new <- gd_outliers[-i,]
      outlier_cast <- gd_change %>%
        st_cast("POLYGON")
      outlier_centroids <- st_centroid(outlier_cast)
      outlier_centroids_x <- st_coordinates(outlier_centroids)[, "X"]
      outlier_centroids_x_positive <- outlier_centroids_x[outlier_centroids_x > 0]
      outlier_centroids_x_negative <- outlier_centroids_x[outlier_centroids_x < 0]
      outlier_cast$xmin <- NA
      outlier_cast$xmax <- NA
      for (i in 1:nrow(outlier_cast)) {
        bbox <- st_bbox(outlier_cast[i,])
        outlier_cast[i,]$xmin <- bbox[1]
        outlier_cast[i,]$xmax <- bbox[3]
      }
      if (length(outlier_centroids_x_positive) > length(outlier_centroids_x_negative)) {
        outlier_cast <- outlier_cast %>%
          filter(xmin > 0 & xmax > 0)
      } else {
        outlier_cast <- outlier_cast %>%
          filter(xmin < 0 & xmax < 0)
      }
      # Replace geom in the current gd_outliers[i,] with the geometry derived from st_union of the outlier_cast
      gd_change <- gd_change %>%
        mutate(geometry = st_geometry(st_union(outlier_cast)))
    }}

  # Add gd_change to the gd_outliers_new, but only if gd_outliers_new exists
  if (exists("gd_outliers_new")) {
    gd_outliers <- rbind(gd_outliers_new, gd_change)
  }


  # PART 4: Moving the outliers----
  # For-loop for moving the outliers
  for (i in 1:nrow(gd_outliers)) {
    # Centroid and bbox point calculations
    outlier_bbox_centroid <- st_centroid(st_sf(st_as_sfc(st_bbox(gd_outliers[i,])) %>% st_cast("POLYGON")))
    st_crs(outlier_bbox_centroid) <- st_crs(geodata)
    outlier_NW <- st_sfc(st_point(c((st_bbox(gd_outliers[i,]))[1], (st_bbox(gd_outliers[i,]))[4])))
    st_crs(outlier_NW) <- st_crs(geodata)
    outlier_NE <- st_sfc(st_point(c((st_bbox(gd_outliers[i,]))[3], (st_bbox(gd_outliers[i,]))[4])))
    st_crs(outlier_NE) <- st_crs(geodata)
    outlier_SE <- st_sfc(st_point(c((st_bbox(gd_outliers[i,]))[3], (st_bbox(gd_outliers[i,]))[2])))
    st_crs(outlier_SE) <- st_crs(geodata)
    outlier_SW <- st_sfc(st_point(c((st_bbox(gd_outliers[i,]))[1], (st_bbox(gd_outliers[i,]))[2])))
    st_crs(outlier_SW) <- st_crs(geodata)

    # Calculate the distance from the centroid of the outlier to the 4 points in a list
    outlier_distances <- list()
    outlier_distances$NW <- st_distance(outlier_bbox_centroid, outlier_NW)
    outlier_distances$NE <- st_distance(outlier_bbox_centroid, outlier_NE)
    outlier_distances$SE <- st_distance(outlier_bbox_centroid, outlier_SE)
    outlier_distances$SW <- st_distance(outlier_bbox_centroid, outlier_SW)
    # Extract the highest distance from the list and add it to the distance_outlier col
    gd_outliers[i,]$radius_outlier <- max(unlist(outlier_distances))
    # Calculate distance from non_outliers_bbox_centroid to outlier_bbox_centroid and store it in the distance_centroids col
    gd_outliers[i,]$distance_centroids <- as.numeric(st_distance(non_outliers_bbox_centroid, outlier_bbox_centroid))

    # Add radius_non_outliers and radius_outlier and store it in the radius_non_o_plus_o col
    gd_outliers[i,]$radius_non_o_plus_o <- radius_non_outliers + gd_outliers[i,]$radius_outlier

    # Create a LINESTRING from the two points non_outliers_bbox_centroid and outlier_bbox_centroid
    point1 <- st_sf(geometry = st_as_sf(non_outliers_bbox_centroid))
    point2 <- st_sf(geometry = st_as_sf(outlier_bbox_centroid))
    line <- st_cast(st_union(point1, point2), "LINESTRING")

    # Moving the outlier iteratively
    ratio_0 <- as.numeric(gd_outliers[i,]$radius_non_o_plus_o) / as.numeric(gd_outliers[i,]$distance_centroids)
    if (ratio_0 > 1) {ratio_1 <- 1} else {ratio_1 <- ratio_0}

    if (st_coordinates(point1)[, "X"] != st_coordinates(line)[1,1]) {
      ratio_2 <- abs(ratio_1 - 1)
    } else {
      ratio_2 <- ratio_1
    }

    # "Guam problem"
    if (st_coordinates(point1)[, "X"] < 0 & (st_coordinates(point1)[, "X"] > -180 & (st_coordinates(point2)[, "X"] > 0 & st_coordinates(point2)[, "X"] < 180))) {
      ratio_3 <- abs(ratio_1 - 1)
    } else {
      ratio_3 <- ratio_2
    }


    ratio <- ratio_3

    satisfied <- 0

    while (satisfied == 0) {
      if (ratio_3 == ratio_1) {
        new_point <- st_linesubstring(line, from = 0, to = ratio) %>%
          st_endpoint()

        offset <- st_geometry(new_point) - st_geometry(outlier_bbox_centroid)
        shifted <- gd_outliers[i,]
        st_geometry(shifted) <- st_geometry(shifted) + offset
        shifted <- st_set_crs(shifted, st_crs(geodata))

        # Plot
        print(gd_outliers[i,] %>% ggplot() +
                geom_sf() +
                geom_sf(data = gd_non_outliers, color = "blue") +
                geom_sf(data = shifted, color = "purple") +
                geom_sf(data = non_outliers_bbox_centroid, color = "black") +
                geom_sf(data = outlier_bbox_centroid, color = "red") +
                geom_sf(data = line, color = "red") +
                geom_sf(data = new_point, color = "blue")+
                geom_sf(data = gd_shifted, color = "darkgrey")
        )

        # Ask user if he is satisfied with the new position
        question1 <- readline(prompt = "Are you satisfied with the new position? (y/n)")
        if (question1 == "y") {satisfied <- 1}
        else {

          question2 <- readline(prompt = "To move the outlier closer press +, to move it further away press -\n(Multiple symbols possible -> e.g., +++ will move the outlier closer by 3 steps)")
          if ("+" %in% strsplit(question2, "")[[1]]){ratio <- ratio - (nchar(question2) * move_parameter)}
          else if ("-" %in% strsplit(question2, "")[[1]]){ratio <- ratio + (nchar(question2) * move_parameter)}
          else {
            print("Please enter + or -")
            ratio <- ratio
          }
        }
      }
      else {
        new_point <- st_linesubstring(line, from = 0, to = ratio) %>%
          st_endpoint()

        offset <- st_geometry(new_point) - st_geometry(outlier_bbox_centroid)
        shifted <- gd_outliers[i,]
        st_geometry(shifted) <- st_geometry(shifted) + offset
        shifted <- st_set_crs(shifted, st_crs(geodata))

        # Plot
        print(gd_outliers[i,] %>% ggplot() +
                geom_sf() +
                geom_sf(data = gd_non_outliers, color = "blue") +
                geom_sf(data = shifted, color = "purple") +
                geom_sf(data = non_outliers_bbox_centroid, color = "black") +
                geom_sf(data = outlier_bbox_centroid, color = "red") +
                geom_sf(data = line, color = "red") +
                geom_sf(data = new_point, color = "blue") +
                geom_sf(data = gd_shifted, color = "darkgrey")
        )

        # Ask user if he is satisfied with the new position
        question1 <- readline(prompt = "Are you satisfied with the new position? (y/n)")
        if (question1 == "y") {satisfied <- 1}
        else {

          question2 <- readline(prompt = "To move the outlier closer press +, to move it further away press -\n(Multiple symbols possible -> e.g., +++ will move the outlier closer by 3 steps)")

          if ("+" %in% strsplit(question2, "")[[1]]){ratio <- ratio + (nchar(question2) * move_parameter)}
          else if ("-" %in% strsplit(question2, "")[[1]]){ratio <- ratio - (nchar(question2) * move_parameter)}
          else {
            print("Please enter + or -")
            ratio <- ratio
          }
        }
      }
    }

    # Add shifted to gd_shifted
    gd_shifted <- rbind(gd_shifted, shifted)

  }

  # PART 5: End----
  # Fuse gd_shifted and gd_non_outliers
  gd_shifted <- gd_shifted %>% select(names(gd_non_outliers))
  gd_combined_moved <- rbind(gd_non_outliers, gd_shifted)




  return(gd_combined_moved)


}
