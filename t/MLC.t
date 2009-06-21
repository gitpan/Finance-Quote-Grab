#!/usr/bin/perl

# Copyright 2008, 2009 Kevin Ryde

# This file is part of Finance-Quote-Grab.
#
# Finance-Quote-Grab is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Finance-Quote-Grab is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Finance-Quote-Grab.  If not, see <http://www.gnu.org/licenses/>.


use strict;
use warnings;
use Finance::Quote::MLC;

use Test::More tests => 9;

SKIP: { eval 'use Test::NoWarnings; 1'
          or skip 'Test::NoWarnings not available', 1; }

my $want_version = 2;
cmp_ok ($Finance::Quote::MLC::VERSION, '>=', $want_version,
        'VERSION variable');
cmp_ok (Finance::Quote::MLC->VERSION,  '>=', $want_version,
        'VERSION class method');
{ ok (eval { Finance::Quote::MLC->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Finance::Quote::MLC->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# symbol_to_fund_and_product()

foreach my $elem (['Foo Bar,Quux Xyzzy', 'Foo Bar', 'Quux Xyzzy'],
                  # missing product is invalid, but see it splits ok
                  ['Foo Bar', 'Foo Bar', ''],
                 ) {
  my ($symbol, $want_fund, $want_product) = @$elem;
  my ($got_fund, $got_product)
    = Finance::Quote::MLC::symbol_to_fund_and_product ($symbol);

  is ($got_fund, $want_fund, "symbol: $symbol");
  is ($got_product, $want_product, "symbol: $symbol");
}

exit 0;