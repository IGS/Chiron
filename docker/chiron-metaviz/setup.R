source("https://bioconductor.org/biocLite.R")
biocLite(c("phyloseq", "metagenomeSeq"))
install.packages("devtools", repos='http://cran.revolutionanalytics.com/')
install.packages("devtools", repos='http://cran.revolutionanalytics.com/')
install.packages("tidyverse", repos='http://cran.revolutionanalytics.com/')
install.packages("RNeo4j", repos='http://cran.revolutionanalytics.com/')
library(devtools)
install_github("epiviz/metavizr@chiron", dependencies=TRUE)

