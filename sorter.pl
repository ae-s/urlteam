#!/usr/bin/perl

# URL Shortener Scraper Sorter
# Copyright 2009 Duncan Smith
# BSD license

use warnings;
use strict;

my @elems = ("0" .. "9", "A" .. "Z", "a" .. "z");

#abcdefghijklmnopqrstuvwxyz
my @num = qw/0 6 34 0 1/;

my %queue = ( );

open my $in, '<', shift;
open my $out, '>', shift;
open my $error, '>>', shift;

sub increment () {
    for (reverse @num) {
	$_++;
	if ($_ == scalar @elems) {
	    $_ = 0;
	    next;
	}
	last;
    }
}

sub convert (@) {
    my $out = "";

    for (@_) {
	$out .= $elems[$_];
    }

    return $out;
}

sub add($) {
    my $line = shift;
    $line =~ m/^([a-zA-Z0-9]+)\|(.*)$/;
    $queue{$1} = $2;
    print "Added $1 for total of " . (keys %queue) . "\n";
}

READ: while (<$in>) {
    add($_);
  WRITE: while (defined $queue{convert(@num)}) {
	print $out convert(@num) . "|" . $queue{convert(@num)} . "\n";
	delete $queue{convert(@num)};
	print "Wrote " . convert(@num) . "\n";
	increment;
    }
    if (keys %queue > 10000) {
	print "Skipped " . convert(@num) . "!\n";
	print $error convert(@num) . "\n";
	increment;
    }
}

close $in;
close $out;
close $error;
exit;
