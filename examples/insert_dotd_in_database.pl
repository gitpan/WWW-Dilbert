#!/usr/bin/perl -w

use strict;
use WWW::Dilbert;

my $dilbert = new WWW::Dilbert(
			dbi_dsn => 'DBI:mysql:database:localhost',
			dbi_user => 'username',
			dbi_pass => 'password'
		);
my $strip = $dilbert->get_todays_strip_from_website();
$strip->insert_into_database();


