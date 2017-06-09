#!/usr/bin/env cwl-runner
cwlVersion: v1.0
label: QIIME2 - Create PCoA plots using Emperor
class: CommandLineTool

hints:
  - class: DockerRequirement
    dockerPull: umigs/chiron-qiime2

inputs:
  input_dir:
    type: Directory
  pcoa_file_base:
    type: string
  metadata_file:
    inputBinding:
      prefix: --m-metadata-file
    type: File
  custom_axis:
    label: Name for custom axis label
    inputBinding:
      prefix: --p-custom-axis
    type: string
  out_visualization:
    inputBinding:
      prefix: --o-visualization
    type: string
outputs:
  pcoa_visual:
    type: File
    outputBinding:
      glob: $(inputs.out_visualization)

arguments:
  - valueFrom: $(inputs.input_dir.path + '/' + inputs.pcoa_file_base)
    prefix: --i-pcoa

baseCommand: ["qiime", "emperor", "plot"]
