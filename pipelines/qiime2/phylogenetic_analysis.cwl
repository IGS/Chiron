#!/usr/bin/env cwl-runner
cwlVersion: v1.0
label: QIIME2 - Generate a phylogenetic tree
class: Workflow

hints:
  - class: DockerRequirement
    dockerPull: umigs/chiron-qiime2
  - class: StepInputExpressionRequirement
  - class: InlineJavascriptRequirement

inputs:
  rep_seqs:
    type: File
  seqs_prefix:
    type: string?
outputs:
  rooted_tree:
    type: File
    outputSource: phylogeny_midpoint_root/out_rooted

steps:
  alignment_mafft:
    run:
      class: CommandLineTool
      baseCommand: ["qiime", "alignment", "mafft"]
      inputs:
        rep_seqs:
          inputBinding:
            prefix: --i-sequences
          type: File
        seqs_prefix:
          type: string?
        aligned_seqs:
          inputBinding:
            prefix: --o-alignment
            valueFrom: $(inputs.seqs_prefix + 'aligned-rep-seqs.qza')
          type: string
          default: 'aligned-rep-seqs.qza'
      outputs:
        out_align:
          type: File
          outputBinding:
            glob: $('*' + inputs.aligned_seqs)
    in:
      rep_seqs: rep_seqs
      seqs_prefix: seqs_prefix
    out: [out_align]
  alignment_mask:
    run:
      class: CommandLineTool
      baseCommand: ["qiime", "alignment", "mask"]
      inputs:
        aligned_seqs:
          inputBinding:
            prefix: --i-alignment
          type: File
        seqs_prefix:
          type: string?
        masked_seqs:
          inputBinding:
            prefix: --o-masked-alignment
            valueFrom: $(inputs.seqs_prefix + 'masked-aligned-rep-seqs.qza')
          type: string
          default: 'masked-aligned-rep-seqs.qza'
      outputs:
        out_masked:
          type: File
          outputBinding:
            glob: $('*' + inputs.masked_seqs)
    in:
      aligned_seqs: alignment_mafft/out_align
      seqs_prefix: seqs_prefix
    out: [out_masked]
  phylogeny_fasttree:
    run:
      class: CommandLineTool
      baseCommand: ["qiime", "phylogeny", "fasttree"]
      inputs:
        masked_seqs:
          inputBinding:
            prefix: --i-alignment
          type: File
        seqs_prefix:
          type: string?
        tree:
          inputBinding:
            prefix: --o-tree
            valueFrom: $(inputs.seqs_prefix + 'unrooted-tree.qza')
          type: string
          default: 'unrooted-tree.qza'
      outputs:
        out_tree:
          type: File
          outputBinding:
            glob: $('*' + inputs.tree)
    in:
      masked_seqs: alignment_mask/out_masked
      seqs_prefix: seqs_prefix
    out: [out_tree]
  phylogeny_midpoint_root:
    run:
      class: CommandLineTool
      baseCommand: ["qiime", "phylogeny", "midpoint-root"]
      inputs:
        input_tree:
          inputBinding:
            prefix: --i-tree
          type: File
        seqs_prefix:
          type: string?
        rooted_tree:
          inputBinding:
            prefix: --o-rooted-tree
            valueFrom: $(inputs.seqs_prefix + 'rooted-tree.qza')
          type: string
          default: 'rooted-tree.qza'
      outputs:
        out_rooted:
          type: File
          outputBinding:
            glob: $('*' + inputs.rooted_tree)
    in:
      input_tree: phylogeny_fasttree/out_tree
      seqs_prefix: seqs_prefix
    out: [out_rooted]
