#!/usr/bin/perl

# Copyright 2009 Kevin Ryde

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


# Check that the supported fields described in each pod matches what the
# code says.

use 5.005;
use strict;
use warnings;
use ExtUtils::Manifest;
use File::Spec;
use FindBin;
use Finance::Quote;

use Test::More;
BEGIN {
  # new in 5.6, so unless you've got it separately with 5.005
  eval { require Pod::Parser }
    or plan skip_all => "Pod::Parser not available -- $@";
}
plan tests => 1;

# SKIP: { eval 'use Test::NoWarnings; 1'
#           or skip 'Test::NoWarnings not available', 1; }

use constant DEBUG => 0;


my $toplevel_dir = File::Spec->catdir ($FindBin::Bin, File::Spec->updir);
my $manifest_file = File::Spec->catfile ($toplevel_dir, 'MANIFEST');
my $manifest = ExtUtils::Manifest::maniread ($manifest_file);

my $t_lib_dir = File::Spec->catdir ($toplevel_dir, 't', 'lib');
unshift @INC, $t_lib_dir;
require MyPodParser;

my @check_files = grep {m{^lib/.*\.pm$}} keys %$manifest;
if (DEBUG) { diag "check_files: ", explain \@check_files; }

my %symbols;
my $good = 1;
foreach my $filename (@check_files) {
  my $class = $filename;
  $class =~ s{^lib/|\.pm$}{}g;
  $class =~ s{/}{::}g;
  if (DEBUG) { diag "check_file: $filename $class"; }

  $filename = File::Spec->rel2abs ($filename, $toplevel_dir);
  my $parser = MyPodParser->new;
  $parser->parse_from_file ($filename);
  push @{$symbols{$class}}, @{$parser->symbols_found};
}
if (DEBUG) {
  diag "symbols ", explain \%symbols;
}

foreach my $class (sort keys %symbols) {
  download_symbols ($class, $symbols{$class});
}
ok ($good);

sub download_symbols {
  my ($class, $symbol_list) = @_;
  $class =~ m/([^:]+)$/ or die "Oops, class basename not matched";
  my $method = lc($1);

  my $fq = Finance::Quote->new ('-defaults', 'Casablanca', 'MLC', 'RBA');
  my %quotes = $fq->fetch ($method, @$symbol_list);
  if (DEBUG) { diag explain \%quotes }

  my %numeric_fields = (p_change  => 0,
                        volume    => 0,
                        eps       => 0,
                        div_yield => 0,
                        cap       => 0,

                        # Casablanca.pm
                        bid_quantity             => 0,
                        ask_quantity             => 0,
                        dollar_volume_both_sides => 0,
                        year_high                => 0,
                        year_low                 => 0,
                        net_profit               => 0,
                        payout_percent           => 0,
                        par_value                => 0,
                        shares_on_issue          => 0,
                        nominal_capital          => 0,
                       );
  my $currency_fields_func = ($class->can('currency_fields')
                              || \&Finance::Quote::default_currency_fields);
  @numeric_fields{&$currency_fields_func()} = (); # hash slice

  foreach my $symbol (@$symbol_list) {
    if (! $quotes{$symbol,'success'}) {
      diag "$symbol no 'success'";
      $good = 0;
    }
    if ($quotes{$symbol,'method'} ne $method) {
      diag "$symbol wrong 'method' $quotes{$symbol,'method'}";
      $good = 0;
    }
    if ($quotes{$symbol,'source'} ne $class) {
      diag "$symbol wrong 'source' $quotes{$symbol,'source'}";
      $good = 0;
    }
  }
  while (my ($key,$value) = each %quotes) {
    my ($symbol, $field) = split $;, $key;
    next if $field eq 'a'; # diagnostic left by $fq->store_date()

    if ($value =~ /\240/) {
      diag "'$key' '$value' latin-1 non-breaking space";
      $good = 0;
    }
    if ($value =~ /^(\s|\240)/) {
      diag "'$key' '$value' leading whitespace";
      $good = 0;
    }
    if ($value =~ /(\s|\240)$/) {
      diag "'$key' '$value' trailing whitespace";
      $good = 0;
    }

    if ($field =~ /_range$/ && defined $value) {
      if ($value =~ /^(.+)-(.+)$/) {
        my $hi = $1;
        my $lo = $2;
        check_number ($key, $lo);
        check_number ($key, $hi);
        if ($lo > $hi) {
          diag "'$key' '$value' has lo > hi";
          $good = 0;
        }
      } else {
        diag "'$key' '$value' not NUMBER-NUMBER format";
        $good = 0;
      }
    } elsif (exists $numeric_fields{$field} && defined $value) {
      check_number ($key, $value);
    }

    if ($field eq 'isodate' || $field eq 'ex_div') {
      unless (! defined $value
              || $value =~ /^([0-9]{4})-([0-9]{2})-([0-9]{2})$/) {
        diag "'$key' '$value' not an ISO date";
        $good = 0;
      }
    }

    if ($field eq 'time') {
      unless (! defined $value
              || $value =~ /^[0-9]{2}:[0-9]{2}(:[0-9]{2})?$/) {
        diag "'$key' '$value' not an ISO time";
        $good = 0;
      }
    }
  }
}

sub check_number {
  my ($key, $value) = @_;
  unless ($value =~ m{^-?[0-9]+.[0-9]+$  # decimal
                    |^-?[0-9]+$          # integer
                    |^$}x) {             # allow empty for Casablanca ...
    diag "'$key' '$value' not a number";
    $good = 0;
  }
  if ($value =~ /^0[0-9]/) {
    diag "'$key' '$value' leading zero";
    $good = 0;
  }
}

exit 0;
