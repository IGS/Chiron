#!/usr/bin/env cwl-runner

cwlVersion: v1.0
label: wget test
class: CommandLineTool

#hints:
#  DockerRequirement:
#    dockerPull: jorvis/hmp-cloud-pilot

inputs:
  url:
    type: string
    doc: URL to pass to wget
    inputBinding:
      position: 1

outputs:
  outfile:
    type: File
    outputBinding:
      glob: "*"

baseCommand: ["wget"]
