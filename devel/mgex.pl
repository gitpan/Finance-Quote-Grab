#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011 Kevin Ryde

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

use 5.010;
use strict;
use warnings;
use Perl6::Slurp ('slurp');
use Finance::Quote;

use Finance::Quote::MGEX;
print "Finance::Quote::MGEX version ",Finance::Quote::MGEX->VERSION,"\n";

# uncomment this to run the ### lines
use Smart::Comments;

{
  require HTTP::Response;
  my $resp = HTTP::Response->new(200, 'OK');
  my $content = Perl6::Slurp::slurp(<samples/mgex/aquotes.htx.5>);
  # my $content = Perl6::Slurp::slurp(<samples/mgex/wquotes_js.js.3>);
  # my $content = Perl6::Slurp::slurp(<samples/mgex/intraday-no.html>);
  $resp->content($content);
  $resp->content_type('application/x-javascript');

  #  print $content;
  # print Finance::Quote::MGEX::_java_document_write($content);

  my $fq = Finance::Quote->new;
  my %quotes;
  Finance::Quote::MGEX::resp_to_quotes ($fq, $resp, \%quotes,
                                        ['KEZ11','ISU11','MWZ0','MWZ11']);
  ### %quotes

  exit 0;
}

{
  my $fq = Finance::Quote->new ('-defaults', 'MGEX');
  my %quotes = $fq->fetch ('mgex', 'MWZ1');
  ### %quotes
  exit 0;
}



  # my $url = Finance::Quote::MGEX::barchart_customer_resp_to_url ($resp, 'XYZ');
  # say $url;
