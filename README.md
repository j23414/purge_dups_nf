# purge_dups_nf

simpler test

```
git clone https://github.com/j23414/purge_dups_nf.git
cd purge_dups_nf
```

```
module load nextflow
module load singularity

singularity pull polishclr.sif docker://csiva2022/polishclr:latest

nextflow run main.nf \
  --primary_assembly "Chromosome30.fasta" \
  --pacbio_reads "test.fasta" \
  -with-singularity polishclr.sif \
  -resume
```

* Make sure that `--primary_assembly` is the final polished assembly.
* Make sure that `--pacbio_reads` is in the correct format `bam` or `fasta`

* [ ] Check for any missing input files for each process, that is not explicitly defined by a flag...