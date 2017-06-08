#!/usr/bin/env cwl-runner
cwlVersion: v1.0
label: Humann2 - Join multiple samples
class: CommandLineTool

hints:
  - class: DockerRequirement
    dockerPull: umigs/chiron-humann2

inputs:
  input_dir:
    inputBinding:
      prefix: --input
    type: Directory
  output_tsv:
    inputBinding:
      prefix: --output
    type: string
  file_name:
    inputBinding:
      prefix: --file-name
    type: string
outputs:
  out_tsv:
    type: File
    outputBinding:
      glob: $(inputs.output_tsv)

baseCommand: ["humann2_join_tables"]
