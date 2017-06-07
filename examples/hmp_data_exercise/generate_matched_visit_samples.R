library(reshape2)
require(getopt)

# R Script to take a list of 16S samples and WGS samples and randomly generates a matched list
# of samples that can be used for comparison for a particular visit and body site
library("getopt")

# Get the options specified on the command line
spec = matrix(c('m16s', 's', 1, "character",
                'wgs', 'w', 1, "character",
                'bodysite', 'b', 1, "character",
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

if ( is.null(opt$wgs) ) {
  print("WGS metadata file not specified.\n")
  cat(getopt(spec, usage=TRUE));
  q(status=1);
}

if ( is.null(opt$bodysite) ) {
  print("Body site not specified.\n")
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
wgs_metafile = opt$wgs
body_site = opt$bodysite
visit = opt$visit
count = opt$count

# setwd("/Users/amahurkar/Documents/Projects/DACC/CloudPilot")
# wgs_metafile = "wgs_metadata.tsv"
# m16s_metafile = "16s_metadata.tsv"
# visit = 1
# count = 20
# body_site = "Stool"

# Read the metadata files
wgs_sample_info = read.table(wgs_metafile, sep = "\t", header = TRUE)
m16s_sample_info = read.table(m16s_metafile, sep = "\t", header = TRUE)
v35_samples = m16s_sample_info[which(m16s_sample_info$Region == "V35"), ]

# Merge the WGS and 16S and then get the subjects and visits for which we have 16S and WGS data
merged_used = rbind(wgs_sample_info[, 1:7], v35_samples[, 1:7])
merged_table = dcast(merged_used, RSID + Gender + STSite + Visit ~ Type, length)
merged_table$Both = ifelse(merged_table$`16S` > 0 & merged_table$WGS > 0, 1, 0)
colnames(merged_table) = c("RSID", "Gender", "STSite",  "Visit",   "m16S",     "WGS",     "Both")

# Generate the list of samples from the visit for the body site
visit_samples = subset(merged_table, (STSite == body_site & Visit == visit & Both == 1))
visit_subset = merge(merged_used, visit_samples[, c("RSID", "Gender", "STSite", "Visit")],
                           by = c("RSID", "Gender", "STSite", "Visit"))

# Generate a set of IDs for the three body sites randomly from the list
filename = paste(body_site, "_rand_samples.txt", sep = "")
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
write.table(file = filename, subset_of_samples, 
            sep = "\t", quote = FALSE, row.names = FALSE, col.names = TRUE)




