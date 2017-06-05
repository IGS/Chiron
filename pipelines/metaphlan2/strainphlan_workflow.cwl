#!/usr/bin/env cwl-runner
cwlVersion: v1.0
label: Testing the HMP Cloud Pilot Strainphlan workflow
class: Workflow

requirements:
  - class: DockerRequirement
    dockerPull: umigs/chiron-strainphlan
  - class: ScatterFeatureRequirement

inputs:
  fasta_input:
    type: File[]
  genome_input:
    type: File
  sam_out:
    type: File
  bowtie2_out:
    type: File
  ifn_markers:
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
      ifn_ref_genomes: genome_file
      output_dir: outputdir
      clades: clades
      marker_in_clade: marker_in_clade
    out: [outputdir]

