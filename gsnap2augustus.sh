#!/bin/sh
RunDir=$(cd `dirname $(readlink -f $0)`; pwd)

if [ ! -z $(uname -m) ]; then
	machtype=$(uname -m)
elif [ ! -z "$MACHTYPE" ]; then
	machtype=$MACHTYPE
else
	echo "Warnings: unknown MACHTYPE" >&2
fi

################# help message ######################################
help() {
cat<<HELP

$0 --- gsnap2augustus

Requirements: 
  [Func1] bam2hints
    [Augustus] bam2hints
    [Linux] cp, cat, tee, grep, sort, perl
    [Parameter] -bam1, -o1, -o2
  [Func2] augustus (1st run)
    [Augustus] \$AUGUSTUS_CONFIG_PATH, augustus
    [Parameter] -bam1, -s, -g, -m, -o1, -o2
  [Func3] exon_flank.fa
    [Augustus] intron2exex.pl
    [Linux] grep, tee, perl, cat, sort
    [Parameter] -bam1,  -l, -g, -o1, -o2, -o3ex, -o3ps
  [Func4] bam2hints (intron/intronexon)
    [Augustus] samMap.pl, bam2hints, bam2wig, wig2hints.pl
    [Linux] cat
    [BIO] samtools, bamutils
    [Custom] bam_remove_CIGAR_N.pl, bamverify, 
    [Parameters] -bam1, -bam2, -l, -o3p, -o4
    [Output] -o4p.intrononly.gff
             -o4p.IntronExon.gff
  [Func5] augustus (2ndst run)
    [Augustus] \$AUGUSTUS_CONFIG_PATH, augustus
    [Parameter] -s, -g, -m, -o4, -o5
	  
Version: 20180405

Descriptions:
  2-step gsnap-augustus to improve the performace

Options:
  -h    [Opt] Print this help message
  -f    [Msg] Function
          1 - bam2hints
          2 - augustus
          3 - aug1 to exex
          4 - bam2hints
          5 - augustus2
  -bam1	[Msg] Sorted BAM file for 1
  -bam2 [Msg] Sorted exex BAM file for 2, also need -bam1
  -m    [Msg] Genemodel: partial, intronless, complete, atleastone, exactlyone
  -s    [Msg] Augustus species trained
  -g    [Msg] Genome sequence in fasta format
  -l    [Msg] Read length
  -e    [Opt] Include hints for exonparts if you have good 
              Augustus UTR model
  -o1   GFF output of Func1 bam2hints
  -o2	GFF output of Func2 augustus
  -o3ex Intron flaking sequence in Fasta
  -o3ps	Coordinate file exex.fa vs genome
  -o4p	Prefix of GFF output of Func4 intron/intronexon hints
  -o5	GFF Final output of ab initio prediction

Example:
  $0 

Author:
  Fu-Hao Lu
  Post-Doctoral Scientist in Micheal Bevan laboratory
  Cell and Developmental Department, John Innes Centre
  Norwich NR4 7UH, United Kingdom
  E-mail: Fu-Hao.Lu@jic.ac.uk
HELP
exit 0
}
[ -z "$1" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ] && help
#################### Defaults #######################################
echo -e "\n######################\nNGSimple initializing ...\n######################\n"
echo "Adding $RunDir/bin into PATH"
#export PATH=$RunDir/bin:$RunDir/utils/bin:$PATH

###Defaults
include_exonhints=0
#################### parameters #####################################
while [ -n "$1" ]; do
  case "$1" in
    -h) help;shift 1;;
    -f) function=$2;shift 2;;
    -bam1) bamfile1=$2; shift 2;;
    -bam2) bamfile2=$2; shift 2;;
    -o1) step1out=$2; shift 2;;
    -o2) step2out=$2; shift 2;;
    -o3ex) step3exex=$2; shift 2;;
    -o3ps) step3psl=$2; shift 2;;
    -o4p) step4out=$2; shift 2;;
    -o5) step5out=$2; shift 2;;
    -m) genemodel=$2; shift 2;;
    -s) species=$2; shift 2;;
    -g) genome=$2; shift 2;;
    -l) readlength=$2;shift 2;;
    -e) include_exonhints=1;shift 1;;
    --) shift;break;;
    -*) echo "error: no such option $1. -h for help" > /dev/stderr;exit 1;;
    *) break;;
  esac
done



#################### Subfuctions ####################################
###Detect command existence
CmdExists () {
  if command -v $1 >/dev/null 2>&1; then
    echo 0
  else
    echo 1
  fi
}



#################### Command test ###################################
if [ $function -eq 1 ] || [ $function -eq 4 ]; then
  if [ $(CmdExists 'bam2hints') -eq 1 ]; then
    echo "Error: CMD 'bam2hints' in PROGRAM 'augustus'  is required but not found.  Aborting..." >&2
    exit 127
  fi
  if [ -z "$AUGUSTUS_CONFIG_PATH" ] || [ ! -d $AUGUSTUS_CONFIG_PATH ]; then
  	echo "Error: AUGUSTUS_CONFIG_PATH needed to augustus root path" >&2
  	exit 127
  fi
fi
if [ $function -eq 2 ] || [ $function -eq 5 ]; then
  if [ $(CmdExists 'augustus') -eq 1 ]; then
    echo "Error: CMD 'augustus' in PROGRAM 'augustus'  is required but not found.  Aborting..." >&2
    exit 127
  fi
  if [ -z 
fi
if [ $function -eq 3 ]; then
  if [ $(CmdExists 'intron2exex.pl') -eq 1 ]; then
    echo "Error: Script 'intron2exex.pl' in PROGRAM 'augustus'  is required but not found.  Aborting..." >&2
    exit 127
  fi
fi
if [ $function -eq 4 ]; then
	if [ $(CmdExists 'samMap.pl') -eq 1 ]; then
		echo "Error: Script 'samMap.pl' in PROGRAM 'augustus' is required but not found.  Aborting..." >&2
		exit 127
	fi
	if [ $(CmdExists 'bam2hints') -eq 1 ]; then
		echo "Error: Script 'bam2hints' in PROGRAM 'augustus' is required but not found.  Aborting..." >&2
		exit 127
	fi
	if [ $(CmdExists 'bam2wig') -eq 1 ] ; then
		echo "Error: CMD 'bam2wig' in PROGRAM 'augustus' is required but not found.  Aborting..." >&2
		exit 127
	fi
	if [ $(CmdExists 'wig2hints.pl') -eq 1 ]; then
		echo "Error: Script 'wig2hints.pl' in PROGRAM 'augustus' is required but not found.  Aborting..." >&2
		exit 127
	fi
	if [ $(CmdExists 'samtools') -eq 1 ]; then
		echo "Error: CMD 'samtools' in PROGRAM 'SAMtools' is required but not found.  Aborting..." >&2
		exit 127
	fi
	if [ $(CmdExists 'bamutils') -eq 1 ]; then
		echo "Error: CMD 'bamutils' in PROGRAM 'NGSutils' is required but not found.  Aborting..." >&2
		exit 127
	fi
	if [ $(CmdExists 'bam_remove_CIGAR_N.pl') -eq 1 ]; then
		echo "Error: custom script 'bam_remove_CIGAR_N.pl' is required but not found.  Aborting..." >&2
		exit 127
	fi
	if [ $(CmdExists 'bamverify') -eq 1 ]; then
		echo "Error: custom script 'bamverify' is required but not found.  Aborting..." >&2
		exit 127
	fi
fi




#################### Defaults #######################################



#################### Input and Output ###############################
#BAM1
if [ $function -eq 1 ] || [ $function -eq 2 ] || [ $function -eq 3 ] || [ $function -eq 4 ]; then
	if [ -z "$bamfile1" ] || [ ! -s $bamfile1 ]; then
		echo "Error: invalid BAM input: -bam1 $bamfile1" >&2
		exit 1
	fi
	bam1name=${bamfile1##*/}
	bam1base=${bam1name%.*}
fi

#BAM2
if [ $function -eq 4 ]; then
	if [ -z "$bamfile2" ] || [ ! -s $bamfile2 ]; then
		echo "Error: invalid BAM input: -bam2 $bamfile2" >&2
		exit 1
	fi
	bam2name=${bamfile2##*/}
	bam2base=${bam2name%.*}
fi

#check species
if [ $function -eq 2 ] || [ $function -eq 5 ]; then
  if [ -z "$species" ] || [ ! -s $AUGUSTUS_CONFIG_PATH/species/$species ]; then
    echo "Error: invalid or un-trained species: $species" >&2
    exit 1
  fi
  if [ -z "$genemode" ]; then
    echo "Error: empty genemodel" >&2
    exit 1
  elif [ "$genemode" == "partial" ] ||  [ "$genemode" == "intronless" ] ||  [ "$genemode" == "complete" ] ||  [ "$genemode" == "atleastone" ] ||  [ "$genemode" == "exactlyone" ]; then
  	echo "Info: augustus GeneModel: $genemode"
  else
  	echo "Error: invalid genemodel: $genemode" >&2
  	exit 1
  fi
fi
##check genome
if [ $function -eq 2 ] || [ $function -eq 3 ] || [ $function -eq 5 ]; then
  if [ -z "$genome" ] || [ ! -s $genome ]; then
    echo "Error: invalid genome: $genome" >&2
    exit 1
  fi
fi
##read length
if [ $function -eq 3 ] || [ $function -eq 4 ]; then
  if [[ $readlength =~ ^[0-9]{2,3}$ ]]; then
    echo "Info: read length: $readlength"
  else
    echo "Error: invalid read length: -l $readlength" >&2
    exit 1
  fi
fi
	






################### Main ############################################

####################Function 1: bam2hints
###Require: bam2hints
###Input: $bamfile1
if [ $function -eq 1 ]; then
	echo -e "\n\n\n#####Func1"
	echo -e "\n\n\n#####Func1" >&2
	if [ -z "$step1out" ]; then
		step1out=$PWD/Step1.$bam1base.bam2hints.gff
	fi
	bam2hints --intronsonly --in=$bamfile1 --out=$step1out
	if [ $? -ne 0 ] || [ ! -s $step1out ]; then
		echo "Func1Error: bam2hints run or output error" >&2
		exit 1
	fi
	echo "Info: Func1 output: $step1out"
fi



####################Function 2: augustus (1st run)
###Require: cp, augustus
###Input: $step1out, $AUGUSTUS_CONFIG_PATH, $species, $genome, $bam1base
if [ $function -eq 2 ]; then
	echo -e "\n\n\n#####Func2"
	echo -e "\n\n\n#####Func2" >&2
#check input
	if [ -z "$step1out" ] || [ ! -s $step1out ]; then
		echo "Func2Error: invalid bam2hints file for augustus" >&2
		exit 1
	fi
	if [ -z "$step2out" ]; then
		step2out=$PWD/Step2.$bam1base.augustus1.out
	fi
#check extrinsic.M.RM.E.W.cfg
	if [ ! -s ./extrinsic.M.RM.E.W.cfg ]; then
		if [ ! -s $AUGUSTUS_CONFIG_PATH/extrinsic/extrinsic.M.RM.E.W.cfg ]; then
			echo "Func2Error: extrinsic.M.RM.E.W.cfg not found" >&2
			exit 1
		fi
		cp -f $AUGUSTUS_CONFIG_PATH/extrinsic/extrinsic.M.RM.E.W.cfg  ./
	fi
	if [ ! -s ./extrinsic.M.RM.E.W.cfg ]; then
		echo "Func2Error: extrinsic.M.RM.E.W.cfg copy error" >&2
		exit 1
	fi
#augustus
	augustus --species=$species --extrinsicCfgFile=extrinsic.M.RM.E.W.cfg --alternatives-from-evidence=true --hintsfile=$step1out --allow_hinted_splicesites=atac --introns=on --genemodel=$genemodel $genome > $step2out
	if [ $? -ne 0 ] || [ ! -s $step2out ]; then
		echo "Func2Error: augustus running or output error" >&2
		exit
	fi
#Output
  echo "Info: Func2 output: $step2out"
fi



####################Function 3
###Require: grep, tee, perl, cat, sort, intron2exex.pl
###Input: $bam1base, $step1out, $step2out, $readlength, $genome
if [ $function -eq 3 ]; then
	echo -e "\n\n\n#####Func3"
	echo -e "\n\n\n#####Func3" >&2
#check input
	if [ -z "$step1out" ] || [ ! -s $step1out ]; then
		echo "Func3Error: invalid step1out: -o1 $step1out" >&2
		exit 1
	fi
	if [ -z "$step2out" ] || [ ! -s $step2out ]; then
		echo "Func3Error: invalid step2out: -o2 $step2out" >&2
		exit 1
	fi
	if [ -z "$step3exex" ]; then
		step3exex=$PWD/Func3.flankingexons.fa
	fi
	if [ -z "$step3psl" ]; then
		step3psl=$PWD/Func3.flankingexons.map.psl
	fi
#get intron list
	cat $step2out | tee Func2.$bam1base.augustus1.prelim.gff | grep -P "\tintron\t" > Func2.$bam1base.augustus1.introns.gff
	if [ $? -ne 0 ] || [ ! -s Func2.$bam1base.augustus1.introns.gff ]; then
		echo "Func3Error: intron extraction error" >&2
		exit 1
	fi
	cat $step1out Func3.$bam1base.augustus1.introns.gff | perl -ne 'unless(/^#/) {@array = split(/\t/, $_);print "$array[0]:$array[3]-$array[4]\n";}' | sort -u > Func3.introns.list
	if [ $? -ne 0 ] || [ ! -s Func3.introns.list ]; then
		echo "Func3Error: intron list output error" >&2
		exit 1
	fi
#get flanking exons
	intron2exex.pl --introns Func3.introns.list --seq $genome --exex $step3exex --map $step3psl --flank $readlength
	if [ $? -ne 0 ] || [ ! -s $step3exex ] || [ ! -s $step3psl ]; then
		echo "Func3Error: intron list output error" >&2
		exit 1
	fi
#Output
	echo "Info: EXON: $step3exex"
	echo "Info: MAPPSL: $step3psl"
fi



####################Function 4
###Require: samMap.pl, bam_remove_CIGAR_N.pl, samtools, bam2hints, bamutils, bamverify, bam2wig, wig2hints.pl, cat
###Input: $bamfile2, $readlength, $bamfile1, $step3psl
if [ $function -eq 4 ]; then
	echo -e "\n\n\n#####Func4"
	echo -e "\n\n\n#####Func4" >&2
#check input
	if [ -z "$step3psl" ] || [ ! -s $step3psl ]; then
		echo "Func4Error: invalid step3psl: -o3p $step3psl" >&2
		exit 1
	fi
	if [ -z "$step4out" ]; then
		if [ $include_exonhints -eq 0 ]; then
			$step4out=$PWD/Func4.mergeNnoN.f.intrononly.gff
		elif [ $include_exonhints -eq 1 ]; then
			$step4out=$PWD/Func4.mergeNnoN.f.IntronExon.gff
		fi
	else
		if [ $include_exonhints -eq 0 ]; then
			$step4out=$step4out.intrononly.gff
		elif [ $include_exonhints -eq 1 ]; then
			$step4out=$step4out.IntronExon.gff
		fi
	fi
	tempfiles=''

###2nd gsnap
#gmap_build -d exex Func4.flankingexons.fa
#gsnap --format=sam --nofails -d exex rnaseq.fastq > gsnap.2.sam

###samMap.pl and BAM2withN
samMap.pl $bamfile2 $step3psl $readlength > Func4.$bam2base.sammapnoheader.sam
if [ $? -ne 0 ] || [ ! -s Func4.$bam2base.sammapnoheader.sam ]; then
	echo "Func4Error: samMap.pl running or output error" >&2
	exit 1
fi
samtools view -H $bamfile1 > Func4.$bam1name.header
if [ $? -ne 0 ] || [ ! -s Func4.$bam1name.header ]; then
	echo "Func4Error: Extract BAM header error: $bamfile1" >&2
	exit 1
fi
cat Func4.$bam1name.header Func4.$bam2base.sammapnoheader.sam  | samtools view -b -h -S - | samtools sort -f - Func4.$bam2base.bam
if [ $? -ne 0 ] || [ ! -s Func4.$bam2base.bam ]; then
    echo "Func4Error: reheader failed" >&2
    exit 1
fi
tempfiles="$tempfiles Func4.$bam2base.sammapnoheader.sam Func4.$bam1name.header Func4.$bam2base.bam"

###BAM1withNoN
samtools view -h $bamfile1 | bam_remove_CIGAR_N.pl | samtools view -b -S -F 4 - > Func4.$bam2base.noN.bam
if [ $? -ne 0 ] || [ ! -s Func4.$bam2base.noN.bam ]; then
    echo "Func4Error: remove CIGAR N failed: $bamfile1" >&2
    exit 1
fi
tempfiles="$tempfiles Func4.$bam2base.noN.bam"
###Merge
samtools merge Func4.mergeNnoN.bam Func4.$bam2base.bam Func4.$bam2base.noN.bam
if [ $? -ne 0 ] || [ ! -s Func4.mergeNnoN.bam ]; then
    echo "Func4Error: merge failed: Func4.$bam2base.bam Func4.$bam2base.noN.bam" >&2
    exit 1
fi
samtools index Func4.mergeNnoN.bam
if [ $? -ne 0 ] || [ ! -s Func4.mergeNnoN.bam.bai ]; then
    echo "Func4Error: index failed: Func4.mergeNnoN.bam.bai" >&2
    exit 1
fi
if [ ! -z "$tempfiles" ]; then
  rm $tempfiles
  tempfiles=''
fi

###filter BAM
bamutils filter Func4.mergeNnoN.bam Func4.mergeNnoN.f.bam -properpair -nosecondary -nopcrdup
if [ $? -ne 0 ] || [ ! -s Func4.mergeNnoN.f.bam ]; then
	echo "Func4Error: bamutils filter error" > /dev/stderr
	exit 1
fi
bamverify Func4.mergeNnoN.f.bam
if [ $? -eq 0 ]; then
	samtools index Func4.mergeNnoN.f.bam
	if [ $? -ne 0 ]; then
		echo "Func4Error: samtools index error2: Func4.mergeNnoN.f.bam" >&2
		exit 1
	fi
else
	echo "Func4Error: BAM not intact: Func4.mergeNnoN.f.bam" >&2
	exit 1
fi

###bam2hints intron
bam2hints --intronsonly --in=Func4.mergeNnoN.f.bam --out=Func4.mergeNnoN.f.intrononly.gff
if [ $? -ne 0 ] || [ ! -s Func4.mergeNnoN.f.intrononly.gff ]; then
	echo "Func4Error: BAM2hints error" > /dev/stderr
	exit 1
fi
#Output
if [ $include_exonhints -eq 0 ]; then
	echo "Func4Info: IntronOnly: $step4out"
	mv Func4.mergeNnoN.f.intrononly.gff $step4out
fi

###exon hints [optional]
if [ $include_exonhints -eq 1 ]; then
	bam2wig Func4.mergeNnoN.f.bam > Func4.mergeNnoN.f.wig
	if [ $? -ne 0 ] || [ ! -s Func4.mergeNnoN.f.wig ]; then
		echo "Func4Error: bam2wig error" >&2
		exit 1
	fi
	tempfiles="$tempfiles Func4.mergeNnoN.f.wig"
	cat Func4.mergeNnoN.f.wig | wig2hints.pl --width=10 --margin=10 --minthresh=2 --minscore=4 --prune=0.1 --src=W --type=ep \ 
  --UCSC=unstranded.track --radius=4.5 --pri=4 --strand="." > Func4.mergeNnoN.f.exononly.gff
	if [ $? -ne 0 ] || [ ! -s Func4.mergeNnoN.f.exononly.gff ]; then
		echo "Func4Error: wig2hints error" >&2
		exit 1
	fi
  # we'll join and move hints so that you can proceed with this tutorial regardless of whether you created exonparthints, or not:
	cat Func4.mergeNnoN.f.intrononly.gff Func4.mergeNnoN.f.exononly.gff > $step4out
	if [ $? -ne 0 ] || [ ! -s $step4out ]; then
		echo "Func4Error: merge hints for intron and exon error" >&2
		exit 1
	fi
	echo "Func4Info: hints file for Intron and Exon: $step4out"
	if [ ! -z "$tempfiles" ]; then
		echo "Func4Info: deleting $tempfiles ..."
		rm $tempfiles
	fi
fi


####################Function 5: augustus (2nd run)
###Require: augustus
###Input: $AUGUSTUS_CONFIG_PATH, $species, $genome, $genemodel, $step4out, $step5out
if [ $function -eq 5 ]; then
	echo -e "\n\n\n#####Func5"
	echo -e "\n\n\n#####Func5" >&2
#check input
	if [ -z "$step4out" ] || [ ! -s $step4out ]; then
		echo "Func5Error: invalid bam2hints file for augustus" >&2
		exit 1
	fi
	if [ -z "$step5out" ]; then
		step5out=$PWD/Func2.final.augustus2.gff
	fi
#check extrinsic.M.RM.E.W.cfg
  if [ ! -s ./extrinsic.M.RM.E.W.cfg ]; then
    if [ ! -s $AUGUSTUS_CONFIG_PATH/extrinsic/extrinsic.M.RM.E.W.cfg ]; then
      echo "Func5Error: extrinsic.M.RM.E.W.cfg not found" >&2
      exit 1
    fi
    cp -f $AUGUSTUS_CONFIG_PATH/extrinsic/extrinsic.M.RM.E.W.cfg  ./
  fi
  if [ ! -s ./extrinsic.M.RM.E.W.cfg ]; then
    echo "Func5Error: extrinsic.M.RM.E.W.cfg copy error" >&2
    exit 1
  fi
#augustus
  augustus --species=$species --extrinsicCfgFile=extrinsic.M.RM.E.W.cfg --alternatives-from-evidence=true --hintsfile=$step1out --allow_hinted_splicesites=atac --introns=on --genemodel=$genemodel $genome > $step5out
  if [ $? -ne 0 ] || [ ! -s $step5out ]; then
  	echo "Func5Error: augustus running or output error" >&2
  	exit
  fi
#Output
  echo "Func5Info: final output: $step5out"
fi


exit 0
