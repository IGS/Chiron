# Notes for running QIIME CWL Workflows
* If running on MacOS/OSX, must provide the following two options:
  * '--tmpdir-prefix=<./tmp>'
  * ' --tmp-outdir-prefix=<out>'
* By default output is written to your current directory.  To write to a specific directory, pass in the '--outdir' option