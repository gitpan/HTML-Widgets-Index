package HTML::Widgets::Index;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD $DEBUG $DEBUG_HERE
			$DEBUG_RECURSE $DEBUG_RENDER_ITEM_HTML
            );
#################################################################
#
$VERSION="0.5";

# 0.5 : Fixed small bugs, added render_nth_parents
#        Changed to Format.pm 0.02
#        Updated all test results to match new indentation in
#        Format.pm 0.02
# 0.4 : Added render_nephews option
# 0.3 : fixed all the tests
# 0.2 : indent changing image width in HTML

#####################################
use Carp;
use HTTP::BrowserDetect;

#####################################
use HTML::Widgets::Index::Item;
use HTML::Widgets::Index::Format;
use HTML::Widgets::Index::Javascript;


require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$DEBUG=0;
$DEBUG_HERE=0;

my %FIELDS_RO = (
	path => undef,
	title => undef,
	javascript => '' ,
	browser => new HTTP::BrowserDetect(),
	_dbh => undef,
	dbh => undef,
);

my %FIELDS_RW = (
	format => HTML::Widgets::Index::Format->new(),
	uri => undef,
	table_items => 'index_items',
	allowed => undef,
	render_children => 0,
	render_active_children => 0,
	render_parent => 0,
	render_nth_parents => 0,
	render_all => 0,
	render_nephews => 1,
	hide_brothers => 0,
	home => '',
	js => HTML::Widgets::Index::Javascript->new(),
	debug => 0,
);


=head1 NAME

HTML::Widgets::Index - Perl for creating web Indexes and Menus

=head1 SYNOPSIS

  use HTML::Widgets::Index;

=head1 DESCRIPTION

This module renders the index of a document tree using
the data stored in a MySQL database generated by anxova.
It has a flexible set of render options that gives the
webmaster many options on the menu item layout.

=head2 Table

The tree data must be in a table in a database. The
fields of this table should be:


 id: int            identifies the entry
 uri: varchar(150)  link of the entry
 text: varchar(150) text displayed in the screen
 id_parent: int	    the parent of the current entry. The root is 0
 ordern: int        menu item position on the menu


=head2 Data

Say you have a document tree like this:

 a
   a1.html
   a2.html

 b
   b1.html
   b2
     b21.html
     b22.html
   b3.html

 c
   c1.html

Then you must enter this in the table :

 ; First the directory A
 INSERT INTO index_items (id,id_parent,uri,text) 
    VALUES (1,0,'a','dir A');

 ; Now the docs of the a dir
 INSERT INTO index_items (id,id_parent,uri,text) 
    VALUES (2,1,'a1.html','A first');
 INSERT INTO index_items (id,id_parent,uri,text) 
    VALUES (3,1,'a2.html','A 2nd');

; Now the directory B
 INSERT INTO index_items (id,id_parent,uri,text)
    VALUES (4,0,'b','dir B');
 INSERT INTO index_items (id,id_parent,uri,text)
    VALUES (5,4,'b1.html','B first');

; The directory B has subdirs
 INSERT INTO index_items (id,id_parent,uri,text)
    VALUES (6,4,'b2','B second section');

 INSERT INTO index_items (id,id_parent,uri,text)
    VALUES (7,6,'b21.html','B 2 1 doc');

Notice the uri field is relative, not absolute.
You don't need to specify all the path to a document.
So you can move docs in the directory, then just change
the parent in the table.

The items are sorted alphabetically, if you want to change
the order displayed in the html, just add the field ordern
when you do the insert:

  INSERT INTO index_items (id,id_parent,uri,text,ordern)
    VALUES (5,4,'b1.html','B first',2);

  INSERT INTO index_items (id,id_parent,uri,text)
    VALUES (6,4,'b2','B second section',1);



=head1 CONSTRUCTOR

=head2 open


  my $index = HTML::Widgets::Index->open($dbh);

  my $index = HTML::Widgets::Index->open(
	       dbh => $dbh           # mandatory
	    format => $format,       # optional
	javascript => $javascript,   # optional
  );

  my $index = HTML::Widgets::Index->open(
           $dbh,                 # mandatory
        format => $format,       # optional
    javascript => $javascript,   # optional
  );

=cut

sub open {
    my $proto = shift;
    my $class = ref($proto) || $proto;

	my $dbh;
	$dbh = shift if (scalar(@_) % 2);

	my %arg = @_;

	$arg{format} = HTML::Widgets::Index::Format->new($arg{format})
		if (exists $arg{format});

	my $self = {};

    foreach my $field (keys %FIELDS_RO , keys %FIELDS_RW) {
        die "Field $field duplicated in RO and RW\n"
            if exists $self->{$field};
        if (exists $arg{$field}) {
            $self->{$field} = $arg{$field};
        } elsif (exists $FIELDS_RO{$field}) {
            $self->{$field} = $FIELDS_RO{$field};
        } elsif (exists $FIELDS_RW{$field}) {
            $self->{$field} = $FIELDS_RW{$field};
        }
        delete $arg{$field};
    }
    croak "Unknown fields ".(join ',',sort keys %arg)
        if keys %arg;

	$self->{_dbh} = $dbh if defined $dbh;
	$self->{_dbh} = $self->{dbh} if defined $self->{dbh};
	croak "Undefined dbh" unless defined $self->{_dbh};

    $self->{home} = '' if $self->{home} eq '/';
	bless $self , $class ;
	return $self;

}

=head1 METHODS

=head2 set_uri

  $index->set_uri( $uri );

  $index->set_uri('/products/networking.html');

=cut

sub set_uri {
	my $self = shift;
	my $uri = shift;
	$uri =~ s!//+!/!g;
	$uri =~ s/(.*?)\?.*/$1/;
	$uri =~ s/index.html$//;
	my $home = $self->get_home;
	$uri =~ s#//+#/#g;
	$uri =~ s#($home.+)/$#$1#;
	$uri .= '/' if $uri eq $home;# && $uri !~ m#/$#;
	return if defined $self->get_uri 
			&& ( $uri eq $self->get_uri );

	$self->{render} = undef;
	$self->{uri} = $uri;
	$self->{title} = undef;
	$self->{path} = undef;
}

=head2 get_html

Renders the menu to html:

    print $index->get_html( );

You can use it from a perl templating system for apache, like
HTML::Mason or others:

    <% $index->get_html %>

=cut


sub get_html {
	return html(@_);
}

sub html {
	return render(@_);
}

=head2 get_title

Returns a suitable title for the document.

The url /computers/networking/data.html returns:

  computers - networking - data

=cut

sub title {
	my $self = shift;
    return $self->get_title();
}


=head2 get_path

Returns all the items  that leads to the current document,
each one has its href.

The url "/computers/networking.html" returns:

  <a href="/computers">computers</a> 
   - <a href="/computers/netwoking.html">networking</a>

It's like the title with links to each part of it.

=cut

sub path {
     my $self = shift;
    return $self->get_path();
}



sub render {

	my $self = shift;

	if ($self->{uri} && $self->{render} ) {
			return $self->{render};
	}

	croak "You must set_uri first"
		unless $self->{uri};

	my $home = $self->get_home;
	my $level = ($self->{uri} =~ tr#/##) - ($home =~ tr#/##);
	$self->{level} = $level;
	warn "level =$level $self->{uri} ".$self->get_home if $DEBUG_HERE;

	$self->{title}='';
	$self->{path}='';
	$self->{abs_uri}='';
	$self->{javascript}='';

	$self->{render} = $self->recurse_render();

	return $self->{render};

}

=head2 set_allowed

  Adds a check before every item.

   $index->set_allowed(\&check_user);

  The argument is a reference to a subroutine. This subroutine will
  accept the first argument as the uri and must return true or false.

  example:

    sub check_user {
        my $uri = shift;
        return $uri =~ m#^/intranet#
			&& defined $ENV{REMOTE_USER}
			&& exists intranet_users{$ENV{REMOTE_USER}};
    }

=cut

##########################################################
# private methods

sub indent {
	my $self = shift;
	my $indent='';
	for (2..shift) {
		$indent.=' ';
	}
	return $indent;
}

sub recurse_render {
	my $self = shift;
	my %arg=(
		# Valors per defecte
		id_parent => 0 , 
	 		level => 1, 
			  uri => $self->get_uri,
			path => '',
		@_ # parametres passats
	);
	my $home = ($self->get_home or '');
#	warn $arg{uri} if $home;
#	warn "undefined $home " unless defined $home;
	$arg{uri}='' unless $arg{uri};
    warn "$arg{id_parent}\n" if $DEBUG_RECURSE;# && $arg{uri};
	$home="" unless $arg{uri}=~/^$home/;
	my ($current_uri,$next)=$arg{uri} =~ m!^$home/(.*?)(/.*|$)!;
	$current_uri = '' unless defined $current_uri;
#	warn "$arg{uri} $home\n$current_uri $next" if $home;

    my @items=();
    my ($html,$html_item,$js_item) = ( '' );
    foreach my $item (HTML::Widgets::Index::Item->search(
                        dbh => $self->{_dbh},
						table_items => $self->get_table_items,
                        id_parent => $arg{id_parent}
                    )) {
		warn "  ",$item->get_uri,"\n" if $DEBUG_RECURSE;
		$js_item = $self->render_javascript(
								path => $arg{path},
								uri => $item->get_uri,
								item => $item,
								level => $arg{level},
		) if $arg{level} > 1;
		my $render_now =0;
		my $render_next = $self->{render_next};
		$html_item=$self->render_item_html(
						 item => $item,
						level => $arg{level} , 
						  uri => $current_uri,
						 path => $arg{path}
		);
		$render_now = 1 if defined $self->{render_next}
							&& defined $render_next
							&& $render_next < $self->{render_next};
		$html.=$html_item;
#		warn $item->get_uri." ".length $html_item
#				if $DEBUG && defined $js_item;
		$self->{javascript} .= $js_item
			if defined $js_item && length $html_item;
		my $recurse_render =
			$self->get_render_all
            || (defined $next && defined $current_uri)
                &&  (
                    $arg{level} == $self->{level}
                    || $current_uri eq $item->get_uri
                    || "$current_uri/" eq $item->get_uri
                );
		warn "curr=$current_uri next=$next item=".$item->get_uri.
				"\n levels = $arg{level} , $self->{level} ".
				" recurse_render=$recurse_render\n"
									if $item->get_uri
										&& defined $next
										&& $DEBUG_HERE;

		$render_next = $self->{render_next};
		$self->{render_next} = 0 unless $render_now;
		$html .= $self->recurse_render(
							  uri => $next, 
							level => $arg{level}+1,
						id_parent => $item->get_id,
							path => "$arg{path}/".$item->get_uri
		) if $recurse_render;
		$self->{render_next} = $render_next;

    }
	$self->{render_next}=0;
    return $html;
}

sub render_javascript {
	my $self = shift;
	my %args = @_;
	my ($parent_item,$path,$uri,$level) = @args{'item','path','uri','level'};
	confess "Undefined parent_item" unless defined $parent_item;
	my $javascript = '';
    foreach my $item (HTML::Widgets::Index::Item->search(
                        dbh => $self->{_dbh},
						table_items => $self->get_table_items,
                        id_parent => $parent_item->get_id
                    )) {
		$javascript.= $self->render_item_js(
			item => $item,
			path => $self->get_home.$path,
			uri => $uri,
			level => $level
		);
	}
	if (length $javascript) {
		$javascript = $self->render_start_js($parent_item)
					.$javascript
					.$self->render_end_js();

		$parent_item->set_href_js(
			'onMouseOver="'.$self->get_js->get_onMouseOver
					.'(\'item'.$parent_item->get_id
					.'\', event);"'
					.' onMouseOut="'.$self->get_js->get_onMouseOut.'"');


	} else {
		$parent_item->set_href_js('');
	}
	return $javascript;

}

sub append_title {
	my ($self,$text) = @_;
	$self->{title}.=" - " if length $self->{title};
	$self->{title}.= $text;
}

sub append_path {
	my ($self,$item,$path) = @_;
	$self->{path}.=" / " if length $self->{path};
    $self->{path}.=
                '<a href="'.$path.'/'.$item->get_uri.'">'.
                $item->get_text."</a>";

}

sub level_rendereable {
	my ($self,$level) = @_;
	my $ret = (
		$level == 1
		|| $level == $self->{level}
		|| $self->get_render_all
		|| ($self->{level}==1 && $level==2 )
		|| ($level == $self->{level}+1 && $self->get_render_children)
		|| ($level == $self->{level}-1 && $self->get_render_parent)
		|| $self->{render_next}
	);
	warn "\trendereable=$ret level=$level my_level=".$self->{level}."\n"
		if ( $level == $self->{level}-1 && $self->get_debug
			|| $DEBUG_RENDER_ITEM_HTML);
	return $ret;
}

sub allowed {
	my $self = shift;
#	warn "allowed $_[0]" if $DEBUG;
	return 1 unless defined $self->get_allowed;
	&{$self->get_allowed(@_)};
}

sub javascript {
	my ($self,$level,$item) = @_;
}


sub render_item {

	my $self = shift;
	$self->render_item_js(@_);
	return $self->render_item_html(@_);

}

sub has_javascript {
	my $self = shift;
	my ($level,$uri) = @_;
	return 0 if $level == 0;
	unless ($self->get_format->get_javascript($level)) {
#		warn "No javascript $level" if $DEBUG;
		return 0;
	}
	if (
		length $self->get_format->get_no_javascript($level)
		&& $uri =~ $self->get_format->get_no_javascript($level)
	) {
		warn "No javascript match $uri at level $level"."\n"
			.$self->get_format->get_no_javascript($level)
				if $DEBUG;
		return 0;
	}
	#warn "Has javascript";
	return 1;
}

sub render_start_js {
	my $self = shift;
	my $item = shift;
	my $js_layer = $self->get_js->get_createLayer;
	my $id = $item->get_id();
	my $text = $item->get_text();
	$js_layer =~ s/\$id/$id/g;
	$js_layer =~ s/\$text/$text/g;
	return "//item ".$item->get_id."\n".$js_layer;
}

sub render_end_js {
	my $self = shift;
	return $self->get_js->get_endMenu();
}
sub render_item_js {
	my $self = shift;
	my %args = @_;
	my ($item,$path,$uri,$level) = @args{'item','path','uri','level'};
	$uri="$path/$uri/".$item->get_uri;
	$uri=~s!//+!/!g;
	return '' unless $self->has_javascript($level,$uri.'/'.$item->get_uri);
	my $text = $item->get_text;
	my $js = $self->get_js->get_addItem;
	$js =~ s/\$text/$text/g;
	$js =~ s/\$uri/$uri/g;
	return $js;
}

sub render_item_html {
	my $self=shift;
	my %args = @_;
	my ($item,$level,$uri,$path) = @args{'item','level','uri','path'};

	warn "RENDER: $uri ".$item->get_uri."\n" if $DEBUG_RENDER_ITEM_HTML;
	my $active = ($item->get_uri eq $uri
                    || $item->get_uri eq "$uri/"
                    || $item->get_uri."/" eq $uri);
	if ($active) {
		warn "\tactive\n" if $DEBUG_RENDER_ITEM_HTML;
		$self->append_title($item->get_text);
		$self->append_path($item,$self->get_home.$path);
		if ($self->get_render_active_children()) {
			warn "render my children $uri\n" if $DEBUG_RENDER_ITEM_HTML;
			$self->{render_next}++;
			$self->{max_render_next} = $self->{render_next}
				if !exists $self->{max_render_next}
					|| $self->{render_next} > $self->{max_render_next};
		}
	}
	warn $item->getabs_uri if $level==0 && $DEBUG;
	return '' unless $self->level_rendereable($level)
				&& $self->allowed("$path/".$item->getabs_uri) ||
			($active
			&& ($self->get_render_nth_parents > 0)
			&& (($self->{level} - $level) > 0)
			&& (($self->{level} - $level) <= $self->get_render_nth_parents)
			);

	my $selfuri = $self->get_uri;
	return '' if ( ($level>$self->{level} && ($self->get_home."/$path/".$item->getabs_uri) !~ m#$selfuri#)
				&& ($self->get_render_nephews == 0));
	$selfuri = $path."/".$item->getabs_uri;
	return '' if ( ($level < $self->{level}) && ($level > 2)
			&& !($self->get_uri =~ m#$selfuri#)
			&& $self->get_hide_brothers);


	warn "rendering\n" if $DEBUG_RENDER_ITEM_HTML;
	return $self->get_format->item_start($level , $active ).
		$self->get_format->indent($level , $active ).
		$self->get_format->uri(
						$self->get_home."/$path/".$item->getabs_uri , 
						$level , 
						$item
		).
		$self->get_format->text($item , $level , $active ).
		"</a>".
		$self->get_format->item_end($level , $active );
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

sub set_byname {
	my $self = shift;
	my ($var,$value) = @_;

	$value =~ s#/$## if $var eq 'home';
	$self->{$var}=$value;
	if ($var eq 'allow' 
				|| $var eq 'home' 
				|| $var =~ /render_\w+/) {
		foreach (qw(render title path)) {
			$self->{$_} = undef;
		}
	}

	return $self->{$var};
}

sub set_render_cousins {
	#Macro for backwards compatibility after fixing a semantinc error
	set_render_nephews(@_);
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



=head2 set_render_children

Sets if active item's next level in menu should be rendered
or not.
This includes not only direct children but also the same level
item's children (aka nephews).

  $index->set_render_children( 0 );
  $index->set_render_children( 1 );

=cut

=head2 set_render_parent

Sets if active item's parent AND uncles should appear in menu
or not.

  $index->set_render_parent( 0 );
  $index->set_render_parent( 1 );

=cut

=head2 set_render_nephews

Sets if active item's nephews should be rendered or not.

  $index->set_render_nephews( 0 );
  $index->set_render_nephews( 1 );

=cut

=head2 set_render_nth_parents

Sets the number of parents to be rendered (in ascending order).
A value of zero deactivates this feature, while a value of one
would render only the current menu item (and allow brothers and
childs).

  $index->set_render_nth_parents( 0 );
  $index->set_render_nth_parents( 2 );

=cut
=head1 AUTHOR

Francesc Guasch - Ortiz , frankie@etsetb.upc.edu
Joaquim Rovira , jrovira@etsetb.upc.edu

=head1 SEE ALSO

HTML::Widgets::Index::Format, (menu item formatting)
HTML::Widgets::Index::Javascript (javascript popups)

=cut

1;
__END__
