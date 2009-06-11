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

use strict;
use warnings;

use FindBin;
my $progname = $FindBin::Script;

# use LWP::Debug '+';

my $method;
my $module;
my @symbols;

if (1) {
  $method = 'mlc';
  $module = 'MLC';
  @symbols = ('MLC MasterKey Horizon 1 - Bond Portfolio,MasterKey Allocated Pension (Five Star)');
}
if (0) {
  $method = 'casablanca';
  $module = 'Casablanca';
  @symbols = ('MNG', 'BCE');
}
if (0) {
  $method = 'rba';
  $module = 'RBA';
  @symbols = ('AUDTWI', 'AUDUSD');
}

if (@ARGV && $ARGV[0] =~ /^-/) {
  my $opt = shift @ARGV;
  $method = substr $opt, 1;
  $module = ucfirst $method;
}
if (@ARGV) {
  @symbols = @ARGV;
}

{
  require Finance::Quote;
  my $q = Finance::Quote->new ($module);
  my $quotes = $q->fetch ($method,@symbols);

  require Data::Dumper;
  print Data::Dumper->new([$quotes],['quotes'])->Sortkeys(1)->Dump;
  exit 0;
}
