#!/usr/bin/perl -w

use strict;
use WWW::Dilbert;

my $dilbert = new WWW::Dilbert();
my $strip = $dilbert->get_strip_from_website('2004081525314')

printf("Content-type: %s\n",$strip->file_media_type);
printf("Content-length: %s\n\n",$strip->bytes);
#print $strip->strip_blob;


