#!/usr/bin/env cwl-runner
cwlVersion: v1.0
label: Humann2 - Visualize stratified output
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
  output_png:
    inputBinding:
      prefix: --output
    type: string
    default: "plot.png"
  last_metadatum:
    inputBinding:
      prefix: --last-metadatum
    type: string
  focal_metadatum:
    inputBinding:
      prefix: --focal-metadatum
    type: string
  focal_feature:
    inputBinding:
      prefix: --focal-feature
    type: string
  sort_type:
    label: Ways to sort data.  Can specify more than one
    inputBinding:
      prefix: --sort
      itemSeparator: " "
    type: string[]?
  scaling:
    inputBinding:
      prefix: --scaling
    type: string?
  top_strata:
    inputBinding:
      prefix: --top-strata
    type: int?
outputs:
  out_png:
    type: File
    outputBinding:
      glob: $(inputs.output_png)

baseCommand: ["humann2_barplot"]
