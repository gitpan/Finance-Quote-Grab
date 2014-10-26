#!/usr/bin/perl -w

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

use strict;
use warnings;

use FindBin;
my $progname = $FindBin::Script;

# use LWP::Debug '+';

my $method;
my @modules;
my @symbols;

if (0) {
  # Finance::Quote::Yahoo::Australia
  # Finance::Quote::Yahoo::Europe
  # Finance::Quote::Yahoo::USA
  # Finance::Quote::Yahoo::Asia
  # Finance::Quote::Yahoo::Base

  $method = 'australia'; @symbols = ('BHP');
  $method = 'europe'; @symbols = ('TSCO.L');
  $method = 'asia'; @symbols = ('000010.SS');
  $method = 'asia'; @symbols = ('ISPATIND.BO');
  $method = 'usa'; @symbols = ('F');
}
if (0) {
  $method = 'mgex';
  @modules = ('MGEX');
  @symbols = ('ICMWZ09');
}
if (0) {
  $method = 'mlc';
  @modules = ('MLC');
  @symbols = ('MLC MasterKey Horizon 1 - Bond Portfolio,MasterKey Allocated Pension (Five Star)');
}
if (1) {
  $method = 'casablanca';
  @modules = ('Casablanca');
  # @symbols = ('MNG', 'BCE');
  @symbols = ('BCE');
}
if (0) {
  $method = 'rba';
  @modules = ('RBA');
  @symbols = ('AUDTWI', 'AUDUSD');
}

if (@ARGV && $ARGV[0] =~ /^-/) {
  my $opt = shift @ARGV;
  $method = substr $opt, 1;
  @modules = ucfirst $method;
}
if (@ARGV) {
  @symbols = @ARGV;
}

{
  print "module @modules symbol @symbols\n";

  require Finance::Quote;
  my $q = Finance::Quote->new (@modules);
  my $quotes = $q->fetch ($method,@symbols);

  require Data::Dumper;
  print Data::Dumper->new([$quotes],['quotes'])->Sortkeys(1)->Dump;
  exit 0;
}
