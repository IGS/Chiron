#!/usr/bin/env cwl-runner
cwlVersion: v1.0
label: Humann2 - Normalizing RPKs to relative abundance
class: CommandLineTool

hints:
  - class: DockerRequirement
    dockerPull: umigs/chiron-humann2
#  - class: InitialWorkDirRequirement
#    listing:
#      - $(inputs.input_tsv.dirname)

inputs:
  input_tsv:
    inputBinding:
      prefix: --input
    type: File
#  input_dir:
#    inputBinding:
#      valueFrom: $(inputs.input_tsv.dirname)
#    type: Directory
  output_tsv:
    inputBinding:
      prefix: --output
    type: string
  units:
    inputBinding:
      prefix: --units
    type: string
    default: "cpm"
  update_snames:
    inputBinding:
      prefix: --update-snames
    type: boolean?
outputs:
  out_tsv:
    type: File
    outputBinding:
      glob: $(inputs.output_tsv)

baseCommand: ["humann2_renorm_table"]
