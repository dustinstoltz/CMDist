#' Concept Mover's Distance Function
#'
#' The function outputs a dataframe with Concept Mover's Distances for each document.
#' @references \url{https://journals.sagepub.com/doi/10.1177/2378023119827674}
#' @param Function requires a document-term matrix and a matrix of word embeddings.
#' @examples cm.dists <- CMDist(dtm, cw = "death", cv = concept.vectors)
#' @export
#' 
  CMDist <- function(dtm, cw = NULL, cv = NULL, wv, method = "cosine", scale = TRUE, parallel = FALSE, threads = 2, setup_timeout = 120) {
            
            list_output <- .prepINPUT(dtm, cw, cv, wv)

            dtm  <- list_output[[1]]
            pdtm <- list_output[[2]]
            wem  <- list_output[[3]]

            ## workhorse function                
            if(parallel==FALSE){
              # deprecated Kusner et al. RWMD
              # dist <- text2vec::dist2(dtm, pdtm, method = kusnerRWMD$new(wem, method), norm = 'none')
              # Linear Complexity RWMD
                dist <- text2vec::RWMD$new(dtm, wem)$sim2(pdtm)
                dist <- t(dist[1:nrow(pdtm)-1, , drop=FALSE])

            }

            if(parallel==TRUE){
              print(paste0("Running parallel on ", threads, " threads"))
              require("doSNOW")
              # Determine chunk-size to be processed by different threads
              ind <- bigstatsr:::CutBySize(nrow(dtm), nb = threads)
              cl  <- parallel::makeCluster(threads, setup_timeout = setup_timeout)
              doSNOW::registerDoSNOW(cl)
              dist <- .parDist2(dtm, pdtm, wem, ind, method)
              on.exit(parallel::stopCluster(cl))
            }

            ##
            n.pd <- list_output[[4]]

            if(n.pd==1) {
              df <- as.data.frame(dist[,1])
            }
            
            if(n.pd!=1) {
              df <- as.data.frame(dist[,1:n.pd])
            }

            if(scale == TRUE) {
              df <- as.data.frame(scale(df))
            }

            if(scale == FALSE) {
              df <- (df)
            }

            #
            df <- df[,1:n.pd]
            df <- as.data.frame(cbind(rownames(dtm), df), stringsAsFactors=FALSE )
            
            colnames(df) <- c("docs", paste("cmd", list_output[[5]], sep=".") )

            return(df)
        }
