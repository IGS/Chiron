#!/usr/bin/env cwl-runner

cwlVersion: v1.0
label: wget test
class: CommandLineTool

inputs:
  output_file:
    type: string
    label: path to save output file to
    inputBinding:
      prefix: -O
      position: 1
  url:
    type: string
    label: URL to pass to wget
    inputBinding:
      position: 2

outputs:
  outfile:
    type: File
    outputBinding:
      glob: $(inputs.output_file)

baseCommand: ["wget"]
