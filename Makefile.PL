require 5.005;
use strict;
use ExtUtils::MakeMaker qw(WriteMakefile);

WriteMakefile(
   NAME          => 'WWW::Dilbert',
   VERSION_FROM  => 'lib/WWW/Dilbert.pm',
   ABSTRACT_FROM => 'lib/WWW/Dilbert.pm',
   AUTHOR        => 'Nicola Worthington <nicolaworthington@msn.com>',
   PREREQ_PM     => { 'DBI'         => 0,
                      'Image::Info' => 0,
                      'LWP::Simple' => 0,
                      'WWW::Mechanize' => 0,
                      'Carp'        => 0,
                     },
);

