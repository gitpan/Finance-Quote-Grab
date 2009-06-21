# Copyright 2007, 2008, 2009 Kevin Ryde

# This file is part of Finance-Quote-Grab.
#
# Finance-Quote-Grab is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Finance-Quote-Grab is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


package Finance::Quote::RBA;
use strict;
use warnings;
use List::Util;

use vars qw($VERSION %name_to_symbol);
$VERSION = 2;

use constant DEBUG => 0;


sub methods {
  return (rba => \&rba_quotes);
}
sub labels {
  return (rba => [ qw(date isodate name currency
                      last close
                      method source success errormsg

                      time copyright_url) ]);
}

use constant EXCHANGE_RATES_URL =>
  'http://www.rba.gov.au/Statistics/exchange_rates.html';

use constant COPYRIGHT_URL =>
  'http://www.rba.gov.au/Copyright/index.html';

# this is "our" vaguely in case you have to add something new or changed on
# the RBA page ... as an undocumented feature though ...
%name_to_symbol =
  ('united states dollar'  => 'AUDUSD',
   'japanese yen'          => 'AUDJPY',
   'european euro'         => 'AUDEUR',
   'south korean won'      => 'AUDKRW',
   'new zealand dollar'    => 'AUDNZD',
   'chinese renminbi'      => 'AUDCNY',
   'uk pound sterling'     => 'AUDGBP',
   'new taiwan dollar'     => 'AUDTWD',
   'singapore dollar'      => 'AUDSGD',
   'indonesian rupiah'     => 'AUDIDR',
   'hong kong dollar'      => 'AUDHKD',
   'malaysian ringgit'     => 'AUDMYR',
   'swiss franc'           => 'AUDCHF',
   'special drawing right' => 'AUDSDR',
   'trade-weighted index'  => 'AUDTWI');

sub rba_quotes {
  my ($fq, @symbol_list) = @_;
  if (! @symbol_list) { return; }

  my $ua = $fq->user_agent;
  require HTTP::Request;
  my $req = HTTP::Request->new ('GET', EXCHANGE_RATES_URL);
  $ua->prepare_request ($req);
  $req->accept_decodable; # using decoded_content() below
  $req->user_agent ("Finance::Quote::RBA/$VERSION " . $req->user_agent);

  my $resp = $ua->request ($req);
  my %quotes;
  _parse ($fq, $resp, \%quotes, \@symbol_list);
  return wantarray() ? %quotes : \%quotes;
}

sub _parse {
  my ($fq, $resp, $quotes, $symbol_list) = @_;

  foreach my $symbol (@$symbol_list) {
    $quotes->{$symbol,'method'}  = 'rba';
    $quotes->{$symbol,'source'}  = __PACKAGE__;
    $quotes->{$symbol,'success'} = 0;
  }

  if (! $resp->is_success) {
    _errormsg ($quotes, $symbol_list, $resp->status_line);
    return;
  }
  my $content = $resp->decoded_content (raise_error => 1);

  require HTML::TableExtract;
  my $te = HTML::TableExtract->new
    (headers => ['Click for earlier rates'],
     keep_headers => 1,
     slice_columns => 0);
  $te->parse($content);
  my $ts = $te->first_table_found;
  if (! $ts) {
    _errormsg ($quotes, $symbol_list, 'rates table not found in HTML');
    return;
  }

  # Desired figures are in last column.
  # But on a bank holiday a column will have "BANK HOLIDAY", one letter per
  # row, so skip that if necessary, identified by the "B" in BANK in the
  # first row.
  my $col = $ts->columns - 1;
  while ($ts->cell(1,$col) eq 'B') {
    $col--;
    if ($col < 0) {
      _errormsg ($quotes, $symbol_list, 'oops, all "B" columns');
      return;
    }
  }

  # second last column
  my $prevcol = $col-1;
  while ($ts->cell(1,$prevcol) eq 'B') {
    $prevcol--;
    if ($prevcol < 0) {
      _errormsg ($quotes, $symbol_list, 'oops, all "B" columns');
      return;
    }
  }
  if (DEBUG) { print "  col=$col, prevcol=$prevcol\n"; }

  my $date = $ts->cell (0, $col);

  my %want_symbol;
  @want_symbol{@$symbol_list} = (); # hash slice
  my %seen_symbol;

  foreach my $row (@{$ts->rows()}) {
    my $name = $row->[0];
    ($name, my $time) = _name_extract_time ($name);

    my $symbol = $name_to_symbol{lc $name};
    if (! $symbol) { next; }  # unrecognised row
    if (! exists $want_symbol{$symbol}) { next; } # unwanted row

    my $rate = $row->[$col];
    my $prev = $row->[$prevcol];

    $fq->store_date($quotes, $symbol, {eurodate => $date});
    $quotes->{$symbol,'time'}  = $time;
    $quotes->{$symbol,'name'}  = $name;
    $quotes->{$symbol,'last'}  = $rate;
    $quotes->{$symbol,'close'} = $prev;
    if ($symbol ne 'TWI') {
      $quotes->{$symbol,'currency'} = $symbol;
    }
    $quotes->{$symbol,'copyright_url'} = COPYRIGHT_URL;
    $quotes->{$symbol,'success'}  = 1;

    # don't delete AUDTWI from %want_symbol since want to get the last row
    # which is 16:00 instead of the 9:00 one
    $seen_symbol{$symbol} = 1;
  }

  delete @want_symbol{keys %seen_symbol}; # hash slice
  # any not seen
  _errormsg ($quotes, [keys %want_symbol], 'No such symbol');
}

sub _errormsg {
  my ($quotes, $symbol_list, $errormsg) = @_;
  foreach my $symbol (@$symbol_list) {
    $quotes->{$symbol,'errormsg'} = $errormsg;
  }
}

# pick out name and time from forms like
#     Trade-weighted index (9am)
#     Trade-weighted index (Noon)
#     Trade-weighted index (4pm)
# or without a time is 4pm, like
#     UK pound sterling
#
sub _name_extract_time {
  my ($name) = @_;

  my $time = 16;
  if ($name =~ m/(.*?) +\(([0-9]+)am\)$/i) {
    # 12am is 00:00, otherwise 1am -> 1:00 etc
    $time = ($2 == 12 ? $2 - 12 : $2);
    $name = $1;
  } elsif ($name =~ m/(.*?) +\(Noon\)$/i) {
    $time = 12;
    $name = $1;
  } elsif ($name =~ m/(.*?) +\(([0-9]+)pm\)$/i) {
    # 12pm is 12:00, otherwise 1pm -> 13:00 etc
    $time = ($2 == 12 ? $2 - 12 : $2) + 12;
    $name = $1;
  }
  $time = ($time % 24) . ':00';
  return ($name, $time);
}

1;
__END__

=head1 NAME

Finance::Quote::RBA - download Reserve Bank of Australia currency rates

=head1 SYNOPSIS

 use Finance::Quote;
 $q = Finance::Quote->new ('RBA');
 %rates = $q->fetch ('rba', 'AUDGBP', 'AUDUSD');

=head1 DESCRIPTION

This module downloads currency rates for the Australian dollar from the
Reserve Bank of Australia,

=over 4

L<http://www.rba.gov.au/>

=back

using the page

=over 4

L<http://www.rba.gov.au/Statistics/exchange_rates.html>

=back

As of June 2009 the web site terms of use set out under

=over 4

L<http://www.rba.gov.au/Copyright/index.html>

=back

are for personal non-commercial use with proper attribution.  (It will be
noted material is to be used in ``unaltered form'', but the bank advises
import into a charting program is permitted.)  It's your responsibility to
ensure your use of this module complies with current and future terms.

=head2 Symbols

The symbols used are "AUDXXX" where XXX is the other currency.  The
following are available

    AUDCNY    Chinese renminbi
    AUDEUR    Euro
    AUDJPY    Japanese yen
    AUDHKD    Hong Kong dollar
    AUDIDR    Indonesian rupiah
    AUDMYR    Malaysian ringgit
    AUDNZD    New Zealand dollar
    AUDCHF    Swiss franc
    AUDSGD    Singapore dollar
    AUDKRW    South Korean won
    AUDTWD    Taiwanese dollar
    AUDGBP    British pound sterling
    AUDUSD    US dollar

Plus the RBA's Trade Weighted Index for the Australian dollar, and the
Australian dollar valued in the IMF's Special Drawing Right basket of
currencies.

    AUDTWI    Trade Weighted Index
    AUDSDR    Special Drawing Right

The AUD in each is a bit redundant, but it's in the style of Yahoo Finance
and makes it clear which way around the rate is expressed.

=head2 Fields

The following standard F-Q fields are returned

=for Finance_Quote_Grab standard_fields flowed

    date isodate name currency
    last close
    method source success errormsg

Plus the following extras

=for Finance_Quote_Grab extra_fields table

    time              ISO string "HH:MM"
    copyright_url

C<time> is always "16:00", ie. 4pm, currently.  The bank publishes TWI
(trade weighted index) values for 10am and Noon too, but not until the end
of the day when the 4pm value is the latest.

C<currency> is the target cross, since prices are the value of an Australian
dollar in the respective currency.  For example in "AUDUSD" it's "USD".
C<currency> is omitted for "AUDTWI" since "TWI" is probably not a defined
international currency code.  But it is returned for "AUDSDR", the IMF
special drawing right basket.

=head1 OTHER NOTES

Currency rates are downloaded just as "prices", there's no tie-in to the
C<Finance::Quote> currency conversion feature.

The currency names in the web page are hard coded in this module, so if it's
extended or changed the code probably has to be updated (though the
C<name_to_symbol> hash is a package variable as an undocumented way to
perhaps allow a temporary fix externally).

=head1 SEE ALSO

L<Finance::Quote>, L<LWP>

RBA website L<http://www.rba.gov.au/>

=head1 HOME PAGE

L<http://www.geocities.com/user42_kevin/finance-quote-grab/>

=head1 LICENCE

Copyright 2007, 2008, 2009 Kevin Ryde

Finance-Quote-Grab is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Finance-Quote-Grab is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Finance-Quote-Grab; see the file F<COPYING>.  If not, see
L<http://www.gnu.org/licenses/>.

=cut
