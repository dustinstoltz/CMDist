# Private helper function to parallize the computation of distance-matrices
    .parDist2 <- function(dtm, pd, wem, ind, method) { 
            # prepare progress bar
            pb <- utils::txtProgressBar(max = nrow(ind), style = 3)   
            progress <- function(n) utils::setTxtProgressBar(pb, n)
            opts <- list(progress = progress)
        # Compute distance in parallel threads
        dist <- foreach(
                    i = 1:nrow(ind), 
                    .packages = c("text2vec", "CMDist"), 
                    .combine = "rbind", 
                    .export = ".parDist2", 
                    .inorder = TRUE, .verbose=FALSE, .options.snow = opts
                    ) %dopar% {
                a <- as.numeric(ind[i,1])
                b <- as.numeric(ind[i,2])
                # deprecated Kusner et al. RWMD
                # dist <- text2vec::dist2(dtm[a:b,], pd, method = CMDist::kusnerRWMD$new(wem, method), norm = 'none')
                # Linear Complexity RWMD
                dist <- text2vec::RWMD$new(dtm[a:b,], wem)$sim2(pd)
                dist <- t(dist[1:nrow(pd)-1, , drop=FALSE])
                }
            # Clean-up
            close(pb)
            return(dist)
        }

