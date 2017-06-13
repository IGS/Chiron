# Notes for running Strainphlan CWL Workflows

## Invoking a CWL workflow
```
cwl-runner <cwl tool/workflow script> <input parameter yml/json>
```
The first parameter is a valid cwl tool or workflow script.  In this directory, these have the extension __.cwl__.

The second parameter is YAML or JSON file consisting of input parameters for the CWL script.  In this directory, YAML examples are provided and are listed with the extension __.yml__.

## Running the Strainphlan pipeline
```
cwl-runner ./strainphlan_complete.cwl ./strainphlan_complete_test.yml
```

The file "strainphlan\_complete\_test.yml" is an example of a typical Strainphlan run using example inputs from the workshop tutorial. Passing in multiple input files will parallelize the pipeline runs per sample up to the point where "strainphlan" is called to build trees, in which case it uses all input markers in one command.

## Outputs
* Metaphlan2 profile text file (one per input sample)
* Metaphlan2 bowtie2 file (one per input sample - can be used to quickly rerun Metaphlan)
* Strainphlan list of clades
* Bowtie2 FASTA of sequences from reference database
* Strainphlan tree with the RAxML\_bestTree algorithm 
* Graphlan dendrogram .png file
* Graphlan single-strain dendrogram .png file

## Misc Notes
* If running on MacOS/OSX, must provide the following two options:
  * --tmpdir-prefix=./tmp
  * --tmp-outdir-prefix=out
* By default output is written to your current directory.  To write to a specific directory, pass in the --outdir option
* TODO: (potentially as needed)
  * Make strainphlan accept multiple clades and ref\_genomes (via array)
  * Make add\_metadata\_tree.py accept a list of input files instead of singles