
.onAttach <- function(...) {

msg <- paste("The", sQuote("CMDist"), "package is deprecated as of August 2021.",
             "To use the Concept Mover's Distance method,", 
             "with improved functionality, please use",
             sQuote("text2map"), "instead. It is available on CRAN.", 
             "Run: install.packages('text2map'); remove.packages('CMDist')")

packageStartupMessage(msg)

}
