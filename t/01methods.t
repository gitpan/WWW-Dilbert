# $Id: 01methods.t,v 1.8 2004/09/26 18:39:31 nicolaw Exp $

use Test::More qw(no_plan);
use lib qw(./lib ../lib);
use WWW::Dilbert;
use Data::Dumper;
chdir 't' if -d 't';

ok(my $dilbert = WWW::Dilbert->new(), 'Create WWW::Dilbert object');
ok(my $strip_url = $dilbert->get_todays_strip_url(), 'get_todays_strip_url()');

my ($strip1,$width,$height,$file_ext,$strip_id);
until ($strip1) {
	ok($strip1 = $dilbert->get_todays_strip_from_website(), 'get_todays_strip_from_website()');
	if ($strip1) {
		$width = $strip1->width();
		$height = $strip1->height();
		$file_ext = $strip1->file_ext();
		$strip_id = $strip1->strip_id();
	}
}

ok(my $strip2 = $dilbert->get_strip_from_website($strip_id), "get_strip_from_website(\"$strip_id\")");

my $file = "test.$file_ext";
unlink $file if -e $file;
open(FH,">$file") || die "Unable to open file handle FH for filename '$file': $!";
ok(my $strip_blob = $strip2->strip_blob, "Write strip_blob out to $file");
binmode FH;
print FH $strip_blob;
close(FH);

ok(my $strip3 = $dilbert->get_strip_from_filename($file), "get_strip_from_filename('$file')");

ok($strip3->width() == $width, 'Check image width');
ok($strip3->height() == $height, 'Check image height');
ok($strip3->file_ext() == $file_ext, 'Check image file_ext');

ok(my $strip4 = $dilbert->get_strip_from_filename('dilbert2004081525314.gif'),
	'get_strip_from_filename("dilbert2004081525314.gif")');




