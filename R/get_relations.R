#' Word Embedding Semantic Direction and Centroid Builder functions
#'
#' The get_direction outputs a vector corresponding to one pole of the "semantic direction" built from pairs of antonyms or juxtposed terms. The get_centroid outputs an averaged vector from a set of terms
#' 
#' 
#' @param Both functions require a matrix of word embeddings. get_direction requires a two column dataframe of juxtoposed pairs. get_centroid requires a one column dataframe with pairs of terms to be averaged.
#' @examples sd <- get_direction(pairs, wv)
#' @export

       # checks that all terms are in the word embeddings
       .check_terms_in_embeddings <- function(terms, wv){
               words <- unlist( terms)
               bad.words <- words[!(words %in% rownames(wv) )]
               if( length(bad.words) != 0 ){
               bad.words <- paste(bad.words, collapse='; ' ) 
               stop(paste0("No word vectors for the following words: ", bad.words) )
                   }
               }

   get_centroid <- function(terms, wv){
          
        # convert list of terms into data.frame
        if(is.data.frame(terms)!=TRUE){
        terms <- as.data.frame(terms)
              }

        # check that word vectors exist for all words
        .check_terms_in_embeddings(terms, wv)

            # get vectors for words in column 1
            v <- wv[ terms[, 1, drop=TRUE]  , , drop = FALSE]
            # get the average of the resulting vector
            v <- t(as.matrix( colMeans(v) ) )

        # create unique name
        rownames(v) <- paste0( terms[1,1], ".centroid")
        return(v)
        }
   
   get_direction <- function(pairs, wv, method = "KTE"){
         # check that word vectors exist for all words
         .check_terms_in_embeddings(pairs, wv)

        # Kozlowski et al. 2019:
        # take the mean  of a set of word vector differences between a collection of antonym word pairs 
        if(method == "KTE"){
            # subtract vectors corresponding to words in column 2 from words in column 1
            v <- wv[ pairs[,1, drop=TRUE]  , , drop = FALSE] - wv[pairs[,2,drop=TRUE] , , drop = FALSE]
            # get the average of the resulting differences
            v <- t(as.matrix( colMeans(v) ) )
            }

        # Larsen et al 2015:
        # average  the vectors for words on each pole, then take the difference between these two average
        if(method == "LSLW"){
            mu1 <- t(as.matrix(colMeans(wv[ pairs[,1, drop=TRUE]  , , drop = FALSE]) ) )
            mu2 <- t(as.matrix(colMeans(wv[ pairs[,2, drop=TRUE]  , , drop = FALSE]) ) )
            v   <- mu1 - mu2
            }

        # Bolukbasi et al. 2016a: Euclidean norm
        if(method == "BCZSKa"){ 
            v <- wv[ pairs[,1, drop=TRUE]  , , drop = FALSE] - wv[pairs[,2,drop=TRUE] , , drop = FALSE]
            # get the average of the resulting differences
            v <- t(as.matrix( colMeans(v) ) )
            # divide by Euclidean norm
            v <- v/norm(v, type="2")   
            }

        # create unique name
        rownames(v) <- paste0( pairs[1,1], ".pole")
        return(v)

        }
