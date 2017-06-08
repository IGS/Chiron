# Notes for running QIIME CWL Workflows
* Must pass the '--no-match-user' option to the 'cwl-runner' executable
* If running on MacOS/OSX, must provide the following two options:
  * '--tmpdir-prefix=<./tmp>'
  * ' --tmp-outdir-prefix=<out>'