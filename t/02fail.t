use WWW::Dilbert;
use Test::More tests => 2;

ok( !eval{ WWW::Dilbert->new(invalid_option => 1) } );

my $dilbert = WWW::Dilbert->new();
ok ( !eval{ $dilbert->get_strip_from_database() } );

