# R Script to subset the Qiime matrices to extract the samples specified
# in the input sample list file
library("getopt")

# Get the options specified on the command line
spec = matrix(c('qiime', 'q', 1, "character",
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

if ( is.null(opt$outfile) ) {
  print("Output file not specified.\n")
  cat(getopt(spec, usage=TRUE));
  q(status=1);
}

qiime_file = opt$qiime
samples_file = opt$samples
outfile = opt$outfile

# setwd("/Users/amahurkar/Documents/Projects/DACC/CloudPilot")
# qiime_file = "otu_table_psn_v35.txt"
# samples_file = "stool_nares_subsamples.tsv"
# outfile = paste("stool_nares_subsamples_", qiime_file, sep = "")

# Read the samples file
samples = read.csv(samples_file, sep = "\t", header = TRUE, 
                   stringsAsFactors = FALSE)

# Read Qiime table
qiime = read.csv(qiime_file, sep = "\t", header = TRUE, comment.char = "",
                 stringsAsFactors = FALSE, skip = 1)

# Filter the Qiime table for the samples in the list
subsample_list = samples[which(samples$Type == "16S"), ]
subsample_list$SampleName = paste("X", subsample_list$PSN, sep = "")
col_list = colnames(qiime)
indices = which(col_list %in% subsample_list$SampleName)
subsamples = qiime[, c(1, indices, ncol(qiime))]
write.csv(file = outfile, subsamples, 
          row.names = FALSE, quote = FALSE)
