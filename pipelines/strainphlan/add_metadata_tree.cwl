#!/usr/bin/env cwl-runner
cwlVersion: v1.0
label: BioBakery add_metadata_tree script
class: CommandLineTool

requirements:
  - class: InlineJavascriptRequirement
#  - class: InitialWorkDirRequirement
#    listing:
#      - $(inputs.metadata_input)
#      - $(inputs.tree_input)

hints:
  - class: DockerRequirement
    dockerPull: umigs/chiron-phlan

inputs:
  tree_input:
    inputBinding:
      prefix: --ifn_trees
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
      glob: $(inputs.tree_input + '.metadata')
  # Script writes to input directory
  out_dir:
    type: Directory
    outputBinding:
      outputEval: $(inputs.tree_input.dirname)

baseCommand: ["add_metadata_tree.py"]
