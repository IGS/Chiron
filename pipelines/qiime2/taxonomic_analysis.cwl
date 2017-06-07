#!/usr/bin/env cwl-runner
cwlVersion: v1.0
label: QIIME2 - Perform taxonomic analysis
class: Workflow

hints:
  - class: DockerRequirement
    dockerPull: umigs/chiron-qiime2

inputs:
  rep_seqs:
    type: File
  classifier:
    type: File
  metadata_file:
    type: File
  input_table:
    type: File
outputs:
  taxa_visual:
    type: File
    outputSource: taxa_tabulate/out_visual
  barplots:
    type: File
    outputSource: taxa_barplot/barplots
  taxonomy:
    type: File
    outputSource: classify_sklearn/out_taxa

steps:
  classify_sklearn:
    run:
      class: CommandLineTool
      baseCommand: ["qiime", "feature-classifier", "classify-sklearn"]
      inputs:
        rep_seqs:
          inputBinding:
            prefix: --i-reads
          type: File
        classifier:
          inputBinding:
            prefix: --i-classifier
          type: File
        taxonomy:
          inputBinding:
            prefix: --o-classification
          type: string
          default: "taxonomy.qza"
      outputs:
        out_taxa:
          type: File
          outputBinding:
            glob: $(inputs.taxonomy)
    in:
      rep_seqs: rep_seqs
      classifier: classifier
    out: [out_taxa]
  taxa_tabulate:
    run:
      class: CommandLineTool
      baseCommand: ["qiime", "taxa", "tabulate"]
      inputs:
        taxa_data:
          inputBinding:
            prefix: --i-data
          type: File
        taxa_visualization:
          inputBinding:
            prefix: --o-visualization
          type: string
          default: "taxonomy.qzv"
      outputs:
        out_visual:
          type: File
          outputBinding:
            glob: $(inputs.taxa_visualization)
    in:
      taxa_data: classify_sklearn/out_taxa
    out: [out_visual]
  taxa_barplot:
    run:
      class: CommandLineTool
      baseCommand: ["qiime", "taxa", "barplot"]
      inputs:
        table:
          inputBinding:
            prefix: --i-table
          type: File
        taxa_data:
          inputBinding:
            prefix: --i-taxonomy
          type: File
        metadata:
          inputBinding:
            prefix: --m-metadata-file
          type: File
        plots:
          inputBinding:
            prefix: --o-visualization
          type: string
          default: "taxa-bar-plots.qzv"
      outputs:
        barplots:
          type: File
          outputBinding:
            glob: $(inputs.plots)
    in:
      table: input_table
      taxa_data: classify_sklearn/out_taxa
      metadata: metadata_file
    out: [barplots]
