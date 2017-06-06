#!/usr/bin/env cwl-runner
cwlVersion: v1.0
label: QIIME2 - A complete QIIME2 workflow (uses DADA2 instead of Deblur)
class: Workflow

requirements:
  - class: DockerRequirement
    dockerPull: umigs/chiron-qiime2
  - class: SubworkflowFeatureRequirement
  - class: StepInputExpressionRequirement

inputs:
  staging_dir:
    label: Directory the barcode and sequence files are located in
    type: Directory
  barcode_file:
    type: File
  sequence_file:
    type: File
  training_classifier:
    label: Training feature classifier file used for taxonomic analysis
    type: File
  metadata_file:
    type: File
  metadata_category_beta:
    label: Feature name to determine beta group significance
    type: string[]
  metadata_category_ancom:
    label: Feature name to determine differential abundance
    type: string
  custom_axis:
    label: Axis label to use in Emperor PCoA plots.
    type: string[]
  collapse_level:
    label: Taxonomic level to collapse into when performing differential abundance analyses
    type: int

outputs:
  demux_visual:
    outputSource: demultiplex/demux_visual
  feat_table_visual:
    outputSource: feat_tbl_summarize/out_table_visual
  feat_seqs_visual:
    outputSource: feat_tbl_tabulate/out_seqs_visual
  taxa_visual:
    outputSource: taxonomic_analysis/taxa_visual
  taxa_barplots:
    outputSource: taxonomic_analysis/barplots
  diff_abundance_visual:
    outputSource: differential_abundance/feat_visual
  collapsed_diff_abundance_visual:
    outputSource: collapsed_differential_abundance/feat_visual
  alpha_visual: # array
      outputSource: alpha_group_significance/out_visual
  beta_visual: # array
      outputSource: beta_group_significance/out_visual
  emperor_visual: # array
      outputSource: PCoA_plot/pcoa_visual

steps:
  demultiplex:
    run: demux-empseq.cwl
    in:
      staging_dir: staging_dir
      barcode_file: barcode_file
      metadata_file: metadata_file
      sequence_file: sequence_file
    out: [demux_seqs, demux_visual]

  dada2:
    run: dada2.cwl
    in:
      input_seqs: demultiplex/demux_seqs
    out: [out_rep_seqs, out_table]

  feat_tbl_summarize:
    run: feat_tbl_summarize.cwl
    in:
      input_table: dada2/out_table
      metadata_file: metadata_file
    out: [out_table_visual]

  feat_tbl_tabulate:
    run: feat_tbl_tabulate_seqs.cwl
    in:
      rep_seqs: dada2/rep_seqs
    out: [out_seqs_visual]

  phylogenetic_analysis:
    run: phylogenetic_analysis.cwl
    in:
      rep_seqs: dada2/rep_seqs
    out: [rooted_tree]

  diversity_core_metrics:
    run: diversity_core_metrics.cwl
    in:
      input_tree: phylogenetic_analysis/rooted_tree
      input_table: dada2/out_table
    out: [out_dir, alpha_vector, distance_matrix, pcoa_results]

  alpha_group_significance:
    run: alpha_significance.cwl
    in:
      input_alpha: diversity_core_metrics/alpha_vector
      metadata_file: metadata_file
    out: [out_visual]
    scatter: input_alpha

  beta_group_significance:
    run: beta_significance.cwl
    in:
      input_matrix: diversity_core_metrics/distance_matrix
      metadata_file: metadata_file
      metadata_category: metadata_category_beta
      out_visualization:
    out: [out_visual]
    scatter: [metadata_category_beta, out_visualization]
    scatterMethod: dotproduct

  PCoA_plot:
    run: emperor_plot.cwl
    in:
      input_pcoa: diversity_core_metrics/pcoa_results
      metadata_file: metadata_file
      custom_axis: custom_axis
    out: [pcoa_visual]
    scatter: [input_pcoa, custom_axis]
    scatterMethod: dotproduct

  taxonomic_analysis:
    run: taxonomic_analysis.cwl
    in:
      input_seqs: dada2/rep_seqs
      classifier: training_classifier
      metadata_file: metadata_file
      input_table: dada2/out_table
    out: [taxa_visual, barplots, taxonomy]

  differential_abundance
    run: diff_abundance.cwl
    in:
      metadata_file: metadata_file
      metadata_category: metadata_category_ancom
      input_table: dada2/out_table
    out: [feat_visual]

  collapsed_differential_abundance
    run: diff_abundance_w_collapse.cwl
    in:
      metadata_file: metadata_file
      metadata_category: metadata_category_ancom
      input_table: dada2/out_table
      collapse_level: collapse_level
      input_taxonomy: taxonomic_analysis/taxonomy
    out: [feat_visual]
