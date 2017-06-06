#!/usr/bin/env cwl-runner
cwlVersion: v1.0
label: QIIME2 - Perform differential abundance analysis
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
outputs:
  feat_visual:
    type: File
    outputSource: ancom/out_visual

steps:
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
      table: input_table
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
