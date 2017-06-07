#!/usr/bin/env cwl-runner
cwlVersion: v1.0
label: QIIME2 - Demultiplex input EMP Single-End Sequences
class: Workflow

hints:
  - class: DockerRequirement
    dockerPull: umigs/chiron-qiime2

inputs:
  staging_dir:
    label: Directory the barcode and sequence files are located in
    type: Directory
  barcode_file:
    type: File
  metadata_file:
    type: File
  sequence_file:
    type: File

outputs:
  demux_seqs:
    type: File
    outputSource: demux_emp_single/outfile
  demux_visual:
    type: File
    outputSource: demux_summarize/outfile

steps:
  tools_import:
    label: Import the EMPSingleEndSequences QIIME plugin
    run:
      class: CommandLineTool
      baseCommand: ["qiime", "tools", "import"]
      inputs:
        input_type:
          inputBinding:
            prefix: --type
          type: string
          default: EMPSingleEndSequences
        input_path:
          inputBinding:
            prefix: --input-path
          type: Directory
          default: .
        output_path:
          inputBinding:
            prefix: --output-path
          type: string
          default: "emp-single-end-sequences.qza"
      outputs:
        outpath:
          type: File
          outputBinding:
            glob: $(inputs.output_path)
    in:
      input_path: staging_dir
    out: [outpath]

  demux_emp_single:
    label: Demultiplex the sequence
    run:
      class: CommandLineTool
      baseCommand: ["qiime", "demux", "emp-single"]
      inputs:
        input_seqs:
          inputBinding:
            prefix: --i-seqs
          type: File
        barcodes_file:
          inputBinding:
            prefix: --m-barcodes-file
          type: File
        barcodes_category:
          inputBinding:
            prefix: --m-barcodes-category
          type: string
          default: BarcodeSequence
        output_file:
          inputBinding:
            prefix: --o-per-sample-sequences
          type: string
          default: "demux.qza"
      outputs:
        outfile:
          type: File
          outputBinding:
            glob: $(inputs.output_file)
    in:
      input_seqs: tools_import/outpath
      barcodes_file: metadata_file
    out: [outfile]

  demux_summarize:
    label: Generate summary of demultiplexing results
    run:
      class: CommandLineTool
      baseCommand: ["qiime", "demux", "summarize"]
      inputs:
        input_data:
          inputBinding:
            prefix: --i-data
          type: File
        output_file:
          inputBinding:
            prefix: --o-visualization
          type: string
          default: "demux.qzv"
      outputs:
        outfile:
          type: File
          outputBinding:
            glob: $(inputs.output_file)
    in:
      input_data: demux_emp_single/outfile
    out: [outfile]
