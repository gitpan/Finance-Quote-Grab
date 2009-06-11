#!/usr/bin/perl

# Copyright 2008, 2009 Kevin Ryde

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


# Usage: ./dump.pl [-method] SYMBOL SYMBOL ...
#
# Print a dump of Finance::Quote prices downloaded for the given symbols.
# Eg.
#
#    ./dump.pl -MLC 'MLC MasterKey Horizon 1 - Bond Portfolio,MasterKey Allocated Pension (Five Star)'
#    ./dump.pl -RBA AUDUSD AUDTWI

use strict;
use warnings;
use Finance::Quote;

my $method = 'casablanca';
if (@ARGV && $ARGV[0] =~ /^-/) {
  $method = substr $ARGV[0], 1;
  shift @ARGV;
}

my @symbols = @ARGV;
if (! @symbols) {
  @symbols = ('MNG');
}

my $q = Finance::Quote->new ('-defaults', 'Casablanca', 'MLC', 'RBA');
my %rates = $q->fetch ($method, @symbols);

foreach my $symbol (@symbols) {
  print "Symbol: '$symbol'\n";

  # keys have the $; separator like "$symbol$;last", match and strip the
  # "$symbol$;" part
  foreach my $key (sort grep /^$symbol$;/, keys %rates) {
    my $showkey = $key;
    $showkey =~ s/.*?$;//; # strip for display

    printf "  %-14s '%s'\n", $showkey, $rates{$key};
  }
}

exit 0;
