# $Id: 01methods.t,v 1.2 2004/08/14 17:04:49 nicolaw Exp $

use Test::More tests => 4;

use WWW::Dilbert;

ok(my $dilbert = WWW::Dilbert->new());
ok(my $strip = $dilbert->get_todays_strip_from_website() );
ok($strip = $dilbert->get_strip_from_website('2004081525314') );
ok($strip = $dilbert->get_strip_from_filename('t/dilbert2004081525314.gif') );




