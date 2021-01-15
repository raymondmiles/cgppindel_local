<!-- dx-header -->
# cgppindel (DNAnexus Platform App)
  
  
  
## What does this app do?
cgpPindel is a modified version of Pindel that is optimized for detecting somatic insertions and deletions (indels) in cancer genomes and other samples compared to a reference control.

More information on: https://github.com/cancerit/cgpPindel

<br></br>

## What are typical use cases for this app?
This app may be executed as a standalone app and is also part of the Uranus workflow for somatic variant discovery for myeloid samples.
<br></br>

## What data are required for this app to run?
Required inputs for this app:

|Input |Details|
|--- |---|
|docker image| cgppindel docker image |
|reference.fa [.fai] |Reference genome file|
|simrep.bed [.tbi]| Tabix indexed simple/satellite repeats.|
| genes | Tabix indexed coding gene footprints.|
|unmatched|Tabix indexed gff3 of unmatched normal panel|
|assembly string| Assembly version (default: GRCh38) |
|seqtype string| TG: targeted panel, WXS: Whole Exome, WGS: Whole Genome|
|filter.lst|Output filter rules|
|tumour bam input [.bai]|Tumour BAM/CRAM file index |
|normal bam input [.bai]|Normal BAM/CRAM file|
<br></br>

## What does this app output?
This app outputs:
|File| Details|
|--- |--- |
|T_vs_N.flagged.vcf.gz [.tbi]|	Variant call format (bgzip compressed)|
|T_vs_N_wt.bam [.bai/.md5]|	Pindel‐aligned reads from the wild‐type/normal sample in BAM format|
|T_vs_N_mt.bam [.bai/.md5]|	Pindel‐aligned reads from the mutant/tumour sample in BAM format|
|T_vs_N.germline.bed	|BED file containing ranges of events highly likely to be germline|

This is the source code for an app that runs on the DNAnexus Platform.
For more information about how to run or modify it, see
https://documentation.dnanexus.com/.

#### This app was made by EMEE GLH