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
use Benchmark;
use strict;

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

my @test_uri =qw(
/estudis
/estudis/normatives
/intercanvis/etsetb/estudiants/estugre.html
/intercanvis/etsetb/institucions/Alemanya/aachen.html
/intercanvis/etsetb/institucions/Belgica
/intercanvis/etsetb/institucions/Finlandia/tampere.html
/intercanvis/etsetb/institucions/France/eurecom.html
/intercanvis/etsetb/institucions/Gran_Bretanya
/intercanvis/etsetb/optar.html
/intercanvis/externs/courses-guide/Telecommunication_engineering/ects-telecommunication-optative-2.html
/l_escola/entitats/departaments
/l_escola/presentacio/dades/estudiants.html
/l_escola/serveis/cpet
/l_escola/serveis/serveis_informatics/correu
/l_escola/serveis/serveis_informatics/espais_docents/aularia2/localitzacio.html
/l_escola/serveis/serveis_informatics/espais_docents/espaisb3/telensenyament
/relacions/empreses/coop_educat/procediment.html
);

print "1..".(($#test_uri+1)*2)."\n";

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
			javascript => 1,
		no_javascript => 'empreses'
	},
	1=> {
		indent_active => '',
		indent_inactive => '',
		inactive_text_placeholder => 
			'<img src="/img/icon/<url>.gif" alt="<text>" border="0">',
		active_text_placeholder => 
            '<img src="/img/icon/<url>.gif" alt="<text>" border="0">',
	},
	2=> {
			},
};


HTML::Widgets::Index::Item->config_fields(
        id => 'idMenu_item',
        id_parent => 'idParent',
        text => 'item',
        uri => 'link',
);

add_serveis();

my $javascript = HTML::Widgets::Index::Javascript->new(
	onMouseOver => 'mostraMenu',
	onMouseOut => 'temps();',
	createLayer => 'creaMenu("item$id")'."\n".
					'afegirTitol("$text")'."\n",
	addItem => 'afegirItem("$text","$uri")'."\n",
	endMenu => "fiMenu()\n",
);

my $index = HTML::Widgets::Index->open( 
	$dbh, 
		 format => $format,
	 		js  => $javascript,
	table_items => 'frankie_Menu_items',
);

my ($cont,$tested)=(1,1);

foreach my $uri (@test_uri) {
	do_test($uri);
}

my $home = '/another/home/dir';
my $source=1;
$index->set_home($home);
for my $uri (@test_uri) {
	copy_expected($source++);
	do_test("$home/$uri");
	remove_expected($tested-1) unless $?;
}

$dbh->disconnect;

#########################################################

sub add_serveis {
	$dbh->do("INSERT INTO frankie_Menu_items
		VALUES(null,1,768,'est1','Est1',1)"
	);
}

sub do_test {
	my $uri = shift;
	$index->set_uri($uri);
	$tested="0$tested" while length $tested<2;
	open OUT ,">t/out/teleco_js_$tested.html"
    			or die $!;
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
	`diff t/out/teleco_js_$tested.html t/out/expected_teleco_js_$tested.html`;
	#`cp t/out/teleco_js_$tested.html t/out/expected_teleco_js_$tested.html` if $?;
	print "not " if $?;
	print "ok $tested\n";
	unlink "t/out/teleco_js_$tested.html" unless $?;
	$tested++;

}

sub copy_expected {
	my $source=shift;
	$source ="0$source" while length $source<2;
	$tested="0$tested" while length $tested<2;

	my $source_file="t/out/expected_teleco_js_$source.html";
	open SOURCE ,"<$source_file"
		or die "$! $source_file";
	my $dest_file ="t/out/expected_teleco_js_$tested.html";
#	die "$dest_file already exists" if -f $dest_file;
	open DEST ,">$dest_file"
		or die $!;
	while (<SOURCE>) {
		s/href="/href="$home/g;
		s/(afegirItem.*",")/$1$home/;
		s!(</head>)!$1$home!;
		print DEST;
	}
	close DEST;
	close SOURCE;
}

sub remove_expected {
	my $source= shift;
	die "I won't remove $source"
		if $source <= $#test_uri;
	$source ="0$source" while length $source<2;
	unlink "t/out/expected_teleco_js_$source.html";
}

