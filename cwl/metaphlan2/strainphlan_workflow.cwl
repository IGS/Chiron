#!/usr/bin/env cwl-runner
cwlVersion: v1.0
label: Testing the HMP Cloud Pilot Strainphlan workflow
class: Workflow

requirements:
  - class: DockerRequirement
    dockerPull: umigs/chiron-strainphlan
  - class: ScatterFeatureRequirement

inputs:
  fasta_url:
    type: string[]
  genome_url: string
  sam_out: File
  bowtie2_out: File
  ifn_markers: string
  output_dir: string
  clades: string
  marker_in_clade: float
  num_cores:
    type: int
    default: 1

outputs: []
  outputdir:
    type: Directory
    outputSource: strainphlan/outputdir

steps:
  wget_fasta:
    run: ../shared/wget.cwl
    in:
      url: fasta_url
    out: [outfile]
    scatter: url

  wget_genome:
    run: ../shared/wget.cwl
    in:
      url: genome_url
    out: [outfile]

  metaphlan2:
    run: metaphlan2.cwl
    in:
      fasta_input: wget_fasta/outfile
      profile: metaphlan2_profile
      sam_out: sam_out
      bowtie2_out: bowtie2_out
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

  strainphlan:
    run: strainphlan.cwl
    in:
      ifn_markers: ifn_markers
      ifn_ref_genomes: wget_genome/outfile
      output_dir: outputdir
      clades: clades
      marker_in_clade: marker_in_clade
    out: [outputdir]

