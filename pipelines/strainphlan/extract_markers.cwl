#!/usr/bin/env cwl-runner
cwlVersion: v1.0
label: BioBakery extract_markers script
class: CommandLineTool

hints:
  - class: DockerRequirement
    dockerPull: umigs/chiron-strainphlan

inputs:
  ifn_markers:
    inputBinding:
      prefix: --ifn_markers
    type: string
    default: 'all_markers.fasta'
  ofn_markers:
    inputBinding:
      prefix: --ofn_markers
    type: string
  mpa_pkl:
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
    default: '.'
outputs:
  out_markers:
    type: File
    outputBinding:
      glob: $(inputs.ofn_markers)

baseCommand: ["extract_markers.py"]
