use strict;
use Carp;

use vars qw(@EXPORT $cont $index $OUT_NAME $header $foot $add_br $copia);

@EXPORT = qw ( do_test index OUT_NAME cont header foot add_br copia);

$copia=0;

sub do_test {
	my $uri = shift;
	croak '$cont uninitialized' unless defined $cont;
	croak '$OUT_NAME uninitialized' unless defined $OUT_NAME;
	my $cont_expected=(shift or $cont);
	$cont="0$cont" while length $cont<2;
	$cont_expected="0$cont_expected" while length $cont_expected<2;
	croak "cont_expected bad $cont_expected"
		unless $cont_expected =~ /^\d+$/;
#	croak "\n$cont_expected"
#		unless -f "t/out/expected_${OUT_NAME}_$cont_expected.html";
	$index->set_uri($uri);
	my $iguals = iguals($cont,$cont_expected);
	if ($uri =~ m!/$!) {
		$index->set_uri($uri."index.html");
		$iguals =iguals($cont,$cont_expected) if $iguals;
	}
	if (!iguals($cont,$cont_expected)) {
		print "not ";
		copia($cont,$cont_expected) if $copia;
	} else {
		unlink "t/out/${OUT_NAME}_$cont.html" unless $?;
	}
	print "ok $cont\n";
	$cont++;
}

sub iguals {
	my ($cont,$cont_expected) = @_;
	open OUT ,">t/out/${OUT_NAME}_$cont.html"
    		or die " $OUT_NAME $!";
	my $br='';
	$br='<br>' if defined $add_br && $add_br;
	print OUT $index->get_uri,"$br\n";
	print OUT $index->get_title,"$br\n";
	print OUT $index->get_path,"$br\n";
	print OUT $header if defined $header;
	print OUT $index->render();
	print OUT $foot if defined $foot;
	close OUT;
	my $test = "t/out/${OUT_NAME}_$cont.html";
	my $expected = "t/out/expected_${OUT_NAME}_$cont_expected.html";
#	`diff t/out/${OUT_NAME}_$cont.html t/out/expected_${OUT_NAME}_$cont_expected.html`;
	`diff $test $expected`;
#	`cp $test $expected` if $?;
	return !$?;
}

sub copia {
	my ($cont,$cont_expected) = @_;
    my $test = "t/out/${OUT_NAME}_$cont.html";
    my $expected = "t/out/expected_${OUT_NAME}_$cont_expected.html";
	warn "copia $test a $expected\n";
   `cp $test $expected`;# if $?;
}

1;

