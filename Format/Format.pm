package HTML::Widgets::Index::Format;

use strict;
use vars qw($VERSION $AUTOLOAD);
use Carp;
use HTML::Widgets::Index::Format::Item;

require Exporter;
require AutoLoader;

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use HTML::Widgets::Index::Format ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.

$VERSION = '0.02';

# 0.02 : Recursive indent
# 0.01 : Initial version

my %FIELDS_RO = (

);

my %FIELDS_RW = (

	default => HTML::Widgets::Index::Format::Item->new()

);



# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

# Below is stub documentation for your module. You better edit it!

=head1 NAME

HTML::Widgets::Index::Format - Formatting for rendering HTML::Widgets::Menu

=head1 SYNOPSIS

  use HTML::Widgets::Index::Format;
  my $format = HTML::Widgets::Index::Format(
      default => {
                 active_item_start => '',
                 active_item_end => "\n",
                 inactive_item_start => '',
                 inactive_item_end => "\n",
                 active_text_start => '<b>',
                 active_text_end => '</b>',
                 inactive_text_start => '',
                 inactive_text_end => '',
                 inactive_text_placeholder => '<text>', 
                 active_text_placeholder=>'<text>',
                 link_args=>'',
                 indent_active => '*',
                 indent_inactive => ' ',
                 javascript => 0,
                 no_javascript => '',
      },
      1 => {
         active_text_placeholder => '<span class="menu1"><text></span>',
         indent => ' ',
      }
  );

=head1 DESCRIPTION

With this object you can alter the format of the output. Each level
of the Index can have different formatting. The levels are numbered
starting from 1, and there is a default level. Undefined formatting
applies default options.

Remember that since Format.pm version 0.02, indent attributes are
recursively checked in descendant order, so a level 3 inactive menu
item would have level 1, 2 and 3 indentation in this order. When an
item is rendered active, his active_indent attribute will be used, 
along with recursed inactive indents.
In case recursing leads to an image indent, the remaining levels
will be indented using that image, correctly resized horizontally to
fill those levels, while keeping the higher levels active and inactive
indents.

In the placeholders you can use the special tags: <text> and <url> that
are replaced with the text and url items when rendered.

Example for menu with tables and image items in the first level.
Notice:

=over

=item *

indenting is done using an image that is one pixel long

=item *

In level 1, a reference to an image is built.

=item *

The item starts and finishes with <tr> & <td> tags. So each one
is one row of the table.

=back

  my $format = {
	default => {
   
        link_args => 'class="menu"',
        active_item_start => 
              '<tr><td bgcolor="white">'.
                    '<img src="/img/point.gif" height="1">'.
              '</td></tr>'.
              "<tr><td>\n",
   
        active_item_end => "</td></tr>\n",
        inactive_item_start => 
              '<tr><td bgcolor="white">'.
                    '<img src="/img/point.gif" width="15" height="1">'.
              "</td></tr><tr><td>\n",

        inactive_item_end => "</td></tr>\n",

        active_text_placeholder =>
              '<span class="menu_active"><text></span>',

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

For this menu to be rendered you should print the table html tags before
and after:

  my $menu = HTML::Widgets::Index->open(
      dbh => $dbh,
     format => $format,
  );
  print '<table border="0">', $menu->get_html , '</table>';

=head1 CONSTRUCTOR

=head2 new

=cut

sub new {
	my $proto = shift;
    my $class = ref($proto) || $proto;
	my %self = ( %FIELDS_RO , %FIELDS_RW );
	my $data = shift;
	my @default;
	for my $level (keys %$data) {
#		warn "Format $level";
#		$HTML::Widgets::Index::Format::Item::DEBUG=1
#			if $level eq '1';
		$self{$level} =HTML::Widgets::Index::Format::Item
				->new(%{$data->{$level}});
#		$HTML::Widgets::Index::Format::Item::DEBUG=0;
	}
	$self{default}->apply_default();
	my $self = \%self;
	bless $self, $class;
	return $self;
}

=head1 METHODS

The methods of this module are used from the html renderer.
The end use should just check the DESCRIPTION of the items.

=head2 uri

  Applies the format to an URI

    $format->uri($item,$level,$active);

=cut

sub uri {
	my $self = shift;
	my ($uri,$level,$item) = @_;
	$uri.='/'
		unless $uri=~/\.\w+$/
			|| $uri =~ m#/$#;
	$uri =~ s#//+#/#g unless $uri =~ m#^\w+://#;
	my $ret= "<a href=\"$uri\"";
	$ret.=' ' if length $item->get_href_js;
	$ret.=$item->get_href_js;
	$ret.=' ' if length $self->get_link_args($level);
	$ret.=$self->get_link_args($level);
	$ret.=">";
	return $ret;
}

sub item_start {
	my ($self,$item,$active) = @_;
	return $self->get_active_item_start($item) if $active;
	return $self->get_inactive_item_start($item);
}

sub item_end {
	my ($self,$item,$active) = @_;
    return $self->get_active_item_end($item) if $active;
    return $self->get_inactive_item_end($item);

}

=head2 indent

	Intents depending of the level and if it's active or not

	$format->indent($level , $active );

=cut

sub indent {
	my $self = shift;
	my $level = shift;
	my $active = shift;
	my $indent_start = "";
	my $indent_end = "";
	my $ret;

	my $ilev = $level;
	$ilev = "default" unless ( (exists $self->{$level})
		&& (defined $self->{$level}->get_indent_start)
		&& (defined $self->{$level}->get_indent_end) );

	$indent_start = $self->{$ilev}->get_indent_start unless !defined $self->{$ilev}->get_indent_start;
	$indent_end = $self->{$ilev}->get_indent_end unless !defined $self->{$ilev}->get_indent_end;
	

#	$level-- if(($level ne "default") && ($level > 0));
	
	if($active) {
		$ret = $self->get_indent_active($level);
	} else {
		$ret = $self->get_indent_inactive($level);
	}
		
	return $indent_start . $ret . $indent_end if ($ret ne "");
	return "";
}

sub indent_level_img {
	my ($text,$level) = @_;
	my ($width)= $text =~ /width=["']?(.*?)["' ]/;
#	warn "width=$width*$level\n";
	unless ($width =~ /^\d+$/) {
		warn "Can't parse width in $text\n";
		return indent_level_text(@_);
	}
#	warn "	$text\n";
	$width*=$level;
	$text =~ s/(.*)width=.*?([ >].*)/$1width="$width"$2/;
#	warn "	$text\n";
	return $text;
	
}

sub indent_level_text {
	my ($text,$level) = @_;
	my $indent;
	for (1..$level) {
		$indent.=$text;
	}
	return $indent;
}

sub indent_level {
	my ($text,$level) = @_;
	return $text if $level eq 'default';
	if ($text =~ /<img[^>]+>/) {
		return indent_level_img(@_);
	} else {
		return indent_level_text(@_);
	}
}

sub recursive_indent_inactive {
	my $self = shift;
	my $level = shift;
	my $ret = "";
	
	my $ilev = $level;
	$ilev = "default" unless (exists $self->{$level}
				&& defined $self->{$level}->get_indent_inactive);
	my $indent = $self->{$ilev}->get_indent_inactive;
	
	if ($indent =~ /<img[^>]+>/) {
		return indent_level_img($indent,$level);
	}

	$ret = $self->recursive_indent_inactive($level-1) if ($level>1);
	$ret .= $indent;

	return $ret;
}

sub get_indent_active {
	my $self = shift;
	my $level = shift;
	my $active = '';
	my $inactive = '';

	my $ilev = $level;
	$ilev = "default" unless (exists $self->{$level}
				&& defined $self->{$level}->get_indent_active);
	$active = $self->{$ilev}->get_indent_active;

	if ($active =~ /<img[^>]+>/) {
		return indent_level_img($active,$level);
	}

 	$inactive = $self->recursive_indent_inactive($level-1)
		if ( ($level ne 'default') && ($level > 1) );

	return $inactive.$active;
}

sub get_indent_inactive {
	my $self = shift;
	my $level = shift;

#	my $indent=$self->get_indent_inactive('default') unless $level eq 'default';

#	if (exists $self->{$level} && defined $self->{$level}->get_indent_inactive ) {
#		$indent = $self->{$level}->get_indent_inactive;
#	}

#	return indent_level($indent,$level);
	return $self->recursive_indent_inactive($level);
}


=head2 text

   Applies format to the text

	$format->text($item,$level,$active);

=cut

sub text {

	my $self = shift;
	my $item = shift;
	my $level = shift;
	my $active = shift;
	return $self->text_active($item,$level) if $active;
	return $self->text_inactive($item,$level);

}

sub text_active {
	my $self = shift;
	my $item=shift;
	my $level = shift;
	my $url = $item->getabs_uri();
	my $text_plain = $item->getabs_text;
	my $text = $self->get_active_text_placeholder($level);
	$text =~ s/<text>/$text_plain/g;
	$text =~ s/<url>/$url/;

    return $self->get_active_text_start($level).
		$text.
		$self->get_active_text_end($level);

}

sub text_inactive {
	my $self = shift;
	my ($item,$level) = @_;

    my $text_plain = $item->getabs_text;
	my $url = $item->getabs_uri();
    my $text = $self->get_inactive_text_placeholder($level);
    $text =~ s/<text>/$text_plain/g;
	$text =~ s/<url>/$url/;

	return $self->get_inactive_text_start($level).
		$text.
		$self->get_inactive_text_end($level);
}

sub get_byname {
    my $self=shift;
	my ($var,$level) = @_;

	confess "I need the level for get_$var"
		unless defined $level;

	croak "Can't access `$var' field in class ".ref $self
		unless exists $HTML::Widgets::Index::Format::Item::FIELDS_RO{$var}
			||  exists $HTML::Widgets::Index::Format::Item::FIELDS_RW{$var};

	if (exists $self->{$level} 
		&& defined $self->{$level}->get_byname($var) ) {
#		 warn "$var $level ".$self->{$level}->get_byname($var)
#			if $var =~ /inactive_text_placeholder/;
		return $self->{$level}->get_byname($var);
	}
#	warn "$var default ".$self->{default}->get_byname($var);
	my $res = $self->{default}->get_byname($var);
	confess "No trobo $var "
		.$HTML::Widgets::Index::Format::Item::FIELDS_RW{$var}
		 unless defined $res;
	return $res;
}


sub AUTOLOAD {
    my $self = shift;
    my $type = ref($self)
        or croak "$self is not an object";
        
    my $name = $AUTOLOAD;
    $name =~ s/.*://;   # strip fully-qualified portion
    return if $name=~/^[A-Z]+$/;
    
    my ($access,$var)=$name =~ /(\wet)_(.*)/;
    
	my ($level , $active ) = @_;
    return $self->get_byname($var , $level , $active)
        if (defined $access && $access eq 'get');
        
    if (defined $access && $access eq 'set' 
			&& exists $HTML::Widgets::Index::Format::Item::FIELDS_RW{$var}) {
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
