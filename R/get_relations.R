#' Word Embedding Semantic Direction Builder
#'
#' The `get_direction` function outputs a vector corresponding to 
#' one pole of the "semantic direction" in a word embedding 
#' space built from sets of antonyms or juxtaposed terms.
#'
#' @name get_direction
#' @author Dustin Stoltz
#'
#' @param anchors two column data.frame or matrix of juxtoposing "anchor" terms
#' @param wv matrix of word embeddings
#' @param method method used to calculate vector offset
#' @export
get_direction <- function(anchors, wv, method = "paired"){
  # check that word vectors exist for all words
  .check_terms_in_embeddings(anchors, wv)
  
  # convert data.frame to matrix
  if(is.data.frame(anchors) == TRUE){
    anchors <- as.matrix(anchors)
  }

  # take the mean of a set of word vector differences
  # between a collection of antonym word pairs
  # as used in Kozlowski et al. 2019 and Stoltz and Taylor 2019
  if(method == "paired"){
    # subtract vectors for words in column 2 from words in column 1
    v <- wv[anchors[,1, drop=TRUE]  , , drop=FALSE] -
         wv[anchors[,2, drop=TRUE] , , drop=FALSE]
    # get the average of the resulting differences
    v <- t(as.matrix( colMeans(v) ) )
  }

  # average  the vectors for words on each pole,
  # then take the difference between these two average
  # as used in Larsen et al 2015 and Arseniev-Koehler and Foster 2020
  if(method == "pooled"){
    mu1 <- t(as.matrix(colMeans(
      wv[anchors[,1, drop=TRUE]  , , drop=FALSE]) ) )
    mu2 <- t(as.matrix(colMeans(
      wv[anchors[,2, drop=TRUE]  , , drop=FALSE]) ) )
    v   <- mu1 - mu2
  }

  # Euclidean norm
  # as used in Bolukbasi et al. 2016
  if(method == "euclidean"){
    v <- wv[anchors[,1, drop=TRUE] , , drop=FALSE] -
      wv[anchors[,2, drop=TRUE] , , drop=FALSE]
    # get the average of the resulting differences
    v <- t(as.matrix( colMeans(v) ) )
    # divide by Euclidean norm
    v <- v/norm(v, type="2")
  }

  # create unique name
  rownames(v) <- paste0( anchors[1,1], ".pole")
  return(v)

}

#' Word Embedding Semantic Centroid Builder
#'
#' `get_centroid` requires a one column dataframe or list of
#' terms to be averaged. The function outputs an averaged
#' vector from a set of terms.
#'
#' @name get_centroid
#' @author Dustin Stoltz
#'
#' @param anchors list of terms to be averaged
#' @param wv matrix of word embeddings.
#' @export
get_centroid <- function(anchors, wv){

  # check that word vectors exist for each word
  .check_terms_in_embeddings(anchors, wv)

  # select vectors for words in column 1
  v <- wv[ anchors[(anchors %in% rownames(wv) )], , drop = FALSE]
  # average the resulting vector
  v <- t(as.matrix( colMeans(v) ) )

  # create unique name
  rownames(v) <- paste0( anchors[[1]], ".centroid")
  return(v)
}


# INTERNAL FUNCTIONS
# checks that all terms are in the word embeddings
.check_terms_in_embeddings <- function(terms, wv){
  words <- unlist(terms)
  bad.words <- words[!(words %in% rownames(wv) )]
  if( length(bad.words) != 0 ){
    bad.words <- paste(bad.words, collapse='; ' )
    stop(paste0("No word vectors for the following words: ", bad.words) )
  }
}
