package WWW::Dilbert;

use strict;
use warnings;
use Image::Info ();
use LWP::Simple ();
use DBI ();
use Carp qw(croak cluck confess);

use vars qw($VERSION @ISA);
$VERSION = sprintf('%d.%02d', q$Revision: 1.2 $ =~ /(\d+)/g);

sub new {
	ref(my $class = shift) && croak 'Class name required';

        croak 'Odd number of elements passed when even number was expected' if @_ % 2;
        my $self = { @_ };

        while (my ($k,$v) = each %{$self}) {
                unless (grep(/^$k$/i, qw(dbi_dsn dbi_user dbi_pass))) {
                        croak "Unrecognised paramater '$k' passed to module $class";
                }
        }

        bless($self,$class);
        return $self;
}

sub get_random_strip_from_database {
	my $self = shift;

	my $dbh = $self->_dbh();
	my $sth = $dbh->prepare('SELECT COUNT(*) FROM dilbert_strip');
	$sth->execute();
	my $records = $sth->fetchrow_array();
	my $record = int(rand($records))||0;
	$sth = $dbh->prepare("SELECT id FROM dilbert_strip LIMIT $record,1");
	$sth->execute();
	my $strip_id = $sth->fetchrow_array();
	$sth->finish();
	
	return $self->get_strip_from_database($strip_id);
}

sub search_database {
	my $self = shift;

}

sub get_strip_from_database {
	my $self = shift;

	my $strip_id = shift;
	croak "Malformed strip_id: '$strip_id'" unless _is_valid_strip_id($strip_id);

	my $dbh = $self->_dbh();
	my $sth = $dbh->prepare('SELECT * FROM dilbert_strip WHERE id = ?');
	$sth->execute($strip_id);
	
	my $strip = WWW::Dilbert::Strip->_new(
					dilbert => $self,
					strip_id => $strip_id,
					%{$sth->fetchrow_hashref()}
				);
	$sth->finish();
	
	return $strip;
}

sub delete_strip_from_database {
	my $self = shift;

	my $strip_id = shift;
	croak "Malformed strip_id: '$strip_id'" unless _is_valid_strip_id($strip_id);

	my $dbh = $self->_dbh();
	my $sth = $dbh->prepare('DELETE FROM dilbert_strip WHERE id = ?');
	$sth->execute($strip_id);
}

sub get_strip_from_filename {
	my $self = shift;

	my $filename = shift;
	if (open(FH,$filename)) {
		binmode(FH);
		my $strip_blob = do { local( $/ ) ; <FH> } ;

		my $strip = WWW::Dilbert::Strip->_new(
						dilbert => $self,
						strip_blob => $strip_blob,
						strip_id => _filename2strip_id($filename)
					);

		close(FH) || confess("Unable to close filehandle FH for filename '$filename'");
		return $strip;
	}	

	confess("Unable to open filehandle FH for filename '$filename'");
	return undef;
}

sub get_todays_strip_from_website {
	my $self = shift;
	my $strip = $self->get_strip_from_website(_get_todays_strip_url());
	return $strip;
}

sub get_strip_from_website {
	my $self = shift;
	my $strip_url = shift;
	unless ($strip_url =~ /^http/i) {
		$strip_url = "http://www.dilbert.com/comics/dilbert/archive/images/dilbert$strip_url.gif";
	}
	my $strip_blob = LWP::Simple::get($strip_url);
	my $strip = WWW::Dilbert::Strip->_new(
					dilbert => $self,
					strip_blob => $strip_blob,
					strip_id => _filename2strip_id($strip_url)
				);
	return $strip;
}

sub _filename2strip_id {
	my ($strip_id) = $_[0] =~ /dilbert([0-9]{10,14})\./i;
	return $strip_id;
}

sub _get_todays_strip_url {
	my $html = LWP::Simple::get('http://www.dilbert.com');
	(my $strip_uri) = $html =~ m|SRC="(?:http.?://.+?)?(/comics/dilbert/archive/images/dilbert[0-9]{10,14}\.gif)"|i;
	return "http://www.dilbert.com$strip_uri";
}

sub _connect_to_database {
	my $self = shift;
	croak('You have not specified dbi_dsn, dbi_user or dbi_pass; unable to perform database action') unless ($self->{dbi_dsn} && $self->{dbi_user} && $self->{dbi_pass});
	$self->{dbh} = DBI->connect($self->{dbi_dsn}, $self->{dbi_user}, $self->{dbi_pass});
}

sub _dbh {
	my $self = shift;
	$self->_connect_to_database() unless exists $self->{dbh};
	return $self->{dbh};
}

sub _is_valid_strip_id {
	return $_[0] =~ /^[0-9]{10,14}$/;
}

sub DESTROY {
	my $self = shift;
	$self->{dbh}->disconnect() if exists $self->{dbh};
}

1;


package WWW::Dilbert::Strip;

use vars qw(@ISA $AUTOLOAD);
use Carp qw(croak cluck confess);
@ISA = qw(WWW::Dilbert);

sub AUTOLOAD {
	my $self = shift;
	my $type = ref($self) || croak "$self is not an object";

	(my $name = $AUTOLOAD) =~ s/.*://;

	if (exists $self->{$name}) {
		return $self->{$name};
	} elsif (exists $self->{image_info}) {
		return ($self->{image_info}->{$name} || undef);
	}
}

sub _new {
	ref(my $class = shift) && croak 'Class name required';

        my $self = { @_ };
	if (exists $self->{strip_blob}) {
		$self->{bytes} = length($self->{strip_blob});
		$self->{image_info} = Image::Info::image_info(\$self->{strip_blob});
	}
        bless($self, $class);

        return $self;
}

sub insert_into_database {
	my $self = shift;

	my $dilbert = $self->{dilbert};
	my $dbh = $dilbert->_dbh();
	my $sth = $dbh->prepare('INSERT INTO dilbert_strip (
			id, strip_blob,
			bytes, width, height,
			colour, cells, text
				) VALUES (?, ?, ?, ?, ?, ?, ?, ?)');
	$sth->execute(
			$self->{strip_id}, $self->{strip_blob},
			$self->{bytes}, $self->{image_info}->{width}, $self->{image_info}->{height},
			undef, 3, undef
		);

	return $self->{strip_id};
}

1;


=pod

=head1 NAME

WWW::Dilbert - Dilbert of the day comic strip archive and retieval module

=head1 VERSION

$Version$

=head1 SYNOPSYS

 use WWW::Dilbert;
 my $dilbert = new WWW::Dilbert;
 my $strip = $dilbert->get_todays_strip_from_website();

 use WWW::Dilbert;
 my $dilbert = new WWW::Dilbert(
                         dbi_dsn => 'DBI:mysql:nicolaw:localhost',
                         dbi_user => 'username',
                         dbi_pass => 'password'
                 );
 chdir '/home/albert/my_dilbert_archive_directory';
 if (opendir(DH,'.')) {
         for (grep(/dilbert[0-9]{10,14}\.gif$/, readdir(DH))) {
                 my $strip = $dilbert->get_strip_from_filename($_);
                 $strip->insert_into_database();
         }
 }

=head1 DESCRIPTION

=head1 SQL Schema

 CREATE TABLE dilbert_character (
 	id int unsigned not null primary key auto_increment,
 	name char(100) not null,
 	regular_character bool default null,
 	notes text,
 	photo_blob blob
 );
 
 CREATE TABLE dilbert_strip (
 	id bigint(14) unsigned not null primary key,
 	strip_blob mediumblob not null,
 	bytes int unsigned not null,
 	width int(4) unsigned not null,
 	height int(4) unsigned not null,
 	colour bool default null,
 	cells enum('3','6','-1') default "3" not null,
 	text text
 );
 
 CREATE TABLE dilbert_character2dilbert_strip (
 	dilbert_character_id int unsigned not null,
 	dilbert_strip_id bigint(14) unsigned not null,
 	primary key (dilbert_character_id, dilbert_strip_id)
 );
 
=head1 SEE ALSO

Dev::Bollocks

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

=head1 AUTHOR

Nicola Worthington <nicolaworthington@msn.com>

Copyright (C) 2004 Nicola Worthington.

http://www.nicolaworthington.com

=cut


