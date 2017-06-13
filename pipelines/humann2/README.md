# Notes for running Humann2 CWL Workflows

## Invoking a CWL workflow
```
cwl-runner <cwl tool/workflow script> <input parameter yml/json>
```
The first parameter is a valid cwl tool or workflow script.  In this directory, these have the extension __.cwl__.

The second parameter is YAML or JSON file consisting of input parameters for the CWL script.  In this directory, YAML examples are provided and are listed with the extension __.yml__.

Any additional command-line options must be provided before the "cwl tool/workflow script"

## Running the Humann2 pipeline
### Standard humann2 run
```
cwl-runner ./humann2_complete.cwl ./humann2_complete_test.yml
```

The file "humann2\_complete\_test.yml" is an example of a typical Humann2 run using example inputs from the workshop tutorial. Passing in multiple input files will parallelize the pipeline runs per sample.

### Pipeline that merges Humann2 output first
```
cwl-runner ./humann2_join_complete.cwl ./humann2_join_complete_test.yml
```

The file "humann2\_join\_complete\_test.yml" is an example of a typical Humann2 run that first merges all humann2 output files in a given directory before running the downstream steps. Passing in multiple input directories will parallelize the pipeline runs per directory.

## Outputs (for both pipelines)
* Feature .tsv file from humann2\_rename\_table
* Normalized .tsv file from humann2\_renorm\_table
* Regrouped .tsv file from humann2\_regroup\_table

## Misc Notes

* If running on MacOS/OSX, must provide the following two options:
  * --tmpdir-prefix=./tmp
  * --tmp-outdir-prefix=out
* By default output is written to your current directory.  To write to a specific directory, pass in the --outdir option
* Some Biobakery demo steps will fail because the 'uniref90' database is not downloaded by default in the Docker image.  Please see section 1.2.1 for information on how to install the requisite databases
  * Section 3.1
  * Section 3.3
* For tests where the output file is located in the same directory as the input file in the tutorial example, I am moving it up a directory.  The input directory/file is mounted in Docker as read-only, so this poses issues with writing to that same directory
  * Section 3.1
  * Section 3.2
  * Section 3.3
* TODO: Create humann group tests for Section 4.2 (join features into one table)