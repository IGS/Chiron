#!/usr/bin/env cwl-runner
cwlVersion: v1.0
label: Strainphlan workflow test
class: CommandLineTool

hints:
  - class: DockerRequirement
    dockerPull: umigs/chiron-strainphlan

inputs:
  ifn_samples:
    inputBinding:
      prefix: --ifn_samples
    type: string
    default: '*.markers'
  ifn_markers:
    inputBinding:
      prefix: --ifn_markers
    type: string?
  ifn_ref_genomes:
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
outputs:
  outputdir:
    type: Directory
    outputBinding:
      outputEval: $(inputs.output_dir)
  clades_out:
    type: stdout

stdout: clades.txt

baseCommand: ["strainphlan.py"]
