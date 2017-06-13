#!/usr/bin/env cwl-runner
cwlVersion: v1.0
label: Extracts information from a Bowtie index about what kind of index it is and what reference sequences were used to build it
class: CommandLineTool

requirements:
  - class: InlineJavascriptRequirement

hints:
  - class: DockerRequirement
    dockerPull: umigs/chiron-phlan

# bowtie2-inspect ../db_v20/mpa_v20_m200 > db_markers/all_markers.fasta

inputs:
  index_dir:
    type: Directory
  base_str:
    type: string
outputs:
  out_fasta:
    type: stdout
stdout: 'all_markers.fasta'

arguments:
  - valueFrom: $(inputs.index_dir.path + '/' + inputs.base_str)
    position: 1

baseCommand: ["bowtie2-inspect"]
