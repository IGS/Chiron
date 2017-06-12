#!/usr/bin/env cwl-runner
cwlVersion: v1.0
label: BioBakery extract_markers script
class: CommandLineTool

requirements:
  - class: InlineJavascriptRequirement

hints:
  - class: DockerRequirement
    dockerPull: umigs/chiron-phlan

inputs:
  ifn_markers:
    inputBinding:
      prefix: --ifn_markers
    type: File
    default: 'all_markers.fasta'
  ofn_markers:
    inputBinding:
      prefix: --ofn_markers
      valueFrom: $(inputs.clade + '.markers.fasta')
    type: string
    default: 'markers.fasta'
  index_dir:
    type: Directory
  mpa_pkl:
    label: The metadata pickled MetaPhlAn filename
    type: string
  clade:
    inputBinding:
      prefix: --clade
    type: string
outputs:
  out_marker:
    type: File
    outputBinding:
      glob: $('*' + inputs.ofn_markers)
arguments:
  - valueFrom: $(inputs.index_dir.path + '/' + inputs.mpa_pkl)
    prefix: --mpa_pkl

baseCommand: ["extract_markers.py"]
