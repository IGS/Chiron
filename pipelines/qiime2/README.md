# Notes for running QIIME CWL Workflows

## Invoking a CWL workflow
```
cwl-runner <cwl tool/workflow script> <input parameter yml/json>
```
The first parameter is a valid cwl tool or workflow script.  In this directory, these have the extension __.cwl__.

The second parameter is YAML or JSON file consisting of input parameters for the CWL script.  In this directory, YAML examples are provided and are listed with the extension __.yml__.

## Misc Notes
Any additional command-line options must be provided before the "cwl tool/workflow script"
* If running on MacOS/OSX, must provide the following two options:
  * --tmpdir-prefix=./tmp
  * --tmp-outdir-prefix=out
* By default output is written to your current directory.  To write to a specific directory, pass in the --outdir option
* The basename of the demultiplexed sequences file will be used as a naming prefix for the outputted files