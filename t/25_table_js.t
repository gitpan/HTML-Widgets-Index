# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; }
use strict;
use HTML::Widgets::Index;
use HTML::Widgets::Index::Javascript;

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):
use DBI;

my $dbh;

eval {
my $DSN = ( $ENV{DSN_TEST} or "DBI:mysql:test" );
$dbh = DBI->connect($DSN,undef,undef,{PrintError=>0,RaiseError=>1})
	or die $DBI::errstr;
};

if ($@) {
	print "1..0\n";
	exit;
}

print "1..16\n";

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

  #          active_text_placeholder =>'<span class="menu_active"><text></span>',
            indent_inactive => 
				'<img src="/img/point.gif" width="4" height="1">',
			indent_active =>
				'<img src="/img/point.gif" width="4" height="1">',
			javascript => 1,
	},
	1=> {
		indent_active => '',
		indent_inactive => ''
	}
};


my $javascript = HTML::Widgets::Index::Javascript->new(
    onMouseOver => 'mostraMenu',
    onMouseOut  => 'temps();',
    createLayer => 'creaMenu("item$id")'."\n".
                        'afegirTitol("$text")'."\n",
    addItem => 'afegirItem("$text","$uri")'."\n",
    endMenu => "fiMenu()\n"
);

my $index = HTML::Widgets::Index->open( 
	$dbh, 
	format => $format,
	js => $javascript
);

my $cont=1;
my $NAME_OUT="js_base";

test_recursiu();


#########################################################

sub do_test {
	my $cont = shift;
	my $uri = shift;
	$cont="0$cont" if length $cont<2;
	open OUT ,">t/out/${NAME_OUT}_$cont.html"
   		or die $!;
	$index->set_uri($uri);
	print OUT "<head><title>".$index->get_title."</title>\n";
	print OUT '<script src="/javascript/dhtml_func.js" '.
				'language="Javascript"></script>'."\n";
	print OUT "  <script language=\"Javascript\">\n".
				"	".$index->get_javascript."\n".
				"  </script>\n".
			"</head>";
	print OUT $index->get_uri,"<br>\n";
	print OUT $index->get_title,"<br>\n";
	print OUT $index->get_path,"<br>\n";
	print OUT '<table border="0" cellspacing="0" cellpadding="0"'.
				'bgcolor="#e0f0e0">'."\n";
	print OUT $index->render();
	print OUT "</table>\n";

	close OUT;
	#`cp t/out/${NAME_OUT}_$cont.html t/out/expected_${NAME_OUT}_$cont.html`;
	`diff t/out/${NAME_OUT}_$cont.html t/out/expected_${NAME_OUT}_$cont.html`;
	print "not " if $?;
	print "ok $cont\n";
	unlink "t/out/${NAME_OUT}_$cont.html" unless $?;

}

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
		last if $cont>11;
#		warn "$path/$uri";
		do_test($cont,"$path/$uri");
		$cont++;
		test_recursiu($id,$index->get_uri);
	}
	$sth->finish;
}

##########################################################

open OUT ,">t/out/${NAME_OUT}_$cont.html"
   		or die $!;
$index->set_uri("/");
print OUT "<head><title>".$index->get_title."</title>\n";
print OUT '<script src="/javascript/dhtml_func.js" language="Javascript"></script>'."\n";
print OUT "  <script language=\"Javascript\">\n".
				"	".$index->get_javascript."\n".
				"  </script>\n".
			"</head>";
print OUT $index->get_uri,"<br>\n";
print OUT $index->get_title,"<br>\n";
print OUT $index->get_path,"<br>\n";
print OUT '<table border="0" cellspacing="0" cellpadding="0"'.
				'bgcolor="#e0f0e0">'."\n";
print OUT $index->render();
print OUT "</table>\n";

close OUT;

#`cp t/out/${NAME_OUT}_$cont.html t/out/expected_${NAME_OUT}_$cont.html`;
`diff t/out/${NAME_OUT}_$cont.html t/out/expected_${NAME_OUT}_$cont.html`;
print "not " if $?;
print "ok $cont\n";
unlink "t/out/${NAME_OUT}_$cont.html" unless $?;

#######################################################################

$cont++;

$dbh->do("INSERT INTO index_items VALUES (null,'b3521','B3521',15,100)");
open OUT ,">t/out/${NAME_OUT}_$cont.html"
   		or die $!;
$index->set_uri("/b/b3/b35/b351.html");
print OUT "<head><title>".$index->get_title."</title>\n";
print OUT '<script src="/javascript/dhtml_func.js" language="Javascript"></script>'."\n";
print OUT "  <script language=\"Javascript\">\n".
				"	".$index->get_javascript."\n".
				"  </script>\n".
			"</head>";
print OUT $index->get_uri,"<br>\n";
print OUT $index->get_title,"<br>\n";
print OUT $index->get_path,"<br>\n";
print OUT '<table border="0" cellspacing="0" cellpadding="0"'.
				'bgcolor="#e0f0e0">'."\n";
print OUT $index->render();
print OUT "</table>\n";
close OUT;

#`cp t/out/${NAME_OUT}_$cont.html t/out/expected_${NAME_OUT}_$cont.html`;
`diff t/out/${NAME_OUT}_$cont.html t/out/expected_${NAME_OUT}_$cont.html`;

print "not " if $?;
print "ok $cont\n";
unlink "t/out/${NAME_OUT}_$cont.html" unless $?;

####################################################################

do_test(++$cont,'/b/b1/');

#$HTML::Widgets::Index::DEBUG=1;

$index->set_render_children(1);
do_test(++$cont,'/b/b3/');

$HTML::Widgets::Index::DEBUG=0;


$index->set_home('/home');
do_test(++$cont,'/home');

$dbh->disconnect;

