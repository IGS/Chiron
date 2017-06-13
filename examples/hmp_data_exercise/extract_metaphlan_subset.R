# R Script to subset the Qiime and MetaPhlAn matrices to extract the samples specified
# in the input sample list file
library(getopt)

# Get the options specified on the command line
spec = matrix(c('metaphlan', 'm', 1, "character",
                'samples', 's', 1, "character",
                'outfile', 'o', 1, "character",
                'help', 'h', 0, "logical"
                ), 
              byrow = TRUE, ncol=4)
opt = getopt(spec)

if ( !is.null(opt$help) ) {
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

if ( is.null(opt$outfile) ) {
  print("Output file not specified.\n")
  cat(getopt(spec, usage=TRUE));
  q(status=1);
}

metaphlan_file = opt$metaphlan
samples_file = opt$samples
outfile = opt$outfile

# setwd("/Users/amahurkar/Documents/Projects/DACC/CloudPilot")
# samples_file = "stool_wgs_rand_samples.tsv"
# metaphlan_file = "hmp1-II_metaphlan2-mtd-qcd.pcl.txt"
# outfile = paste("stool_nares_subsamples_", metaphlan_file, sep = "")

# Read the samples file
samples = read.csv(samples_file, sep = "\t", header = TRUE, 
                   stringsAsFactors = FALSE)

# Read the metaphlan table
mphlan = read.csv(metaphlan_file, sep = "\t", header = TRUE, 
                  stringsAsFactors = FALSE, comment.char = "")

# Filter the Metaphlan table for the samples in the list
subsample_list = samples[which(samples$Type == "WGS"), ]
subsample_list$SampleName = paste("X", subsample_list$SN, sep = "")
col_list = colnames(mphlan)
indices = which(col_list %in% subsample_list$SampleName)
subsamples = mphlan[, c(1, indices)]
write.csv(file = outfile, subsamples, 
          row.names = FALSE, quote = FALSE)
