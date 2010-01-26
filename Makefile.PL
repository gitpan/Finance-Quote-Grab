#!/usr/bin/perl

# Copyright 2008, 2009, 2010 Kevin Ryde

# This file is part of Finance-Quote-Grab.
#
# Finance-Quote-Grab is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Finance-Quote-Grab is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Finance-Quote-Grab.  If not, see <http://www.gnu.org/licenses/>.

# aiming for 5.005 and up same as Finance::Quote itself
use 5.005;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use lib 'inc';
use MyMakeMakerExtras;

MyMakeMakerExtras::WriteMakefile
  (NAME         => 'Finance-Quote-Grab',
   ABSTRACT     => 'Fetch stock quotes from a grab bag of sources.',
   VERSION_FROM => 'lib/Finance/Quote/MLC.pm',
   MIN_PERL_VERSION => '5.005',
   PREREQ_PM    => {
                    'Finance::Quote' => 0,

                    # Finance::Quote depends on this already actually
                    'HTML::TableExtract' => 0,

                    # version 5.814 for HTTP::Request::accept_decodable()
                    'LWP' => '5.814',
                    # parts of LWP, but used explicitly, so name them
                    'HTTP::Request'  => 0,
                    'HTTP::Response' => 0,
                    'URI::Escape'    => 0,

                    'List::Util'   => 0,
                    'Scalar::Util' => 0,
                    'Test::More'   => 0,
                    'warnings'     => 0,
                   },

   AUTHOR       => 'Kevin Ryde <user42@zip.com.au>',
   LICENSE      => 'gpl',
   SIGN         => 1,

   META_MERGE
   => { resources
        => { homepage
             => 'http://user42.tuxfamily.org/finance-quote-grab/index.html'
           },
        optional_features
        => { maximum_tests
             => { description => 'Have "make test" do as much as possible.',
                  requires => { 'Pod::Parser' => 0,
                                'Test::NoWarnings' => 0,
                              },
                },
             maximum_devel
             => { description => 'Stuff used variously for development.',
                  requires => { 'Perl6::Slurp' => 0,
                              },
                },
           },
      },
  );

#------------------------------------------------------------------------------
package MY;
sub postamble {
  my ($makemaker) = @_;
  return MyMakeMakerExtras::postamble($makemaker);
}
