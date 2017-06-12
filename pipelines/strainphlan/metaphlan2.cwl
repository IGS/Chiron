#!/usr/bin/env cwl-runner
cwlVersion: v1.0
label: BioBakery MetaPhlan2 script
class: CommandLineTool

requirements:
  - class: InlineJavascriptRequirement

hints:
  - class: DockerRequirement
    dockerPull: umigs/chiron-phlan

inputs:
  input_file:
    inputBinding:
      position: 1
    type: File
  seq_prefix:
    label: Prefix to give to output files
    type: string
  index_dir:
    type: Directory
  base_str:
    type: string
  mpa_pkl:
    label: The metadata pickled MetaPhlAn filename
    type: string
  bowtie2_out:
    inputBinding:
      prefix: --bowtie2out
      valueFrom: $(inputs.seq_prefix + '_bowtie2_out.bz2')
    type: string?
    default: 'bowtie2_out.bz2'
  sam_out:
    inputBinding:
      prefix: --samout
      valueFrom: $(inputs.seq_prefix + '.sam.bz2')
    type: string?
    default: 'sam.bz2'
  profile_out:
    inputBinding:
      position: 2
      valueFrom: $(inputs.seq_prefix + '_profile.txt')
    type: string?
    default: 'profile.txt'
  input_type:
    label: Type of input provided among fastq,fasta,multifasta,multifastq,bowtie2out,or sam
    inputBinding:
      prefix: --input_type
    type: string
  num_cores:
    inputBinding:
      prefix: --nproc
    type: int
    default: 1
outputs:
  out_bowtie2:
    type: File
    outputBinding:
      glob: $('*' +inputs.bowtie2_out)
  out_sam:
    type: File
    outputBinding:
      glob: $('*' + inputs.sam_out)
  out_profile:
    type: File
    outputBinding:
      glob: $('*' + inputs.profile_out)
  out_prefix:
    type: string
    outputBinding:
      outputEval: $(inputs.seq_prefix)

arguments:
  - valueFrom: $(inputs.index_dir.path + '/' + inputs.base_str)
    prefix: --bowtie2db
  - valueFrom: $(inputs.index_dir.path + '/' + inputs.mpa_pkl)
    prefix: --mpa_pkl

baseCommand: ["metaphlan2.py"]
