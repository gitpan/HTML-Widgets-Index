package HTML::Widgets::Index::Format::Item;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD %FIELDS_RO %FIELDS_RW
			$DEBUG );

use Carp;

require Exporter;
require AutoLoader;

@ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use HTML::Widgets::Index::Format::Item ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
$VERSION = '0.01';

$DEBUG = 0;

%FIELDS_RO = ();

%FIELDS_RW = (

	active_item_start => '',
	active_item_end => "\n",
	inactive_item_start => '',
	inactive_item_end => "\n",
	font=>'',
	active_text_start => '<b>',
	active_text_end => '</b>',
	inactive_text_start => '',
	inactive_text_end => '',
	inactive_text_placeholder => '<text>', 
	active_text_placeholder=>'<text>',
	link_args=>'',
	indent => '',
	indent_start => '',
	indent_end => '',
	indent_active => '*',
	indent_inactive => ' ',
	javascript => 0,
	no_javascript => '',

);

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

# Below is stub documentation for your module. You better edit it!

=head1 NAME

HTML::Widgets::Index::Format::Item - Perl extension for blah blah blah

=head1 SYNOPSIS

  use HTML::Widgets::Index::Format::Item;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for HTML::Widgets::Index::Format::Item, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head1 CONSTRUCTOR

=head2 new

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my %args = @_;
	my %self;
	%self =  %args ;
	my $self = \%self;
	if ($DEBUG) {
		foreach (keys %self) {
			warn "$_=$self{$_}\n";
		}
	}
	bless ($self,$class);
	return $self;
}

=head1 METHODS

=head2 apply_default

    Puts defaults to unknown values.

    $item->apply_default;

=cut

sub apply_default {
	my $self = shift;
	foreach (keys %FIELDS_RO) {
		$self->{$_}=$FIELDS_RO{$_}
			unless exists $self->{$_};
	}
	foreach (keys %FIELDS_RW) {
		$self->{$_}=$FIELDS_RW{$_}
			unless exists $self->{$_};
	} 
}


##############################################################

sub get_byname {
	my $self=shift;
	my $var = shift;
	return $self->{$var}
		if exists $FIELDS_RO{$var};

	return $self->{$var}
		if exists $FIELDS_RW{$var};

   croak "Can't access `$var' field in class ".ref $self;
}

sub AUTOLOAD {
	my $self = shift;
	my $type = ref($self)
		or croak "$self is not an object";
		
	my $name = $AUTOLOAD;
	$name =~ s/.*://;   # strip fully-qualified portion

	return if $name=~/^[A-Z]+$/;

	my ($access,$var)=$name =~ /(\wet)_(.*)/;

	return $self->get_byname($var)
		if ($access eq 'get');

	if ($access eq 'set' && exists $FIELDS_RW{$var}) {
		$self->{$var}=shift;
		return $self->{$var};
	}
	confess "Can't access `$name' field in class $type";

}



=head1 AUTHOR

A. U. Thor, E<lt>a.u.thor@a.galaxy.far.far.awayE<gt>

=head1 SEE ALSO

L<perl>.

=cut

1;
__END__
