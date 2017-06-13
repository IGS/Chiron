#!/usr/bin/env cwl-runner
cwlVersion: v1.0
label: QIIME2 - Perform differential abundance analysis
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
  seqs_prefix:
    type: string?
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
      table: input_table
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
