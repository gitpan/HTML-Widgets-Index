BEGIN { $| = 1; }

use Cwd;
use DBI;
use HTML::Widgets::Index;

use strict;

use lib 'inc';
use HWITest;

use Test::More skip_all => 'TODO test #2';

my $dbh;
my $DSN = ( $ENV{DSN_TEST} or "DBI:mysql:test" );
eval {
	$dbh = DBI->connect($DSN,undef,undef,{RaiseError=>1,PrintError=>0});
};
if ($@) {
	print "1..0\n";
	exit;
}
print "1..3\n";

`rm -rf picoxova`;
mkdir 'picoxova' or die $!;
chdir 'picoxova' or die $!;
`touch index.html`;
mkdir 'a';
`touch a/index.html`;
`touch a/a1.html`;
`mkdir a/a2/`;
`touch a/a2/index.html`;
###############################################################################
my $HOME=cwd;
`../bin/minixova --home=$HOME --DSN="$DSN" --table=pico_index`;

my $sth = $dbh->prepare("SELECT text FROM pico_index where id=?");
$sth->execute(1);
my ($text) = $sth->fetchrow;
$sth->finish;

print "not " if defined $text && $text eq 'a';
print "ok 1\n";

$sth->execute(2);
($text) = $sth->fetchrow;
$sth->finish;

# TODO
#
print "not " unless $text eq 'a1';
print "ok 2\n";

$index = HTML::Widgets::Index->open(
	dbh => $dbh,
	table_items => 'pico_index',
);

# actually it is 3, but I TODOED test 2
$cont = 3;
$OUT_NAME='picoxova';
#$HTML::Widgets::Index::DEBUG=1;
#$HTML::Widgets::Index::Item::DEBUG=1;
$index->set_render_all(0);
$index->set_render_children(0);
chdir ".." or die $!;
do_test('/');

do_test('/a');

$dbh->disconnect;
