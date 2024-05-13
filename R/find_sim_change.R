#' Find similar values in two dataframe columns and change them
#'
#' `find_sim_change` finds similar values based on different possible similarity measures in two columns of two dataframes.
#' It then prompts the user to decide whether the values in one dataframe should be replaced by the values in the other dataframe.
#' The function can also be used multiple times with different similarity measures.
#'
#' @param df_main A dataframe (data.frame). This df remains unchanged
#' @param df_main_col The name of the column in df_main that is used to compare similar values (character)
#' @param df_change A dataframe (data.frame). This df will be changed.
#' @param df_change_col The name of the column in df_change that is used to compare similar values (character)
#' @param sim Can be "sim", "jc" (Jaccard Similarity), or "jw" (Jaro Winkler Similarity) (character vector)
#' @param thresh Threshold for similarity measure (numeric)
#'
#' @return Updated df_change dataframe.
#'
#'
#' @importFrom dplyr setdiff
#'
#' @author Anna Bischof
#'
#' @export


find_sim_change <- function(df_main, df_main_col, df_change, df_change_col, sim = "sim", thresh = 0.5){

  # names of variables as characters for the prompts
  name_df_main <- deparse(substitute(df_main))
  name_df_change <- deparse(substitute(df_change))


  values_df_main <- df_main[[df_main_col]]
  values_df_change <- df_change[[df_change_col]]


  # Find values that are present in df_main, but not in df_change
  unique_values_df_main <- setdiff(values_df_main, values_df_change)
  # other way round
  unique_values_df_change <- setdiff(values_df_change, values_df_main)

  # iterate over unique value in df_change
  for (value in unique_values_df_change){
    # select sim measure
    if (sim == "jc"){
      similar_values <- jaccard_similarity(value, unique_values_df_main, thresh)
      similar_values <- similar_values[["word"]]
    } else if (sim == "jw"){
      similar_values <- jaro_winkler_similarity(value, unique_values_df_main, thresh)
      similar_values <- similar_values[["word"]]
    } else {
      similar_values <- find_similar_value(value, unique_values_df_main)
    }
    # Replacement question
    if (length(similar_values)!=0) {
      for (similar_value in similar_values) {
        prompt <- sprintf("Should '%s' in %s (%s) be replaced by '%s' in %s (%s)? (y/n)\n Press x to move to the next value\n",
                          value, df_change_col,
                          name_df_change,
                          similar_value, df_main_col,
                          name_df_main)
        response <- tolower(readline(prompt))

        if (response %in% c("yes", "y")) {
          df_change[df_change[[df_change_col]] == value, df_change_col] <- similar_value
          cat(sprintf("'%s' was replaced by '%s'.\n",
                      value, similar_value))
          break
        }
        if (response == "x"){
          break
        }
      }
    } else {
      cat(sprintf("No similar value found for '%s' in %s.\n",
                  value, df_main_col))
    }
  }

  return(df_change)
}

#Default parameter for find_sim_change------
# Default function that identifies similar values based on pattern match (4 consecutive characters) and position match (1st and 4th character)
find_similar_value <- function(value, vector) {
  pattern_matches <- grep(paste0(".*", substr(value, 1, 4), ".*"), vector, value = TRUE)
  position_matches <- grep(paste0(".*", substr(value, 1, 1), ".{2}", substr(value, 4, 4), ".*"), vector, value = TRUE)
  pattern_matches_back <- grep(paste0(".*", substr(value, nchar(value) - 3, nchar(value)), ".*"), vector, value = TRUE)
  return (unique(c(pattern_matches, position_matches, pattern_matches_back)))
}

#Jaccard Similartiy-----
#similarity calculated by dividing the size of the intersection by the size of the union

jaccard_similarity <- function(value, vector, threshold){

  # create vector that saves sim values
  sim_values <- numeric(length(vector))

  # remove spaces from value
  set_value <- strsplit(value, '')[[1]]
  set_value <- set_value[set_value != ' ']

  # iterate over all words in vector
  for (i in seq_along(vector)) {
    word <- vector[i]
    # remove spaces from word
    set_vector <- strsplit(word, '')[[1]]
    set_vector <- set_vector[set_vector != ' ']
    # calculate similarity
    intersection <- length(intersect(set_value, set_vector))
    union <- length(union(set_value, set_vector))
    similarity <- intersection / union
    # save similarity
    sim_values[i] <- similarity
  }

  # sort the results according to similarity
  sorted_indices <- order(sim_values, decreasing = TRUE)
  sorted_vector <- vector[sorted_indices]
  sorted_sim_values <- sim_values[sorted_indices]
  result <- data.frame(word = sorted_vector, similarity = sorted_sim_values)

  #filter threshold
  result <- subset(result, similarity >= threshold & similarity < 1)
  return(result)
}


#Jaro Similarity -----
# is part of jaro_winkler_similarity calculation

jaro_similarity <-function(word1, word2){
  # if both words are same
  if (word1 == word2){
    return(1.0)
  }
  # prepare words
  word1_list <- strsplit(word1, '')[[1]]
  word2_list <- strsplit(word2, '')[[1]]
  word1_split<- word1_list[word1_list!= ' ']
  word2_split<- word2_list[word2_list!= ' ']

  # determine length of words
  w1_len <- length(word1_split)
  w2_len <- length(word2_split)

  #Matching distance defined by Jaro
  max_dist <-floor((max(w1_len, w2_len) / 2) - 1)

  #Count of matches
  match <-  0

  #Hash for matches
  hash_w1 <- rep.int(0, w1_len)
  hash_w2 <- rep.int(0, w2_len)

  #Count matching characters
  for (idx in 1:w1_len){
    start <- max(1, idx - max_dist)
    end <- min(w2_len, idx + max_dist)
    # change here
    if (start <= end){
      for (i in start:end){
        # print(paste0("Start: ", start, "End: ", end,
        #              "Start > End: ", start>end,
        #              "idx: ", idx, " i: ", i, " word1_split[idx]: ", word1_split[idx], " word2_split[i]: ", word2_split[i], " hash_w2[i]: ", hash_w2[i], " hash_w1[idx]: ", hash_w1[idx]))
        if (word1_split[idx] == word2_split[i] && hash_w2[i] == 0){
          hash_w1[idx] <- 1
          hash_w2[i] <- 1
          match <- match + 1
          break
        }
      }
    }
  }

  #if non-matching is zero
  if (match == 0){
    return(0)
  }
  #count Transposition
  t <- 0
  point <- 1

  #Count number of occurences where the characters in the first word are not in the same position in the second word
  for (i in 1:w1_len){
    if (hash_w1[i] == 1){
      while (hash_w2[point] == 0){
        point <- point + 1
      }
      if (word1_split[i] != word2_split[point]){
        point <- point + 1
        t <- t + 1
      } else {
        point <- point + 1
      }
    }
  }
  t <- t / 2
  return ((match / w1_len + match / w2_len + (match - t) / match) / 3.0)
}

# Jaro Winkler Similarity----
jaro_winkler_similarity <- function(value, vector, threshold) {
  # Initialize a vector to store similarity values
  sim_values <- numeric(length(vector))
  # iterate over all words in vector
  for (i in seq_along(vector)) {
    word <- vector[i]
    # calculate jaro similarity
    sim_j <- jaro_similarity(value, word)
    # threshold for jaro similarity
    if (sim_j > 0.5) {

      # length of the common prefix
      prefix <- 0

      for (j in 1:min(nchar(value), nchar(word))) {
        if (substr(value, j, j) == substr(word, j, j)) {
          prefix <- prefix + 1
        } else {
          break
        }
      }
      # Ensure maximum of 4 characters are allowed in prefix
      prefix <- min(4, prefix)

      # Calculation of Jaro-Winkler similarity
      sim_j_w <- sim_j + 0.1 * prefix * (1 - sim_j)
    } else{sim_j_w <- 0}

    # Store similarity value in vector
    sim_values[i] <- sim_j_w

  }

  # Sort the vector indices based on similarity values in descending order
  sorted_indices <- order(sim_values, decreasing = TRUE)

  # Sort the vector and similarity values based on sorted indices
  sorted_vector <- vector[sorted_indices]
  sorted_sim_values <- sim_values[sorted_indices]

  # Create a dataframe to store sorted words and their similarity values
  result <- data.frame(word = sorted_vector, similarity = sorted_sim_values)
  # filter for threshold
  result <- subset(result, similarity >= threshold & similarity < 1)
  return(result)
}
