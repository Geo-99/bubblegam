#' Merge geodataframe with dataframe
#'
#' `merge_gd_df` merges a gdf and df with a left join and checks if/what data would be lost in the right df
#'
#' @param gdf_left The geodataframe (sf data.frame)
#' @param id_left The name of the column in the gdf that will be used to merge (character)
#' @param df_right A dataframe (data.frame)
#' @param id_right The name of the column in the df that will be used to merge (character)
#' @param cols_to_keep The columns that should be kept in the merged gdf (character vector)
#'
#' @return The merged geodataframe
#'
#' @importFrom dplyr select setdiff
#'
#' @author Anna Bischof
#'
#' @export



merge_gd_df <- function(gdf_left, id_left, df_right, id_right=id_left, cols_to_keep= "ALL"){

  # left merge
  merged_df <- merge(x = gdf_left, y = df_right, by.x = id_left, by.y = id_right, all.x = TRUE)

  # check if cols should be omitted
  if (cols_to_keep[1] != "ALL"){
    cols_to_keep <- c("geometry", id_left, cols_to_keep)
    merged_df <- merged_df %>% select(all_of(cols_to_keep))
  }

  # get all features that would be lost in a merge
  lost_features <- dplyr::setdiff(df_right[[id_right]], merged_df[[id_left]])

  # inform user of lost features
  if (length(lost_features) != 0){
    cat("The following features from the csv file would be lost in a left merge:\n",
        paste0(lost_features, collapse = "\n "), "\n")
    cat("If you think that some features would be incorrectly deleted,\napply the SIMILARITY function (find_sim_change) beforehand\nor manually edit the features\n")
    prompt <- tolower(readline("Do you want to continue with the merge? (y/n)"))
    if (prompt %in% c("yes", "y")){
      return(merged_df)
    } else {
      return(print("Merge aborted."))
    }
  }else{
    cat("No information in the csv file was lost, every feature was successfully merged\n")
    return(merged_df)}
}
