#' Word Embedding Cultural Dimension Builder function
#'
#' The function outputs a vector corresponding to one pole of "cultural dimension" built from antonym pairs.
#' 
#' @param Function requires a two column dataframe of antonym pairs and a matrix of word embeddings.
#' @examples cdims <- get_antodim(antonyms, wv)
#' @export
   get_antodim <- function(antonyms, wv){
         # check that word vectors exist for all words
         words <- c(antonyms[,1], antonyms[,2])
         bad.words <- words[!(words %in% rownames(wv) )]
         if( length(bad.words) != 0 ){
         bad.words <- paste(bad.words, collapse='; ' ) 
         stop(paste0("No word vectors for the following words: ", bad.words) )
         }
        # subtract vectors corresponding to words in column 2 from words in column 1
        v <- wv[ antonyms[,1, drop=TRUE]  , , drop = FALSE] - wv[antonyms[,2,drop=TRUE] , , drop = FALSE]
        # get the average of the resulting differences
        v <- t(as.matrix( colMeans(v) ) )
        # create unique name
        rownames(v) <- paste0( antonyms[1,1], ".pole")
        return(v)
        }
