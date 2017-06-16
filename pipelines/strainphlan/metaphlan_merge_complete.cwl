#!/usr/bin/env cwl-runner
cwlVersion: v1.0
label: Complete HMP Cloud Pilot Metaphlan merge workflow
class: Workflow

requirements:
  - class: DockerRequirement
    dockerPull: umigs/chiron-phlan
  - class: ScatterFeatureRequirement
  - class: StepInputExpressionRequirement
  - class: InlineJavascriptRequirement

inputs:
# General options
  input_file:
    label: Array of sample sequences. Start of the pipeline
    type: File[]
  input_type:
    label: Type of input provided among fastq,fasta,multifasta,multifastq,bowtie2out,or sam
    type: string
  seq_prefix:
    label: File prefix to name output
    type: string[]
  num_cores:
    type: int
    default: 1

outputs:
  out_profile:
    type: File[]
    outputSource: metaphlan2/out_profile
  merged_out_profile:
    type: File
    outputSource: merge_tables/out_table

steps:
  metaphlan2:
    run: metaphlan2.cwl
    in:
      input_file: input_file
      seq_prefix: seq_prefix
      input_type: input_type
      num_cores: num_cores
    out: [out_bowtie2, out_sam, out_profile, out_prefix]
    scatter: [input_file, seq_prefix]
    scatterMethod: dotproduct

  merge_tables:
    run: metaphlan_merge_tables.cwl
    in:
      input_tables: metaphlan2/out_profile
    out: [out_table]
