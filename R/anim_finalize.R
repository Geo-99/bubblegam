#' Function to fine-tune a raw animation
#'
#' `anim_finalize` loads a raw animation, defines the fps and enables a delay at the beginning
#' and end before the new animation gets saved.
#'
#' @param anim_raw The path and name of the raw animation file (.gif) (character)
#' @param anim_path_file The path and name of the final animation file (.gif) (character)
#' @param fps_anim The frames per second of the animation (numeric)
#' @param delay_anim Should the animation have a delay at the beginning and end? (logical)
#' @param delay_frames The number of frames of the beginning and end delay (numeric)
#'
#'
#' @return None, but saves a .gif file at the specified path_file_name
#'
#'
#' @importFrom magick image_read image_animate image_write
#'
#'
#' @author Georg Starz
#'
#' @export



anim_finalize <- function(anim_raw, anim_path_file,
                      fps_anim = 10, delay_anim = TRUE,
                      delay_frames = 60){

  raw_anim <- image_read(anim_raw)
  anim <- image_animate(raw_anim, fps = fps_anim)

  if (delay_anim == TRUE){
    anim_delayed <- anim[c(rep(1, each = delay_frames), 2:(length(anim)-1), rep(length(anim), each = delay_frames))]
    image_write(anim_delayed, anim_path_file)
  } else {
    image_write(anim, anim_path_file)
  }
}
