#!/usr/bin/env perl
use strict;
use warnings;
use constant USAGE =><<EOH;

Version: 20180405

Remove BAM alignments with N in CIGAR

Example:

samtools view -h my.st.bam | $0 | samtools view -bS - >my.st2.bam

samtools view -h my.st.bam | $0 | samtools view -bS - | samtools calmd - my.fa | samtools view -bS - > my.calmd.bam

EOH


while (my $line=<>) {
	if ($line=~/^\@/) {
		print $line; 
		next;
	}
	else {
		my @arr=split(/\s+/, $line);
		if (defined $arr[5] and $arr[5] ne '') {
			print $line unless ($arr[5]=~/N/);
		}
	}
}
