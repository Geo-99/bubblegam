#' Function to create a raw animation for continuous data
#'
#' `anim_cont_raw` plots a ggplot of a all intermediary states of a transition df,
#' fills the polygons according to a continuous data column and creates a raw animation
#' that gets saved.
#'
#' @param transition_df A transition data.frame (result of create_transition function)
#' @param path_file_name The path and file name (.gif) of the raw animation that gets created (character)
#' @param anim_width The width of the animation frames (in px) (numeric)
#' @param anim_height The height of the animation frames (in px) (numeric)
#' @param anim_res The nominal resolution in ppi (numeric)
#' @param column The name of the column in transition_df that contains the continuous data to be plotted (character)
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
#' @return None, but saves a .gif file at the specified path_file_name
#'
#'
#' @importFrom animation saveGIF
#' @importFrom sf st_as_sf
#'
#'
#' @author Georg Starz, Anna Bischof
#'
#' @export



anim_cont_raw <- function(transition_df, path_file_name,
                          anim_width = 500, anim_height = 500, anim_res = 500,
                          column = "v_plot1", plot_limits,
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

  datalist <- split(transition_df, transition_df$.frame)
  sf_datalist <- lapply(datalist, function(datalist) st_as_sf(datalist))
  my_plots <- lapply(sf_datalist, bubblegam::plot_cont,
                     column, plot_limits,
                     title, title_size, title_face,
                     fill_colorscale,
                     edge_color, edge_width,
                     na_values, na_color, na_label,
                     legend_limits, legend_breaks,
                     legend_accuracy, legend_text,
                     adding_outline,
                     adding_outline_borders,
                     outline_gdf,
                     outline_calculate_union, outline_color, outline_width,
                     outline_borders_color, outline_borders_width)

  saveGIF({
    for (i in 1:length(datalist)) plot(my_plots[[i]])},
    movie.name = path_file_name,
    ani.width = anim_width, ani.height = anim_height,
    ani.res = anim_res
  )
}
