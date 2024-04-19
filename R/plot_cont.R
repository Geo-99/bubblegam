#' Function to plot continuous data
#'
#' `plot_cont` plots a ggplot of a geodataframe and fills the polygons according to continuous data
#'
#' @param gdf A geodataframe (sf data.frame)
#' @param column The name of the column in gdf that contains the data to be plotted (character)
#' @param plot_limits the limits of the plot (list of two vectors containing two values), usually result of define_limits()
#' @param title The title of the plot (character)
#' @param title_size The size of the title (numeric)
#' @param title_face The typographical emphasis of the title (character)
#' @param fill_colorscale Color scale to fill polygons (character vector)
#' (example: c("#8d0613","white","darkblue"))
#' @param edge_color The color of the polygon edges (character)
#' @param edge_width The width of the polygon edges (numeric)
#' @param na_values NA values present in column? (logical)
#' @param na_color The color to fill the NA values with (character)
#' @param na_label The label for NA values (character)
#' @param legend_limits Start and end point of legend (numeric vector)
#' @param legend_breaks Breaks for legend (numeric vector). Requires start and end point when specified.
#' @param legend_accuracy Specifies the decimal points (numeric) (example: 1.0 for one decimal point)
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
#' @return Plot of geodataframe with filled polygons according to continuous data
#'
#'
#' @import ggplot2
#' @importFrom dplyr rename
#' @importFrom sf st_union
#'
#' @author Anna Bischof, Georg Starz
#'
#' @export



plot_cont <- function(gdf, column, plot_limits,
                           title = "", title_size = 18, title_face = "bold.italic",
                           fill_colorscale = c("lightblue", "darkblue"),
                           edge_color = NA, edge_width = 0.5,
                           na_values = FALSE, na_color = "grey", na_label = "No Data",
                           legend_limits = c(min(gdf$v_plot1, na.rm = TRUE), max(gdf$v_plot1, na.rm = TRUE)),
                           legend_breaks = c(min(legend_limits),
                                             (max(legend_limits)-min(legend_limits))*0.25 + min(legend_limits),
                                             (max(legend_limits)-min(legend_limits))*0.5 + min(legend_limits),
                                             (max(legend_limits)-min(legend_limits))*0.75 + min(legend_limits),
                                             max(legend_limits)),
                           legend_accuracy = 1, legend_text = 15,
                           adding_outline = FALSE,
                           adding_outline_borders = FALSE,
                           outline_gdf = NA,
                           outline_calculate_union = TRUE, outline_color = "darkgrey", outline_width = 0.5,
                           outline_borders_color = "darkgrey", outline_borders_width = 0.5) {

  gdf <- gdf %>%
    rename(v_plot1 = column)

  xlim_plot <-  c(plot_limits[[1]][1], plot_limits[[1]][2])
  ylim_plot <-  c(plot_limits[[2]][1], plot_limits[[2]][2])


  # Start with empty ggplot
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

  if (na_values == TRUE) {
    p <- p +
      geom_sf(data = gdf, aes(fill = v_plot1, color="")) +
      geom_sf(data = gdf, aes(fill = v_plot1), color=edge_color, lwd = edge_width) +

      ggtitle(title) +

      coord_sf(xlim = xlim_plot, ylim = ylim_plot) +

      labs(fill = NULL) +
      scale_fill_gradientn(colors = fill_colorscale,
                           limits = legend_limits,
                           breaks = legend_breaks,
                           labels = scales::number_format(accuracy = legend_accuracy),
                           na.value= na_color) +
      scale_color_manual(values = NA) +
      theme_void() +
      theme(legend.position = "bottom",
            legend.key.size = unit(0.75, 'cm'),
            legend.key.width= unit(1.5, 'cm'),
            legend.text = element_text(size = legend_text),
            legend.spacing = unit(1, 'cm'),
            plot.title = element_text(hjust = 0.5, size = title_size, face = title_face, lineheight = 1.5)) +
      guides(colour = guide_legend(na_label, override.aes = list(fill = na_color, color = na_color)))

  }
  else if (na_values == FALSE) {
    p <- p +
      geom_sf(data = gdf, aes(fill = v_plot1), color=edge_color, lwd = edge_width) +

      ggtitle(title) +

      coord_sf(xlim = xlim_plot, ylim = ylim_plot) +

      labs(fill = NULL) +
      scale_fill_gradientn(colors = fill_colorscale,
                           limits = legend_limits,
                           breaks = legend_breaks,
                           labels = scales::number_format(accuracy = 1),
                           #guide = guide_colorbar(frame.color = legend_frame_color, ticks.color = legend_ticks_color)
      ) +
      theme_void() +
      theme(legend.position = "bottom",
            legend.key.size = unit(0.75, 'cm'),
            legend.key.width= unit(1.5, 'cm'),
            legend.text = element_text(size = legend_text),
            plot.title = element_text(hjust = 0.5, size = title_size, face = title_face, lineheight = 1.5))
  }

  return(p)
}
