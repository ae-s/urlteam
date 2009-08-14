#!/usr/bin/perl

use warnings;
use strict;

require LWP::UserAgent;

my @elems = ("0" .. "9", "A" .. "Z", "a" .. "z");
my $host = 'link.0daymeme.com';

my $len = 1;
my @num = ( 0 );

#my @numthreads = 1;

my $ua = LWP::UserAgent->new;

sub convert (@) {
    my $out = "";

    for my $p (@_) {
	$out .= $elems[$p];
    }

    return $out;
}

sub fetch ($) {
    my $out = "";

    

print convert( @num ), "\n";


