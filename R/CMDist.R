#' Concept Mover's Distance Function
#'
#' The function outputs a dataframe with Concept Mover's Distances for each document.
#' @references \url{https://journals.sagepub.com/doi/10.1177/2378023119827674}
#' @param Function requires a document-term matrix and a matrix of word embeddings.
#' @examples cm.dists <- CMDist(dtm, cw = "death", wv = wordvectors, scale = TRUE
#' @export
      CMDist <- function(dtm, cw, wv, method = "cosine", scale = TRUE, parallel = FALSE, threads = 2) {
                
                # make DTM dgCMatrix sparse if not already
                if(any(class(dtm)=="simple_triplet_matrix") ){
                    dtm2 <-Matrix::sparseMatrix(i=dtm$i, j=dtm$j, x=dtm$v, dims=c(dtm$nrow, dtm$ncol) )
                    dimnames(dtm2) = list(rownames(dtm),colnames(dtm))
                    dtm <- dtm2
                    rm(dtm2)
                  }

                if(any(class(dtm)=="matrix") ){
                  dtm <- Matrix::Matrix(dtm, sparse = TRUE)
                  }
                ##
                cw <- str_trim(cw)
                l <- length(cw)
                vocab <- unique(unlist( strsplit(cw, " ") ) )
                check <- data.frame(vocab, result = sapply(vocab,function(x)any(grepl(x,rownames(wv) ) ) ), stringsAsFactors=FALSE)

                if( any(check$result==FALSE) ){
                  bad_words <- c(unlist(check$vocab[check$result == FALSE] ) )
                  bad_words <- paste(bad_words, collapse='; ' ) 
                  stop(paste0("No word vectors for the following words: ", bad_words) )
                	}
                ## add word if not in DTM
                for (i in vocab) {
                  if(!i %in% colnames(dtm)) {
                    new <- matrix(0, nrow=nrow(dtm))
                    colnames(new) <- i
                    dtm <- cbind(dtm, new)
                  }
                }
                
                # prepare word embeddings
                wem <- wv[intersect(rownames(wv), colnames(dtm)),]
                wem <- wem[rowSums(is.na(wem)) != ncol(wem), ] # Remove any NAs or RWMD won't like it
                dtm  <- dtm[,as.vector(rownames(wem))] # remove words in the dtm without word vectors

                ## create pseudo-dtm
                # pseudo-dtm must be at least two rows for dist2, 
                # even if one concept word
                  pdtm <- as(Matrix::sparseMatrix(dims = c(nrow = l+1, ncol(dtm)), i={}, j={}), "dgCMatrix")
                  colnames(pdtm) <- colnames(dtm)
                  st <- strsplit(cw, " ")

                  for (i in 1:l) {
                        pdtm[i, st[[i]] ] <- 1
                  	}

                ## the Work Horse of the function:
                model <- text2vec::RWMD$new(wem, method)
                                                           
                if(parallel==FALSE){
                dist <- text2vec::dist2(dtm, pdtm, method = model, norm = 'none')
                	}

                if(parallel==TRUE){
                  print(paste0("Running parallel on ", threads, " threads"))
                  require("doSNOW")
                  # Determine chunk-size to be processed by different threads
                  ind <- bigstatsr:::CutBySize(nrow(dtm), nb = threads)
                  cl  <- parallel::makeCluster(threads)
                  doSNOW::registerDoSNOW(cl)
                  dist <- .parDist2(dtm, pdtm, wem, ind, model)
                  on.exit(parallel::stopCluster(cl))
                	}
                ##
                
                if(l==1) {
                  df <- as.data.frame(dist[,1])
                }
                
                if(l!=1) {
                  df <- as.data.frame(dist[,1:l])
                }

                if(scale == TRUE) {
                  df <- as.data.frame(scale(df)*-1)
                }

                if(scale == FALSE) {
                  df <- (df)*-1
                }
                #
                df <- sapply(df[,1:l], as.numeric)
                df <- as.data.frame(cbind(rownames(dtm), df) )
                colnames(df) <- c("docs", paste0("cmd.", 1:l ) )

                return(df)
            }
