BEGIN { $| = 1; }

use Cwd;
use DBI;
use HTML::Widgets::Index;
use Test::More;

use strict;

use lib 'inc';
use HWITest;

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

plan tests=> 10;

#print "1..10\n";

my @n =(5,7,13,17,23,29);
my $n='';
for my $cont (0..$#n) {
	for my $fw ($cont+1..$#n) {
		$n.=substr($n[$cont]/$n[$fw],0,17);
	}
}
$n =~ s#\.##g;
$n =~ s#\,##g;

my $current_a=0;
my $acumula=0;
`rm -rf t/test_trees`;
mkdir 't/test_trees' or die $!;
mkdir 't/test_trees/pseudo' or die $!;
my @random;

regenera_random();
chdir 't/test_trees/pseudo' or die $!;
open INDEX,">index.html" or die $!;
print INDEX "<h1>main index</h1>";
close INDEX;

for my $lletra ('a'..'e') {
	entra($lletra);
};

###############################################################################
sub regenera_random {
for my $current (split m##,$n) {
#	warn $current;
	if (!$current) {
		$acumula=1;
		next;
	}
	if ($acumula && $acumula--) {
		confess "non numeric current" if $current =~ /,/;
		$current_a+=$current;
		next;
	}
	if ($current_a) {
		$current=$current_a+$current;
		$current_a=0;
	}
	push @random,($current);
}
}

sub prandom {
	regenera_random() unless $#random;
	return pop @random;
}

sub entra {
	my $lletra = shift;
	mkdir $lletra or die $!;
	chdir $lletra or die "$! $lletra\n";
	open HTML,">index.html" or die $!;
	print HTML "index $lletra\n";
	close HTML;
	for my $i (1..prandom) {
		my $entra = prandom;
		my $nlletra = $lletra;
		$nlletra =~ s/_//g;
		if ($entra<3 && length $nlletra<prandom() 
				&& length $nlletra<prandom()  ) {
			entra($lletra."_$i");
		} else {
			open HTML ,">${lletra}_$i.html" or die $!;
			print HTML $lletra," $i\n";
			close HTML;
		}
	}
	chdir "..";
}

###############################################################################
my $HOME=cwd;
`$based/bin/minixova --home=$HOME --DSN="$DSN" --table=random_index`;
#`echo wow > wow`;
ok( -f "$HOME/javascript/dhtml_func.js");

ok( -f "$HOME/autohandler");

ok( -f "$HOME/menu/menu.mc");

my $sth = $dbh->prepare("SELECT text FROM random_index where id=?");
$sth->execute(1);
my ($text) = $sth->fetchrow;
$sth->finish;

	$sth->execute(10);
SKIP: {
	skip('TODO',2);
	ok( $text eq 'a');

	($text) = $sth->fetchrow;

	ok( $text eq 'b 3');
};

$sth->finish;

my $format = {
	default => {
   
            link_args => 'class="menu"',
            active_item_start => '<tr><td bgcolor="white">'.
                        '<img src="/img/point.gif" height="1">'.
                        '</td></tr>'.
                        "<tr><td>\n",
   
            active_item_end => "</td></tr>\n",
            inactive_item_start => '<tr><td bgcolor="white">'.
                        '<img src="/img/point.gif" width="15" height="1">'.
                        "</td></tr><tr><td>\n",
            inactive_item_end => "</td></tr>\n",

            active_text_placeholder =>'<span class="menu_active"><text></span>',
            indent_inactive => 
				'<img src="/img/point.gif" width="4" height="1">',
			indent_active =>
				'<img src="/img/point.gif" width="4" height="1">',
	},
	1=> {
		indent_active => '',
		indent_inactive => '',
		inactive_text_placeholder => 
			'<img src="/img/icon/<url>.gif" alt="<text>" border="0">',
		active_text_placeholder => 
            '<img src="/img/icon/<url>.gif" alt="<text>" border="0">',
	}
};

$index = HTML::Widgets::Index->open(
	dbh => $dbh,
#	format => $format,
	table_items => 'random_index',
    home => '/',
);

$cont = 6;
$OUT_NAME='minixova';
#$HTML::Widgets::Index::DEBUG=1;
#$HTML::Widgets::Index::Item::DEBUG=1;
$index->set_render_all(0);
$index->set_render_children(0);
$index->set_render_active_children(1);
#chdir ".." or die $!;
chdir $based or die $!;

SKIP: {
	skip('TODO',5); # HWITest do_test must work with Test::More
#do_test('/');
do_test('/a');
#$HTML::Widgets::Index::DEBUG_HERE=1;
#$HTML::Widgets::Index::DEBUG_RENDER_ITEM_HTML=1;
do_test('/b/b_2');
#$HTML::Widgets::Index::DEBUG_HERE=0;
do_test('/b/b_5');
do_test('/a/a_2.html');
	do_test('/e/e_4/e_4_5');
};
$dbh->disconnect;
