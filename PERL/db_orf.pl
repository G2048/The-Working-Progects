#!/usr/bin/perl
use strict;
use DBI;
use Data::Dumper;

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

sub Slice {

	my $get_ref = shift;
    my @fexist = ();
    my @fexist_moved = ();
    my @fnoexist = ();

	foreach my $list_ref (@$get_ref) {
		foreach my $list (@$list_ref) {

			if ($list =~ /^filedata/) {
				$list = "/var/lib/staffcop/upload/" . "$list";
				if ( -e $list ) { push @fexist, $list; }
				else { goto DONT_EXIST; }
			}
			elsif ( -e $list ) {
				push @fexist_moved, $list ;
				#print "File $list is Exist!\n"
			}
			else {
				DONT_EXIST:
				push @fnoexist, $list;
				print "File $list is not Exist!\n";
			}

		}
	}
	return \@fexist, \@fexist_moved, \@fnoexist;
}

my $raw_data = DataBase();
my @orf_files = &Slice($raw_data);

#print Dumper @orf_files; #For debagging
print join("\n", @{$orf_files[0]}); #Print files from /var/lib/staffcop/upload/
print join("\n", @{$orf_files[1]}); #Print files from another storage, /mnt/storage....
