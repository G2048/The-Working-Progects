#!/usr/bin/perl

use Benchmark qw(:all) ;
use DBI;
use strict;

my $t0 = Benchmark->new;

sub DataBase {

	sub Open_DB {
		my $password;
		open (PASS, "</etc/staffcop/config") or die "$!";
		while (<PASS>) {
			$password = "$1" if $_ =~ /(?<='PASSWORD': ')(.*)(?=',)/;
		}
		close (PASS);

		my $driver = "Pg";
		my $database="staffcop";
		my $dsn = "DBI:$driver:dbname = $database; host = 127.0.0.1; port = 5432";
		my $userid = "staffcop";
		my $dbh = DBI->connect($dsn, $userid, $password, { RaiseError => 1 })
			or die $DBI::errstr;
		my $ref_dbh = \$dbh ;

		print "Opened database successfully!\n";
		return $ref_dbh ;
	}


	sub Queri {
			my $dbh_ref = &Open_DB ();
			my $dbh = $$dbh_ref;	

			my $queri = shift;
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
	}

	$dbh->disconnect() or warn $dbh->errstr;
}
 
# qq(SELECT data FROM agent_attachedfile);

my $queri_2 = qq(SELECT guid FROM agent_agent);
&DataBase();


my $t1 = Benchmark->new;
my $td = timediff($t1, $t0);

print "\nTime execution of code: ", timestr($td), "\n"

