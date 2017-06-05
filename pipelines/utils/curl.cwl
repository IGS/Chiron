#!/usr/bin/env cwl-runner

cwlVersion: v1.0
label: Perform a cURL command
class: CommandLineTool

arguments: ["-sL", "--create-dirs"]

inputs:
  url:
    type: string
    label: URL to pass to wget
    inputBinding:
      position: 1
  output_file:
    type: string
    label: path to save output file to.  Will create non-existing directories
    inputBinding:
      prefix: -o
      position: 2

outputs:
  outfile:
    type: File
    outputBinding:
      glob: $(inputs.output_file)

baseCommand: ["curl"]
