# Notes for running Metacompass CWL Tool

## Invoking a CWL workflow
```
cwl-runner <cwl tool/workflow script> <input parameter yml/json>
```
The first parameter is a valid cwl tool or workflow script.  In this directory, these have the extension __.cwl__.

The second parameter is a YAML or JSON file consisting of input parameters for the CWL script.  In this directory, YAML examples are provided and are listed with the extension __.yml__.

## Running the Metacompass tool
```
cwl-runner ./metacompass.cwl ./metacompass_test1.yml
```

The file "metacomposs\_test1.yml" is an example of a typical Metacompass run using example inputs from the workshop tutorial.

## Misc Notes
* If running on MacOS/OSX, must provide the following two options:
  * --tmpdir-prefix=./tmp
  * --tmp-outdir-prefix=out
* By default output is written to your current directory.  To write to a specific directory, pass in the --outdir option