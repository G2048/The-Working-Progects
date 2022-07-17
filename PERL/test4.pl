#!/usr/bin/perl

$lenght = 64;
$sbort = 2;

$allplace = "-"x$sbort ." "x($lenght - $sbort*2) ."-"x($sbort) ."\n" ;

#$\="\n";
print "-"x$lenght ."\n" ;
print "$allplace"x16;
print "-"x$lenght ."\n";
