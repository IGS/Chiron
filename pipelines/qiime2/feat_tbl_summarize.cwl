#!/usr/bin/env cwl-runner
cwlVersion: v1.0
label: QIIME2 - FeatureTable summarize
class: CommandLineTool

hints:
  - class: DockerRequirement
    dockerPull: umigs/chiron-qiime2
  - class: InlineJavascriptRequirement

inputs:
  input_table:
    inputBinding:
      prefix: --i-table
    type: File
  metadata_file:
    inputBinding:
      prefix: --m-sample-metadata-file
    type: File
  in_prefix:
    type: string?
  table_visualization:
    inputBinding:
      prefix: --o-visualization
      valueFrom: $(inputs.in_prefix + 'table.qzv')
    type: string
    default: 'table.qzv'

outputs:
  out_table_visual:
    type: File
    outputBinding:
      glob: $(inputs.table_visualization)

baseCommand: ["qiime", "feature-table", "summarize"]
