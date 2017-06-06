#!/usr/bin/env cwl-runner
cwlVersion: v1.0
label: QIIME2 - Perform differential abundance analysis on a collapsed taxonomic level
class: Workflow

hints:
  - class: DockerRequirement
    dockerPull: umigs/chiron-qiime2

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
      class: CommandLineTool
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
        feat_visualization:
          inputBinding:
            prefix: --o-visualization
          type: string
          default: ancom.qcv
      outputs:
        out_visual:
          type: File
          outputBinding:
            glob: $(inputs.feat_visualization)
    in:
      comp_table: add_pseudocount/out_comp_table
      metadata_file: metadata_file
      metadata_category: metadata_category
    out: [out_visual]
