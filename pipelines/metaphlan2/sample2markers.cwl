#!/usr/bin/env cwl-runner
cwlVersion: v1.0
label: BioBakery sample2markers script
class: CommandLineTool

#requirements:
#  - class: DockerRequirement
#    dockerPull: jorvis/hmp-cloud-pilot

inputs:
  ifn_samples:
    inputBinding:
      prefix: --ifn_samples
    type: File
  input_type:
    inputBinding:
      prefix: --input_type
    type: string
    default: sam
  output_dir:
    inputBinding:
      prefix: --output_dir
    type: string
  num_cores:
    inputBinding:
      prefix: --nproc
    type: int
    default: 1
outputs:
  out_marker:
    type: File
    outputBinding:
      glob: '*.markers'

baseCommand: ["sample2markers.py"]
