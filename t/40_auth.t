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

my $dbh;
my $DEBUG=0;

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

my @test=qw(1 20 170 210);
my %test = map { $_ , 1 }@test;

print "1..".($#test+1+4)."\n";

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

sub check_user {
	my ($url) = @_;
	my $ret = 1;
	$ret = 0 if $url =~ m!^/relacions!;
	$ret = 0 if $url =~ /su/;
	warn "check1 $url $ret" if $DEBUG;
# && $url =~/relacions/;
	return $ret;
}

sub check_user2 {
	my $url = shift;
	my $ret = 1;
	$ret = 0 if $url =~ m!^/estudis/acces!;
	warn "check2 $url $ret" if $DEBUG;
	return $ret;
}

sub check_allow_org {
	my $url = shift;
	return 0 if $url =~ m!^/l_escola/organitzacio!;
	return 1;
}

my $index = HTML::Widgets::Index->open( 
	$dbh, 
	format => $format,
	table_items => 'frankie_Menu_items',
	allowed => \&check_user
);

my ($cont,$tested)=(1,1);

test_recursiu();


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
			$tested="0$tested" while length $tested<3;
			open OUT ,">t/out/auth_$tested.html"
    			or die $!;
			print OUT $index->get_uri,"<br>\n";
			print OUT $index->get_title,"<br>\n";
			print OUT $index->get_path,"<br>\n";
			print OUT '<table border="0" cellspacing="0" cellpadding="0"'.
					'bgcolor="#e0f0e0">'."\n";
			print OUT $index->render();
			print OUT "</table>\n";

			close OUT;
			#`cp t/out/auth_$tested.html t/out/expected_auth_$tested.html`;
			`diff t/out/auth_$tested.html t/out/expected_auth_$tested.html`;
			print "not " if $?;
			print "ok $tested\n";
			unless ($?) {
				unlink "t/out/auth_$tested.html" 
					or die "$! t/out/auth_$tested.html";
			}
			$tested++;
		}

		$cont++;
		test_recursiu($id,$index->get_uri);
	}
	$sth->finish;
}

sub test {
	my ($uri,$tested) = @_;
	$index->set_uri($uri);
	$tested="0$tested" while length $tested<3;
	open OUT ,">t/out/auth_$tested.html"
 			or die $!;
	print OUT $index->get_uri,"<br>\n";
	print OUT ($index->get_title or ''),"<br>\n";
	print OUT ($index->get_path or ''),"<br>\n";
	print OUT '<table border="0" cellspacing="0" cellpadding="0"'.
		'bgcolor="#e0f0e0">'."\n";
print OUT $index->render();
print OUT "</table>\n";

close OUT;
#`cp t/out/auth_$tested.html t/out/expected_auth_$tested.html`;
`diff t/out/auth_$tested.html t/out/expected_auth_$tested.html`;
print "not " if $?;
print "ok $tested\n";
unless ($?) {
	unlink "t/out/auth_$tested.html" 
		or die "$! t/out/auth_$tested.html";
}

}

############################################################

test('/',$tested++);

$DEBUG=0;
$index->set_allowed(\&check_user2);
test('/',$tested++);
$DEBUG=0;
test('/estudis/acces',$tested++);

$index->set_render_children(1);
$index->set_allowed(\&check_allow_org);
test('/l_escola/presentacio',$tested++);

$dbh->disconnect;

