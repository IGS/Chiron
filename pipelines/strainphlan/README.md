# Notes for running Strainphlan CWL Workflows
* If running on MacOS/OSX, must provide the following two options:
  * --tmpdir-prefix=./tmp
  * --tmp-outdir-prefix=out
* By default output is written to your current directory.  To write to a specific directory, pass in the --outdir option
* TODO: (potentially as needed)
  * Make strainphlan accept multiple clades and ref\_genomes (via array)
  * Make add\_metadata\_tree.py accept a list of input files instead of singles