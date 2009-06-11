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
use Finance::Quote::Casablanca;
use Test::More tests => 4;

my $want_version = 1;
ok ($Finance::Quote::Casablanca::VERSION >= $want_version,
    'VERSION variable');
ok (Finance::Quote::Casablanca->VERSION  >= $want_version,
    'VERSION method');
ok (eval { Finance::Quote::Casablanca->VERSION($want_version); 1 },
    "VERSION class check $want_version");
ok (! eval { Finance::Quote::Casablanca->VERSION($want_version + 1000); 1 },
    "VERSION class check " . ($want_version + 1000));

exit 0;
