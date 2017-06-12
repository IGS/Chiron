#!/usr/bin/env cwl-runner
cwlVersion: v1.0
label: Strainphlan workflow test
class: CommandLineTool

requirements:
  - class: ShellCommandRequirement

hints:
  - class: DockerRequirement
    dockerPull: umigs/chiron-phlan

inputs:
  sample_markers:
  # NOTE: I could not get the '*' path to work in CWL like the tutorial shows (but it works running the direct command in Docker).  However, the option accepts a space-separated list so we'll use that
    label: List of sample marker files
    inputBinding:
      prefix: --ifn_samples
      itemSeparator: " "
      shellQuote: false
    type: File[]
  ref_marker:
    inputBinding:
      prefix: --ifn_markers
    type: File?
  input_ref_genome:
    inputBinding:
      prefix: --ifn_ref_genomes
    type: File?
  output_dir:
    inputBinding:
      prefix: --output_dir
    type: string
  clades:
    inputBinding:
      prefix: --clades
    type: string?
  marker_in_clade:
    inputBinding:
      prefix: --marker_in_clade
    type: float?
  print_clades_only:
    inputBinding:
      prefix: --print_clades_only
    type: boolean?
  num_cores:
    inputBinding:
      prefix: --nprocs_main
    type: int
    default: 1
outputs:
  out_dir:
    type: Directory
    outputBinding:
      glob: $(inputs.output_dir)
  out_tree:
    type: File?
    outputBinding:
      glob: $('RAxML_bestTree.*.tree')
  out_fasta:
    type: File?
    outputBinding:
      glob: $('*.fasta')
    secondaryFiles: $('^.polymorphic')
  clades_out:
    type: stdout

stdout: clades.txt

baseCommand: ["strainphlan.py"]
