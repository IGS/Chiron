#!/usr/bin/env cwl-runner
cwlVersion: v1.0
label: Humann2 - Complete pipeline that merges Humann2 output first
class: Workflow

requirements:
  - class: DockerRequirement
    dockerPull: umigs/chiron-humann2
  - class: ScatterFeatureRequirement
  - class: StepInputExpressionRequirement
  - class: InlineJavascriptRequirement

inputs:
  input_dir:
    label: Directory with some Humann2 output
    type: Directory
  file_name:
    label: File type to merge (i.e. 'genefamilies')
    type: string
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
  merged_tsv:
    type: File
    outputSource: humann2_join_tables/out_tsv
  feature_tsv:
    type: File
    outputSource: rename_table/out_tsv
  normalize_tsv:
    type: File
    outputSource: renorm_table/out_tsv
  regrouped_tsv:
    type: File
    outputSource: regroup_table/out_tsv

steps:

  humann2_join_tables:
    run: humann2_join_tables.cwl
    in:
      input_dir: input_dir
      file_name: file_name
      output_tsv:
        valueFrom: $(inputs.input_dir.basename + '_' + inputs.file_name + '.tsv')
    out: [out_tsv]

  rename_table:
    run: humann2_rename_table.cwl
    in:
      input_tsv: humann2_join_tables/out_tsv
      output_tsv:
        source: humann2_join_tables/out_tsv
        valueFrom: $(self.nameroot + '-names.tsv')
      names: feat_db
    out: [out_tsv]

  renorm_table:
    run: humann2_renorm_table.cwl
    in:
      input_tsv: humann2_join_tables/out_tsv
      output_tsv:
        source: humann2_join_tables/out_tsv
        valueFrom: $(self.nameroot + '-' + inputs.units + '.tsv')
      units: normalize_units
      update_snames: update_snames
    out: [out_tsv]

  regroup_table:
    run: humann2_regroup_table.cwl
    in:
      input_tsv: renorm_table/out_tsv
      output_tsv:
        source: renorm_table/out_tsv
        valueFrom: $(self.nameroot + '-' + inputs.groups +'.tsv')
      groups: regrouping_category
    out: [out_tsv]
