# R Script to subset the Qiime and MetaPhlAn matrices to extract the samples specified
# in the input sample list file
library("getopt")

# Get the options specified on the command line
spec = matrix(c('qiime', 'q', 1, "character",
                'metaphlan', 'm', 1, "character",
                'samples', 's', 1, "character",
                'help', 'h', 0, "logical"
                ), 
              byrow = TRUE, ncol=4)
opt = getopt(spec)

if ( !is.null(opt$help) ) {
  cat(getopt(spec, usage=TRUE));
  q(status=1);
}

if ( is.null(opt$qiime) ) {
  print("Qiime OTU table missing.\n")
  cat(getopt(spec, usage=TRUE));
  q(status=1);
}

if ( is.null(opt$samples) ) {
  cat("Samples file missing.\n")
  cat(getopt(spec, usage=TRUE));
  q(status=1);
}

if ( is.null(opt$metaphlan) ) {
  cat("MetaPhlAn table missing.\n")
  cat(getopt(spec, usage=TRUE));
  q(status=1);
}

qiime_file = opt$qiime
metaphlan_file = opt$metaphlan
samples_file = opt$samples

# setwd("/Users/amahurkar/Documents/Projects/DACC/CloudPilot")
# qiime_file = "v35_psn_otu.genus.fixed.txt"
# samples_file = "Stool_rand_samples.txt"
# metaphlan_file = "hmp1-II_metaphlan2-mtd-qcd.pcl.txt"

# Read the samples file
samples = read.csv(samples_file, sep = "\t", header = TRUE, 
                   stringsAsFactors = FALSE)

# Read the metaphlan table
mphlan = read.csv(metaphlan_file, sep = "\t", header = TRUE, 
                  stringsAsFactors = FALSE)

# Filter the Metaphlan table for the samples in the list
subsample_list = samples[which(samples$Type == "WGS"), ]
subsample_list$SampleName = paste("X", subsample_list$SN, sep = "")
col_list = colnames(mphlan)
indices = which(col_list %in% subsample_list$SampleName)
subsamples = mphlan[, c(1, indices)]
write.csv(file = paste("subset_of_", metaphlan_file, sep = ""), subsamples, 
          row.names = FALSE, quote = FALSE)

# Read Qiime table
qiime = read.csv(qiime_file, sep = "\t", header = TRUE, 
                 stringsAsFactors = FALSE)

# Filter the Qiime table for the samples in the list
subsample_list = samples[which(samples$Type == "16S"), ]
subsample_list$SampleName = paste("X", subsample_list$PSN, sep = "")
col_list = colnames(qiime)
indices = which(col_list %in% subsample_list$SampleName)
subsamples = qiime[, c(1, indices, ncol(qiime))]
write.csv(file = paste("subset_of_", qiime_file, sep = ""), subsamples, 
          row.names = FALSE, quote = FALSE)
