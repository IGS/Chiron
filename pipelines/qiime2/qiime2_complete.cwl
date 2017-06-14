#!/usr/bin/env cwl-runner
cwlVersion: v1.0
label: QIIME2 - A complete QIIME2 workflow (uses DADA2 instead of Deblur)
class: Workflow

requirements:
  - class: DockerRequirement
    dockerPull: umigs/chiron-qiime2
  - class: SubworkflowFeatureRequirement
  - class: StepInputExpressionRequirement
  - class: InlineJavascriptRequirement
  - class: ScatterFeatureRequirement

inputs:
  staging_dir:
    label: Directory the barcode and sequence files are located in
    type: Directory
  metadata_file:
    type: File
  metadata_category:
    label: Feature name to determine beta group significance and differential_abundance
    type: string
# DADA2 inputs
  trim_left:
    label: How many bases to trim off the left-hand side of the sequences
    type: int
    default: 0
  trunc_len:
    label: Length of sequence truncation
    type: int
    default: 120
# Alpha/Beta diversity inputs
  sampling_depth:
    label: Amount of subsampling so that each sample has this number in the output table
    type: int
    default: 1080
  custom_axis:
    label: Axis label to use in Emperor PCoA plots.
    type: string
# Taxonomic analysis inputs
  training_classifier:
    label: Training feature classifier file used for taxonomic analysis
    type: File
# Differential abundance analysis inputs
  collapse_level:
    label: Taxonomic level to collapse into when performing differential abundance analyses
    type: int

outputs:
# Demultiplex outputs
  demux_visual:
    type: File
    outputSource: demultiplex/demux_visual
  demux_seqs:
    type: File
    outputSource: demultiplex/demux_seqs
# Dada2 outputs
  rep_seqs:
    type: File
    outputSource: dada2/out_rep_seqs
  rep_table:
    type: File
    outputSource: dada2/out_table
# FeatureTable and FeatureData outputs
  feat_table_visual:
    type: File
    outputSource: feat_tbl_summarize/out_table_visual
  feat_seqs_visual:
    type: File
    outputSource: feat_tbl_tabulate/out_seqs_visual
# Phylogenetic analysis
  rooted_tree:
    type: File
    outputSource: phylogenetic_analysis/rooted_tree
# Alpha/Beta diversity output
  alpha_faith_visual:
    type: File
    outputSource: alpha_group_significance_faith/out_visual
  alpha_evenness_visual:
    type: File
    outputSource: alpha_group_significance_evenness/out_visual
  beta_visual:
    type: File
    outputSource: beta_group_significance/out_visual
  emperor_unweighted_visual:
    type: File
    outputSource: PCoA_plot_unweighted/pcoa_visual
  emperor_bray_visual:
    type: File
    outputSource: PCoA_plot_bray/pcoa_visual
# Taxonomic analysis outputs
  taxa_visual:
    type: File
    outputSource: taxonomic_analysis/taxa_visual
  taxa_barplots:
    type: File
    outputSource: taxonomic_analysis/barplots
# Differential abundance outputs
  diff_abundance_visual:
    type: File
    outputSource: differential_abundance/feat_visual
  collapsed_diff_abundance_visual:
    type: File
    outputSource: collapsed_differential_abundance/feat_visual

steps:

  demultiplex:
    run: demux_empseq.cwl
    in:
      staging_dir: staging_dir
      metadata_file: metadata_file
    out: [demux_seqs, demux_visual]

  dada2:
    run: dada2.cwl
    in:
      input_seqs: demultiplex/demux_seqs
      trim_left: trim_left
      trunc_len: trunc_len
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
      rep_seqs: dada2/out_rep_seqs
    out: [out_seqs_visual]

  phylogenetic_analysis:
    run: phylogenetic_analysis.cwl
    in:
      rep_seqs: dada2/out_rep_seqs
    out: [rooted_tree]

  diversity_core_metrics:
    run: diversity_core_metrics.cwl
    in:
      input_tree: phylogenetic_analysis/rooted_tree
      input_table: dada2/out_table
      sampling_depth: sampling_depth
    out: [out_dir]

  alpha_group_significance_faith:
    run: alpha_significance.cwl
    in:
      input_dir: diversity_core_metrics/out_dir
      vector_file_base:
        default: 'faith_pd_vector.qza'
      metadata_file: metadata_file
      out_visualization:
        valueFrom: 'faith-pd-group-significance.qzv'
    out: [out_visual]

  alpha_group_significance_evenness:
    run: alpha_significance.cwl
    in:
      input_dir: diversity_core_metrics/out_dir
      vector_file_base:
        default: 'evenness_vector.qza'
      metadata_file: metadata_file
      out_visualization:
        valueFrom: 'evenness-group-significance.qzv'
    out: [out_visual]

# NOTE: Tutorial calls twice for separate metadata categories.  Only performing once
  beta_group_significance:
    run: beta_significance.cwl
    in:
      input_dir: diversity_core_metrics/out_dir
      matrix_file_base:
        default: 'unweighted_unifrac_distance_matrix.qza'
      metadata_file: metadata_file
      metadata_category: metadata_category
      out_visualization:
        valueFrom: $('unweighted-unifrac-' + inputs.metadata_category + '-significance.qzv')
    out: [out_visual]

  PCoA_plot_unweighted:
    run: emperor_plot.cwl
    in:
      input_dir: diversity_core_metrics/out_dir
      pcoa_file_base:
        default: 'unweighted_unifrac_pcoa_results.qza'
      metadata_file: metadata_file
      custom_axis: custom_axis
      out_visualization:
        valueFrom: 'unweighted-unifrac-emperor.qzv'
    out: [pcoa_visual]

  PCoA_plot_bray:
    run: emperor_plot.cwl
    in:
      input_dir: diversity_core_metrics/out_dir
      pcoa_file_base:
        default: 'bray_curtis_pcoa_results.qza'
      metadata_file: metadata_file
      custom_axis: custom_axis
      out_visualization:
        valueFrom: 'bray-curtis-emperor.qzv'
    out: [pcoa_visual]

  taxonomic_analysis:
    run: taxonomic_analysis.cwl
    in:
      rep_seqs: dada2/out_rep_seqs
      classifier: training_classifier
      metadata_file: metadata_file
      input_table: dada2/out_table
    out: [taxa_visual, barplots, taxonomy]

  differential_abundance:
    run: diff_abundance.cwl
    in:
      metadata_file: metadata_file
      metadata_category: metadata_category
      input_table: dada2/out_table
    out: [feat_visual]

  collapsed_differential_abundance:
    run: diff_abundance_w_collapse.cwl
    in:
      metadata_file: metadata_file
      metadata_category: metadata_category
      input_table: dada2/out_table
      collapse_level: collapse_level
      taxonomy_file: taxonomic_analysis/taxonomy
    out: [feat_visual]
