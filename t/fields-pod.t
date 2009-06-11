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


package main;
use 5.005;
use strict;
use warnings;
use File::Spec;
use ExtUtils::Manifest;

use Test::More;
BEGIN {
  # new in 5.6, so unless you've got it separately with 5.005
  eval { require Pod::Parser }
    or plan skip_all => "Pod::Parser not available -- $@";
}
plan tests => 3;

use constant DEBUG => 0;


my $toplevel_dir = File::Spec->catdir ($FindBin::Bin, File::Spec->updir);
my $manifest_file = File::Spec->catfile ($toplevel_dir, 'MANIFEST');
my $manifest = ExtUtils::Manifest::maniread ($manifest_file);

my @check_files = grep {m{^lib/}} keys %$manifest;
if (DEBUG) { diag "check_files: ", explain \@check_files; }

foreach my $filename (@check_files) {
  check_file ($filename);
}

sub check_file {
  my ($filename) = @_;

  my $class = $filename;
  $class =~ s{^lib/}{};
  $class =~ s{\.pm$}{};
  $class =~ s{/}{::}g;
  if (DEBUG) { diag "check_file: $filename $class"; }

  $filename = File::Spec->rel2abs ($filename, $toplevel_dir);
  my $parser = MyParser->new;
  $parser->parse_from_file ($filename);
  my $pod_fields = $parser->fields_found;

  require $filename;
  my %labels = $class->labels;
  foreach my $method (keys %labels) {
    my $code_fields = $labels{$method};
    if (DEBUG) {
      diag "pod_fields  ", explain $pod_fields;
      diag "code_fields ", explain $code_fields;
    }

    $pod_fields = [ sort @$pod_fields ];
    $code_fields = [ sort @$code_fields ];
    is_deeply ($pod_fields, $code_fields,
               "pod vs code fields, $filename");
  }
}


package MyParser;
use strict;
use warnings;
use Carp;
use FindBin;
use base 'Pod::Parser';

use constant DEBUG => 0;

sub command {
  my $self = shift;
  my ($command, $text, $line_num, $pod_para) = @_;
  if (DEBUG) { print "$command -- $text"; }

  if ($command eq 'for' && $text =~ /^\s*Finance_Quote_Grab\s+(.*)/) {
    ($self->{'fields_type'}, $self->{'parse_type'}) = split /\s+/, $1;
  }
}

sub verbatim {
  my ($self, $text, $line_num, $pod_para) = @_;

  if (my $fields_type = delete $self->{'fields_type'}) {
    if (DEBUG) { print "$self->{'parse_type'} -- $text\n"; }

    my @fields;
    if ($self->{'parse_type'} eq 'flowed') {
      $text =~ s/^\s+//;
      @fields = split /\s+/, $text;

    } elsif ($self->{'parse_type'} eq 'table') {
      while ($text =~ m{^\s*(\w+)}mg) {
        push @fields, $1;
      }
    }
    @fields or die "Oops, no fields recognised -- $text";
    $self->{$fields_type} = \@fields;
    push @{$self->{'fields'}}, @fields;
  }
}

sub textblock {
  my ($self) = @_;
  if ($self->{'fields_type'}) {
    croak "Oops, expected verbatim paragraph after =for Finance_Quote_Grab";
  }
}

# return arrayref of field names found in the pod
sub fields_found {
  my ($self) = @_;
  return $self->{'fields'} || croak "No fields found";
}


exit 0;
