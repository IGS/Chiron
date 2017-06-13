#!/usr/bin/env cwl-runner
cwlVersion: v1.0
label: QIIME2 - Perform differential abundance analysis on a collapsed taxonomic level
class: Workflow

hints:
  - class: DockerRequirement
    dockerPull: umigs/chiron-qiime2
  - class: StepInputExpressionRequirement
  - class: InlineJavascriptRequirement

inputs:
  metadata_file:
    type: File
  metadata_category:
    type: string
  input_table:
    type: File
  collapse_level:
    type: int
  taxonomy_file:
    type: File
  seqs_prefix:
    type: string?
outputs:
  feat_visual:
    type: File
    outputSource: ancom/out_visual

steps:
  collapse:
    run:
      class: CommandLineTool
      baseCommand: ["qiime", "taxa", "collapse"]
      inputs:
        table:
          inputBinding:
            prefix: --i-table
          type: File
        taxonomy_file:
          inputBinding:
            prefix: --i-taxonomy
          type: File
        seqs_prefix:
          type: string?
        collapse_level:
          inputBinding:
            prefix: --p-level
          type: int
          default: 2
        collapsed_table:
          inputBinding:
            prefix: --o-collapsed-table
            valueFrom: $(inputs.seqs_prefix + 'level' + inputs.collapse_level + '-coll-table.qza')
          type: string
          default: 'coll-table.qza'
      outputs:
        out_collapsed_table:
          type: File
          outputBinding:
            glob: $('*' + inputs.collapsed_table)
    in:
      table: input_table
      taxonomy_file: taxonomy_file
      collapse_level: collapse_level
      seqs_prefix: seqs_prefix
    out: [out_collapsed_table]

  add_pseudocount:
    run:
      class: CommandLineTool
      baseCommand: ["qiime", "composition", "add-pseudocount"]
      inputs:
        table:
          inputBinding:
            prefix: --i-table
          type: File
        seqs_prefix:
          type: string?
        composition:
          inputBinding:
            prefix: --o-composition-table
            valueFrom: $(inputs.seqs_prefix + 'comp-table.qza')
          type: string
          default: 'comp-table.qza'
      outputs:
        out_comp_table:
          type: File
          outputBinding:
            glob: $('*' + inputs.composition)
    in:
      table: collapse/out_collapsed_table
      seqs_prefix: seqs_prefix
    out: [out_comp_table]

  ancom:
    run:
      class: CommandLineTool
      baseCommand: ["qiime", "composition", "ancom"]
      inputs:
        comp_table:
          inputBinding:
            prefix: --i-table
          type: File
        metadata_file:
          inputBinding:
            prefix: --m-metadata-file
          type: File
        metadata_category:
          inputBinding:
            prefix: --m-metadata-category
          type: string
        seqs_prefix:
          type: string?
        feat_visualization:
          inputBinding:
            prefix: --o-visualization
            valueFrom: $(inputs.seqs_prefix + 'ancom.qzv')
          type: string
          default: 'ancom.qzv'
      outputs:
        out_visual:
          type: File
          outputBinding:
            glob: $('*' + inputs.feat_visualization)
    in:
      comp_table: add_pseudocount/out_comp_table
      metadata_file: metadata_file
      metadata_category: metadata_category
      seqs_prefix: seqs_prefix
    out: [out_visual]
