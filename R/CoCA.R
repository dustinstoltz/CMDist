#' Concept Class Analysis (CoCA) Function
#'
#' The function outputs schematic classes derived from the DTM.
#' @references \url{}
#' @param Function requires a document-term matrix, a matrix of word embeddings, and a matrix of word pair vector differences.
#' @examples classes <- CoCA(my.dtm, wv = my.wv, directions = death.sd, filter.sig = TRUE, filter.value = 0.05, zero.action = "drop")
#' @export
#' 
  CoCA <- function(dtm, wv = NULL, directions = NULL, filter.sig = TRUE, filter.value = 0.05, zero.action = c("drop", "ownclass"), verbose = TRUE) {
    
    if (verbose == TRUE) {
      
      cat("Estimating CMD scores across", nrow(directions), "semantic directions\n")
      cmds <- CMDist::CMDist(dtm = dtm, cv = directions, wv = wv, scale = TRUE)
      
      cat("Conducting CCA on the inter-document absolute Pearson correlations derived from the", nrow(directions), "semantic direction CMDs\n")
      classes <- corclass::cca(as.data.frame(cmds[,-1]), filter.sig, 
                               filter.value, zero.action, verbose = TRUE)
      class(classes) <- "CoCA"
      
      return(classes)
      
    } else {
      
      cmds <- CMDist::CMDist(dtm = dtm, cv = directions, wv = wv, scale = TRUE)
      
      classes <- corclass::cca(as.data.frame(cmds[,-1]), filter.sig, 
                               filter.value, zero.action, verbose = FALSE)
      class(classes) <- "CoCA"
      
      return(classes)
      
    }
  }
  
  print.CoCA <- function(x, ...) { #Modified from Boutyline's print.cca function in his corclass package
    
    cat("CoCA found", length(unique(x$membership)), "schematic classes in the corpus. Sizes:", table(x$membership), "\n")
    
    degen <- sapply(x$modules, function (m1) m1$degenerate)
    
    if (any(degen)) {
      cat("NOTE: result contains ", sum(degen), " degenerate class(es): ", 
          paste("#", which(degen), sep = "", collapse = " "), ".\n", sep="")
      
    }
    
  }
  
  plot.CoCA <- function(x, module = NULL, cutoff = 0.05, repulse = 1.86, 
                         min = .15, max = 1, main = NULL) { #Modified from Boutyline's plot.cca function in his corclass package
    
    if (missing(module)) {
      stop("Please specify the schematic class you'd like to plot using the 'module = ' argument.")
    }
    
    if(x$modules[[module]]$degenerate == TRUE) {
      stop(paste("Module #", module, " is degenerate (one or more column correlations are undefined).", sep = ""))
    }
    
    if (is.null(main)) {
      
      qgraph::qgraph(x$modules[[module]]$cormat,
                     graph = "cor",
                     minimum = min, maximum = max, threshold="sig", sampleSize = nrow(x$modules[[module]]$dtf), 
                     alpha = cutoff, layout = "spring", repulsion = repulse, label.cex = 2,
                     posCol = "black", negCol = "black", negDashed = T,
                     borders = T, shape = "circle", label.prop = 0.75,
                     curveAll = F, edge.labels = F, edge.label.cex = 0.45, esize = 8,
                     title = paste("Class #", module), labels = rownames(x$modules[[module]]$cormat)
      )
      
    } else {
      
      qgraph::qgraph(x$modules[[module]]$cormat,
                     graph = "cor",
                     minimum = min, maximum = max, threshold="sig", sampleSize = nrow(x$modules[[module]]$dtf), 
                     alpha = cutoff, layout = "spring", repulsion = repulse, label.cex = 2,
                     posCol = "black", negCol = "black", negDashed = T,
                     borders = T, shape = "circle", label.prop = 0.75,
                     curveAll = F, edge.labels = F, edge.label.cex = 0.45, esize = 8,
                     title = main, labels = rownames(x$modules[[module]]$cormat)
      )
      
    }
    
  }
  


    

