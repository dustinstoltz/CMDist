#The most recent version of text2vec changed the underlying algorithm for calculating distances between two documents. 
#Rather than the Relaxed Word Mover's Distance (RWMD) as discussed in Kusner et al's (2015) "From Word Embeddings To 
#Document Distances", it now uses the Linear-Complexity Relaxed Word Mover's Distance (LC-RWMD) as described by 
#Atasu et al. (2017) paper. While LC-RWMD decreases computational demands, the decrease in accuracy renders it unusuable 
#for the kind of conceptual engagement Concept Mover's Distance measures. Therefore, we incorporated code from an 
#older version (0.5.1) of text2vec written by Dmitriy Selivanov directly into the CMDist package. For more information, 
#see Selivanov's text2vec website (http://text2vec.org/index.html). 

  ### From text2vec 0.5.1, by Dmitriy Selivanov:
      
      # we assume wv matrix is already normalized. In this case L2 normalized
      # wv - word vectors matrix (WORDS = COLUMNS, because faster subsetting!)
        cosine_dist_internal = function(m_i, m_j) {
          1 - crossprod(m_i, m_j)
        }

      # we assume wv matrix is already normalized. In this case L2 normalized
      # wv - word vectors matrix (WORDS = COLUMNS, because faster subsetting!)
        euclidean_dist_internal = function(m_i, m_j) {
          euclidean_dist(m_i, m_j)
        }

        dist_internal = function(m_i, m_j, method) {
          switch(method,
                cosine = cosine_dist_internal(m_i, m_j),
                euclidean = euclidean_dist_internal(m_i, m_j))
        }

  text2vec_dist = R6::R6Class(
      classname = "distance_model",
      public = list(
        dist2 = function(...) {stop("Method is not implemented")},
        progressbar = TRUE
      ),
      private = list(
        internal_matrix_format = NULL
      )
    )
#' @name KusnerRelaxedWordMoversDistance
#' @title Creates model which can be used for calculation of "relaxed word movers distance".
KusnerRelaxedWordMoversDistance = R6::R6Class(
    classname = "RWMD",
    inherit = text2vec_dist,
    public = list(
      initialize = function(wv, method = c('cosine', 'euclidean'), normalize = TRUE, progressbar = interactive()) {
        stopifnot(is.matrix(wv))
        stopifnot(is.numeric(wv))
        stopifnot(is.logical(normalize) && is.logical(progressbar))

        private$internal_matrix_format = 'RsparseMatrix'
        private$method = match.arg(method)
        self$progressbar = progressbar
        # make shure  that word vectors are L2 normalized
        # and transpose them for faster column subsetting
        # R stores matrices in column-major format
        private$wv = t(as.matrix(normalize(wv, "l2")))
      },
    dist2 = function(x, y) {
      stopifnot( inherits(x, "sparseMatrix") && inherits(y, "sparseMatrix"))
      stopifnot( colnames(x) == colnames(y) )
      # take only words that appear both in word vectors
      terms = intersect(colnames(x), colnames(private$wv))
      # make sure we don't have empty string - matrices doesn't allow subsetting by empty string
      terms = setdiff(terms, "")
      wv_internal = private$wv[, terms, drop = FALSE]
      # convert matrices in row-major format
      x_csr =  normalize(x[, terms, drop = FALSE], "l1")
      x_csr =  as(x_csr, private$internal_matrix_format)

      y_csr = normalize(y[, terms, drop = FALSE], "l1")
      y_csr = as(y_csr, private$internal_matrix_format)

      if (self$progressbar)
      pb = txtProgressBar(initial = 1L, min = 2L, max = length(x_csr@p), style = 3)
      # preallocate resulting matrix
      res = matrix(Inf, nrow = nrow(x_csr), ncol = nrow(y_csr))
      # main loop
      for (j in 2L:(length(x_csr@p))) {
        if (self$progressbar) setTxtProgressBar(pb, j)
        i1 = (x_csr@p[[j - 1]] + 1L):x_csr@p[[j]]
        j1 = x_csr@j[i1] + 1L
        m_j1 = wv_internal[, j1, drop = FALSE]
        x1 = x_csr@x[i1]

        dist_matrix = dist_internal(m_j1, wv_internal, private$method)
        for (i in 2L:(length(y_csr@p))) {
          # document offsets
          i2 = (y_csr@p[[i - 1L]] + 1L):y_csr@p[[i]]
          # word indices
          j2 = y_csr@j[i2] + 1L
          # nbow values
          x2 = y_csr@x[i2]
          res[j - 1L, i - 1L] = private$rwmd_cache(dist_matrix[, j2, drop = FALSE], x1, x2)
        }
      }
      if (self$progressbar) close(pb)
      res
    }
  ),
  private = list(
    wv = NULL,
    method = NULL,
    # workhorse for rwmd calculation
    rwmd = function(m_i, m_j, weight_i, weight_j) {
      dist_matrix = dist_internal(m_i, m_j, private$method)
      d1 = sum( text2vec:::rowMins(dist_matrix) * weight_i)
      d2 = sum( text2vec:::colMins(dist_matrix) * weight_j)
      max(d1, d2)
    },
    rwmd_cache = function(dist_matrix, weight_i, weight_j) {
      d1 = sum( text2vec:::rowMins(dist_matrix) * weight_i)
      d2 = sum( text2vec:::colMins(dist_matrix) * weight_j)
      max(d1, d2)
    }
  )
)

#' @rdname KusnerRelaxedWordMoversDistance
#' @export
kusnerRWMD = KusnerRelaxedWordMoversDistance
