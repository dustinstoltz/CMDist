#' Concept Mover's Distance Function
#'
#' The function outputs a dataframe with Concept Mover's Distances for each document.
#' @references \url{https://journals.sagepub.com/doi/10.1177/2378023119827674}
#' @param Function requires a document-term matrix and a matrix of word embeddings.
#' @examples cm.dists <- CMDist(dtm, cw = "death", wv = wordvectors, scale = TRUE)
#' @export
#' 
      CMDist <- function(dtm, cw = NULL, cd = NULL, wv, method = "cosine", scale = TRUE, parallel = FALSE, threads = 2) {
                
                # make DTM dgCMatrix sparse if not already
                if(any(class(dtm)=="simple_triplet_matrix") ){
                    dtm2 <-Matrix::sparseMatrix(i=dtm$i, j=dtm$j, x=dtm$v, 
                                      dims=c(dtm$nrow, dtm$ncol) )
                    dimnames(dtm2) = list(rownames(dtm),colnames(dtm))
                    dtm <- dtm2
                    rm(dtm2)
                  }

                if(any(class(dtm)=="matrix") ){
                  dtm <- Matrix::Matrix(dtm, sparse = TRUE)
                  }

                # number of pseudo-docs 
                n.pd = 0

                # if concept words are provided
                if( !is.null(cw) ){
                    ## Make sure there are no extra spaces for concept words
                    cw <- str_trim(cw)
                    n.pd <- length(cw)
                    vocab <- unique(unlist( strsplit(cw, " ") ) )
                    check <- data.frame(vocab, result = 
                                sapply(vocab,function(x)any(grepl(x,rownames(wv) ) ) ), 
                                stringsAsFactors=FALSE)
                    st.cw <- strsplit(cw, " ")


                if( any(check$result==FALSE) ){
                  bad_words <- c(unlist(check$vocab[check$result == FALSE] ) )
                  bad_words <- paste(bad_words, collapse='; ' ) 
                  stop(paste0("No word vectors for the following words: ", bad_words) )
                	}

                ## add concept word if not in DTM
                for (i in vocab) {
                  if(!i %in% colnames(dtm)) {
                    new <- matrix(0, nrow=nrow(dtm))
                    colnames(new) <- i
                    dtm <- cbind(dtm, new)
                        }
                    }
                }

                ## add cultural dimension to DTM and word vectors
                if( !is.null(cd) ){
                    n.pd <- n.pd + nrow(cd)
                    rownames(cd) <- paste0(rownames(cd), ".", 1:nrow(cd) )
                    wv  <- rbind(wv, cd)
                
                    cdim <- matrix(0, ncol=nrow(cd), nrow=nrow(dtm) )
                    colnames(cdim) <- rownames(cd)

                    dtm <- cbind(dtm, cdim)
                    st.cd <- unlist(strsplit(colnames(cdim), " ") )
                }


                # create a full list of unique vocabulary for each pseudo-doc
                if( !is.null(cd) & !is.null(cw)){st <- c(st.cw, st.cd)}
                if( !is.null(cd) & is.null(cw)){st <- st.cd}
                if( is.null(cd) & !is.null(cw)){st <- st.cw}

                # st <- unlist(st)

                ## prepare word embeddings
                wem  <- wv[intersect(rownames(wv), colnames(dtm)),]
                wem  <- wem[rowSums(is.na(wem)) != ncol(wem), ] # Remove any NAs or RWMD won't like it
                dtm  <- dtm[, as.vector(rownames(wem))] # remove words in the dtm without word vectors

                ## create pseudo-dtm
                # pseudo-dtm must be at least two rows for dist2, 
                # even if one concept word
                  pdtm <- as(Matrix::sparseMatrix(dims = c(nrow = n.pd + 1, ncol(dtm)), 
												  i={}, j={}), "dgCMatrix")
                  colnames(pdtm) <- colnames(dtm)

                  for (i in 1:n.pd) {
                        pdtm[i, st[[i]] ] <- 1
                  	}

                ## the Work Horse of the function:
                if(parallel==FALSE){
                dist <- text2vec::dist2(dtm, pdtm, method = RWMD$new(wem, method), norm = 'none')
                	}

                if(parallel==TRUE){
                  print(paste0("Running parallel on ", threads, " threads"))
                  require("doSNOW")
                  # Determine chunk-size to be processed by different threads
                  ind <- bigstatsr:::CutBySize(nrow(dtm), nb = threads)
                  cl  <- parallel::makeCluster(threads)
                  doSNOW::registerDoSNOW(cl)
                  dist <- .parDist2(dtm, pdtm, wem, ind, method)
                  on.exit(parallel::stopCluster(cl))
                	}
                ##
                
                if(n.pd==1) {
                  df <- as.data.frame(dist[,1])
                }
                
                if(n.pd!=1) {
                  df <- as.data.frame(dist[,1:n.pd])
                }

                if(scale == TRUE) {
                  df <- as.data.frame(scale(df)*-1)
                }

                if(scale == FALSE) {
                  df <- (df)*-1
                }
                #
                df <- sapply(df[,1:n.pd], as.numeric)
                df <- as.data.frame(cbind(rownames(dtm), df), stringsAsFactors=FALSE )

                # make column labels
                if( !is.null(cd) & !is.null(cw)){
                        cw.labs <- gsub('(^\\w+)\\s.+','\\1', cw)
                        labs <- c(cw.labs, unlist(st.cd ) )}

                if(  is.null(cd) & !is.null(cw)){
                        cw.labs <- gsub('(^\\w+)\\s.+','\\1', cw)
                        labs <- cw.labs}

                if( !is.null(cd) &  is.null(cw)){labs <- st.cd}

                colnames(df) <- c("docs", paste("cmd", 1:n.pd, labs, sep=".") )

                return(df)
            }
