############################################################
# $Id: Dilbert.pm,v 1.12 2005/12/29 21:41:59 nicolaw Exp $
# WWW::Dilbert - Retrieve Dilbert of the day comic strip images
# Copyright: (c)2005 Nicola Worthington. All rights reserved.
############################################################
# This file is part of WWW::Dilbert.
#
# WWW::Dilbert is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# WWW::Dilbert is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with WWW::Dilbert; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
############################################################

package WWW::Dilbert;
# vim:ts=4:sw=4:tw=78

use strict;
use Exporter;
use LWP::UserAgent qw();
use Carp qw(carp croak);
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

$VERSION     = sprintf('%d.%02d', q$Revision: 1.12 $ =~ /(\d+)/g);
@ISA         = qw(Exporter);
@EXPORT      = ();
@EXPORT_OK   = qw(&get_strip &strip_url &mirror_strip);
%EXPORT_TAGS = ( all => \@EXPORT_OK );

sub mirror_strip {
	my $filename = shift;
	my $url = shift || strip_url();
	my $blob = get_strip($url);
	return undef if !defined($blob);
	if ((!defined($filename) || !length($filename)) && defined($url)) {
		($filename = $url) =~ s#.*/##;
	}
	my $ext = _image_format($blob);
	$filename =~ s/(\.(jpe?g|gif))?$/.$ext/i;
	open(FH,">$filename") ||
		croak "Unable to open file handle FH for file '$filename': $!";
	binmode FH;
	print FH $blob;
	close(FH) ||
		carp "Unable to close file handle FH for file '$filename': $!";
	return $filename;
}

sub get_strip {
	my $url = shift || strip_url();
	if ($url =~ /^(?:dilbert)?(\d+(\.(jpg|gif))?)$/i) {
		$url = "http://www.dilbert.com/comics/dilbert/".
					"archive/images/dilbert$1";
		$url .= '.gif' unless $url =~ /\.(jpg|gif)$/i;
	}
	my $ua = _new_agent();
	my $response = $ua->get($url);
	my $status;
	unless ($response->is_success) {
		$status = $response->status_line;
		unless ($url =~ s/\.gif$/.jpg/i) { $url =~ s/\.jpg$/.gif/i; }
		$response = $ua->get($url);
	}
	if ($response->is_success) {
		unless (_image_format($response->content)) {
			carp('Unrecognised image format');
			return undef;
		}
		return $response->content;
	} elsif ($^W) {
		carp($status);
	}
	return undef;
}

sub strip_url {
	my $ua = _new_agent();
	my $response = $ua->get('http://www.dilbert.com');
	if ($response->is_success) {
		my $html = $response->content;
		if ($html =~ m#<img\s+src="((?:https?://[\w\.:\d\/]+)?
					/comics/dilbert/archive/images/dilbert.+?)"#imsx) {
			my $url = $1;
			$url = "http://www.dilbert.com$1" unless $url =~ /^https?:\/\//i;
			return $url;
		}
	} elsif ($^W) {
		carp($response->status_line);
	}
	return undef;
}

sub _image_format {
	local $_ = shift || '';
	return 'gif' if /^GIF8[79]a/;
	return 'jpg' if /^\xFF\xD8/;
	return 'png' if /^\x89PNG\x0d\x0a\x1a\x0a/;
	return undef;
}

sub _new_agent {
	my $ua = LWP::UserAgent->new(
			agent => 'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.7.8) '.
					'Gecko/20050718 Firefox/1.0.4 (Debian package 1.0.4-2sarge1)',
			timeout => 20
		);
	return $ua;
}


1;

=pod

=head1 NAME

WWW::Dilbert - Retrieve Dilbert of the day comic strip images

=head1 SYNOPSYS

 use WWW::Dilbert qw(get_strip mirror_strip strip_url);
 
 # Get the URL for todays strip
 my $image_url = strip_url();
 
 # Get todays strip
 my $image_blob = get_strip();
 
 # Get a specific strip by specifying the ID
 my $ethical_garbage_man = get_strip("2666040051128");
 
 # Write todays strip to local_filename.gif on disk
 my $filename_written = mirror_strip("local_filename.gif");
 
 # Write a specific strip to mystrip.gif on disk
 my $filename_written = mirror_strip("mystrip.gif","2666040051128");

=head1 DESCRIPTION

This module will download the latest Dilbert of the Day cartoon strip
from the Dilbert website and return a binary blob of the image, or
write it to disk. 

=head1 VERSION

$Id: Dilbert.pm,v 1.12 2005/12/29 21:41:59 nicolaw Exp $

=head1 AUTHOR

Nicola Worthington <nicolaw@cpan.org>

L<http://perlgirl.org.uk>

=head1 COPYRIGHT

(c) Nicola Worthington 2004, 2005. This program is free software; you can
redistribute it and/or modify it under the GNU GPL.

See the file COPYING in this distribution, or
L<http://www.gnu.org/licenses/gpl.txt>

=cut



