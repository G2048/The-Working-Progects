#!/usr/bin/perl

use Benchmark qw(:all) ;
use DBI;
use strict;

my $t0 = Benchmark->new;

sub DataBase {
	my $driver = "Pg";
	my $database="staffcop";
	my $dsn = "DBI:$driver:dbname = $database;host = 127.0.0.1;port = 5432";
	my $userid = "staffcop";
	my $password = "ac11f61f9d6c4239d837e75d010cd2076c6b56ba8c5e2ae0298e94cf20c626c3";
	my $dbh = DBI->connect($dsn, $userid, $password, { RaiseError => 1 })
		or die $DBI::errstr;

	print "Opened database successfully!\n";

	#my $queri = qq(SELECT guid FROM agent_agent);
	my $queri = qq(SELECT data FROM agent_attachedfile);
	my $res = $dbh->prepare($queri);
	my $rv = $res->execute() or die $DBI::errstr;

	my $count = 0;
	while (my @row = $res->fetchrow_array()) {

		if ( -e $row[0]) {
			print "File $row[0] is Exist!\n";
		}
		else { print "File $row[0] is not Exist!\n"; }
		$count++
	}
	
	printf "\nNumbers files: %s\n", $count;
	$res->finish();
	$dbh->disconnect();
}

DataBase();
my $t1 = Benchmark->new;
my $td = timediff($t1, $t0);

print "\nTime execution of code: ", timestr($td), "\n"

