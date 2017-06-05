#!/usr/bin/env cwl-runner
cwlVersion: v1.0
label: QIIME2 - FeatureTable summarize
class: CommandLineTool

inputs:
  input_table:
    inputBinding:
      prefix: --i-table
    type: File
  metadata_file:
    inputBinding:
      prefix: --m-sample-metadata-file
    type: File
  table_visualization:
    inputBinding:
      prefix: --o-visualization
    type: string
    default: "table.qzv"
outputs:
  out_table:
    type: File
    outputBinding:
      glob: $(inputs.table_visualization)

baseCommand: ["qiime", "feature-table", "summarize"]
