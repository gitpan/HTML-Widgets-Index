BEGIN { $| = 1; }

use Cwd;
use DBI;
use HTML::Widgets::Index;

use strict;

use lib '.';
use Test;

my $based = cwd;
my $dbh;
my $DSN = ( $ENV{DSN_TEST} or "DBI:mysql:test" );
eval {
	$dbh = DBI->connect($DSN,undef,undef,{RaiseError=>1,PrintError=>0});
};
if ($@) {
	print "1..0\n";
	exit;
}
print "1..7\n";

`rm -rf t/test_trees/nephews`;
mkdir 't/test_trees/nephews' or die $!;
chdir 't/test_trees/nephews' or die $!;
`touch index.html`;
mkdir 'a';
`touch a/index.html`;
`mkdir a/a1/`;
`touch a/a1/index.html`;
`touch a/a1/wow.html`;
`mkdir b/`;
`touch b/index.html`;
`touch b/bow.html`;
`mkdir c/`;
`touch c/index.html`;
`touch c/row.html`;
###############################################################################
my $HOME=cwd;
`$based/bin/minixova --home=$HOME --DSN="$DSN" --table=nephews_index`;

my $sth = $dbh->prepare("SELECT text FROM nephews_index where id=?");
$sth->execute(1);
my ($text) = $sth->fetchrow;
$sth->finish;

print "not " unless $text eq 'a';
print "ok 1\n";

$sth->execute(2);
($text) = $sth->fetchrow;
$sth->finish;

print "not " unless $text eq 'b';
print "ok 2\n";

$index = HTML::Widgets::Index->open(
	dbh => $dbh,
	table_items => 'nephews_index',
);

$cont = 3;
$OUT_NAME='nephews';
#$HTML::Widgets::Index::DEBUG=1;
#$HTML::Widgets::Index::Item::DEBUG=1;
$index->set_render_all(0);
$index->set_render_children(0);
$index->set_render_nephews(0);
chdir $based or die $!;
do_test('/');

do_test('/a');

do_test('/b');

do_test('/c');

$index->set_render_nephews(1);

do_test('/c');

$dbh->disconnect;
