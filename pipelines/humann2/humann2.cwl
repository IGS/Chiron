#!/usr/bin/env cwl-runner
cwlVersion: v1.0
label: Humann2 - Run Humann2 tool
class: CommandLineTool

hints:
  - class: DockerRequirement
    dockerPull: umigs/chiron-humann2

inputs:
  input_file:
    label: Accepts FASTA, FASTQ, SAM, or m8 formats
    inputBinding:
      prefix: --input
    type: File
  output_dir:
    inputBinding:
      prefix: --output
    type: string
  gap_fill:
    label: Can be set to "on".  Default is "off"
    inputBinding:
      prefix: --gap-fill
    type: string?
  bypass_translated_search:
    label: Runs all of the alignment steps except the translated search
    inputBinding:
      prefix: --bypass-translated-search
    type: boolean?
  bypass_nucleotide_search:
    label: Bypasses all of the alignment steps before the translated search
    inputBinding:
      prefix: --bypass-nucleotide-search
    type: boolean?
  num_threads:
    inputBinding:
      prefix: --threads
    type: int
    default: 1
outputs:
  out_dir:
    type: Directory
    outputBinding:
      glob: $(inputs.output_dir)
  out_gene_families:
    type: File
    outputBinding:
      glob: $(inputs.output_dir + '/' + inputs.input_file.nameroot + '_genefamilies.tsv')
  out_path_abundance:
    type: File
    outputBinding:
      glob: $(inputs.output_dir + '/' + inputs.input_file.nameroot + '_pathabundance.tsv')
  out_path_coverage:
    type: File
    outputBinding:
      glob: $(inputs.output_dir + '/' + inputs.input_file.nameroot + '_pathcoverage.tsv')
  out_prefix:
    type: string
    outputBinding:
      outputEval: $(inputs.input_file.nameroot)

baseCommand: ["humann2"]
