#!/usr/bin/perl -w

use strict;
use WWW::Dilbert;

my $dilbert = new WWW::Dilbert(
			dbi_dsn => 'DBI:mysql:database:localhost',
			dbi_user => 'username',
			dbi_pass => 'password'
		);

if (opendir(DH,'.')) {
	for (grep(/dilbert[0-9]{10,14}\.gif$/, readdir(DH))) {
		my $strip = $dilbert->get_strip_from_filename($_);
		$strip->insert_into_database();
	}
}


