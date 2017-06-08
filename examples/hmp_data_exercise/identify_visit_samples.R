library(gdata)
library(ggplot2)
library(plyr)
library(reshape2)
library(doBy)
library(psych)
library(car)
library(xlsx)

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

setwd("/Users/amahurkar/Documents/Projects/DACC/")

sample_info = read.csv("PaperAnalysis/all_sample_info-2016-08-04.csv")
wgs_sample_info = sample_info[which(sample_info$Type == 'WGS'), ]
wgs_sample_info$VISNO = as.character(wgs_sample_info$VISNO)
wgs_sample_info$Visit = car::recode(wgs_sample_info$VISNO, 
                                    "c('3', '03S') = '3'; c('1', '01S', '01T') = '1'; c('2', '02S') = '2'")

# Read the replication list and only use samples from the QC passed list
qc_list = read.csv("PaperAnalysis/hmp1-II_replication.tab.cleaned", header = FALSE, sep = "\t")
qc_list = data.frame(qc_list[, c(1)])
colnames(qc_list) = c("SN")

# Remove replicates and failed QC from WGS list
wgs_sample_info = merge(qc_list, wgs_sample_info, by.x = "SN", by.y = "SN")
wgs_sample_info_used = wgs_sample_info
wgs_sample_info_used = wgs_sample_info_used[, c("RANDSID", "Gender", "STSite", "Visit", "Type", "SNPRNT", "SN", "SRS")]
colnames(wgs_sample_info_used) = c("RSID", "Gender", "STSite", "Visit", "Type", "PSN", "SN", "SRS")

# 16S data
m16s_sample_info = read.table("CloudPilot/16s_metadata.tsv.raw", sep = "\t", header = TRUE)
m16s_sample_info$VISNO = as.character(m16s_sample_info$VisitNo)
m16s_sample_info$Visit = car::recode(m16s_sample_info$VISNO, 
                                    "c('3', '03S') = '3'; c('1', '01S', '01T') = '1'; c('2', '02S') = '2'")
m16s_sample_info_used = m16s_sample_info
m16s_sample_info_used$Type = "16S"
m16s_sample_info_used = m16s_sample_info_used[, c("RSID", "Sex", "HMPBodySubsite", "Visit", "Type", "PSN", "NAP", "Region")]
colnames(m16s_sample_info_used) = c("RSID", "Gender", "STSite", "Visit", "Type", "PSN", "SN", "Region")
v35_samples = m16s_sample_info_used[which(m16s_sample_info_used$Region == "V35"), ]

# Merge the WGS and 16S and then get the subjects and visits for which we have 16S and WGS data
merged_used = rbind(wgs_sample_info_used[, 1:6], v35_samples[, 1:6])
merged_table = dcast(merged_used, RSID + STSite + Visit ~ Type, length)
merged_table$Both = ifelse(merged_table$`16S` > 0 & merged_table$WGS > 0, 1, 0)
colnames(merged_table) = c("RSID", "STSite",  "Visit",   "m16S",     "WGS",     "Both")

# Generate the list of samples from first visit for three body sites
first_visit_subjects = subset(merged_table, (STSite == "Anterior_nares"
                                               | STSite == "Posterior_fornix"
                                               | STSite == "Stool") & Visit == 1 & Both == 1)
first_visit_subset = merge(merged_used, first_visit_subjects[, c("RSID", "STSite", "Visit")],
                           by = c("RSID", "STSite", "Visit"))
write.csv(first_visit_subset, file = "CloudPilot/cloud_pilot_first_visit_subset.csv", row.names = FALSE, quote = FALSE)

# Generate a set of IDs for the three body sites randomly from the list
for(site in unique(first_visit_subset$STSite)) {
  filename = paste("CloudPilot/", site, "_rand_samples.txt", sep = "")
  unique_subject_ids = unique(first_visit_subset[which(first_visit_subset$STSite == site), c("RSID")])
  rowcount = length(unique_subject_ids)
  rand = sample(1:rowcount, 20, replace=FALSE)
  subjects = data.frame(unique_subject_ids[rand])
  colnames(subjects) = c("RSID")
  subset_of_samples = merge(first_visit_subset[which(first_visit_subset$STSite == site), ], subjects)
  write.table(file = filename, subset_of_samples[, c("RSID", "PSN", "SN", "Type", "Visit")], 
              sep = "\t", quote = FALSE, row.names = FALSE, col.names = TRUE)
}


# Code to verify script
stool_rand_list = read.csv(file = "CloudPilot/Stool_rand_samples.txt", sep = "\t", header = TRUE)
unique_stool_samples = unique(stool_rand_list$RSID)

wgs_sample_info_used = wgs_sample_info
wgs_sample_info_used = wgs_sample_info_used[, c("RANDSID", "STSite", "Visit", "Type", "SNPRNT", "SN", "SRS")]
colnames(wgs_sample_info_used) = c("RSID", "STSite", "Visit", "Type", "PSN", "SN", "SRS")
wgs_stool_subsamples = wgs_sample_info_used[which(wgs_sample_info_used$RSID %in% unique_stool_samples & 
                                                    wgs_sample_info_used$STSite == "Stool" & 
                                                    wgs_sample_info_used$Visit == 1), ]

orderBy(~RSID, data = wgs_stool_subsamples)

m16s_sample_info_used = m16s_sample_info_used[, c("RSID", "HMPBodySubsite", "Visit", "Type", "PSN", "NAP", "Region", "SampleID")]
colnames(m16s_sample_info_used) = c("RSID", "STSite", "Visit", "Type", "PSN", "SN", "Region", "SampleID")
v35_samples = m16s_sample_info_used[which(m16s_sample_info_used$Region == "V35"), ]

v35_stool_subsamples = v35_samples[which(v35_samples$RSID %in% unique_stool_samples & 
                                           v35_samples$STSite == "Stool" & 
                                           v35_samples$Visit == 1), ]
orderBy(~RSID, data = v35_stool_subsamples)

merged_subsamples = rbind(v35_stool_subsamples[, c(1:6)], wgs_stool_subsamples[, c(1:6)])
orderBy(~RSID+Type, data = merged_subsamples)

# Uniquify list
distinct(m16s_sample_info, RSID, Gender, STSite, Visit, Region, .keep_all = TRUE)



