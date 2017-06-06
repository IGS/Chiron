#!/usr/bin/env cwl-runner
cwlVersion: v1.0
label: QIIME2 - Perform differential abundance analysis on a collapsed taxonomic level
class: Workflow

inputs:
  metadata_file:
    type: File
  metadata_category:
    type: string
  input_table:
    type: File
  collapse_level:
    type: string
  input_taxonomy:
    type: File
outputs:
  feat_visualization:
    outputSource: ancom/out_visualization

steps:
  collapse:
    run:
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
        collapse_level:
          inputBinding:
            prefix: --p-level
          type: int
          default: 2
        collapsed_table:
          inputBinding:
            prefix: --o-collapsed-table
          type: string
          default: "coll-table.qza"
      outputs:
        out_collapsed_table:
          type: File
          outputBinding:
            glob: $(inputs.collapsed_table)
    in:
      table: input_table
      taxonomy_file: taxonomy_file
      collapse_level: collapse_level
    out: [out_collapsed_table]

  add_pseudocount:
    run:
      baseCommand: ["qiime", "composition", "add-pseudocount"]
      inputs:
        table:
          inputBinding:
            prefix: --i-table
          type: File
        composition:
          inputBinding:
            prefix: --o-composition-table
          type: string
          default: "comp-table.qza"
      outputs:
        out_comp_table:
          type: File
          outputBinding:
            glob: $(inputs.composition)
    in:
      table: collapse/out_collapsed_table
    out: [out_comp_table]

  ancom
    run:
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
        feat_visualization:
          inputBinding:
            prefix: --o-visualization
          type: string
          default: ancom.qcv
      outputs:
        out_visualization:
          type: File
          outputBinding:
            glob: $(inputs.feat_visualization)
    in:
      comp_table: add_pseudocount/out_comp_table
      metadata_file: metadata_file
      metadata_category: metadata_category
    out: [out_visualization]
