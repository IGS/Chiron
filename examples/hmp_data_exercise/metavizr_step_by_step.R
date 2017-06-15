startMetavizTutorial <- function() {
	require(httr, quietly=TRUE)
	public_ipv4 <- httr::content(httr::GET("http://169.254.169.254/latest/meta-data/public-ipv4"))

  	setMetavizStandalone()
  	startMetavizStandalone(host=public_ipv4, daemonized=FALSE)
}

download.file("https://github.com/IGS/Chiron/blob/master/docker/chiron-metaviz/workshopData?raw=true" ,destfile = "workshopData")

wgs_16s_compare_obj <- readRDS("workshopData")

library(metavizr)

app <- startMetavizTutorial()

facetZoom <- app$plot(wgs_16s_compare_obj, datasource_name = "wgs_16s_compare", feature_order = colnames(fData(wgs_16s_compare_obj))[1:6])

## Run this command in the R console after each UI interaction
## This is an issue that we are working to resolve
app$service()
