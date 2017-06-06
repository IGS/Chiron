#!/usr/bin/env cwl-runner
cwlVersion: v1.0
label: BioBakery MetaPhlan2 script
class: CommandLineTool

hints:
  - class: DockerRequirement
    dockerPull: umigs/strainphlan2

inputs:
  fasta_input:
    inputBinding:
      position: 1
    type: File
  bowtie2_out:
    inputBinding:
      prefix: --bowtie2out
    default: $(inputs.fasta_input.nameroot)_bowtie2.txt
# NOTE: I wanted to keep the same fasta_input basename but can't find a proper way to do it, so the user will manually enter for now
    type: string?
  sam_out:
    inputBinding:
      prefix: --samout
    default: $(inputs.fasta_input.nameroot)_sam.bz2
    type: string?
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
      glob: $(inputs.bowtie2_out)
  out_sam:
    type: File
    outputBinding:
      glob: $(inputs.sam_out)
  out_profile:
    type: File
    outputBinding:
      type: stdout
stdout: $(inputs.fasta_input.nameroot).profile.txt

baseCommand: ["metaphlan2.py"]
