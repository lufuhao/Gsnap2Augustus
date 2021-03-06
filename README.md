# Gsnap2Augustus

RRID: [SCR_017555](https://scicrunch.org/resolver/RRID:SCR_017555)

## Descriptions:

  2-step gsnap-augustus to improve *ab initio* prediction

1. GSNAP map reads to genome, merge and sort BAM to --bam1

2. Execuate Function 1-3 to generate -o3ex

3. GSNAP map reads to -o3ex, merge and sort BAM to --bam2

4. Execuate Function 4-5

>    Note: do Step 2 & 4 in the same folder

## Requirements:

>  Linux: cp, cat, tee, grep, sort, perl

>  [Augustus](http://bioinf.uni-greifswald.de/augustus/)
>            augustus, bam2hints, \$AUGUSTUS_CONFIG_PATH, 
>            intron2exex.pl, samMap.pl, bam2wig, wig2hints.pl
>
>  [samtools](https://github.com/samtools/)
>
>  [bamutils](https://github.com/statgen/bamUtil)
>
>  bam_remove_CIGAR_N.pl: included
>
>  bamverify: included

## Options:

>  -h    [Opt] Print this help message
>
>  -f    [Msg] Function
>
>          1 - bam2hints
>          2 - augustus
>          3 - aug1 to exex
>          4 - bam2hints
>          5 - augustus2
>
>  -bam1	[Msg] Sorted BAM file for 1
>
>  -bam2 [Msg] Sorted exex BAM file for 2, also need -bam1
>
>  -m    [Msg] Genemodel: partial, intronless, complete, atleastone, exactlyone
>
>  -s    [Msg] Augustus species trained
>
>  -g    [Msg] Genome sequence in fasta format
>
>  -l    [Msg] Read length
>
>  -e    [Opt] Include hints for exonparts if you have good 
>
>              Augustus UTR model
>
>  -o1   GFF output of Func1 bam2hints
>
>  -o2	GFF output of Func2 augustus
>
>  -o3ex Intron flaking sequence in Fasta
>
>  -o3ps	Coordinate file exex.fa vs genome
>
>  -o4p	Prefix of GFF output of Func4 intron/intronexon hints
>
>  -o5	GFF Final output of ab initio prediction


## Author:

>  Fu-Hao Lu
>
>  Post-Doctoral Scientist in Micheal Bevan laboratory
>
>  Cell and Developmental Department, John Innes Centre
>
>  Norwich NR4 7UH, United Kingdom
>
>  E-mail: Fu-Hao.Lu@jic.ac.uk

## Copyright

	Copyright (c) 2015-2018 Fu-Hao Lu
