#!/usr/bin/env cwl-runner
cwlVersion: v1.0
label: QIIME2 - Perform alpha group significance analysis
class: CommandLineTool

hints:
  - class: DockerRequirement
    dockerPull: umigs/chiron-qiime2

inputs:
  input_alpha:
    inputBinding:
      prefix: --i-alpha-diversity
    type: File
  metadata_file:
    inputBinding:
      prefix: --m-metadata-file
    type: File
  out_visualization:
    inputBinding:
      prefix: --o-visualization
    type: string
outputs:
  out_visual:
    type: File
    outputBinding:
      glob: $(inputs.out_visualization)

baseCommand: ["qiime", "diversity", "alpha-group-significance"]
