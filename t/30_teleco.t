# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; }
use locale;
use POSIX qw(locale_h);
setlocale(LC_ALL,'es_ES@euro');

use HTML::Widgets::Index;
use Benchmark;

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):
use DBI;

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

my @test=qw(1 10 20 30 40 50 60 70 100 110 121 130 140 150 160 170 210);
my @test_uri= qw(
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

my $TOTAL=$#test+1;
my %test = map { $_ , 1 }@test;

print "1..".($TOTAL*2)."\n";

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

my $index = HTML::Widgets::Index->open( 
	$dbh, 
	format => $format,
	table_items => 'frankie_Menu_items'
);

my ($cont,$tested)=(1,1);

for (@test_uri) {
	do_test($_);
}

my $home='/other/home';
$index->set_home($home);
my $source=1;
for my $uri (@test_uri) {
	copy_expected($source++);
	do_test("$home/$uri");
	remove_expected($tested-1) unless $?;
}

$dbh->disconnect;

#########################################################

sub test_recursiu {

	my $id_parent = ( shift or 0 );
	my $path = ( shift or '');
	my $sth= $dbh->prepare(
		"SELECT link,idMenu_item FROM frankie_Menu_items	
		WHERE idParent = $id_parent
		ORDER BY link"
	);
	$sth->execute;
	my ($uri,$id);
	$sth->bind_columns(\($uri,$id));
	while ( $sth->fetch ) {
#		warn "$path/$uri";
		$index->set_uri("$path/$uri");
		if ($test{$cont}) {
			warn "\n$path/$uri\n";
			do_test("$path/$uri");
		}

		$cont++;
		test_recursiu($id,$index->get_uri);
	}
	$sth->finish;
}

sub do_test {
	my $uri = shift;
	$index->set_uri($uri);
	$tested="0$tested" while length $tested<3;
	open OUT ,">t/out/teleco_$tested.html"
   		or die $!;
	print OUT $index->get_uri,"<br>\n";
	print OUT $index->get_title,"<br>\n";
	print OUT $index->get_path,"<br>\n";
	print OUT '<table border="0" cellspacing="0" cellpadding="0"'.
				'bgcolor="#e0f0e0">'."\n";
	print OUT $index->render();
	print OUT "</table>\n";

	close OUT;
	#`cp t/out/teleco_$tested.html t/out/expected_teleco_$tested.html`;
	`diff t/out/teleco_$tested.html t/out/expected_teleco_$tested.html`;
	my $t2 = new Benchmark;

	print "not " if $?;
	print "ok $tested\n";
	unlink "t/out/teleco_$tested.html" unless $?;
	$tested++;

}

sub copy_expected {
	my $source=shift;
	$source ="0$source" while length $source<3;
	$tested="0$tested" while length $tested<3;

	my $source_file="t/out/expected_teleco_$source.html";
	open SOURCE ,"<$source_file"
		or die "$! $source_file";
	my $dest_file ="t/out/expected_teleco_$tested.html";
#	die "$dest_file already exists" if -f $dest_file;
	open DEST ,">$dest_file"
		or die $!;
	$_=<SOURCE>;
	s/^/$home/;
	print DEST;
	while (<SOURCE>) {
		s/href="/href="$home/g;
		print DEST;
	}
	close DEST;
	close SOURCE;
}

sub remove_expected {
	my $source= shift;
	die "I won't remove $source"
		if $source <= $#test_uri;
	$source ="0$source" while length $source<3;
	unlink "t/out/expected_teleco_$source.html";
}
