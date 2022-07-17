#!/usr/bin/perl -w
=begin
U must have installed the following packages:
	sudo apt-get install build-essential
	sudo cpan DBI
	sudo apt-get install libpq-dev
	sudo cpan DBD::Pg module
=cut

use Benchmark qw(:all) ;
use DBI;
use warnings;
use strict;
use Data::Dumper;

#--Start-of-Benchmark--#
my $t0 = Benchmark->new;

#--Data-capture-from-DB--#
sub DataBase {

    #--Reading-DB-password--#
    my $password;
    open (PASS, "</etc/staffcop/config") or die "$!";
    while (<PASS>) {
        $password = "$1" if $_ =~ /(?<='PASSWORD': ')(.*)(?=',)/;
    }
    close (PASS);
    #-----------------------#

    my $driver = "Pg";
    my $database="staffcop";
    my $dsn = "DBI:$driver:dbname = $database; host = 127.0.0.1; port = 5432";
    my $userid = "staffcop";
    my $dbh = DBI->connect($dsn, $userid, $password, { RaiseError => 1 })
        or die $DBI::errstr;

    print "Opened database successfully!\n";

    my $queri = qq{SELECT data FROM agent_attachedfile};
    my $sth = $dbh->prepare($queri);
    my $rv = $sth->execute;
    my $data_db = $sth->fetchall_arrayref();

    $dbh->disconnect();

    return $data_db;
}

#--Slise-and-check-to-exist-raw-data-from-DB--#
sub Slice {

    my $get_ref = shift;
	my $external_storage; #Path a external storage
	my $full_list;
    my @fexist = ();

    foreach my $list_ref (@$get_ref) {
        foreach my $list (@$list_ref) {

            if ( $list =~ /^filedata/) {
                $full_list = "/var/lib/staffcop/upload/" . "$list";
            }
			elsif ( ! length $external_storage) {
				$external_storage = join("", split(/\/\d{4}_\d{2}_\d{2}.*/,,$list));
				return $external_storage;
			}
        }
    }
	print "Path to external storage: $external_storage";
}

#--Reading-and-Counting-files-from-../upload/filedata/..--#
sub OpenDirs {                                                                  
                                                                                
    my $upload_dirs = shift;                                                    
    my @folders;				#Variable for saving files                                  
    my @case;					#Variable for saving folders with files                     
                                                                                
    if ( -d $upload_dirs ) {                                                    
        opendir(local *DIR, $upload_dirs) || die "Error in opening dir $upload_dirs\n";
                                                                                
        foreach (readdir (DIR)) {                                               
            next if $_ eq "." or $_ eq ".." ;                                   
            my $sub_dir = "$upload_dirs" . "/" . "$_" ;                         
            push @folders, &OpenDirs($sub_dir);     #Push files in folder       
        }                                                                       
        closedir (DIR);                                                         
    }                                                                           
    else {                                                                      
        return $upload_dirs if -e $upload_dirs ;    #Retun a file                                   
    }                                                                           
                                                                                
    push @case, @folders;       #Push a folders with files                      
    return \@case;              #Return the results reference                   
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
    return \@path;                                                            
}                                                               

#--Search-Union-Difference-and-Crossing--#
sub DiVens {
	
	my $fexist_db = shift;	#Take a files reference from the DataBase
	my $phfiles = shift;	#Take a files reference from the Disk
	my %diff;
	
	#Difference $lesser_array\$great_array
	my %uniq_hash;
	print Dumper @$fexist_db;

	foreach my $list_ref (@$get_ref) {
        foreach my $list (@$list_ref) {

            if ( $list =~ /^filedata/) {
                $full_list = "/var/lib/staffcop/upload/" . "$list";
            }
			elsif ( ! length $external_storage) {
				$external_storage = join("", split(/\/\d{4}_\d{2}_\d{2}.*/,,$list));
		
	%uniq_hash = map { @{$_} => 1 if } @$fexist_db;				#Create a unique array

	foreach my $index (@$phfiles) {
		if ( ! $uniq_hash{$index} ) { $diff{$index} = 1; }		#Difference
	}

	my @delfiles = keys %diff;									#IT's the Difference for deleted
	
	#print Dumper \@delfiles;
	my $len = length(scalar(@delfiles));
	print "================"."="x$len."\n";
	print "||Difference: ", scalar(@delfiles),"||\n";
	print "================"."="x$len."\n";

	return \@delfiles;
}


#--Deleting-Difference-from-physical-storage--#
sub Deleting {

	my @upload = @{$_[0]};
	print  "\nNothing delete... \n" and goto SKIP if ! scalar(@upload);

	print "\nDeleting the files? (Yes/No): \n";
	my $choose = <>;

	if ( $choose =~ "[Yy]" ) {
		
		print join("\n", @upload);
		my $count = (unlink (@upload) or die "Having trouble deleting $upload[$_]: $!");
		system ("staffcop restart");
		print "\nDeleted is $count files\n";
	}
	else { print "Files is not deleting...\n"; }
}

##--Start-code-of-this--##

	exec("sudo $0") if ! $< == 0;				#Run script with "sudo"


	#--Pull-Files-From-DB--#
	my $ref_filebd = &DataBase();				#Pull all a files from DB
	my $ref_fexist_db = $ref_filebd; 			#Pull exist files
	my $ext_storage = &Slice($ref_filebd);		#

	#--Pull-Files-From-Physycal-Storage--##
	my $def_path = "/var/lib/staffcop/upload/filedata/by_date";  
	my $def_output = &OpenDirs($def_path);                          
	my $def_ref_phfiles = &Unwrap($def_output);                                                  
	my $full_ref_phfiles;

	#If files exist in external storage the functions is run
	if ( -d $ext_storage) {
		my $ext_output = &OpenDirs($ext_storage);
		my $ext_ref_phfiles = &Unwrap($ext_output);
		$full_ref_phfiles = [@$def_ref_phfiles, @$ext_ref_phfiles];
	}

	else { $full_ref_phfiles = [@$def_ref_phfiles]; }	#Finally links the physical files


	#--Print-Output--#
	printf "\n\nSummary existing files into Storage: %s\n", scalar(@$full_ref_phfiles);
	printf "Summary existing files from DataBases: %s\n", scalar(@$ref_fexist_db);
	printf "Difference: %s\n", ($#$full_ref_phfiles - $#$ref_fexist_db);

	#--Files-with-out-links--#
	my $ref_orf_files = &DiVens($ref_fexist_db,$full_ref_phfiles);

	#--Invoke-sub-Deleting--#
	&Deleting ($ref_orf_files);

##-------------------------##
SKIP:
#--Block-of-Benchmark--#
my $t1 = Benchmark->new;
my $td = timediff($t1, $t0);

print "\nTime execution of code: ", timestr($td), "\n";
