# $Id: 03members.t,v 1.05 2004/09/19 14:45:30 nicolaw Exp $

use Test::More tests => 2;

use WWW::Dilbert;

my $email = '';    # your comic.com members account email address
my $password = ''; # your comic.com members account password
my $date = '19890416';

ok(my $dilbert = WWW::Dilbert->new(), 'Create WWW::Dilbert object');

SKIP: {
	skip 'www.comic.com membership email address and password required', 1 unless $email && $password;
	ok($strip = $dilbert->get_strip_from_website(email => $email, password => $password, date => $date) ,'get_strip_from_website( <<members only 19890416>> )');
};




