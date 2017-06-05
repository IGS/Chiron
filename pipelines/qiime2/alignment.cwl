#!/usr/bin/env cwl-runner
cwlVersion: v1.0
label: QIIME2 - Generate a phylogenetic tree
class: Workflow

inputs:
  rep_seqs:
    type: File
outputs:
  masked_seqs:
    outputSource: alignment_mask/out_masked

steps:
  alignment_mafft:
    run:
      baseCommand: ["qiime", "alignment", "mafft"]
      inputs:
        rep_seqs:
          inputBinding:
            prefix: --i-sequences
          type: File
        aligned_seqs:
          inputBinding:
            prefix: --o-alignment
          type: string
          default: "aligned-rep-seqs.qza"
      outputs:
        out_align:
          type: File
          outputBinding:
            glob: $(inputs.aligned_seqs)
    in:
      rep_seqs: rep_seqs
    out: [out_align]
  alignment_mask
    run:
      baseCommand: ["qiime", "alignment", "mask"]
      inputs:
        aligned_seqs:
          inputBinding:
            prefix: --i-alignment
          type: File
        masked_seqs:
          inputBinding:
            prefix: --o-masked-alignment
          type: string
          default: "masked-aligned-rep-seqs.qza"
      outputs:
        out_masked:
          type: File
          outputBinding:
            glob: $(inputs.masked_seqs)
    in: []
    out: [masked_seqs]
