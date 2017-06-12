#!/usr/bin/env cwl-runner
cwlVersion: v1.0
label: Complete HMP Cloud Pilot Strainphlan workflow
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
  bowtie2_index_dir:
    label: Location of a bowtie2 index
    type: Directory
  bowtie2_base_str:
    label: Index prefix of the reference to be inspected
    type: string
  mpa_pkl_filename:
    label: The metadata pickled MetaPhlAn filename
    type: string
  num_cores:
    type: int
    default: 1
# Strainphlan options
  genome_input:
    label: Reference genome to use in strainphlan
    type: File
  clades:
    type: string
  marker_in_clade:
    type: float
# Graphlan options
  metadata_file:
    label: Metadata file to add to tree
    type: File
  metadata_category:
    type: string

outputs:
  out_profile:
    type: File[]
    outputSource: metaphlan2/out_profile
  out_clades:
    type: File
    outputSource: identify_clades/clades_out
  out_fasta:
    type: File
    outputSource: build_tree/out_fasta
  best_tree:
    type: File
    outputSource: build_tree/out_tree
  dendrogram_png:
    type: File
    outputSource: create_dendrogram/out_png
  single_strain_dendrogram_png:
    type: File
    outputSource: create_single_strain_dendrogram/out_png

steps:
  metaphlan2:
    run: metaphlan2.cwl
    in:
      input_file: input_file
      seq_prefix: seq_prefix
      input_type: input_type
      index_dir: bowtie2_index_dir
      base_str: bowtie2_base_str
      mpa_pkl: mpa_pkl_filename
      num_cores: num_cores
    out: [out_bowtie2, out_sam, out_profile, out_prefix]
    scatter: [input_file, seq_prefix]
    scatterMethod: dotproduct

  sam2markers:
    run: sample2markers.cwl
    in:
      ifn_samples: metaphlan2/out_sam
      input_type:
        default: 'sam'
      output_dir:
        default: '.'
      num_cores: num_cores
    out: [out_marker]
    scatter: [ifn_samples]

  identify_clades:
    run: strainphlan.cwl
    in:
      sample_markers: sam2markers/out_marker
      output_dir:
        default: '.'
      print_clades_only:
        default: true
    out: [clades_out]

  bowtie2_inspect:
    run: bowtie2_inspect.cwl
    in:
      index_dir: bowtie2_index_dir
      base_str: bowtie2_base_str
    out: [out_fasta]

  extract_db_markers:
    run: extract_markers.cwl
    in:
      index_dir: bowtie2_index_dir
      mpa_pkl: mpa_pkl_filename
      ifn_markers: bowtie2_inspect/out_fasta
      clade: clades
    out: [out_marker]

  build_tree:
    run: strainphlan.cwl
    in:
      sample_markers: sam2markers/out_marker
      ref_marker: extract_db_markers/out_marker
      input_ref_genome: genome_input
      output_dir:
        default: '.'
      clades: clades
      marker_in_clade: marker_in_clade
    out: [out_dir, out_tree, out_fasta]

#  add_metadata_to_tree:
#    run: add_metadata_tree.cwl
#    in:
#      tree_input: build_tree/out_tree
#      metadata_input: metadata_file
#      metadata_category: metadata_category
#    out: [out_tree]

#  create_dendrogram:
#    run:  plot_tree_graphlan.cwl
#    in:
#      tree_input: add_metadata_to_tree/out_tree
#      metadata_category: metadata_category
#    out: [out_png]

#  build_tree_single_strain:
#    run: build_tree_single_strain.cwl
#    in:
#      alignment_input: build_tree/out_fasta
#      num_cores: num_cores
#    out: [out_tree]

#  add_metadata_to_single_strain_tree:
#    run: add_metadata_tree.cwl
#    in:
#      tree_input: build_tree_single_strain/out_tree
#      metadata_input: metadata_file
#      metadata_category: metadata_category
#    out: [out_tree]

#  create_single_strain_dendrogram:
#    run: plot_tree_graphlan.cwl
#    in:
#      tree_input: add_metadata_to_single_strain_tree/out_tree
#      metadata_category: metadata_category
#    out: [out_png]

