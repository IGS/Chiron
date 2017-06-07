#!/usr/bin/env cwl-runner
cwlVersion: v1.0
label: Humann2 - Regrouping genes to other functional categories
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
  groups:
    inputBinding:
      prefix: --groups
    type: string
    default: "uniref90_level4ec"
outputs:
  out_tsv:
    type: File
    outputBinding:
      glob: $(inputs.output_tsv)

baseCommand: ["humann2_regroup_table"]
