<%once>
    use DBI;
    use HTML::Widgets::Index;
    my $dbh_menu=DBI->connect("DBI:mysql:test",undef,undef,
                            { RaiseError => 1,PrintError => 1}
    ) or die $DBI::errstr;
</%once>

<%init>
	my $menu = HTML::Widgets::Index->open(
		dbh => $dbh_menu,
        table_items => 'random_index',
        home => '/',
        format => $m->comp("menu_format.mc"),
	);
	$menu->set_uri($r->uri);
	return $menu;
</%init>
