#!/usr/bin/env cwl-runner
cwlVersion: v1.0
label: BioBakery plot_tree_graphlan script
class: CommandLineTool

requirements:
  - class: InlineJavascriptRequirement
  - class: InitialWorkDirRequirement
    listing:
      - $(inputs.tree_input)

hints:
  - class: DockerRequirement
    dockerPull: umigs/chiron-phlan

inputs:
  tree_input:
    inputBinding:
      prefix: --ifn_tree
    type: File
  metadata_category:
    label: Metadata categories to be colorized
    inputBinding:
      prefix: --colorized_metadata
    type: string
  leaf_marker_size:
    inputBinding:
      prefix: --leaf_marker_size
    type: int?
  legend_marker_size:
    inputBinding:
      prefix: --legend_marker_size
    type: int?
outputs:
  out_png:
    type: File
    outputBinding:
      glob: $(inputs.tree_input + '.png')

baseCommand: ["plot_tree_graphlan.py"]
