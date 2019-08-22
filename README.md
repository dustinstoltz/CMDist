# CMDist: quick start guide
R package for Concept Mover's Distance

[Dustin S. Stoltz](https://www.dustinstoltz.com) and [Marshall A. Taylor](https://www.marshalltaylor.net)

<img align="middle" src="https://images.squarespace-cdn.com/content/v1/57cf17802e69cf96e1c4f406/1554677109807-MDCV0XG0BIQHJHIWTLCP/ke17ZwdGBToddI8pDm48kH34NSqJ76-ixS257mGaUjh7gQa3H78H3Y0txjaiv_0fDoOvxcdMmMKkDsyUqMSsMWxHk725yiiHCCLfrh8O1z5QHyNOqBUUEtDDsRWrJLTmxXXTZVXzkeXI_1XN_RfG8mev2iBWWK1p2MzLH4LINwAedhRYPgYfymgS9t3aYSzh/2019_Stoltz_Taylor_concept_movers_distance.png?format=1500w" width="800" height="500">


Install and load the textSpan package from GitHub:
```{r}
  # install.packages("devtools")
  devtools::install_github("dustinstoltz/CMDist")
  library(CMDist)

```

## Document-Term Matrix and Word Embeddings Vectors

To use Concept Mover's Distance (CMD) function, you will need a document-term matrix (DTMs) and a matrix of word embeddings vectors (with the "words" as rownames). DTMs can be made either with the tm, text2vec or Quanteda package. Ultimately, CMD is only as good as the word embeddings used.

Word embeddings vectors can be from a __pre-trained source__, for example, https://nlp.stanford.edu/projects/glove/ or https://fasttext.cc/docs/en/english-vectors.html. It might take little data wrangling to get them loaded as a matrix in R with rownames as the words.

You can also create your own embeddings trained on the corpus on which you are using CMD -- i.e. __corpus-trained embeddings__. For example, the text2vec R package uses the GloVe method to train embeddings. 

One important caveat: the word used to denote a concept need not be in the corpus, _but it must be in the word embeddings matrix_. If it is not, the function will stop and let you know. This means, obviously, that corpus-trained embeddings cannot be used with words not in the corpus (pre-trained must be used).

## Single Word

Once you have a DTM and word vector matrix, the simplest use of CMDist involves finding the distance from a focal concept denoted by a _single word_. Here, we use the word "word1."

```{r}
  
  doc.distances <- CMDist(dtm = my.dtm, cw = "word1", wv = my.wv)

```

## Compound Concepts

However, we may be interested in specifying the concept somewhat by addition additional terms. For example, "healthy breakfast" -- and it is as simple as putting both words, separated by a space in the quotes.

```{r}
  
  doc.distances <- CMDist(dtm = my.dtm, cw = "word1 word2", wv = my.wv)

```

## Ngrams

What if instead of a compound concept we are interested in a common concept represented with two words (i.e. a bigram)? First, just like with any other word, ngram must be in the set of embeddings (the fastText pre-trained embeddings have a lot of ngrams). As long as the ngram is in the embeddings, the only difference for CMD is that an underscore rather than a space needs to be placed between words: 

```{r}
  
  doc.distances <- CMDist(dtm = my.dtm, cw = "word1_word2", wv = my.wv)

```


## Parallel CMDist

Calculating CMD relies on text2vec's RWMD, and while it is a more efficient rendering of Word Mover's Distance, it is still a very complex process and thus takes a while. One way to reduce complexity and thus time (without a noticeable drop in accuracy) is by removing very sparse terms in your DTM.. Parallelizing is another option, so we decided to build it in. To use parallel calculations just set parallel = TRUE. The default number of threads is 2, but you can set it as high as you have threads/cores (but usually you want to use less than your maximum).

```{r}
  
  doc.distances <- CMDist(dtm = my.dtm, cw = "word1_word2", wv = my.wv, parallel = TRUE, threads = 2)

```
## Multiple Distances at Once

An analysis might suggest multiple concepts are of interest. As running CMD can take some time, it is useful to get multiple distances at the same time. This, in effect, is adding more rows to our pseudo-document-term matrix. For example, in our JCSS paper, we compare Shakespeare's play's engagement with "death" against 200 other concepts.

```{r}

  concept.words <- c("word1", "word2", "word3")
  
  doc.distances < CMDist(dtm = my.dtm, cw = concept.words, wv = my.wv)
  
  concept.words <- c("word1 word2", "word2_word3")
  
  doc.distances < CMDist(dtm = my.dtm, cw = concept.words, wv = my.wv)

```

For more discussion see Stoltz and Taylor (2019) "[Concept Mover's Distance](https://link.springer.com/article/10.1007/s42001-019-00048-6)" in the _Journal of Computational Social Science_. The replication code and data can be found here: https://github.com/dustinstoltz/concept_movers_distance_jcss

### --------------------------------------------------------
