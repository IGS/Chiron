#!/usr/bin/env cwl-runner
cwlVersion: v1.0
label: QIIME2 - Create PCoA plots using Emperor
class: CommandLineTool

inputs:
  input_pcoa:
    inputBinding:
      prefix: --i-pcoa
    type: File
  metadata_file:
    inputBinding:
      prefix: --m-metadata-file
    type: File
  custom-axis:
    label: Name for custom axis label
    inputBinding:
      prefix: --p-custom-axis
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

baseCommand: ["qiime", "emperor", "plot"]
