#!/usr/bin/env cwl-runner
cwlVersion: v1.0
label: QIIME2 - Perform beta group significance analysis
class: CommandLineTool

inputs:
  input_matrix:
    inputBinding:
      prefix: --i-distance-matrix
    type: File
  metadata_file:
    inputBinding:
      prefix: --m-metadata-file
    type: File
  metadata_category:
    inputBinding:
      prefix: --m-metadata-category
    type: string
  out_visualization:
    inputBinding:
      prefix: --o-visualization
    type: string
outputs:
  out_visualization:
    type: File
    outputBinding:
      glob: $(inputs.out_visualization)

arguments: ["--p-pairwise"]
baseCommand: ["qiime", "diversity", "beta-group-significance"]
