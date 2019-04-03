# Sample of ways to play with the assembly summaries

# Note that you should run this script piecemeal.
# Start by loading the data in BLOCK 1.

# things to try 
#  - only look at specific types of errors (e.g., ignore coverage type errors)
#    do the results change?
#  - Can you see things better in log space?

########################
### BLOCK 1: Data input
########################
# Reading the summary file from VALET
datadir <- "../"
summary.hmp <- read.csv(paste0(datadir, "SRS014465_hmp_valet/summary.tsv"), 
                        head=T, row.names=1, sep="\t", check.names=F)
summary.hmp[is.na(summary.hmp)] <- 0
sizes.hmp <- summary.hmp[,'contig_length', drop=FALSE] # all contig sizes

summary.soap <- read.csv(paste0(datadir, "SRS014465_soap_valet/summary.tsv"), 
                         head=T, row.names=1, sep="\t", check.names=F)
summary.soap[is.na(summary.soap)] <- 0
sizes.soap <- summary.soap[,'contig_length', drop=FALSE]

summary.spades <- read.csv(paste0(datadir,"SRS014465_spades_valet/summary.tsv"), 
                           head=T, row.names=1, sep="\t", check.names=F)
summary.spades[is.na(summary.spades)] <- 0
sizes.spades <- summary.spades[,'contig_length', drop=FALSE]

summary.idba <- read.csv(paste0(datadir, "SRS014465_idba_valet/summary.tsv"), 
                         head=T, row.names=1, sep="\t", check.names=F)
summary.idba[is.na(summary.idba)] <- 0
sizes.idba <- summary.idba[,'contig_length', drop=FALSE]

errorCols <- c("low_cov", "high_cov", "reapr", "breakpoints") # total number of errors
errorBpsCols <- c("low_cov_bps", "high_cov_bps", "reapr_bps", "breakpoints_bps") # total number of basepairs in errors


##################################
### BLOCK 2: Contiguity statistics
##################################
# Compute general assembly statistics

contigs.tmp <- rev(sort(sizes.hmp[,1]))
n50.tmp <- contigs.tmp[cumsum(contigs.tmp) >= sum(contigs.tmp)/2][1]
stats.hmp <- c(length(sizes.hmp[,1]), mean(sizes.hmp[,1]), median(sizes.hmp[,1]), sum(sizes.hmp[,1]), n50.tmp)

contigs.tmp <- rev(sort(sizes.soap[,1]))
n50.tmp <- contigs.tmp[cumsum(contigs.tmp) >= sum(contigs.tmp)/2][1]
stats.soap <- c(length(sizes.soap[,1]), mean(sizes.soap[,1]), median(sizes.soap[,1]), sum(sizes.soap[,1]), n50.tmp)

contigs.tmp <- rev(sort(sizes.spades[,1]))
n50.tmp <- contigs.tmp[cumsum(contigs.tmp) >= sum(contigs.tmp)/2][1]
stats.spades <- c(length(sizes.spades[,1]), mean(sizes.spades[,1]), median(sizes.spades[,1]), sum(sizes.spades[,1]), n50.tmp)

contigs.tmp <- rev(sort(sizes.idba[,1]))
n50.tmp <- contigs.tmp[cumsum(contigs.tmp) >= sum(contigs.tmp)/2][1]
stats.idba <- c(length(sizes.idba[,1]), mean(sizes.idba[,1]), median(sizes.idba[,1]), sum(sizes.idba[,1]), n50.tmp)

all.contiguity.stats <- rbind(stats.hmp, stats.soap, stats.spades, stats.idba)
rownames(all.contiguity.stats) <- c("HMP", "SoapDenovo", "Spades", "IDBA-UD")
colnames(all.contiguity.stats) <- c("num", "mean size", "median size", "total size", "n50 size")

all.contiguity.stats

#########################################
#### BLOCK 3 - Size plots
#########################################
contigSizes.hmp <- summary.hmp[order(summary.hmp[, "contig_length"], decreasing=T), "contig_length"]
contigSums.hmp <- cumsum(contigSizes.hmp)
contigNum.hmp <- c(rep(1, length(contigSizes.hmp)))
contigNum.hmp <- cumsum(contigNum.hmp)

contigSizes.soap <- summary.soap[order(summary.soap[, "contig_length"], decreasing=T), "contig_length"]
contigSums.soap <- cumsum(contigSizes.soap)
contigNum.soap <- c(rep(1, length(contigSizes.soap)))
contigNum.soap <- cumsum(contigNum.soap)

contigSizes.spades <- summary.spades[order(summary.spades[, "contig_length"], decreasing=T), "contig_length"]
contigSums.spades <- cumsum(contigSizes.spades)
contigNum.spades <- c(rep(1, length(contigSizes.spades)))
contigNum.spades <- cumsum(contigNum.spades)

contigSizes.idba <- summary.idba[order(summary.idba[, "contig_length"], decreasing=T), "contig_length"]
contigSums.idba <- cumsum(contigSizes.idba)
contigNum.idba <- c(rep(1, length(contigSizes.idba)))
contigNum.idba <- cumsum(contigNum.idba)

par(mfrow=c(1,2))
# Size plots
# N50 plot - contig size by cumulative contig size (how much of the assembly is contained in contigs greater than x)
plot(contigSizes.hmp, contigSums.hmp, type='l', #log="y",
     xlim=rev(range(contigSizes.hmp, contigSizes.spades, contigSizes.soap, contigSizes.idba)),
     ylim=c(1, max(contigSums.hmp, contigSums.spades, contigSums.soap, contigSums.idba)),
     main="Cumulative contig sizes", 
     xlab="Contig size",
     ylab="Cumulative contig size")
abline(h=max(contigSums.soap)/2, col='red')
abline(h=max(contigSums.idba)/2, col='green')
par(new=T)
plot(contigSizes.spades, contigSums.spades, type='l', #log="y",
     xlim=rev(range(contigSizes.hmp, contigSizes.spades, contigSizes.soap, contigSizes.idba)),
     ylim=c(1, max(contigSums.hmp, contigSums.spades, contigSums.soap, contigSums.idba)),
     main="Cumulative contig sizes", col="blue", 
     xlab="Contig size",
     ylab="Cumulative contig size")
par(new=T)
plot(contigSizes.soap, contigSums.soap, type='l', #log="y",
     xlim=rev(range(contigSizes.hmp, contigSizes.spades, contigSizes.soap, contigSizes.idba)),
     ylim=c(1, max(contigSums.hmp, contigSums.spades, contigSums.soap, contigSums.idba)),
     main="Cumulative contig sizes", col="red", 
     xlab="Contig size",
     ylab="Cumulative contig size")
par(new=T)
plot(contigSizes.idba, contigSums.idba, type='l', # log="y",
     xlim=rev(range(contigSizes.hmp, contigSizes.spades, contigSizes.soap, contigSizes.idba)), 
     ylim=c(1, max(contigSums.hmp, contigSums.spades, contigSums.soap, contigSums.idba)),
     main="Cumulative contig sizes", col="green",
     xlab="Contig size",
     ylab="Cumulative contig size")
legend(x=80000, y=10000000,border="black", 
       legend=c("HMP", "Soap", "spades", "IDBA-UD"), 
       col=c("black", "red", "blue", "green"),
       pch=c(19,19,19,19))

# count50 plot - number of contigs needed to reach a certain total amount of sequence
# red line is half of the total sequence in the HMP assembly
plot(contigNum.hmp, contigSums.hmp, type='l', #log="y",
     xlim=c(0,max(contigNum.hmp, contigNum.soap, contigNum.spades, contigNum.idba)),
     ylim=c(1, max(contigSums.hmp, contigSums.soap, contigSums.spades, contigSums.idba)),
     main="Cumulative contig numbers",
     xlab="Number of contigs",
     ylab="Cumulative contig size")
abline(h=max(contigSums.soap)/2, col='red')
abline(h=max(contigSums.idba)/2, col='green')
par(new=T)
plot(contigNum.soap, contigSums.soap, type='l', #log="y",
     xlim=c(0,max(contigNum.hmp, contigNum.soap, contigNum.spades, contigNum.idba)),
     ylim=c(1, max(contigSums.hmp, contigSums.soap, contigSums.spades, contigSums.idba)),
     main="Cumulative contig numbers",
     col="red",
     xlab="Number of contigs",
     ylab="Cumulative contig size")
par(new=T)
plot(contigNum.spades, contigSums.spades, type='l', #log="y",
     xlim=c(0,max(contigNum.hmp, contigNum.soap, contigNum.spades, contigNum.idba)),
     ylim=c(1, max(contigSums.hmp, contigSums.soap, contigSums.spades, contigSums.idba)),
     col="blue",
     main="Cumulative contig numbers",
     xlab="Number of contigs",
     ylab="Cumulative contig size")
par(new=T)
plot(contigNum.idba, contigSums.idba, type='l', #log="y",
     xlim=c(0,max(contigNum.hmp, contigNum.soap, contigNum.spades, contigNum.idba)),
     ylim=c(1, max(contigSums.hmp, contigSums.soap, contigSums.spades, contigSums.idba)),
     col="green",
     main="Cumulative contig numbers",
     xlab="Number of contigs",
     ylab="Cumulative contig size")
legend(x=100, y=10000000,border="black", 
       legend=c("HMP", "Soap", "spades", "IDBA-UD"), 
       col=c("black", "red", "blue", "green"),
       pch=c(19,19,19,19))

##############################
### BLOCK 4: Basic scatterplot
##############################
# basic scatterplot - outliers are contigs with more errors than the 'baseline'
## Run each block of 2 lines separately

## Or put them all in one plot
par(mfrow=c(2,2))
totErrors.hmp<- rowSums(summary.hmp[,errorCols])
plot(summary.hmp[,"contig_length"], totErrors.hmp, main="HMP errors/bp", xlab="contig size", ylab="# errors")
totErrors.soap<- rowSums(summary.soap[,errorCols])
plot(summary.soap[,1], totErrors.soap, main="SOAP errors/bp", xlab="contig size", ylab="# errors")
totErrors.spades<- rowSums(summary.spades[,errorCols])
plot(summary.spades[,1], totErrors.spades, main="SPADES errors/bp", xlab="contig size", ylab="# errors")
totErrors.idba<- rowSums(summary.idba[,errorCols])
plot(summary.idba[,1], totErrors.idba, main="IDBA-UD errors/bp", xlab="contig size", ylab="# errors")



#####################################
### BLOCK 5 - Feature Response Curve
#####################################

# if you haven't run block 3 run this:
totErrors.hmp<- rowSums(summary.hmp[,errorCols])
totErrors.soap<- rowSums(summary.soap[,errorCols])
totErrors.spades<- rowSums(summary.spades[,errorCols])
totErrors.idba<- rowSums(summary.idba[,errorCols])

par(mfrow=c(1,1))

contigSizes.hmp <- summary.hmp[order(summary.hmp[, "contig_length"], decreasing=T), "contig_length"]
contigErrors.hmp <- totErrors.hmp[order(summary.hmp[,"contig_length"], decreasing=T)]

contigSums.hmp <- cumsum(contigSizes.hmp)
errorSums.hmp <- cumsum(contigErrors.hmp)

contigNum.hmp <- c(rep(1, length(contigSizes.hmp)))
contigNum.hmp <- cumsum(contigNum.hmp)

contigSizes.soap <- summary.soap[order(summary.soap[, "contig_length"], decreasing=T), "contig_length"]
contigErrors.soap <- totErrors.soap[order(summary.soap[,"contig_length"], decreasing=T)]

contigSums.soap <- cumsum(contigSizes.soap)
errorSums.soap <- cumsum(contigErrors.soap)

contigNum.soap <- c(rep(1, length(contigSizes.soap)))
contigNum.soap <- cumsum(contigNum.soap)

contigSizes.spades <- summary.spades[order(summary.spades[, "contig_length"], decreasing=T), "contig_length"]
contigErrors.spades <- totErrors.spades[order(summary.spades[,"contig_length"], decreasing=T)]

contigSums.spades <- cumsum(contigSizes.spades)
errorSums.spades <- cumsum(contigErrors.spades)

contigNum.spades <- c(rep(1, length(contigSizes.spades)))
contigNum.spades <- cumsum(contigNum.spades)

contigSizes.idba <- summary.idba[order(summary.idba[, "contig_length"], decreasing=T), "contig_length"]
contigErrors.idba <- totErrors.idba[order(summary.idba[,"contig_length"], decreasing=T)]

contigSums.idba <- cumsum(contigSizes.idba)
errorSums.idba <- cumsum(contigErrors.idba)

contigNum.idba <- c(rep(1, length(contigSizes.idba)))
contigNum.idba <- cumsum(contigNum.idba)

xrange <- max(max(errorSums.spades, na.rm=T), 
              max(errorSums.hmp, na.rm=T), 
              max(errorSums.soap,na.rm=T), 
              max(errorSums.idba,na.rm=T))
yrange <- max(max(contigSums.hmp), max(contigSums.soap), max(contigSums.spades), max(contigSums.idba))

##  Plot the 'feature response curve' - # errors by cumulative contig size.
##
## For the rest of the plots, black line is HMP, blue is Spades and red is Soap 

plot(errorSums.hmp, contigSums.hmp, #/contigSums.hmp[length(contigSums.hmp)], 
     type='l', # log="y",
     main = "FRC", 
     xlab="# errors", 
     ylab="% assembly covered",
     ylim=c(1,yrange),
     xlim=c(0,xrange))

par(new=T)

plot(errorSums.soap, contigSums.soap, #/contigSums.soap[length(contigSums.soap)], 
   type='l', #log="y",
     # main = "FRC HMP", 
   #  xlab="# errors", 
   #  ylab="% assembly covered")
   xlim=c(0,xrange),
   ylim=c(1,yrange),
   ylab="", xlab="", col="red")

par(new=T)

plot(errorSums.spades, contigSums.spades, #/contigSums.spades[length(contigSums.spades)], 
     type='l', # log="y",
     # main = "FRC HMP", 
     #  xlab="# errors", 
     #  ylab="% assembly covered")
     xlim=c(0,xrange),
     ylim=c(1,yrange),
     ylab="", xlab="", col="blue")

par(new=T)

plot(errorSums.idba, contigSums.idba, #/contigSums.idba[length(contigSums.idba)], 
     type='l', # log="y",
     # main = "FRC HMP", 
     #  xlab="# errors", 
     #  ylab="% assembly covered")
     xlim=c(0,xrange),
     ylim=c(1,yrange),
     ylab="", xlab="", col="green")


legend(x=100, y=10000000,border="black", 
       legend=c("HMP", "Soap", "spades", "IDBA-UD"), 
       col=c("black", "red", "blue", "green"),
       pch=c(19,19,19,19))
