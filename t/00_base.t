# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use locale;
use POSIX qw(locale_h);
setlocale(LC_ALL,'es_ES@euro');

use HTML::Widgets::Index;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):
my $dsn= $ENV{DSN_TEST};
my ($database,$host) = ('test','');
if ($dsn) {
	($host) = $dsn =~ /hostname=(\w+)/;
	die "I can't find host in $dsn\n"
		unless defined $host;
	$host = "-h $host";

	($database) = $dsn=~/database=(\w+)\;?/;
	die "I can't find database in $dsn\n"
		unless defined $database;
}
print `export LANG='es_ES\@euro' ; mysql $host $database< t/sql/test_index.sql 2>/dev/null`
