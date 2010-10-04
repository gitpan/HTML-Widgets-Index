# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; }
use HTML::Widgets::Index;

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):
use strict;

use Carp;
use DBI;


use lib 'inc';

use HWITest;
my $dbh;

eval {
my $DSN = ( $ENV{DSN_TEST} or "DBI:mysql:test" );
$dbh = DBI->connect($DSN,undef,undef,{PrintError=>0,RaiseError=>1})
	or die $DBI::errstr;
};

if ($@) {
	warn "$@\n";
	print "1..0\n";
	exit;
}

print "1..70\n";

$index = HTML::Widgets::Index->open($dbh);
$index->set_render_active_children(0);
$OUT_NAME="minim_mysql";
$cont=1;

do_test('/c');
do_test('/b/b3/b35');

my $OFFSET=31;

test_recursiu();

################################################################
sub test_recursiu {

	my $id_parent = ( shift or 0 );
	my $path = ( shift or '');
	my $sth= $dbh->prepare(
		"SELECT uri,id FROM index_items	
		WHERE id_parent = $id_parent
		ORDER BY uri"
	);
	$sth->execute;
	my ($uri,$id);
	$sth->bind_columns(\($uri,$id));
	while ( $sth->fetch ) {
#		warn "$path/$uri";
		do_test("$path/$uri" );
		test_recursiu($id,$index->get_uri);
	
	}
	$sth->finish;
}

sub test_recursiu_bar {

	my $id_parent = ( shift or 0 );
	my $path = ( shift or '');
	my $sth= $dbh->prepare(
		"SELECT uri,id FROM index_items	
		WHERE id_parent = $id_parent
		ORDER BY uri"
	);
	$sth->execute;
	my ($uri,$id);
	$sth->bind_columns(\($uri,$id));
	while ( $sth->fetch ) {
#		warn "$path/$uri";
		$uri.="/" unless $uri =~ /\.\w+$/;
		do_test("$path/$uri",$cont-$OFFSET);
		test_recursiu_bar($id,$index->get_uri);
		warn "$cont ".($cont-$OFFSET) if $?;
	}
	$sth->finish;
}

##########################################################

do_test('/');

##########################################################

$index->set_render_children(1);
test_recursiu();

$index->set_render_children(0);
test_recursiu_bar();

do_test('/a/a1/?a=1');

$index->set_render_children(1);
$index->set_home('/home');
do_test('/home/a/a1');

for (qw( /b/b3 /b/b3/b35/ /b/b3/b35 /b/b3/b35/b351.html / /index.html)) {
	do_test("/home$_");

}

do_test('/home');

$index->set_home('/home/');
do_test('/home/a/a1');

$index->set_render_children(1);

$index->set_home('/home');
do_test('/home/');

$index->set_home('/');
$index->set_render_children(0);
do_test('//b//b3/b35');

$index->set_render_parent(1);
do_test('/b/b3/b35');

do_test('/b/b3/b35/b351.html');

$index->set_render_parent(0);
do_test('/b/b3/b35/b351.html');

$index->set_render_all(1);
do_test('/');

$index->set_render_all(0);
$index->set_render_parent(0);
$index->set_render_parent(0);

$index->set_render_active_children(1);
do_test('/');
do_test('/b');
do_test('/b/b3');

$index->set_render_active_children(1);
do_test('/b/b1');
do_test('/b/b3');
do_test('/b/b3/b35');
$dbh->disconnect;
