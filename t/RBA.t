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
use Finance::Quote::RBA;

use Test::More tests => 22;

## no critic (ProtectPrivateSubs)

my $want_version = 1;
ok ($Finance::Quote::RBA::VERSION >= $want_version,
    'VERSION variable');
ok (Finance::Quote::RBA->VERSION  >= $want_version,
    'VERSION method');
ok (eval { Finance::Quote::RBA->VERSION($want_version); 1 },
    "VERSION class check $want_version");
ok (! eval { Finance::Quote::RBA->VERSION($want_version + 1000); 1 },
    "VERSION class check " . ($want_version + 1000));

#------------------------------------------------------------------------------
# _name_extract_time

foreach my $elem ([ 'Abc def',        'Abc def', '16:00' ],
                  [ 'Abc def (12am)', 'Abc def', '0:00' ],
                  [ 'Abc def (1am)',  'Abc def', '1:00' ],
                  [ 'Abc def (11am)', 'Abc def', '11:00' ],
                  [ 'Abc def (Noon)', 'Abc def', '12:00' ],
                  [ 'Abc def (12pm)', 'Abc def', '12:00' ],
                  [ 'Abc def (1pm)',  'Abc def', '13:00' ],
                  [ 'Abc def (11pm)', 'Abc def', '23:00' ],
                 ) {
  my ($input_name, $want_name, $want_time) = @$elem;

  my ($got_name, $got_time)
    = Finance::Quote::RBA::_name_extract_time ($input_name);
  is ($got_name, $want_name, "name from '$input_name'");
  is ($got_time, $want_time, "name from '$input_name'");
}

#------------------------------------------------------------------------------
# _parse

{ my $html = <<'HERE';
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html>
<body>
<table><tbody>
<tr>
  <td>Click for earlier rates</td>
  <td>01 Jan 2009</td>
  <td>02 Jan 2009</td>
  <td>03 Jan 2009</td>
  <td>04 Jan 2009</td>
</tr>
<tr>
  <td>United States dollar</td>
  <td>0.6800</td>
  <td>0.6810</td>
  <td>0.6840</td>
  <td>0.6830</td>
</tr>
</tbody></table>
</body>
</html>
HERE

  require Finance::Quote;
  require HTTP::Request;
  require HTTP::Response;

  my $req = HTTP::Request->new();
  $req->uri('...');

  my $resp = HTTP::Response->new;
  $resp->request ($req);
  $resp->content($html);
  $resp->content_type('text/html');
  $resp->{'_rc'} = 200;

  my $fq = Finance::Quote->new;
  my %quotes;
  Finance::Quote::RBA::_parse ($fq, $resp, \%quotes, ['AUDUSD']);
  diag explain \%quotes;
  is_deeply (\%quotes,
             { "AUDUSD$;success"  => 1,
               "AUDUSD$;method"   => 'rba',
               "AUDUSD$;source"   => 'Finance::Quote::RBA',
               "AUDUSD$;isodate"  => '2009-01-04',
               "AUDUSD$;name"     => 'United States dollar',
               "AUDUSD$;copyright_url" => Finance::Quote::RBA::COPYRIGHT_URL(),
               "AUDUSD$;last"     => '0.6830',
               "AUDUSD$;close"    => '0.6840',  # prev
               "AUDUSD$;date"     => '01/04/2009',
               "AUDUSD$;time"     => '16:00',
               "AUDUSD$;currency" => 'AUDUSD'
             },
            '_parse() on sample html');

  my @q_labels = sort map { key_to_label($_) } keys %quotes;
  my %sub_labels = Finance::Quote::RBA::labels();
  my %rba_labels;
  @rba_labels{@{$sub_labels{'rba'}}} = (); # hash slice

  delete $rba_labels{'errormsg'};
  my @rba_labels = sort keys %rba_labels;
  is_deeply (\@q_labels,
             \@rba_labels,
             'labels() matches what _parse() returns');
}

sub key_to_label {
  my ($str) = @_;
  $str =~ s/.*\Q$;\E//;
  return $str;
}
exit 0;
