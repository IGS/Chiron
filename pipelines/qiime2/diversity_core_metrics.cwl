#!/usr/bin/env cwl-runner
cwlVersion: v1.0
label: QIIME2 - Compute core metrics for alpha/beta diversity analysis
class: CommandLineTool

hints:
  - class: DockerRequirement
    dockerPull: umigs/chiron-qiime2

inputs:
  input_tree:
    inputBinding:
      prefix: --i-phylogeny
    type: File
  input_table:
    inputBinding:
      prefix: --i-table
    type: File
  sampling_depth:
    inputBinding:
      prefix: ---p-sampling-depth
    type: int
    default: 1080
  output_dir:
    inputBinding:
      prefix: --output-dir
    type: string
    default: "core-metrics-results"
outputs:
  out_dir:
    type: Directory
    outputBinding:
      glob: $(inputs.output_dir)
  distance_matrix:
    type: File
    outputBinding:
      glob: $(inputs.output_dir + '/unweighted_unifrac_distance_matrix.qza')
  pcoa_results:
    type:
      type: array
      items: File
    outputBinding:
      glob: [$(inputs.output_dir + '/unweighted_unifrac_pcoa_results.qza')][$(inputs.output_dir + '/bray_curtis_pcoa_results.qza')]
  alpha_vector:
    type:
      type: array
      items: File
    outputBinding:
      glob: [$(inputs.output_dir + '/faith_pd_vector.qza')][$(inputs.output_dir + '/evenness_vector.qza')]
baseCommand: ["qiime", "diversity", "core-metrics"]
