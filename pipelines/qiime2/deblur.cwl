#!/usr/bin/env cwl-runner
cwlVersion: v1.0
label: QIIME2 - Deblur denoising tool
class: Workflow

requirements:
  - class: DockerRequirement
    dockerPull: umigs/chiron-qiime2

inputs:
  input_seqs:
    type: File

outputs:
  out_seqs:
    outputSource: denoise_16S/out_seqs
  out_table:
    outputSource: denoise_16S/out_table

steps:
  quality_filter:
    label: Quality filter based on q-score
    run:
      class: CommandLineTool
      baseCommand: ["qiime", "quality-filter", "q-score"]
      inputs:
        input_seqs:
          inputBinding:
            prefix: --i-demux
          type: File
        filtered_seqs:
          inputBinding:
            prefix: --o-filtered-sequences
          type: string
          default: "demux-filtered.qza"
        filter_stats:
          inputBinding:
            prefix: --o-filter-stats
          type: string
          default: "demux-filter-stats.qza"
      outputs:
        out_seqs:
          type: File
          outputBinding:
            glob: $(inputs.filtered_seqs)
        out_stats:
          type: File
          outputBinding:
            glob: $(inputs.filter_stats)
    in:
      input_seqs: input_seqs
    out: [out_seqs, out_stats]

  denoise_16S:
    label: Denoise the sample
    run:
      class: CommandLineTool
      baseCommand: ["qiime", "deblur", "denoise-16S"]
      inputs:
        input_seqs:
          inputBinding:
            prefix: --i-demultiplexed-seqs
          type: File
        trim_length
          inputBinding:
            prefix: --p-trim-length
          type: int
          default: 120
        rep_seqs:
          inputBinding:
            prefix: --o-representative-sequences
          type: string
          default: "rep-seqs.qza"
        table:
          inputBinding:
            prefix: --o-table
          type: string
          default: "table.qza"
        stats:
          inputBinding:
            prefix: --o-stats
          type: string
          default: "deblur-stats.qza"
      outputs:
        out_seqs:
          type: File
          outputBinding:
            glob: $(inputs.rep_seqs)
        out_table:
          type: File
          outputBinding:
            glob: $(inputs.table)
        out_stats:
          type: File
          outputBinding:
            glob: $(inputs.stats)
    in:
      input_seqs: quality_filter/out_seqs
    out: [out_seqs, out_table, out_stats]
