#!/usr/bin/env cwl-runner
cwlVersion: v1.0
label: Humann2 - Complete pipeline
class: Workflow

requirements:
  - class: DockerRequirement
    dockerPull: umigs/chiron-humann2
  - class: ScatterFeatureRequirement
  - class: StepInputExpressionRequirement
  - class: InlineJavascriptRequirement

inputs:
  input_file:
    label: Sample inputs
    type: File[]
# Humann2 options
  humann2_output_dir:
    label: Output Directory used for storing humann2 output
    type: string
    default: '.'
  gap_fill:
    type: string
    default: "off"
  bypass_translated_search:
    type: boolean
    default: false
  num_cores:
    type: int
    default: 1
# Rename Table option
  feat_db:
    type: string
    default: 'uniref90'
# Renorm Table options
  normalize_units:
    label: Compositional units to normalize to (copies per million - 'cpm' or relative abundance)
    type: string
    default: 'cpm'
  update_snames:
    label: update sample names header
    type: boolean
    default: true
# Regroup Table option
  regrouping_category:
    label: Categories in which to regroup our Humann2 table
    type: string
    default: 'uniref90_level4ec'

outputs:
  genefamilies_tsv:
    type: File[]
    outputSource: humann2/out_gene_families
#  feature_tsv:
#    type: File[]
#    outputSource: rename_table/out_tsv
#  normalize_tsv:
#    type: File[]
#    outputSource: renorm_table/out_tsv
#  regrouped_tsv:
#    type: File[]
#    outputSource: regroup_table/out_tsv

steps:

  humann2:
    run: humann2.cwl
    in:
      input_file: input_file
      output_dir: humann2_output_dir
      gap_fill: gap_fill
      bypass_translated_search: bypass_translated_search
      num_threads: num_cores
    out: [out_dir, out_gene_families]
    scatter: [input_file]

#  rename_table:
#    run: humann2_rename_table.cwl
#    in:
#      input_tsv: humann2/out_gene_families
#      output_tsv:
#        source: humann2/out_gene_families
#        valueFrom: $(self.nameroot + '-names.tsv')
#      names: feat_db
#    out: [out_tsv]
#    scatter: [input_tsv]

#  renorm_table:
#    run: humann2_renorm_table.cwl
#    in:
#      input_tsv: humann2/out_gene_families
#      output_tsv:
#        source: humann2/out_gene_families
#        valueFrom: $(self.nameroot + '-' + inputs.units + '.tsv')
#      units: normalize_units
#      update_snames: update_snames
#    out: [out_tsv]
#    scatter: [input_tsv]

#  regroup_table:
#    run: humann2_regroup_table.cwl
#    in:
#      input_tsv: renorm_table/out_tsv
#      output_tsv:
#        source: renorm_table/out_tsv
#        valueFrom: $(self.nameroot + '-' + inputs.groups +'.tsv')
#      groups: regrouping_category
#    out: [out_tsv]
#    scatter: [input_tsv]
