package HTML::Widgets::Index::Item;

use strict;
use vars qw($VERSION @ISA $AUTOLOAD 
	%FIELDS_RO %FIELDS_RW %FIELDS_TABLE %FIELDS_TABLE_REV
	$DEBUG
);
$VERSION='0.01';

use Carp;

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
$DEBUG = 0;
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

%FIELDS_RO = (
	id => undef
);

%FIELDS_RW = (
		 active => 0,
	   		uri => undef,
	   	   text => undef,
		  level => undef,
		href_js => '',
	 has_javascript => 0,
		parent => undef,
);

%FIELDS_TABLE = (
	id => 'id',
	uri => 'uri',
	text => 'text',
	id_parent => 'id_parent',
	ordern => 'ordern',
	has_javascript => 'has_javascript',
	href_js => 'href_js',
	active => 'active',
	level => 'level',
	parent => 'parent',
);

%FIELDS_TABLE_REV = %FIELDS_TABLE;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

HTML::Widgets::Index::Item - Perl extension for blah blah blah

=head1 SYNOPSIS

  use HTML::Widgets::Index::Item;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for HTML::Widgets::Index::Item was created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head1 CONSTRUCTORS

=head2 new 

  my $item = HTML::Widgets::Index::Item->new(
     id => 34,
     text => 'By Picture',
     uri => '/movies/by_picture.html',
     active => 0,
     level => 2,
  );

=cut

sub new {

    my $proto = shift;
    my $class = ref($proto) || $proto;
   
    my $self = parse_args(\@_, ($FIELDS_TABLE{id} , $FIELDS_TABLE{text},
									$FIELDS_TABLE{uri})
	);
	foreach (keys %$self) {
		unless (exists $FIELDS_TABLE_REV{$_}) {
			my $q='';
			foreach (keys %FIELDS_TABLE_REV) {
				$q.="$_=$FIELDS_TABLE_REV{$_} ";
			}
			confess "Unknown field $_ , $q";
		}

		carp "Unknown parameter $_"
			unless (exists $FIELDS_RO{$_}
					|| exists $FIELDS_RW{$_});
	}
	bless $self,$class;
	$self->set_default_fields();
	return $self;
}

=head2 open

  mt $item = HTML::Widgets::Index::Item->open(
        dbh => $dbh,
        id => 34,
        table_items => 'items',
  );

=cut

sub open {
	my $proto = shift;
	my $field = parse_args(\@_ , qw(id dbh table_items));
	my $sth = $field->{dbh}->prepare(
		"SELECT ".select_fields().
		" FROM $field->{table_items}	
		 WHERE $FIELDS_TABLE{id} = $field->{id}"
	);
	$sth->execute;
	my $item = $sth->fetchrow_hashref
		or confess "I can't find item id=$field->{id} in $field->{table_items}";
	
	$sth->finish;
	return HTML::Widgets::Index::Item->new(%$item);
}


sub set_default_fields {
	my $self = shift;
	foreach my $field (keys %FIELDS_RW) {
		next if exists $self->{$field};
		$self->{$field} = $FIELDS_RW{$field};
	}
}

sub parse_args {

  my $arg=shift @_;
  warn $#$arg,(join "-",@$arg) unless $#$arg % 2;
  my %arg=@$arg;
  foreach (@_) {
        confess "Mandatory argument $_ not found"
                        unless exists $arg{$_};
  }
  return \%arg;

}

=head1 METHODS


=head2 search

  my $list_of_items = HTML::Widgets::Index::Item->search(
	dbh => $dbh,
	table_items => 'index_items',
    level => 0,
  );

=cut

sub search {
	my $self = shift;
	my %field=(
		table_items => 'index_items',
		@_
	);
	my $dbh = $field{dbh};
	delete $field{dbh};
	my $table_items = $field{table_items};
	delete $field{table_items};

	my $where='';
	foreach (keys %field) {
		$where.= ' AND ' if length $where;
		$where.= " $FIELDS_TABLE{$_} = '$field{$_}'";
	}
	my $select_fields = $self->select_fields();
	
	my $query=
		"SELECT $select_fields		".
		" FROM $table_items	".
		" WHERE $where".
		" ORDER BY $FIELDS_TABLE{ordern}";
	warn $query,"\n" if $DEBUG;
	my $sth = $dbh->prepare($query);
	$sth->execute
		or die "$DBI::errstr\n$query";
	my @found;
	my $item;
	while ($item=$sth->fetchrow_hashref) {
		warn $item->{uri},"\n" if $DEBUG;
		push @found,(HTML::Widgets::Index::Item->new(%$item));
	}
	$sth->finish;
	return @found;
}

sub select_fields {
	my $self=shift;
	return join ",",($FIELDS_TABLE{id},$FIELDS_TABLE{uri},$FIELDS_TABLE{text});
}
=head2 config_fields

=cut

sub config_fields {

	my $self = shift;

	my %field = @_;
	foreach my $name (keys %field) {
		if (exists $FIELDS_TABLE{$name}) {
			$FIELDS_TABLE{$name}=$field{$name};
			$FIELDS_TABLE_REV{$field{$name}} = $name;
			if (exists $FIELDS_RO{$name}) {
				$FIELDS_RO{$field{$name}}=$FIELDS_RO{$name};
				delete $FIELDS_RO{$name};
			}
			if (exists $FIELDS_RW{$name}) {
                $FIELDS_RW{$field{$name}}=$FIELDS_RW{$name};
                delete $FIELDS_RW{$name};
            }
			delete $field{$name};
        }
	}
	confess "Unknown fields ".(join ",",keys %field)
		if keys %field;
}

sub get_byname {
    my $self=shift;
    my $req_var = shift;
	my $var = $FIELDS_TABLE{$req_var};

	croak "$req_var does not exists in ".ref $self
		unless defined $var;

	confess "$var undefined"
		if $var eq 'js'
		&& !(defined $FIELDS_RO{$var} or defined $FIELDS_RW{$var});

    return $self->{$var}
        if exists $FIELDS_RO{$var};

    return $self->{$var}
        if exists $FIELDS_RW{$var};

    my $err = "Can't access `$req_var ($var)' field in class ".ref $self;
	foreach (keys %FIELDS_RW) {
		$err.="$_=$FIELDS_RW{$_} ";
	}
	die $err;
}


sub AUTOLOAD {
    my $self = shift;
    my $type = ref($self)
        or croak "$self is not an object";

    my $name = $AUTOLOAD;
    $name =~ s/.*://;   # strip fully-qualified portion

    return if $name=~/^[A-Z]+$/;
   
    my ($access,$var)=$name =~ /(\wet)_(.*)/;
	($access,$var) = $name =~ /(\wetabs)_(.*)/
		unless defined $var;
	if ($access =~ /etabs$/) {
		($access) =~ s/(^\wet)abs/$1/;
		$var = $FIELDS_TABLE_REV{$var};
#		warn "abs: $access $var";
	}
   
    return $self->get_byname($var)
        if ($access eq 'get');

    if ($access eq 'set' && exists $FIELDS_RW{$var}) {
        $self->{$var}=shift;
        return $self->{$var};
    }
    croak "Can't access `$name' field in class $type";

}


=head1 AUTHOR

Francesc Guasch - Ortiz , frankie@etsetb.upc.es

=head1 SEE ALSO

perl(1).

=cut

1;
__END__
