#' Defines plot limits of the plots / final animation
#'
#' `define_limits` defines the plot limits of the final animation, or any two plots that should have the same limits. Also works for a single plot.
#'
#' @param data_start A geodataframe (sf data.frame)
#' @param data_end A geodataframe (sf data.frame), if not specified data_start
#' @param parameter_w The parameter for the west limit (numeric). Decrease to have larger plot limits.
#' @param parameter_e The parameter for the east limit (numeric). Increase to have larger plot limits.
#' @param parameter_s The parameter for the south limit (numeric). Decrease to have larger plot limits.
#' @param parameter_n The parameter for the north limit (numeric). Increase to have larger plot limits.
#'
#' @return A lists containing two vectors of two values each.
#'
#'
#' @importFrom sf st_bbox
#'
#'
#' @author Anna Bischof, Georg Starz
#'
#' @export



define_limits <- function(data_start, data_end = data_start,
                          parameter_w = 0.999, parameter_e = 1.001,
                          parameter_s = 0.999, parameter_n = 1.001) {

  bbox1 <- st_bbox(data_start)
  bbox2 <- st_bbox(data_end)

  xlim_plot <- c(parameter_w * round(min(bbox1[["xmin"]], bbox2[["xmin"]]), digits = 5),
                 parameter_e * round(max(bbox1[["xmax"]], bbox2[["xmax"]]), digits = 5))
  ylim_plot <- c(parameter_s * round(min(bbox1[["ymin"]], bbox2[["ymin"]]), digits = 5),
                 parameter_n * round(max(bbox1[["ymax"]], bbox2[["ymax"]]), digits = 5))

  return(list(xlim_plot, ylim_plot))
}
