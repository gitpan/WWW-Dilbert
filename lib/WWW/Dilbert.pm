package WWW::Dilbert;
# vim:ts=4:sw=4:tw=78

use strict;
use warnings;
use FileHandle ();
use Image::Info ();
use LWP::UserAgent ();
use DBI ();
use WWW::Mechanize ();
use Carp qw(croak cluck confess);

use vars qw($VERSION @ISA);
$VERSION = sprintf('%d.%02d', q$Revision: 1.9 $ =~ /(\d+)/g);

sub new {
	ref(my $class = shift) && croak 'Class name required';

	croak 'Odd number of elements passed when even number was expected' if @_ % 2;
	my $self = { @_ };

	while (my ($k,$v) = each %{$self}) {
		unless (grep(/^$k$/i, qw(dbi_dsn dbi_user dbi_pass))) {
			croak "Unrecognised paramater '$k' passed to module $class";
		}
	}

	$self->{public_host} ||= 'http://www.comics.com/comics/dilbert';
	$self->{members_host} ||= 'http://members.comics.com';
	$self->{default_ext} ||= [ 'gif', 'jpg', 'jpeg' ];
	$self->{ext_pattern} ||= '(?:jpe?g|gif)';
	$self->{user_agent} ||= 'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)';
	$self->{retry} ||= 3;
	$self->{tried} ||= 0;

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

	my $strip_id = shift || 'undef';
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

	my $strip_url = $self->get_todays_strip_url();
	return undef unless $strip_url;

	my $strip = $self->get_strip_from_website($strip_url);
	return undef unless $strip;

	return $strip;
}

sub get_strip_from_website {
	my $strip;
	while ($self->{tried} < $self->{retry}+1 && !$strip_url) {
		evla { $strip = $self->get_strip_from_website($strip_url); };
		$self->{tried}++;
	}
	return undef unless $strip;
}

sub get_todays_strip_url {
	my $strip_url;
	while ($self->{tried} < $self->{retry}+1 && !$strip_url) {
		eval { $strip_url = $self->get_todays_strip_url(); };
		$self->{tried}++;
	}
	return undef unless $strip_url;
}

sub _convertStripId2URL {
	my $strip_url;
	while ($self->{tried} < $self->{retry}+1 && !$strip_url) {
		eval { $strip_url = $self->get_todays_strip_url(); };
		$self->{tried}++;
	}
	return undef unless $strip_url;
}

sub _get_strip_from_website {
	my $self = shift;

	# Check we have the right paramaters
	my $param;
	if (@_ > 1) {
		$param = { @_ };
	} else {
		$param->{strip_url} = shift || undef;
	}

	# We need a strip URL or a login, password and date for the members access
	unless ($param->{strip_url} || ($param->{email} && $param->{password} && $param->{date}) ) {
		return undef;
	}

	# Die if we have been passed bad paramaters
        while (my ($k,$v) = each %{$param}) {
                unless (grep(/^$k$/i, qw(strip_url email password public members date))) {
                        croak "Unrecognised paramater '$k'";
                }
        }

	# Check we have a sensible URL - return undef if we don't
	if (exists $param->{strip_url} && $param->{strip_url} !~ /^http/i) {
		$param->{strip_url} = $self->_convertStripId2URL($param->{strip_url});
		if ($param->{strip_url} !~ /^http/i) {
			croak "Unable to convert '$param->{strip_url}' to a valid strip URL";
		}
	}

	my $strip_blob = undef;

	# Login and get the strip URL if we have been given member credentials
	if ($param->{email} && $param->{password} && $param->{date}) {
		$self->_get_members_only_strip(
						email => $param->{email},
						password => $param->{password},
						date => $param->{date}
					);
	}

	# Go and download the image strip
	$self->{strip_url} = $param->{strip_url};
	if ($param->{strip_url}) {
		my $ua = $self->_initUserAgent($self->{user_agent});
		my $response = $ua->get($param->{strip_url});
		if ($response->is_success) {
			$strip_blob = $response->content;
			my $strip = WWW::Dilbert::Strip->_new(
					dilbert => $self,
					strip_blob => $strip_blob,
					strip_id => _filename2strip_id($param->{strip_url})
				);
			return $strip;
		} else {
			croak "Failed to download strip URL";
		}
	}

	return undef;
}

sub _get_todays_strip_url {
	my $self = shift;

	my $ua = $self->_initUserAgent($self->{user_agent});
	my $response = $ua->get($self->{public_host});
	if ($response->is_success) {
		my $html = $response->content();
		(my $strip_uri) = $html =~ m|SRC="(/comics/dilbert/archive/images/dilbert[0-9]{8,14}\.(gif\|jpe?g\|png))"|i;
		return undef unless $strip_uri;
		return sprintf('%s%s',$self->{public_host},$strip_uri);
	} else {
		croak "Failed to download source HTML to determine today's strip URL";
	}

	return undef;
}





###############################################################
# Private methods

sub __convertStripId2URL {
	my $self = shift;
	my $strip_url = shift || undef;
	my $ua = $self->_initUserAgent($self->{user_agent});

	# Check filenames based on all of the default file extensions possible
	for my $file_ext (@{$self->{default_ext}}) {
		# Build the possible URL
		my $url = sprintf('%s/comics/dilbert/archive/images/dilbert%s.%s', $self->{public_host}, $strip_url, $file_ext);

		# Test if the file exists
		my $response = $ua->head($url);
		if ( $response->is_success && $response->header('Content-length') > 10 &&
			($response->header('Content-type') =~ m|^image/$file_ext$| || 
				($response->header('Content-type') =~ m|^image/jpe?g$| && $file_ext =~ m|^jpe?g$|) ) ) {
			$strip_url = $url;
			last;
		}
	}

	return $strip_url;
}

sub _get_members_only_strip {
	my $self = shift;
	my $param = { @_ };

	my $mech = WWW::Mechanize->new(
				quiet => 1,
				autocheck => 1,
				agent => $self->{user_agent},
			);
	$mech->quiet(1);
	$mech->agent_alias('Windows IE 6');
	$mech->redirect_ok();

	my $strip_blob = undef;

	$mech->get(sprintf('%s/members/registration/showLogin.do',$self->{members_host}));
	my $html = $mech->content;
	$html =~ s|</form>|<input type="text" name="MailAction" value="SIGNIN"></form>|isg;
	$mech->update_html($html);
	# $self->_debug_content($mech);

	$mech->form_name('userForm');
	$mech->field('email', $param->{email});
	$mech->field('password', $param->{password});
	$mech->field('MailAction', 'SIGNIN');
	$mech->click('sign in',1,1); # "sign in=SIGNIN"
	$self->_debug_content($mech);

	$mech->follow_link(text_regex => qr/click here to reload/i);
	$self->_debug_content($mech);

	sleep 5;
	my $target_source = sprintf('%s/members/archive/viewStrip.do?date=%s&comicId=107&comic=dilbert', $self->{members_host}, $param->{date});
	warn "\n\n\$target_source = '$target_source'\n\n";
	$html = $mech->content;
	$html =~ s|</form>|<a href="$target_source">Previous Day</a>></form>|isg;
	$mech->update_html($html);
	$mech->follow_link(url_regex => qr/viewStrip.do\?date=/i);
	$self->_debug_content($mech);

	($param->{strip_url}) = $mech->content =~ m!(?:
						(/members/extra/archiveViewer\?stripId=[0-9]{4,})
						|
						((?:(?:/comics)?/dilbert)?/archive/images/dilbert[0-9]{10,14}\.$self->{default_ext})
					)!isx;
	if ($param->{strip_url}) {		
		$param->{strip_url} = sprintf('%s%s', ($param->{strip_url} =~ /archiveViewer/i ? $self->{members_host} : $self->{public_host}), $param->{strip_url});
		warn "\n\n\$param->{strip_url} = $param->{strip_url}\n\n";
		$strip_blob = $mech->follow_link(url => $param->{strip_url});
	}
	$mech->get(sprintf('%s/members/registration/logout.do',$self->{members_host}));

	return $strip_blob;
}

sub _initUserAgent {
	my $self = shift;
	my $user_agent = shift || $self->{user_agent};

	my $ua = LWP::UserAgent->new(
				agent => $user_agent,
				timeout => 5,
				parse_head => 1,
#				from => $self->{public_host},
			);
	$ua->timeout(5);
	$ua->env_proxy;
	return $ua;
}

sub _debug_content {
	my $self = shift;
	my $mech = shift;
	my $content = $mech->content;
	$content =~ s!.*?(</SELECT>|<\!--\s*CONTENT\s*INFORMATION\s*-->)!!isg;
	$content =~ s!<\!--\s*FOOTER\s*INFORMATION\s*-->.*!!isg;
	$content =~ s!\n\s*\n!\n!isg;
	warn "\n",'='x5,$mech->title,': ',$mech->uri,'='x10,"\n";
	warn $content;
	warn "\n",'='x60,"\n\n\n";
}

sub _filename2strip_id {
	my $str = shift || undef;
	my $strip_id = undef;
	if ($str =~ /(?:stripId=([0-9]{4,})|dilbert([0-9]{8,14}))\./i) {
		$strip_id = $1 || $2 || undef;
	}
	return $strip_id;
}

sub _connect_to_database {
	my $self = shift;
	croak('You have not specified dbi_dsn, dbi_user or dbi_pass; unable to perform database action') unless ($self->{dbi_dsn} && $self->{dbi_user} && $self->{dbi_pass});
	$self->{dbh} = DBI->connect($self->{dbi_dsn}, $self->{dbi_user}, $self->{dbi_pass}, { RaiseError => 1, AutoCommit => 1});
}

sub _dbh {
	my $self = shift;
	$self->_connect_to_database() unless exists $self->{dbh};
	return $self->{dbh};
}

sub _is_valid_strip_id {
	my $strip_name = shift || '';
	return $strip_name =~ /^[0-9]{10,14}$/;
}




#####################################################
# Special methods

sub DESTROY {
	my $self = shift;
	$self->{dbh}->disconnect() if exists $self->{dbh};
}

1;




##########################################################

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
		$self->{bytes} = length($self->{strip_blob}||0);
		my $info = Image::Info::image_info(\$self->{strip_blob});
		if (my $error = $info->{error}) {
			$self->{error} = $error;
			$self->{image_info}->{error} = $error;
		} else {
			$self->{image_info} = $info;
		}
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

sub write_to_file {
	my $self = shift;
	my $file_name = shift;
	$file_name ||= $self->{strip_id} . '.' . $self->{image_info}->{file_ext};
	my $file_handle = new FileHandle("> $file_name");
	unless ($file_handle) {
		die("Failed to open '$file_name' for writing:$!\n");
	}
	unless ($file_handle->print($self->{strip_blob})) {
		die("Failed to write to '$file_name':$!\n");
	}
	unless ($file_handle->close()) {
		die("Failed to close '$file_name':$!\n");
	}
}

1;






=pod

=head1 NAME

WWW::Dilbert - Dilbert of the day comic strip archive and retieval module

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

This module will download the latest Dilbert of the Day cartoon strip
from the Dilbert website and return an object which can be either
stored in a database or output to a browser, disk or whatever. It
allows importing of Dilbert strips from disk or alternate URLs, and
has a random strip interface to return strips from the database.

=head1 METHODS

=head2 WWW::Dilbert Object Methods

Strip retrieval object.

=over 4

=item new()

Create a new WWW::Dilbert strip retrieval object. Accepts the following key-value pairs:

 dbi_dns => 'DBI:mysql:database:hostname',
 dbi_user => 'username',
 dbi_pass => 'password'

=item get_todays_strip_from_website()

Returns a strip object containing todays Dilbert of the Day cartoon strip.

=item get_strip_from_website($strip_id)

Returns a strip object containing a specific Dilbert cartoon strip as downloaded from the Dilbert website.

=item get_strip_from_filename($filename)

Returns a strip object containing a specific Dilbert cartoon strip from a Dilbert comic stip file on disk.

=item get_strip_from_database($strip_id)

=item get_todays_strip_url()

=item get_random_strip_from_database()

=back

=head2 WWW::Dilbert::Strip Object Methods

Strip object returned by WWW::Dilbert get methods.

=over 4

=item insert_into_database()

Inserts the strip in to a database via the DBI database defined by the parent WWW::Dilbert object.

=item width()

Returns the width of the comic strip image.

=item height()

Returns the height of the comic strip image.

=item file_ext

Returns the file extension for the comic strip image format.

=item file_media_type

Returns the MIME type for the comic strip image format.

=item bytes()

Returns the total number of bytes of the comic strip image.

=item strip_blob()

Returns the binary image data of the comic strip image.

=item strip_id()

Returns the comic strip id.

=back 

=head1 SQL SCHEMA

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
 
=head1 TODO

Remove the database functionality since it's pretty pointless.

Add retrieval of strips from the last 30 day online archive.

=head1 VERSION

$Id: Dilbert.pm,v 1.9 2005/12/08 15:48:09 nicolaw Exp $

=head1 AUTHOR

Nicola Worthington <nicolaw@cpan.org>

http://perlgirl.org.uk

=head1 ACKNOWLEDGEMENTS

Thanks go to David Dick <david_dick@iprimus.com.au> for the write_file() patch
which he submitted on 22nd September 2004.

=head1 COPYRIGHT

(c) Nicola Worthington 2004, 2005. This program is free software; you can
redistribute it and/or modify it under the GNU GPL.

See the file COPYING in this distribution, or
http://www.gnu.org/licenses/gpl.txt 

=cut



