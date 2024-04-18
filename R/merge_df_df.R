#' Merge two dataframes
#'
#' `merge_df_df` merges a df and df with a inner join and checks if/what data would be lost in the right df
#'
#' @param df_left A dataframe (data.frame)
#' @param id_left The name of the column in df_left that will be used to merge (character)
#' @param df_right A dataframe (data.frame)
#' @param id_right The name of the column in df_right that will be used to merge (character)
#' @param cols_to_keep The columns that should be kept in the merged df (character vector)
#'
#' @return The merged dataframe
#'
#'
#' @importFrom dplyr select setdiff
#'
#' @author Anna Bischof
#'
#' @export



merge_df_df <-  function(df_left, id_left, df_right, id_right=id_left, cols_to_keep= "ALL"){

  # inner merge
  merged_df <- merge(x = df_left, y = df_right, by.x = id_left, by.y = id_right, all = FALSE)

  # check if cols should be omitted
  if (cols_to_keep[1] != "ALL"){
    cols_to_keep <- c(id_left, cols_to_keep)
    merged_df <- merged_df %>% select(all_of(cols_to_keep))
  }

  # get all features that would be lost in a merge
  lost_features <- dplyr::setdiff(df_right[[id_right]], merged_df[[id_left]])

  if (length(lost_features) != 0){
    cat("The following features from the dfs file would be lost in a inner merge:\n",
        paste0(lost_features, collapse = "\n "), "\n")
    cat("If you think that some features would be incorrectly deleted,\napply SIMILARITY function (find_sim_change) beforehand\nor manually edit the features\n")
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
