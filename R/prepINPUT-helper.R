# Private helper function to prepare the dtm, the pseudo-dtm, and the word embedding matrix
# also outputs number of pseudo-documents and the labels for concept words and concept vectors (directions and centroid)

    .prepINPUT <- function(dtm, cw = NULL, cv = NULL, wv){
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
                    cw <- stringr::str_trim(cw)
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

                ## add concept vector to DTM and word vectors
                if( !is.null(cv) ){
                    n.pd <- n.pd + nrow(cv)
                    rownames(cv) <- paste0(rownames(cv), ".", 1:nrow(cv) )
                    wv  <- rbind(wv, cv)
                
                    cvec <- matrix(0, ncol=nrow(cv), nrow=nrow(dtm) )
                    colnames(cvec) <- rownames(cv)

                    dtm   <- cbind(dtm, cvec)
                    st.cv <- unlist(strsplit(colnames(cvec), " ") )
                }

                # create a full list of unique vocabulary for each pseudo-doc
                if( !is.null(cv) & !is.null(cw)){st <- c(st.cw, st.cv)}
                if( !is.null(cv) &  is.null(cw)){st <- st.cv}
                if(  is.null(cv) & !is.null(cw)){st <- st.cw}

                ## prepare word embeddings
                wem  <- wv[intersect(rownames(wv), colnames(dtm)), ]
                wem  <- wem[rowSums(is.na(wem)) != ncol(wem), ] # Remove any NAs or RWMD won't like it
                dtm  <- dtm[, intersect(colnames(dtm), rownames(wem))] # remove words in the dtm without word vectors

                ## create pseudo-dtm
                # pseudo-dtm must be at least two rows for dist2, 
                # even if one concept word
                  pdtm <- as(Matrix::sparseMatrix(dims = c(nrow = n.pd + 1, ncol(dtm)), 
												  i={}, j={}), "dgCMatrix")
                  colnames(pdtm) <- colnames(dtm)
                  for (i in 1:n.pd) {
                        pdtm[i, st[[i]] ] <- 1
                  	}

                  # make labels
                  if( !is.null(cv) & !is.null(cw)){
                          cw.labs <- gsub('(^\\w+)\\s.+','\\1', cw)
                          labs <- c(cw.labs, unlist(st.cv ) )}

                  if(  is.null(cv) & !is.null(cw)){
                          cw.labs <- gsub('(^\\w+)\\s.+','\\1', cw)
                          labs <- cw.labs}
                  if( !is.null(cv) &  is.null(cw)){labs <- st.cv}

                  rownames(pdtm) <- c(labs, "zee_extra_row")
                  # make a list of the three matrices and the number of pseudo-docs, and the labels
             output   <- list(dtm, pdtm, wem, n.pd, labs)
             return(output)
        }

