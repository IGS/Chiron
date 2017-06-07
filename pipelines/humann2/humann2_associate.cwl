#!/usr/bin/env cwl-runner
cwlVersion: v1.0
label: Humann2 - Associate functions with metadata
class: CommandLineTool

hints:
  - class: DockerRequirement
    dockerPull: umigs/chiron-humann2

inputs:
  input_pcl:
    label: Accepts FASTA, FASTQ, SAM, or m8 formats
    inputBinding:
      prefix: --input
    type: File
  output_stats:
    inputBinding:
      prefix: --output
    type: string
    default: "stats.txt"
  last_metadatum:
    inputBinding:
      prefix: --last-metadatum
    type: string
  focal_metadatum:
    inputBinding:
      prefix: --focal-metadatum
    type: string
  focal_type:
    inputBinding:
      prefix: --focal-type
    type: string
    default: "categorical"
outputs:
  out_stats:
    type: File
    outputBinding:
      glob: $(inputs.output_stats)

baseCommand: ["humann2_associate"]
