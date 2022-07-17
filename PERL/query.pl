#!/usr/bin/perl
use List::Util qw(max);

open (rows, "/home/user/temp/query.txt");

#$ = $/;

while (<rows>) {
	
	chop;
	@F = split /|/;
	#$_ = $F[0];

	print $F;
	#print max(@F);
}
