# $Id: 01methods.t,v 1.05 2004/09/19 14:45:30 nicolaw Exp $

use Test::More tests => 9;
use WWW::Dilbert;
chdir 't' if -d 't';

# Test 1
ok(my $dilbert = WWW::Dilbert->new(),
	'Create WWW::Dilbert object');

# Test 2
ok(my $strip1 = $dilbert->get_todays_strip_from_website(),
	'get_todays_strip_from_website()');
my $width = $strip1->width();
my $height = $strip1->height();
my $file_ext = $strip1->file_ext();
my $strip_id = $strip1->strip_id();

# Test 3
ok(my $strip2 = $dilbert->get_strip_from_website($strip_id), "get_strip_from_website(\"$strip_id\")");

# Test 4
my $file = "test.$file_ext";
unlink $file if -e $file;
open(FH,">$file") || die "Unable to open file handle FH for filename '$file': $!";
ok(my $strip_blob = $strip2->strip_blob, "Write strip_blob out to $file");
binmode FH;
print FH $strip_blob;
close(FH);

# Test 5
ok(my $strip3 = $dilbert->get_strip_from_filename($file), "get_strip_from_filename('$file')");

# Test 6, 7, 8
ok($strip3->width() == $width, 'Check image width');
ok($strip3->height() == $height, 'Check image height');
ok($strip3->file_ext() == $file_ext, 'Check image file_ext');

# Test 9
ok(my $strip4 = $dilbert->get_strip_from_filename('dilbert2004081525314.gif'),
	'get_strip_from_filename("dilbert2004081525314.gif")');




