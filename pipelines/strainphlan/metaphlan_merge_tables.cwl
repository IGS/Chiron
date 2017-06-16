#!/usr/bin/env cwl-runner
cwlVersion: v1.0
label: Merge Metaphlan Tables workflow tool
class: CommandLineTool

requirements:
  - class: ShellCommandRequirement

hints:
  - class: DockerRequirement
    dockerPull: umigs/chiron-phlan

inputs:
  input_tables:
    label: List of input tables
    inputBinding:
      position: 0
      itemSeparator: " "
      shellQuote: false
    type: File[]
outputs:
  out_table:
    type: stdout

stdout: 'merged_abundance_table.txt'

baseCommand: ["merge_metaphlan_tables.py"]
