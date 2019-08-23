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

To use the Concept Mover's Distance (CMD) function, you will need to transform your corpus into a document-term matrix (DTM). The preferred DTM is a sparse matrix as output by `text2vec` and `tidytext`'s `cast_sparse` function, but we have tried to make the package accommodate DTMs made with the `tm`, `udpipe`, or `Quanteda` package or a regular old base R matrix.

##  Word Embeddings Matrix

You will also need a matrix of word embeddings vectors (with the "words" as rownames), and ultimately, CMD is only as good as the word embeddings used. 

Word embeddings vectors can be from a __pre-trained source__, for example, https://nlp.stanford.edu/projects/glove/ or https://fasttext.cc/docs/en/english-vectors.html. It might take little data wrangling to get them loaded as a matrix in R with rownames as the words.

You can also create your own embeddings trained on the corpus on which you are using CMD -- i.e. __corpus-trained embeddings__. For example, the `text2vec` R package uses the GloVe method to train embeddings. As we discuss in our paper, the decision to use pre-trained vs corpus-trained is understudied as applied in the social-scientific context.

One important caveat: the word used to denote a concept need not be in the corpus, _but it must be in the word embeddings matrix_. If it is not, the function will stop and let you know. This means, obviously, that corpus-trained embeddings cannot be used with words not in the corpus (pre-trained must be used).

## USE

### Selecting Terms Denoting Focal Concepts

The most difficult and important part of using Concept Mover's Distance is selecting terms that denote the concepts of interest. This should be driven by (a) theory, (b) prior literature, (c) domain knowledge, (d) the word embedding space. One way of double-checking that selected terms are approriate is to look at the term's nearest neighbors. Here we use the `sim2` function from `text2vec` to get the cosine distance between "thinking" and its top 10 nearest neighbors.

```r
    
    cos.sim = text2vec::sim2(x = my.wv, y = my.wv["thinking", , drop = FALSE], method = "cosine")
    
    head(sort(cos.sim[,1], decreasing = TRUE), 10)

```

### Single Word

Once you have a DTM, word vector matrix and terms denoting focal concepts, the simplest use of `CMDist` involves finding the closeness to a focal concept denoted by a _single word_. Here, we use the word "thinking."

```r
  
  doc.closeness <- CMDist(dtm = my.dtm, cw = "thinking", wv = my.wv)

```

### Compound Concepts

However, we may be interested in specifying the concept somewhat with additional words: for example, we might want to capture "critical thinking." To handle this, it is as simple as specifying both words separated by a space in the quotes. This creates a pseudo-document that contains only "critical" and "thinking."

```r
  
  doc.closeness <- CMDist(dtm = my.dtm, cw = "critical thinking", wv = my.wv)

```

### Ngrams

What if instead of a compound concept we are interested in a common concept represented with two words (i.e., a bigram)? First, just like with any other word, the ngram must be in the set of embeddings (the fastText pre-trained embeddings have a lot of n&ge;1 grams). As long as the ngram is in the embeddings, the only difference for `CMDist` is that an underscore rather than a space needs to be placed between words: 

```r
  
  doc.closeness <- CMDist(dtm = my.dtm, cw = "critical_thinking", wv = my.wv)

```
### Multiple Distances at Once

An analysis might suggest multiple concepts are of interest. As running CMD can take some time, it is useful to get multiple distances at the same time. This, in effect, is adding more rows to our pseudo-document-term matrix. For example, in our _JCSS_ paper, we compare how Shakespeare's plays engage with "death" against 200 other concepts.

```r

  # example 1
  concept.words <- c("thinking", "critical", "thought")
  doc.closeness < CMDist(dtm = my.dtm, cw = concept.words, wv = my.wv)
  
  # example 2
  concept.words <- c("critical thought", "critical_thinking")
  doc.closeness < CMDist(dtm = my.dtm, cw = concept.words, wv = my.wv)

```
## OPTIONS

### Performance and Parallel CMDist

Calculating `CMD` relies on `RWMD`, and while it is a more efficient rendering of Word Mover's Distance, it is still a very complex process and thus takes a while. One way to reduce complexity and thus time (without a noticeable drop in accuracy) is by removing very sparse terms in your DTM. Parallelizing is another option, so we decided to build it in. To use parallel calculations just set `parallel = TRUE`. The default number of threads is 2, but you can set it as high as you have threads/cores (but usually you want to use less than your maximum).

```r
  
  doc.closeness <- CMDist(dtm = my.dtm, cw = "critical_thinking", wv = my.wv, 
                          parallel = TRUE, threads = 2)

```

As you can see from the figure below, there is an overhead to setting up parallel processing and the pay off is only really gained with larger matrices. When the DTM has about 5000 documents, their begins to be performance improvements with parallizing. However, specifying 6 threads doesn't have much more of an improvement over 2 threads, but we presume this is not the case for DTMs with document numbers above the limit of our example.

<img align="middle" src="https://github.com/dustinstoltz/CMDist/blob/master/images/Figure_CMD_performance.png?raw=true" width="800" height="600">
_Note: These estimates are based off single runs of each size and thread count (so take with a grain of salt). The DTM is based on a large sample of news articles and with sparesness set to 0.99, the vocabulary size (i.e. the number of columns) was 4,869 (which is on the low end for text analysis)._


### Scaling Output and Vector Comparison Metric

The function comes with a few additional options. First, by default, the closeness scores are normalized using the `scale()` function in R. If this is not desired, set `scale = FALSE`.  Second, the default vector comparison metric in `text2vec`'s `RWMD` implementation is __cosine__, but the original Word Mover's Distance paper which our approach is based off used __Euclidean__ distance to compare word embeddings vectors. Therefore, the default is `method = "cosine"`, but can be set to Euclidean.

```r
  
  doc.closeness <- CMDist(dtm = my.dtm, cw = "thinking", wv = my.wv, 
                          scale = FALSE, method = "euclidean")

```



For more discussion of the math behind the measure see Stoltz and Taylor (2019) "[Concept Mover's Distance](https://link.springer.com/article/10.1007/s42001-019-00048-6)" in the _Journal of Computational Social Science_. The replication code and data for that paper can be found here: https://github.com/dustinstoltz/concept_movers_distance_jcss

### --------------------------------------------------------
