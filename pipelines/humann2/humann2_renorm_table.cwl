#!/usr/bin/env cwl-runner
cwlVersion: v1.0
label: Humann2 - Normalizing RPKs to relative abundance
class: CommandLineTool

hints:
  - class: DockerRequirement
    dockerPull: umigs/chiron-humann2

inputs:
  input_tsv:
    inputBinding:
      prefix: --input
    type: File
  output_tsv:
    inputBinding:
      prefix: --output
    type: string
  units:
    inputBinding:
      prefix: --units
    type: string
    default: "cpm"
  update_snames
    inputBinding:
      prefix: --update-snames
    type: boolean?
outputs:
  out_tsv:
    type: File
    outputBinding:
      glob: $(inputs.output_tsv)

baseCommand: ["humann2_renorm_table"]
