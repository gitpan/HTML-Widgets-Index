use ExtUtils::MakeMaker;

use strict;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my @search_httpd_conf=qw(/etc/httpd/conf /usr/local/apache/etc
						/usr/local/apache2/etc);

#@search_httpd_conf = qw(/tmp);

sub MY::postamble {
	# returns a Makefile. We need to find out httpd.conf. If we find it
	# we'll searc for the DocumentRoot
	# With these variables we can call to the Makefile in etc/
	my $httpd_conf;
	for (@search_httpd_conf) {
		if ( -e "$_/httpd.conf") {
			$httpd_conf= $_;
			last;
		}
	}
	unless ($httpd_conf) {
		warn "WARNING: I can't find httpd.conf, read INSTALL.txt\n";
		return;
	}
	my $ret =
"HTTPD_CONF=$httpd_conf

install_sample: etc/Makefile
	cd etc && make HTTPD_CONF=$httpd_conf";

	my $doc_root=`egrep "^DocumentRoot" $httpd_conf/httpd.conf`;
	chomp $doc_root;
	unless ($doc_root) {
		warn "WARNING: I can't find DocumentRoot in $httpd_conf, read INSTALL.txt\n";
		return;
	}
	$doc_root =~ s/^DocumentRoot\s+//;
	$doc_root=~ s/"//g;
	unless ( -e $doc_root ) {
		warn "WARNING: DocumentRoot $doc_root doesn't exist, read INSTALL.txt\n";
	} else {
		$ret.=" DOC_ROOT=$doc_root";
	}
	return "$ret\n\n";
}


WriteMakefile(
    'NAME'	=> 'HTML::Widgets::Index',
    'VERSION_FROM' => 'Index.pm', # finds $VERSION
    'PREREQ_PM' => { 'HTTP::BrowserDetect' => 0.97 , 'DBD::mysql' => 0.01 },
    'EXE_FILES' => ['bin/minixova', ],
);
