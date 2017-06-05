#!/usr/bin/env cwl-runner
cwlVersion: v1.0
label: BioBakery extract_markers script
class: CommandLineTool

#requirements:
#  - class: DockerRequirement
#    dockerPull: jorvis/hmp-cloud-pilot

inputs:
  ifn_markers:
    inputBinding:
      prefix: --ifn_markers
    type: File
    default: all_markers.fasta
  ofn_markers:
    inputBinding:
      prefix: --ofn_markers
    type: File
  input_type:
    inputBinding:
      prefix: --mpa_pkl
    type: string
  clade:
    inputBinding:
      prefix: --clade
    type: string
  output_dir:
    inputBinding:
      prefix: --output_dir
    type: string
outputs:
  out_marker:
    type: File
    outputBinding:
      glob: '*.markers.fasta'

baseCommand: ["extract_markers.py"]
