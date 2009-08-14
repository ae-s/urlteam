#!/usr/bin/perl

use warnings;
use strict;

require LWP::UserAgent;

my @elems = ("0" .. "9", "A" .. "Z", "a" .. "z");
my $host = 'link.0daymeme.com';

my $len = 1;
my @num = ( 0 );

#my @numthreads = 1;

sub convert (@) {
    my $out = "";

    for my $p (@_) {
	$out .= $elems[$p];
    }

    return $out;
}

sub fetch ($) {
    my $url = shift;
    my $out = "";
    my $ua = LWP::UserAgent->new;

    print "Fetching from $url\n";

    my $resp = $ua->head($url);
#    if ($resp->is_redirect()) {
	print "RE  ";
	my $loc = $resp->header('Location');
	print $loc ;
	print "\n";
#    } else {
#	print "NO\n";
#    }
}

print fetch('http://tinyurl.com/kx9y'), "\n";

print convert( @num ), "\n";


