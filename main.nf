
nextflow.enable.dsl=2

params.primary_assembly="Chromosome30.fasta"
params.pacbio_reads="test.fasta"

process map_pacbio_to_primary {
  publishDir "results", mode:'copy'
  input: tuple path(primary), path(pacbio)
  output: path("${primary.simpleName}_p_mapping.paf.gz")
  script:
  """
  samtools faidx ${primary}
  minimap2 -xmap-pb ${primary} ${pacbio} \
    | gzip -c - > ${primary.simpleName}_p_mapping.paf.gz
  """
}

process pbcstat {
  publishDir "results", mode:'copy'
  input: path(pacbio_mapped)
  output: path("*")
  script:
  """
  pbcstat ${pacbio_mapped}
  """
}

process calcuts {
  publishDir "results", mode:'copy'
  input: path(pb_stat_files)
  output: path("*_cutoffs")
  """
  calcuts PB.stat > p_cutoffs 2> p_calcuts.log
  """
}

process split_fa {
  publishDir "results", mode:'copy'
  input: path(primary)
  output: path("${primary}.split")
  """
  split_fa ${primary} > ${primary}.split
  """
}

process minimap2 {
  publishDir "results", mode:'copy'
  input: path(split_fasta)
  output: path("${split_fasta}_p_mapping.paf.gz")
  script:
  """
  minimap -xasm5 -DP -t ${task.cpus} ${split_fasta} ${split_fasta} \
    | gzip -c - > ${split_fasta}.split.self.paf.gz
  """
}

process purge_dups {
  publishDir "results", mode:'copy'
  input: tuple path(primary_self_mapped), path(calcuts_out), path(pbcstat_out)
  output: path("p_dups.bed")
  script:
  """
  ${purge_dups_app} \
    -2 -T p_cufoffs \
    -c PB.base.cov \
    ${primary_self_mapped} > p_dups.bed 2> p_purge_dups.log
  """
}

process get_seqs {
  publishDir "results", mode:'copy'
  input: tuple path(bedfile), path(primary)
  output: tuple path("*.purged.fa"), path("*.hap.fa")
  script:
  """
  get_seqs -e ${bedfile} ${primary} -p primary
  """
}

workflow {
  pri_ch = channel.fromPath(params.primary_assembly)
  pacbio_ch = channel.fromPath(params.pacbio)

  // First purge_dup
  pri_ch
    | map_pacbio_to_primary
    //| view
    | pbcstat
    //| view
    | calcuts
    //| view

  pri_ch
    | split_fa
    //| view
    | minimap2
    | view
    | combine(calcuts.out | map {n -> [n]})
    | combine(pbcstat.out | map {n -> [n]})
    | view
    | purge_dups
    | combine(pri_ch)
    | get_seqs
    | view

}