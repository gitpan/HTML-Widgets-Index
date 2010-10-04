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
use DBI;
use lib 'inc';
use HWITest;

my $dbh;

eval {
	my $DSN = ( $ENV{DSN_TEST} or "DBI:mysql:test" );
	$dbh = DBI->connect($DSN,undef,undef,
		{	PrintError=>0,
			RaiseError => 1
		}
	)
	or die $DBI::errstr;
};

if ($@) {
	print "1..0\n";
	exit;
}


print "1..6\n";

my $uri;

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


HTML::Widgets::Index::Item->config_fields(
        id => 'idMenu_item',
        id_parent => 'idParent',
        text => 'item',
        uri => 'link',
);

$index = HTML::Widgets::Index->open( 
	$dbh, 
	format => $format,
	table_items => 'frankie_Menu_items'
);

$cont = 1;
$OUT_NAME='teleco_children';
$header='<table border="0" cellspacing="0" cellpadding="0"bgcolor="#e0f0e0">'."\n";
$foot="</table>\n";
$add_br=1;

$index->set_render_children(1);
$copia=0;
do_test("/estudis");
do_test("/estudis/acces");
do_test("/estudis/acces/preinscripcio");
do_test("/intercanvis/etsetb/institucions/Gran_Bretanya");
do_test("/");
do_test("/Fail");

$dbh->disconnect;
