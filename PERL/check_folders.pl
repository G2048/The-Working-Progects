#!/usr/bin/perl

use strict;

#--Reading-and-Counting-files-from-../upload/filedata/..--#
sub OpenDirs {
	
	my $upload_dirs = shift;
	my @folders;	#Variable for saving files
	my @case;		#Variable for saving folders with files

	if ( -d $upload_dirs ) {
		opendir(DIR, $upload_dirs) || die "Error in opening dir $upload_dirs\n";
	
		foreach (readdir (DIR)) {
			next if $_ eq "." or $_ eq ".." ;
			my $sub_dir = "$upload_dirs" . "/" . "$_" ;
			push @folders, &OpenDirs($sub_dir);		#Push files in folder
		}
		closedir (DIR);
	}
	else {  
		return $upload_dirs;	#Retun a file
	}

	push @case, @folders;		#Push a folders with files
	return \@case;				#Return the results reference 
}

#Unwrap files into $output
sub Unwrap {
	
	my $output = shift;
	my @path;
	my $count = 0;
	foreach my $list (@$output) {
		foreach my $list_ref (@$list) {
			push @path ,$list_ref;
			$count++;
		}

	}
	print "Total the number of files after unwrap: $count\n";
	return @path;
}

my $path = "/var/lib/staffcop/upload/filedata/by_date";
my $output = &OpenDirs($path);
&Unwrap($output);
