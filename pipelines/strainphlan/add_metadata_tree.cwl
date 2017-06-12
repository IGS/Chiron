#!/usr/bin/env cwl-runner
cwlVersion: v1.0
label: BioBakery add_metadata_tree script
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
      prefix: --ifn_trees
      valueFrom: $(self.basename)
    type: File
  metadata_input:
    inputBinding:
      prefix: --ifn_metadatas
    type: File
  metadata_category:
    inputBinding:
      prefix: --metadatas
    type: string
outputs:
  out_tree:
    type: File
    outputBinding:
      glob: $(inputs.tree_input.basename + '.metadata')

baseCommand: ["add_metadata_tree.py"]
