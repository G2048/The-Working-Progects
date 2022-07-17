#!/usr/bin/perl -w

use strict;
use Data::Dumper;

sub DIFF {
	my @a = (5..8);
	my @b =  (2..6);

	
	return \@a, \@b;
}

my @refrers = &DIFF;
my $refref = \@refrers;
$\="\n";
print Dumper @refrers;
#print join ("\n", $#{$refrers[0]}+1);
#print "\n\n";
#print join ("\n", "$refrers[0]->[0]");



