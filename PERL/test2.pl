#!/usr/bin/perl
use strict;


sub Difference {
	
	my $a=shift;
	my $b=shift;
	#my @a = ("abc", "bac", "cba");
	#my @b = ("abc", "ccc");
	my @unuon = ();
	my @isect = ();
	my @diff = ();
	my %union = ();
	my %isect = ();
	my %diff = ();


	foreach my $e (@{$a}) {$union{$e} = 1;}
	foreach my $e (@{$b}) {
		if ( ! $union{$e} ) { $diff{$e} = 1;}
		elsif ( $union{$e} ) { $isect{$e} = 1;}

		$union {$e} = 1;
	}
	
	$\ = "\n";
	@unuon = keys %union;
	@diff = keys %diff;
	@isect = keys %isect;
	
	print "A: @$a";
	print "B: @$b\n";
	print "Union: @unuon";
	print "Difference: @diff";
	print "Similar: @isect";
}

my @a = (1, 3, 5, 6, 7, 8);
my @b = (2, 3, 5, 7, 9);
	
Difference(\@a, \@b);

