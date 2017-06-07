#!/usr/bin/env cwl-runner
cwlVersion: v1.0
label: Testing the HMP Cloud Pilot Strainphlan workflow
class: Workflow

requirements:
  - class: DockerRequirement
    dockerPull: umigs/chiron-phlan
  - class: ScatterFeatureRequirement

inputs:
  fasta_input:
    label: Array of fasta sequences
    type: File[]
  genome_input:
    label: Reference genome to use in strainphlan
    type: File
  species_markers:
    type: string
  output_dir:
    type: string
  clades:
    type: string
  marker_in_clade:
    type: float
  num_cores:
    type: int
    default: 1

outputs: []
  outputdir:
    type: Directory
    outputSource: strainphlan/outputdir

steps:
  metaphlan2:
    run: metaphlan2.cwl
    in:
      fasta_input: fasta_input
      num_cores: num_cores
    out: [out_bowtie2, out_sam, out_profile]
    scatter: fasta_input

  sample2markers:
    run: sample2markers.cwl
    in:
      ifn_samples: metaphlan2/out_sam
      output_dir: output_dir
    out: [out_marker]
    scatter: ifn_samples

  identify_clades
    run: strainphlan.cwl
    in:
      ifn_samples:
        default: '*.markers'
      ifn_ref_genomes: genome_file
      output_dir: outputdir
      print_clades_only: true
    out: [outputdir]

  extract_markers:
    run: extract_markers.cwl
    in:
      mpa_pkl: mpa_pkl
      ifn_markers:
        default: 'all_markers.fasta'
      clade: clades
      ofn_markers: species_markers
    out: [out_markers]

  generate_trees:
    run: strainphlan.cwl
    in:
      ifn_samples:
        default: '*.markers'
      ifn_markers: extract_markers/out_markers
      ifn_ref_genomes: genome_file
      output_dir: outputdir
      clades: clades
      marker_in_clade: marker_in_clade
    out: [outputdir]

