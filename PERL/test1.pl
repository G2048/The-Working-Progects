#!/usr/bin/perl
sub Deleting {

    my @upload = @{$_[0]};

    print "\nDeleting the files? (Yes/No): \n";
    my $choose = <>;

    if ( $choose =~ "[Yy]" ) {

        print join("\n", @upload);
        my $count = (unlink (@upload) or die "Having trouble deleting $upload[$_]: $!");
        #system ("staffcop restart");
        print "\nDeleted is $count files\n";
    }
    else { print "Files is not deleting...\n"; }
}


@string = ("/mnt/test/filedata/by_date/2022_02_10/05bd47698cfc4812725381f9273c3d8823620140.jpe");
$ref_string = \@string;
&Deleting($ref_string);
