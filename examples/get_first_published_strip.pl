#!/usr/bin/perl -w

use strict;
use WWW::Dilbert;

my $dilbert = new WWW::Dilbert();
my $strip = $dilbert->get_strip_from_website(
			#date => '19890416', # First ever published Dilbert of the Day
			# http://members.comics.com/members/extra/archiveViewer?stripId=18692
			date => '20000101', # First ever published Dilbert of the Day
			email => 'nicolaworthington@msn.com', # Your comic.com account email address
			password => 'n1k0nf80' # Your comic.com account password
		);

printf("Content-type: %s\n",$strip->file_media_type);
printf("Content-length: %s\n\n",$strip->bytes);


