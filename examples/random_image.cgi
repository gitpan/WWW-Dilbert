#!/usr/bin/perl -w

use strict;
use WWW::Dilbert;

my $dilbert = new WWW::Dilbert(
			dbi_dsn => 'DBI:mysql:nicolaw:localhost',
			dbi_user => 'nicolaw',
			dbi_pass => 'knickers'
		);
my $strip = $dilbert->get_random_strip_from_database();

printf("Content-type: %s\n",$strip->file_media_type);
printf("Content-length: %s\n\n",$strip->bytes);
print $strip->strip_blob;


