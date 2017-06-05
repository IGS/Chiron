#!/usr/bin/env cwl-runner
cwlVersion: v1.0
label: QIIME2 - FeatureTable tabulate seqs command
class: CommandLineTool

inputs:
  rep_seqs:
    inputBinding:
      prefix: --i-data
    type: File
  seqs_visualization:
    inputBinding:
      prefix: --o-visualization
    type: string
    default: "rep-seqs.qzv"
outputs:
  out_rep_seqs:
    type: File
    outputBinding:
      glob: $(inputs.seqs_visualization)

baseCommand: ["qiime", "feature-table", "tabulate-seqs"]
