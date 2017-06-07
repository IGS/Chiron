#!/usr/bin/env cwl-runner
cwlVersion: v1.0
label: Humann2 - Attach names to features
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
  names:
    inputBinding:
      prefix: --names
    type: string
    default: "uniref90"
outputs:
  out_tsv:
    type: File
    outputBinding:
      glob: $(inputs.output_tsv)

baseCommand: ["humann2_rename_table"]
