Test execution of the mapping reports workflow on some very tiny
datasets.  This test is likely a bit "volatile" in the sense that it's
overly sensitive to addition of new plots, etc.  But let's keep it
until we have a better plan.

  $ BH_ROOT=$TESTDIR/../../../

Generate mapping reports workflow, starting from subreads.

  $ bauhaus2 --no-smrtlink --noGrid generate -w EvaluateHQRF -t ${BH_ROOT}test/data/two-tiny-movies-unrolled.csv -o unrolled-mapping
  Validation and input resolution succeeded.
  Generated runnable workflow to "unrolled-mapping"

  $ (cd unrolled-mapping && ./run.sh >/dev/null 2>&1)


  $ tree -I __pycache__ unrolled-mapping
  unrolled-mapping
  |-- benchmarks
  |   |-- MovieA_0_map_chunked_unrolledNoHQ_one_chunk.tsv
  |   |-- MovieA_1_map_chunked_unrolledNoHQ_one_chunk.tsv
  |   |-- MovieA_2_map_chunked_unrolledNoHQ_one_chunk.tsv
  |   |-- MovieA_3_map_chunked_unrolledNoHQ_one_chunk.tsv
  |   |-- MovieA_4_map_chunked_unrolledNoHQ_one_chunk.tsv
  |   |-- MovieA_5_map_chunked_unrolledNoHQ_one_chunk.tsv
  |   |-- MovieA_6_map_chunked_unrolledNoHQ_one_chunk.tsv
  |   |-- MovieA_7_map_chunked_unrolledNoHQ_one_chunk.tsv
  |   |-- MovieA_chunk_subreads_one_condition.tsv
  |   |-- MovieA_map_chunked_unrolledNoHQ_and_gather.tsv
  |   |-- MovieB_0_map_chunked_unrolledNoHQ_one_chunk.tsv
  |   |-- MovieB_1_map_chunked_unrolledNoHQ_one_chunk.tsv
  |   |-- MovieB_2_map_chunked_unrolledNoHQ_one_chunk.tsv
  |   |-- MovieB_3_map_chunked_unrolledNoHQ_one_chunk.tsv
  |   |-- MovieB_4_map_chunked_unrolledNoHQ_one_chunk.tsv
  |   |-- MovieB_5_map_chunked_unrolledNoHQ_one_chunk.tsv
  |   |-- MovieB_6_map_chunked_unrolledNoHQ_one_chunk.tsv
  |   |-- MovieB_7_map_chunked_unrolledNoHQ_one_chunk.tsv
  |   |-- MovieB_chunk_subreads_one_condition.tsv
  |   |-- MovieB_map_chunked_unrolledNoHQ_and_gather.tsv
  |   `-- evaluate_hqrf.tsv
  |-- condition-table.csv
  |-- conditions
  |   |-- MovieA
  |   |   |-- mapped
  |   |   |   |-- chunks
  |   |   |   |   |-- mapped.chunk0.alignmentset.bam
  |   |   |   |   |-- mapped.chunk0.alignmentset.bam.bai
  |   |   |   |   |-- mapped.chunk0.alignmentset.bam.pbi
  |   |   |   |   |-- mapped.chunk0.alignmentset.xml
  |   |   |   |   |-- mapped.chunk1.alignmentset.bam
  |   |   |   |   |-- mapped.chunk1.alignmentset.bam.bai
  |   |   |   |   |-- mapped.chunk1.alignmentset.bam.pbi
  |   |   |   |   |-- mapped.chunk1.alignmentset.xml
  |   |   |   |   |-- mapped.chunk2.alignmentset.bam
  |   |   |   |   |-- mapped.chunk2.alignmentset.bam.bai
  |   |   |   |   |-- mapped.chunk2.alignmentset.bam.pbi
  |   |   |   |   |-- mapped.chunk2.alignmentset.xml
  |   |   |   |   |-- mapped.chunk3.alignmentset.bam
  |   |   |   |   |-- mapped.chunk3.alignmentset.bam.bai
  |   |   |   |   |-- mapped.chunk3.alignmentset.bam.pbi
  |   |   |   |   |-- mapped.chunk3.alignmentset.xml
  |   |   |   |   |-- mapped.chunk4.alignmentset.bam
  |   |   |   |   |-- mapped.chunk4.alignmentset.bam.bai
  |   |   |   |   |-- mapped.chunk4.alignmentset.bam.pbi
  |   |   |   |   |-- mapped.chunk4.alignmentset.xml
  |   |   |   |   |-- mapped.chunk5.alignmentset.bam
  |   |   |   |   |-- mapped.chunk5.alignmentset.bam.bai
  |   |   |   |   |-- mapped.chunk5.alignmentset.bam.pbi
  |   |   |   |   |-- mapped.chunk5.alignmentset.xml
  |   |   |   |   |-- mapped.chunk6.alignmentset.bam
  |   |   |   |   |-- mapped.chunk6.alignmentset.bam.bai
  |   |   |   |   |-- mapped.chunk6.alignmentset.bam.pbi
  |   |   |   |   |-- mapped.chunk6.alignmentset.xml
  |   |   |   |   |-- mapped.chunk7.alignmentset.bam
  |   |   |   |   |-- mapped.chunk7.alignmentset.bam.bai
  |   |   |   |   |-- mapped.chunk7.alignmentset.bam.pbi
  |   |   |   |   `-- mapped.chunk7.alignmentset.xml
  |   |   |   `-- mapped.alignmentset.xml
  |   |   |-- reference.fasta -> /pbi/dept/secondary/siv/references/R_palustris_CGA009_pBR322_plasmidbell_4361bp_circular_6x_l52872/sequence/R_palustris_CGA009_pBR322_plasmidbell_4361bp_circular_6x_l52872.fasta
  |   |   |-- reference.fasta.fai -> /pbi/dept/secondary/siv/references/R_palustris_CGA009_pBR322_plasmidbell_4361bp_circular_6x_l52872/sequence/R_palustris_CGA009_pBR322_plasmidbell_4361bp_circular_6x_l52872.fasta.fai
  |   |   |-- sts.h5 -> .*/bauhaus2/resources/extras/no_sts.h5 (re)
  |   |   |-- sts.xml -> .*/bauhaus2/resources/extras/no_sts.xml (re)
  |   |   `-- subreads
  |   |       |-- chunks
  |   |       |   |-- input.chunk0.subreadset.xml
  |   |       |   |-- input.chunk1.subreadset.xml
  |   |       |   |-- input.chunk2.subreadset.xml
  |   |       |   |-- input.chunk3.subreadset.xml
  |   |       |   |-- input.chunk4.subreadset.xml
  |   |       |   |-- input.chunk5.subreadset.xml
  |   |       |   |-- input.chunk6.subreadset.xml
  |   |       |   `-- input.chunk7.subreadset.xml
  |   |       `-- input.subreadset.xml
  |   `-- MovieB
  |       |-- mapped
  |       |   |-- chunks
  |       |   |   |-- mapped.chunk0.alignmentset.bam
  |       |   |   |-- mapped.chunk0.alignmentset.bam.bai
  |       |   |   |-- mapped.chunk0.alignmentset.bam.pbi
  |       |   |   |-- mapped.chunk0.alignmentset.xml
  |       |   |   |-- mapped.chunk1.alignmentset.bam
  |       |   |   |-- mapped.chunk1.alignmentset.bam.bai
  |       |   |   |-- mapped.chunk1.alignmentset.bam.pbi
  |       |   |   |-- mapped.chunk1.alignmentset.xml
  |       |   |   |-- mapped.chunk2.alignmentset.bam
  |       |   |   |-- mapped.chunk2.alignmentset.bam.bai
  |       |   |   |-- mapped.chunk2.alignmentset.bam.pbi
  |       |   |   |-- mapped.chunk2.alignmentset.xml
  |       |   |   |-- mapped.chunk3.alignmentset.bam
  |       |   |   |-- mapped.chunk3.alignmentset.bam.bai
  |       |   |   |-- mapped.chunk3.alignmentset.bam.pbi
  |       |   |   |-- mapped.chunk3.alignmentset.xml
  |       |   |   |-- mapped.chunk4.alignmentset.bam
  |       |   |   |-- mapped.chunk4.alignmentset.bam.bai
  |       |   |   |-- mapped.chunk4.alignmentset.bam.pbi
  |       |   |   |-- mapped.chunk4.alignmentset.xml
  |       |   |   |-- mapped.chunk5.alignmentset.bam
  |       |   |   |-- mapped.chunk5.alignmentset.bam.bai
  |       |   |   |-- mapped.chunk5.alignmentset.bam.pbi
  |       |   |   |-- mapped.chunk5.alignmentset.xml
  |       |   |   |-- mapped.chunk6.alignmentset.bam
  |       |   |   |-- mapped.chunk6.alignmentset.bam.bai
  |       |   |   |-- mapped.chunk6.alignmentset.bam.pbi
  |       |   |   |-- mapped.chunk6.alignmentset.xml
  |       |   |   |-- mapped.chunk7.alignmentset.bam
  |       |   |   |-- mapped.chunk7.alignmentset.bam.bai
  |       |   |   |-- mapped.chunk7.alignmentset.bam.pbi
  |       |   |   `-- mapped.chunk7.alignmentset.xml
  |       |   `-- mapped.alignmentset.xml
  |       |-- reference.fasta -> /pbi/dept/secondary/siv/references/R_palustris_CGA009_pBR322_plasmidbell_4361bp_circular_6x_l52872/sequence/R_palustris_CGA009_pBR322_plasmidbell_4361bp_circular_6x_l52872.fasta
  |       |-- reference.fasta.fai -> /pbi/dept/secondary/siv/references/R_palustris_CGA009_pBR322_plasmidbell_4361bp_circular_6x_l52872/sequence/R_palustris_CGA009_pBR322_plasmidbell_4361bp_circular_6x_l52872.fasta.fai
  |       |-- sts.h5 -> .*/bauhaus2/resources/extras/no_sts.h5 (re)
  |       |-- sts.xml -> .*/bauhaus2/resources/extras/no_sts.xml (re)
  |       `-- subreads
  |           |-- chunks
  |           |   |-- input.chunk0.subreadset.xml
  |           |   |-- input.chunk1.subreadset.xml
  |           |   |-- input.chunk2.subreadset.xml
  |           |   |-- input.chunk3.subreadset.xml
  |           |   |-- input.chunk4.subreadset.xml
  |           |   |-- input.chunk5.subreadset.xml
  |           |   |-- input.chunk6.subreadset.xml
  |           |   `-- input.chunk7.subreadset.xml
  |           `-- input.subreadset.xml
  |-- config.json
  |-- log
  |-- prefix.sh
  |-- reports
  |   `-- HQRF
  |       `-- report.json
  |-- run.sh
  |-- scripts
  |-- snakemake.log
  `-- workflow
      `-- Snakefile
  
  17 directories, 120 files

