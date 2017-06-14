# Notes for running QIIME CWL Workflows

## Invoking a CWL workflow
```
cwl-runner <cwl tool/workflow script> <input parameter yml/json>
```
The first parameter is a valid cwl tool or workflow script.  In this directory, these have the extension __.cwl__.

The second parameter is a YAML or JSON file consisting of input parameters for the CWL script.  In this directory, YAML examples are provided and are listed with the extension __.yml__.

## Running the QIIME2 pipeline
```
cwl-runner ./qiime2_complete.cwl ./qiime2_complete_test.yml
```

The file "qiime2\_complete\_test.yml" is an example of a typical QIIME2 run using example inputs from the workshop tutorial.

## Outputs from CWL pipeline
* Representative sequences .qza file (post-denoising)
* Representative table .qza file (post-denoising)
* Rooted tree .qza file
* Feature table visualization .qzv file
* Feature sequences visualization .qzv file
* Alpha group significance visualization .qzv file (Faith Phylogenetic Diversity)
* Alpha group significance visualization .qzv file (Evenness metric)
* A Beta group significance visualization .qzv file (Unweighted UniFrac by chosen metadata category)
* Emperor PCoA plot .qzv file (Unweighted UniFrac)
* Emperor PCoA plot .qzv file (Bray-Curtis)
* Taxonomic visualization .qzv file
* Taxonomic barplot .qzv file
* Differential abundance visualization .qzv file
* Differential abundance visualization .qzv file (collapse to chosen taxonomic level)

## Misc Notes
Any additional command-line options must be provided before the "cwl tool/workflow script"
* If running on MacOS/OSX, must provide the following two options:
  * --tmpdir-prefix=./tmp
  * --tmp-outdir-prefix=out
* By default output is written to your current directory.  To write to a specific directory, pass in the --outdir option
* The basename of the demultiplexed sequences file will be used as a naming prefix for the outputted files