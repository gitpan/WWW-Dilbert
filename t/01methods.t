# $Id: 01methods.t,v 1.1 2004/08/13 12:53:41 nicolaw Exp $

use Test::More tests => 2;

use WWW::Dilbert;

ok(my $dilbert = WWW::Dilbert->new());
ok(my $strip = $dilbert->get_todays_strip_from_website() );

