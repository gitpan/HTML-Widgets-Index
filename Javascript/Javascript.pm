package HTML::Widgets::Index::Javascript;

use strict;
use vars qw($VERSION @ISA %FIELDS_RO %FIELDS_RW $AUTOLOAD);

require Exporter;
require AutoLoader;
use Carp;

@ISA = qw(Exporter);
$VERSION = '0.01';


%FIELDS_RO = ();

%FIELDS_RW = (
	onMouseOver => 'showMenu',
	onMouseOut => 'time();',
	createLayer => 	'makeMenu("item$id")'."\n".
						'addTitle("$text")'."\n",
	endMenu => "endMenu()\n",
	addItem => 'addItem("$text","$uri")'."\n",
);


=head1 NAME

HTML::Widgets::Index::Javascript - Names of the javascript routines

=head1 SYNOPSIS

  use HTML::Widgets::Index::Javascript;

=head1 DESCRIPTION

The Index can render javascript so pop-up menus are shown.

my $javascript = HTML::Widgets::Index->new();
$javascript->set_onMouseOver('showMenu');

=head1 CONSTRUCTOR

  my $javascript = HTML::Widgets::Javascript->new(); # default

  my $javascript = HTML::Widgets::Javascript->new(
	onMouseOver => 'showMenu',
	# here you can add the rest of the functions, see below.
	# Usually the default is enough.
  );

=head2 DEFAULT JAVASCRIPT

  With the sources there is a .js file that will be suitable for
  most of you. You can write your own javascript functions if you
  need it.

=cut

sub new {
	my $proto = shift;
    my $class = ref($proto) || $proto;
	my %self = ( %FIELDS_RO , %FIELDS_RW );
	my $self = {};
	my %args = @_;
	foreach (keys %FIELDS_RO, %FIELDS_RW) {
		$self->{$_}= ( $args{$_}
						or $FIELDS_RO{$_}
						or $FIELDS_RW{$_}
		);
		delete $args{$_};
	}
	carp "Unknown fields ".(join ",",keys %args)
		if keys %args;
	bless $self, $class;
	return $self;
}


=head1 FUNCTIONS

=over

=item *

onMouseOver

=item *

onMouseOut

=item *

createLayer

=item *

endMenu

=item *

addItem

=back


=cut

sub set_byname {
	my $self = shift;
	my ($var,$value) = @_;

	$value =~ s#/$## if $var eq 'home';
	$self->{$var}=$value;
	return $self->{$var};
}


sub get_byname {
    my $self=shift;
    my $var = shift;
	$self->render()
		if ($var eq 'title' || $var eq 'path')
			&& ($self->{uri} && ! $self->{render});

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
        
	return $self->set_byname($var,shift)
    	if ($access eq 'set' && exists $FIELDS_RW{$var});

     croak "Can't access `$name' field in class $type";

}


=head1 AUTHOR

Francesc Guasch - Ortiz , frankie@etsetb.upc.es

=head1 SEE ALSO

perl(1) , HTML:Widgets::Menu(1).

=cut

1;
__END__
