#!/usr/bin/env cwl-runner
cwlVersion: v1.0
label: BioBakery build_tree_single_strain script
class: CommandLineTool

requirements:
  - class: InlineJavascriptRequirement

hints:
  - class: DockerRequirement
    dockerPull: umigs/chiron-phlan
  - class: InitialWorkDirRequirement
    listing:
      - $(inputs.alignment_input)

inputs:
  alignment_input:
    inputBinding:
      prefix: --ifn_alignments
      valueFrom: $(self.basename)
    type: File
    secondaryFiles: '^.polymorphic'
  num_cores:
    inputBinding:
      prefix: --nprocs
    type: int
  output_log:
    inputBinding:
      prefix: --log_ofn
    type: string
    default: 'build_tree_single_strain.log'
outputs:
  out_tree:
    type: File
    outputBinding:
      glob: $('RAxML_bestTree.' + inputs.alignment_input.nameroot + '.remove_multiple_strains.tree')
  out_log:
    type: File
    outputBinding:
      glob: 'build_tree_single_strain.log'

baseCommand: ["build_tree_single_strain.py"]
