# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):
use DBI;
my $DSN = ( $ENV{DSN_TEST} or "DBI:mysql:test" );
my $dbh=DBI->connect($DSN,undef,undef,{PrintError=>0,RaiseError=>0})
	or do {
		print "1..0\n";
		exit(0);
	};
print "1..1\n";
for my $table (qw(frankie_Menu_items index_items test_index)) {
	$dbh->do("DROP TABLE $table");
}
$dbh->disconnect;
print "ok 1\n";
#`rm -rf pseudo picoxova`;
