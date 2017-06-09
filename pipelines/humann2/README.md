# Notes for running Humann2 CWL Workflows
* If running on MacOS/OSX, must provide the following two options:
  * '--tmpdir-prefix=<./tmp>'
  * ' --tmp-outdir-prefix=<out>'
* By default output is written to your current directory.  To write to a specific directory, pass in the '--outdir' option
* Some Biobakery demo steps will fail because the 'uniref90' database is not downloaded by default in the Docker image.  Please see section 1.2.1 for information on how to install the requisite databases
  * Section 3.1
  * Section 3.3
* For tests where the output file is located in the same directory as the input file in the tutorial example, I am moving it up a directory.  The input directory/file is mounted in Docker as read-only, so this poses issues with writing to that same directory
  * Section 3.1
  * Section 3.2
  * Section 3.3
* TODO: Create humann group tests for Section 4.2