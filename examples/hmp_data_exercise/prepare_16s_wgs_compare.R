library(tidyverse)
library(metagenomeSeq)
library(stringr)
library(getopt)
library(metavizr)

# Get the options specified on the command line
spec = matrix(c('metaphlan', 'm', 1, "character",
                'qiime', 'q', 1, "character",
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


if ( is.null(opt$metaphlan) ) {
  cat("MetaPhlAn table missing.\n")
  cat(getopt(spec, usage=TRUE));
  q(status=1);
}

filename_16s = opt$qiime
filename_metaphlan = opt$metaphlan
outfile = opt$outfile

dat_16s <- read_csv(filename_16s)
dat_mph <- read_csv(filename_metaphlan)

metadata_mph <- dat_mph %>%
  slice(1:8) %>%
  gather(sample, value, -1) %>%
  spread(SN, value) %>%
  as.data.frame()

counts_mph <- dat_mph %>%
  slice(-(1:8))

fdata_mph <- counts_mph %>% 
  select(lineage=1) %>%
  separate(lineage, c("kingdom", "phylum", "class", "order", "family", "genus","species","strain"),
           "\\|", fill="right") %>%
  rownames_to_column("feature.id") %>%
  filter(kingdom == "k__Bacteria", !is.na(genus), is.na(species)) %>%
  select(-species, -strain) %>%
  select(kingdom, phylum, class, order, family, genus, feature.id) %>%
  as.data.frame()

counts_mph_mat <- counts_mph %>%
  select(-1) %>%
  mutate_all(as.numeric) %>%
  as.matrix()
rownames(counts_mph_mat) <- seq(len=nrow(counts_mph_mat))
counts_mph_mat <- counts_mph_mat[fdata_mph$feature.id,]


rownames(fdata_mph) <- fdata_mph$feature.id
rownames(metadata_mph) <- metadata_mph$sample
counts_mph_mat <- counts_mph_mat[,metadata_mph$sample]

mr_genus_mph <- newMRexperiment(counts_mph_mat, 
                                AnnotatedDataFrame(metadata_mph),
                                AnnotatedDataFrame(fdata_mph))


otu.ids <- dat_16s %>% magrittr::extract2("OTU.ID")
count_16s <- dat_16s %>% select(-1,-Consensus.Lineage) %>% mutate_all(as.numeric) %>% as.matrix()
rownames(count_16s) <- otu.ids

annotate_absent <- function(x, otu.ids, code) {
  ifelse(str_detect(x, "__$") | is.na(x),
         paste0(code, "__", otu.ids),
         x)
}

fdata_16s <- dat_16s %>% 
  select(lineage=Consensus.Lineage, OTU.ID) %>% 
  separate(lineage, c("kingdom", "phylum", "class", "order", "family", "genus"),
           ";", fill="right", extra="warn") %>%
  mutate(kingdom="k__Bacteria") %>%
  mutate(phylum = annotate_absent(phylum, OTU.ID, "p"),
         class = annotate_absent(class, OTU.ID, "c"),
         order = annotate_absent(order, OTU.ID, "o"),
         family = annotate_absent(family, OTU.ID, "f"),
         genus = annotate_absent(genus, OTU.ID, "g")) %>%
  as.data.frame()

rownames(fdata_16s) <- otu.ids

pdata_16s <- data.frame(sample=colnames(count_16s))
rownames(pdata_16s) <- colnames(count_16s)

mr_16s <- newMRexperiment(count_16s,
                          AnnotatedDataFrame(pdata_16s),
                          AnnotatedDataFrame(fdata_16s))

mr_16s_norm <- cumNorm(mr_16s, p=.75)
mr_genus_16s <- aggTax(mr_16s, "genus", norm=TRUE)

##

fdata_mph <- fData(mr_genus_mph)
fdata_16s <- fData(mr_genus_16s)

fdata_merged <- fdata_mph %>%
  full_join(fdata_16s %>% rownames_to_column("genus_16s")) %>%
  filter(!str_detect(genus, "OTU")) %>% 
  mutate(source=case_when(
    is.na(.$feature.id) ~ "16s",
    is.na(.$genus_16s) ~ "wgs",
    TRUE ~ "both")) %>% 
  filter(!duplicated(genus)) %>% 
  mutate(rowname=genus) %>%
  column_to_rownames() %>%
  as.data.frame()

pdata_mph <- pData(mr_genus_mph) %>% mutate(source="wgs")
pdata_16s <- pData(mr_genus_16s) %>% mutate(source="16s")

pdata_merged <- pdata_mph %>%
  inner_join(pdata_16s, by="sample") %>% 
  gather(dummy, source, matches("source")) %>%
  select(-dummy) %>% 
  mutate(sample_id = paste0(sample, "_", source)) %>% 
  column_to_rownames("sample_id") 

counts_mph <- MRcounts(mr_genus_mph) * 1000
counts_mph <- counts_mph[fdata_merged$feature.id[fdata_merged$source != "16s"],]

colnames(counts_mph) <- paste0(colnames(counts_mph), "_wgs")
rownames(counts_mph) <- fdata_merged$genus[fdata_merged$source != "16s"]
missing_counts_mph <- matrix(0, nr=sum(fdata_merged$source == "16s"), nc=ncol(counts_mph))
rownames(missing_counts_mph) <- fdata_merged$genus[fdata_merged$source == "16s"]

counts_mph <- rbind(counts_mph, missing_counts_mph)
counts_mph <- counts_mph[fdata_merged$genus, rownames(pdata_merged)[pdata_merged$source == "wgs"]]

counts_16s <- MRcounts(mr_genus_16s, norm=TRUE)
counts_16s <- counts_16s[fdata_merged$genus_16s[fdata_merged$source != "wgs"],]

colnames(counts_16s) <- paste0(colnames(counts_16s), "_16s")
rownames(counts_16s) <- fdata_merged$genus[fdata_merged$source != "wgs"]
missing_counts_16s <- matrix(0, nr=sum(fdata_merged$source == "wgs"), nc=ncol(counts_16s))
rownames(missing_counts_16s) <- fdata_merged$genus[fdata_merged$source == "wgs"]

counts_16s <- rbind(counts_16s, missing_counts_16s)
counts_16s <- counts_16s[fdata_merged$genus, rownames(pdata_merged)[pdata_merged$source == "16s"]]

scaled_counts_16s <- counts_16s
colsums_16s <- colSums(counts_16s)
for (i in seq(1,length(colsums_16s))){
  scaled_counts_16s[,i] <- counts_16s[,i]/colsums_16s[i]
}

scaled_counts_16s <- scaled_counts_16s * 1000

counts_merged <- cbind(counts_mph, counts_16s)
scaled_counts_merged <- cbind(counts_mph, scaled_counts_16s)

scaled_mr_genus_merged <- newMRexperiment(scaled_counts_merged,
                                   AnnotatedDataFrame(pdata_merged),
                                   AnnotatedDataFrame(fdata_merged))

mr_have_both <- scaled_mr_genus_merged[which(!is.na(fData(scaled_mr_genus_merged)[,"genus_16s"])),]

mobj <- metavizr:::EpivizMetagenomicsData$new(mr_have_both, feature_order=colnames(fData(mr_have_both))[1:6])
mobj$toNEO4JDbHTTP(batch_url = "http://localhost:7474/db/data/batch", neo4juser = "neo4j", neo4jpass = "osdf1", datasource = "wgs_16s_compare")

