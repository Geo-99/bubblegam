#' Function to plot discrete data
#'
#' `plot_discr_data` plots a ggplot of a geodataframe and fills the polygons according to discrete data
#'
#' @param gdf A geodataframe (sf data.frame)
#' @param column The name of the column in gdf that contains the data to be plotted (character)
#' @param plot_limits the limits of the plot (list of two vectors containing two values), usually result of define_limits()
#' @param title The title of the plot (character)
#' @param title_size The size of the title (numeric)
#' @param title_face The typographical emphasis of the title (character)
#' @param fill_colors The colors to fill the polygons with (named character vector)
#' (example: c("A"="beige", "B"="#8d0613", "C"="darkorange"))
#' @param color_pal The color palette to use for fill_colors (function). Only necessary if no fill_colors are specified!
#' @param edge_color The color of the polygon edges (character)
#' @param edge_width The width of the polygon edges (numeric)
#' @param na_values NA values present in column? (logical)
#' @param na_color The color to fill the NA values with (character)
#' @param na_label The label for NA values (character)
#' @param legend_rows The number of rows in the legend (numeric)
#' @param legend_spacing The spacing between legend items (numeric)
#' @param legend_order The order of the legend items (character vector)
#' @param legend_text The size of the legend text (numeric)
#' @param adding_outline If TRUE, outline of unionized polygons is added (logical)
#' @param adding_outline_borders If TRUE, outlines of every polygon/feature are added (logical)
#' @param outline_gdf A sf object that either contains single polygons of the gdf or union of polygons
#' @param outline_calculate_union Only relevant if adding_outline = TRUE: If outline_calculate_union = FALSE, outline_gdf already contains the unionized polygons (logical).
#' Therefore, if TRUE when creating the animation, it will be calculated anew for each frame!
#' @param outline_color If adding_outline = TRUE: The color of the unionized outline (character)
#' @param outline_width If adding_outline = TRUE: The width of the unionized outline (numeric)
#' @param outline_borders_color If adding_outline_borders = TRUE: The color of the polygon/feature outlines (character)
#' @param outline_borders_width If adding_outline_borders = TRUE: The width of the polygon/feature outlines (numeric)
#'
#'
#' @return Plot of geodataframe with filled polygons according to discrete data
#'
#'
#' @import ggplot2
#' @importFrom dplyr rename
#' @importFrom sf st_union
#'
#' @author Anna Bischof, Georg Starz
#'
#' @export



plot_discr_data <- function(gdf, column, plot_limits,
                            title = "", title_size = 18, title_face = "bold.italic",
                            fill_colors = NA,
                            color_pal = rainbow,
                            edge_color = NA, edge_width = 0.5,
                            na_values = FALSE, na_color = "grey", na_label = "No Data",
                            legend_rows = 1, legend_spacing = 0.4,
                            legend_order = names(fill_colors), legend_text = 15,
                            adding_outline = FALSE,
                            adding_outline_borders = FALSE,
                            outline_gdf = NA,
                            outline_calculate_union = TRUE, outline_color = "darkgrey", outline_width = 0.5,
                            outline_borders_color ="darkgrey", outline_borders_width = 0.5) {

  gdf <- gdf %>%
    rename(v_plot1 = column)

  gdf <- gdf %>% mutate(v_plot1 = replace_na(gdf$v_plot1, na_label))


  xlim_plot <-  c(plot_limits[[1]][1], plot_limits[[1]][2])
  ylim_plot <-  c(plot_limits[[2]][1], plot_limits[[2]][2])

  if (is.na(fill_colors)) {
    fill_colors <- setNames(color_pal(length(unique(gdf$v_plot1))), unique(gdf$v_plot1))
  }

  # check for na_values
  if (na_values == TRUE){
    # to ensure na_label is always at the end of legend
    fill_colors <- fill_colors[!names(fill_colors) %in% na_label]
    #add na_color to fill_colors
    fill_colors <- c(fill_colors, setNames(na_color, na_label))

    #add na_label to legend_order
    legend_order <- c(legend_order, na_label)
  }


  #start with empty ggplot
  p <- ggplot()

  if (adding_outline_borders == TRUE) {
    p <- p + geom_sf(data = outline_gdf, color = outline_borders_color, lwd = outline_borders_width, fill = NA)
  }

  if (adding_outline == TRUE) {
    if (outline_calculate_union == TRUE) {
      p <- p + geom_sf(data = st_union(outline_gdf), color = outline_color, lwd = outline_width, fill = NA)}
    else {
      p <- p + geom_sf(data = outline_gdf, color = outline_color, lwd = outline_width, fill = NA)}
  }


  p <-  p +
    geom_sf(data = gdf, aes(fill = v_plot1), color = edge_color, lwd = edge_width) +

    ggtitle(title) +

    coord_sf(xlim = xlim_plot, ylim = ylim_plot) +

    labs(fill = NULL) +
    scale_fill_manual(values = fill_colors, breaks = legend_order) +
    theme_void() +
    theme(legend.position = "bottom",
          legend.key.size = unit(0.75, 'cm'),
          legend.key.width = unit(1.5, 'cm'),
          legend.text = element_text(size = legend_text),
          legend.spacing.x = unit(legend_spacing, 'cm'),
          plot.title = element_text(hjust = 0.5, size = title_size,
                                    face = title_face, lineheight = 1.5)) +
    guides(fill = guide_legend(nrow = legend_rows, byrow = TRUE))



  return (p)

}
