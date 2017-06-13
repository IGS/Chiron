library(reshape2)
library(getopt)
library(dplyr)

# R Script to take a list of 16S samples and randomly generates a matched list
# of samples that can be used for comparison across two bodysites
library("getopt")

# Get the options specified on the command line
spec = matrix(c('m16s', 's', 1, "character",
                'outfile', 'o', 1, "character",
                'bodysite1', 'a', 1, "character",
                'bodysite2', 'b', 1, "character",
                'region', 'r', 1, "character",
                'visit', 'v', 1, "integer",
                'count', 'c', 1, "integer",
                'help', 'h', 0, "logical"
), 
byrow = TRUE, ncol=4)
opt = getopt(spec)

if ( !is.null(opt$help) ) {
  cat(getopt(spec, usage=TRUE));
  q(status=1);
}

if ( is.null(opt$m16s) ) {
  print("16S metadata file not specified.\n")
  cat(getopt(spec, usage=TRUE));
  q(status=1);
}

if ( is.null(opt$bodysite1) ) {
  print("Body site 1 not specified.\n")
  cat(getopt(spec, usage=TRUE));
  q(status=1);
}

if ( is.null(opt$bodysite2) ) {
  print("Body site 2 not specified.\n")
  cat(getopt(spec, usage=TRUE));
  q(status=1);
}

if ( is.null(opt$outfile) ) {
  print("Output file not specified.\n")
  cat(getopt(spec, usage=TRUE));
  q(status=1);
}

if ( is.null(opt$region) ) {
  print("16S region not specified.\n")
  cat(getopt(spec, usage=TRUE));
  q(status=1);
}

if ( is.null(opt$visit) ) {
  cat("Visit not specified.\n")
  cat(getopt(spec, usage=TRUE));
  q(status=1);
}

if ( is.null(opt$count) ) {
  cat("Count of samples not specified.\n")
  cat(getopt(spec, usage=TRUE));
  q(status=1);
}

m16s_metafile = opt$m16s
body_site1 = opt$bodysite1
body_site2 = opt$bodysite2
outfile = opt$outfile
visit = opt$visit
count = opt$count
region = opt$region

setwd("/Users/amahurkar/Documents/Projects/DACC/CloudPilot")
m16s_metafile = "16s_metadata.tsv"
visit = 1
count = 20
body_site1 = "Stool"
body_site2 = "Anterior_nares"
region = "V35"
outfile = "stool_nares_subsamples.tsv"

# Read the metadata files
m16s_sample_info = read.table(m16s_metafile, sep = "\t", header = TRUE)
region_site_samples = m16s_sample_info[which(m16s_sample_info$Region == region & 
                                               (m16s_sample_info$STSite == body_site1 | 
                                                  m16s_sample_info$STSite == body_site2)), 
                                       ]
merged_table = dcast(region_site_samples, RSID + Gender + Visit ~ STSite, length)
colnames(merged_table) = c("RSID", "Gender", "Visit", "Site1", "Site2")
merged_table$Both = ifelse(merged_table$Site1 > 0 & merged_table$Site2 > 0, 1, 0)

# Generate the list of samples from the visit for the body site
visit_samples = subset(merged_table, (Visit == visit & Both == 1))
visit_samples = na.omit(visit_samples)
visit_subset = merge(region_site_samples, visit_samples[, c("RSID", "Gender", "Visit")],
                           by = c("RSID", "Gender", "Visit"))

# Generate a set of IDs for the three body sites randomly from the list
unique_subject_ids = unique(visit_subset$RSID)
rowcount = length(unique_subject_ids)

# If the number of subjects is below threshold requested then quit
if (rowcount < count) {
  cat("Count of subjects specified: ", count, " is less than unique subjects in files.\n")
  q(status=1)
}

rand = sample(1:rowcount, count, replace=FALSE)
subjects = data.frame(unique_subject_ids[rand])
colnames(subjects) = c("RSID")
subset_of_samples = visit_subset[which(visit_subset$RSID %in% subjects$RSID), ]
write.table(file = outfile, subset_of_samples, 
            sep = "\t", quote = FALSE, row.names = FALSE, col.names = TRUE)




