#!/usr/bin/env cwl-runner
cwlVersion: v1.0
label: BioBakery MetaPhlan2 script
class: CommandLineTool

#requirements:
#  - class: DockerRequirement
#    dockerPull: jorvis/hmp-cloud-pilot

inputs:
  fasta_input:
    inputBinding:
      position: 1
    type: File
    type: File
  bowtie2_out:
    inputBinding:
      prefix: --bowtie2out
      #valueFrom: $(inputs.fasta_input.nameroot)_bowtie2.txt
# NOTE: I wanted to keep the same fasta_input name root but can't find a proper way to do it, so the user will manually enter for now
    type: File
  sam_out:
    inputBinding:
      prefix: --samout
      #valueFrom: $(inputs.fasta_input.nameroot)_sam.bz2
    type: File
  input_type:
    inputBinding:
      prefix: --input_type
    type: string
    default: multifasta
  num_cores:
    inputBinding:
      prefix: --nproc
    type: int
    default: 1
outputs:
  out_bowtie2:
    type: File
    outputBinding:
      glob: '*.bowtie2.txt'
  out_sam:
    type: File
    outputBinding:
      glob: '*.sam.bz2'
  out_profile:
    type: File
    outputBinding:
    type: stdout
stdout: $(inputs.fasta_input.nameroot).profile.txt

baseCommand: ["metaphlan2.py"]
