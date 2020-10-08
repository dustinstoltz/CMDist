# CMDist: quick start guide
R package for Concept Mover's Distance, a measure of concept engagement in texts via word embeddings.

[Dustin S. Stoltz](https://www.dustinstoltz.com) and [Marshall A. Taylor](https://www.marshalltaylor.net)

<img align="middle" src="https://github.com/dustinstoltz/CMDist/blob/master/images/Figure_sotu_family_time.png?raw=true" width="800" height="600">

## Installing

Install and load the `CMDist` package from GitHub:
```r
  # install.packages("devtools")
  devtools::install_github("dustinstoltz/CMDist")
  library(CMDist)

```

## Document-Term Matrix

To use the Concept Mover's Distance (CMD) function, you will need to transform your corpus into a document-term matrix (DTM). The preferred DTM is a sparse matrix as output by `text2vec`, `udpipe`, and `tidytext`'s `cast_sparse` function, but we have tried to make the package accommodate DTMs made with the `tm` or `Quanteda` package or a regular old base R matrix.

##  Word Embeddings Matrix

You will also need a matrix of word embeddings vectors (with the "words" as rownames), and ultimately, CMD is only as good as the word embeddings used. Word embedding vectors can be from a __pre-trained source__, for example:
* [Stanford NLP GloVe vectors](https://nlp.stanford.edu/projects/glove/)
* [fastText (Various) English word vectors](https://fasttext.cc/docs/en/english-vectors.html)
* [fastText Wiki and Common Crawl vectors for 294 languages](https://fasttext.cc/docs/en/pretrained-vectors.html)
* [HistWords: Word Embeddings for Historical Text](https://nlp.stanford.edu/projects/histwords/)
* [word2vec GoogleNews vectors](https://drive.google.com/file/d/0B7XkCwpI5KDYNlNUTTlSS21pQmM/edit?usp=sharing)
* [NLPL word embeddings repository](http://vectors.nlpl.eu/repository/)

It will take a little data wrangling to get these loaded as a matrix in R with rownames as the words, or you can just download these R-ready fastText English Word Vectors trained on the Common Crawl (crawl-300d-2M.vec) hosted on Google Drive: 

```r
    library(googledrive) # (see https://googledrive.tidyverse.org/)
    temp <- tempfile()
    drive_download(as_id("1DRBCzd_b_syadZiMxypUnwbNEcsDl2Wg"), path = temp, overwrite = TRUE)
    my.wv <- readRDS(temp)
```

You can also create your own embeddings trained on the corpus on which you are using CMD -- i.e. __corpus-trained embeddings__. For example, the `text2vec` R package uses the GloVe method to train embeddings. As we discuss in our paper, the decision to use pre-trained vs corpus-trained is understudied as applied in the social-scientific context.

One important caveat: the terms used to denote a concept or build a semantic direction need not be in the corpus, _but it must be in the word embeddings matrix_. If it is not, the function will stop and let you know. This means, obviously, that corpus-trained embeddings cannot be used with words not in the corpus (pre-trained must be used).

## Getting CMDs

### Selecting Terms Denoting Focal Concepts

The most difficult and important part of using Concept Mover's Distance is selecting terms. This should be driven by (a) theory, (b) prior literature, (c) domain knowledge, and (d) the word embedding space. One way of double-checking that selected terms are approriate is to look at the term's nearest neighbors. Here we use the `sim2` function from `text2vec` to get the cosine distance between "thinking" and its top 10 nearest neighbors.

```r
    
    cos.sim <- text2vec::sim2(x = my.wv, y = my.wv["thinking", , drop = FALSE], method = "cosine")
    
    head(sort(cos.sim[,1], decreasing = TRUE), 10)

```

### Single Word

Once you have a DTM and word embedding matrix, the simplest use of `CMDist` involves finding the closeness to a focal concept denoted by a _single word_. Here, we use the word "thinking" as our concept word ("cw"):

```r
  
  doc.closeness <- CMDist(dtm = my.dtm, cw = "thinking", wv = my.wv)

```

### Compound Concepts

However, we may be interested in _specifying_ the concept with additional words: for example, we might want to capture "critical thinking." To handle this, it is as simple as including both words separated by a space in the quotes. This creates a pseudo-document that contains only "critical" and "thinking."

```r
  
  doc.closeness <- CMDist(dtm = my.dtm, cw = "critical thinking", wv = my.wv)

```

### Ngrams

What if instead of a compound concept we are interested in a common concept represented with two words (i.e., a bigram)? First, just like with any other word, the ngram must be in the embedding matrix (the fastText pre-trained embeddings have a lot of n&ge;1 grams). As long as the ngram is in the embeddings, the only difference for `CMDist` is that an underscore rather than a space needs to be placed between words: 

```r
  
  doc.closeness <- CMDist(dtm = my.dtm, cw = "critical_thinking", wv = my.wv)

```

### Semantic Directions and Centroids

In the original _JCSS_ paper, we discussed the "binary concept problem," where documents that are close to a concept with a binary opposite will likely also be close to both opposing poles. For example if a document is close to "love" it will also be close to "hate." But, very often an analyst will want to know whether a document is close to one pole or the other of this binary concept. To deal with this we incorporate insights from Kozlowski et al's (2019) paper ["Geometry of Culture"](https://journals.sagepub.com/doi/full/10.1177/0003122419877135) to define "semantic directions" within word embeddings -- i.e. pointing toward one pole and away from the other. We outline this procedure in more detail in a subsequent _JCSS_ paper ["Integrating Semantic Directions with Concept Mover's Distance to Measure Binary Concept Engagement"](https://osf.io/preprints/socarxiv/36r2d/). 

The procedure involves generating a list of antonym pairs for a given binary concept -- that is, terms which may occur in similar contexts but are typically juxtaposed. Then we get the differences between these antonyms' respective vectors, and averaging the result (the `get_direction()`--previously called `get_antodim()`--function takes care of this). The resulting vector will be the location of a one "pole" of this binary concept, and `CMDist` calculates the distance each document is from this concept vector ("cv").

```r
  # first build the semantic direction:
  additions  <- c("death", "casualty", "demise", "dying", "fatality")
  substracts <- c("life", "survivor", "birth", "living", "endure")

  pairs <- cbind(additions, substracts)
  death.sd <- get_direction(pairs, my.wv)
  
  # input it into the function just like a concept word:
  doc.closeness <- CMDist(dtm = my.dtm, cv = death.sd, wv = my.wv)

```

Instead of building a pseudo-document with several terms, as in the compound concept section above, one could also average several terms together to arrive at a "centroid" in the word embedding space -- this can be understood as referring to the center of a "semantic region." Again, `CMDist` will calculate the distance each document is from this concept vector ("cv").

```r
  # first build the semantic centroid:
  terms  <- c("death", "casualty", "demise", "dying", "fatality")
  
  death.sc <- get_centroid(terms, my.wv)
  
  # input it into the function just like a concept word:
  doc.closeness <- CMDist(dtm = my.dtm, cv = death.sc, wv = my.wv)

```

## Concept Class Analysis

Concept Class Analysis (CoCA) is a method for grouping documents based on their schematic similarities in their engagement with multiple semantic directions. This is a generalization of [Correlational Class Analysis](https://sociologicalscience.com/articles-v4-15-353/) for survey data. We outline this method in more detail in a forthcoming _Sociological Science_ paper, "Concept Class Analysis: A Method for Identifying Cultural Schemas in Texts."

The first step to use CoCA is build two or more semantic directions. For example, here are three semantic directions related to socio-economic status:

```r
    # build juxtaposed pairs for each semantic directions
    pairs.01 <- data.frame(additions  = c("rich", "richer", "affluence", "wealthy"),
                           substracts = c("poor", "poorer", "poverty", "impoverished") )

    pairs.02 <- data.frame(additions  = c("skilled", "competent", "proficient", "adept"),
                          substracts = c("unskilled", "incompetent", "inproficient", "inept") )
    
    pairs.03 <- data.frame(additions  = c("educated", "learned", "trained", "literate"),
                           substracts = c("uneducated", "unlearned", "untrained", "illiterate") )
    
    # get the vectors for each direction
    sd.01 <- get_direction(pairs.01, my.wv)
    sd.02 <- get_direction(pairs.02, my.wv)
    sd.03 <- get_direction(pairs.03, my.wv)

    # row bind each direction
    sem.dirs <- rbind(sd.01, sd.02, sd.03)
````
Next, we feed our document-term matrix, word embeddings matrix, and our semantic direction dataframe from above to the `CoCA` function:

```r
  classes <- CMDist::CoCA(my.dtm, wv = my.wv, directions = sem.dirs)
  print(classes)
```

Finally, using the `plot()` function, we can generate simple visualizations of the schematic classes found:

```r
  # this is a quick plot. 
  # designate which module to plot with `module = `
  plot(classes, module=1)
```


## Other Options and Considerations

### Multiple Distances at Once

An analysis might suggest multiple concepts are of interest. As running CMD can take some time, it is useful to get multiple distances at the same time. This, in effect, is adding more rows to our pseudo-document-term matrix. For example, in our _JCSS_ paper, we compare how Shakespeare's plays engage with "death" against 200 other concepts. `CMDist` also incorporate both concept words and vectors into the same run.

```r

  # example 1
  concept.words <- c("thinking", "critical", "thought")
  doc.closeness < CMDist(dtm = my.dtm, cw = concept.words, wv = my.wv)
  
  # example 2
  concept.words <- c("critical thought", "critical_thinking")
  doc.closeness < CMDist(dtm = my.dtm, cw = concept.words, wv = my.wv)
    
  # example 3
  concept.words <- c("critical thought", "critical_thinking")
  doc.closeness < CMDist(dtm = my.dtm, cw = concept.words, cv = concept.vectors, wv = my.wv)

```

### Performance and Parallel CMDist

Calculating `CMD` (as of version 0.5.0) relies on [Linear Complexity RWMD](https://arxiv.org/abs/1711.07227) or `LC-RWMD`. The performance gain over the previous `RWMD` implementation is considerable. Nevertheless, it may be desireable to boost performance further on especially large projects. 

One way to reduce complexity and thus time (without a noticeable drop in accuracy) is by removing very sparse terms in your DTM. Parallelizing is another option, so we built it in. To use parallel calculations just set `parallel = TRUE`. The default number of threads is 2, but you can set it as high as you have threads/cores (but usually you want to use less than your maximum).

```r
  
  doc.closeness <- CMDist(dtm = my.dtm, cw = "critical_thinking", wv = my.wv, 
                          parallel = TRUE, threads = 2)

```
<!-- 
As you can see from the figure below (which shows how quickly a single concept word is estimated per run with different DTM sizes), there is an overhead to setting up parallel processing and the pay off is only really gained with larger matrices. When the DTM has about 5000 documents, there begins to be performance improvements with parallelizing. However, specifying 6 threads doesn't have much more of an improvement over 2 threads, but we presume this is not the case for DTMs with document numbers above the limit of our example.

<img align="middle" src="https://github.com/dustinstoltz/CMDist/blob/master/images/Figure_CMD_performance.png?raw=true" width="800" height="600">

*Note: These estimates are based off single runs of each size and thread count (so take with a grain of salt). The DTM is based on a large sample of news articles and with sparesness set to 0.99, the vocabulary size (i.e. the number of columns) was 4,869 (which is on the low end for text analysis).*
-->

### Scaling Output and Vector Comparison Metric

By default, the outputs are normalized using the `scale()` function in R. If this is not desired, set `scale = FALSE`.  

```r
  
  doc.closeness <- CMDist(dtm = my.dtm, cw = "thinking", wv = my.wv, scale = FALSE)
                          
```

The vector comparison metric in `text2vec`'s `LC-RWMD` implementation is __cosine__, but the Kusner et al. (2015) and Atasu et al. (2017) papers used __Euclidean__ distance to compare word embeddings vectors. The `LC-RWMD` implementation no longer includes the option of specifiying Euclidean distance, however, in all of our comparisons of CMD using Euclidean and cosine (under the previous RWMD implementation) the results were nearly identical.

### Note About Linear Complexity Relaxed Word Mover's Distance

The most recent version of `text2vec` changed the underlying algorithm for calculating distances between two documents. Rather than the Relaxed Word Mover's Distance (RWMD) as discussed in Kusner et al's  (2015) "From Word Embeddings To Document Distances", it now uses the Linear-Complexity Relaxed Word Mover's Distance (LC-RWMD) as described by Atasu et al. (2017) paper. LC-RWMD not only reduces the computational demands considerably, if we take the maximum of each document pair across the upper and lower triangles (i.e., the maximum of each [*i,j*]-[*j,i*] pair), the resulting symmetric distance matrix is precisely the same as the previous algorithm using Kusner et al's approach. As far as our tests have shown, the triangle corresponding to treating the pseudo-document as a "query" and the documents as a "collection" (see the [text2vec documentation](https://cran.r-project.org/web/packages/text2vec/text2vec.pdf), p. 28) will always return this set of maximums, and therefore there is no reason for the additional comparison step. If you have reason to believe this is not the case, please contact us and we will share the code necessary to reproduce results with the original Kusner et al. approach to check.

For more discussion of the math behind Concept Mover's Distance see Stoltz and Taylor (2019) "[Concept Mover's Distance](https://link.springer.com/article/10.1007/s42001-019-00048-6)" in the _Journal of Computational Social Science_. The replication code and data for that paper can be found here: https://github.com/dustinstoltz/concept_movers_distance_jcss

### THE END ----------------------------------------------------------
