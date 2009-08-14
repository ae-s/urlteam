#!/usr/bin/perl

use warnings;
use strict;

use threads;
use Thread::Semaphore;

require LWP::UserAgent;

my @elems = ("0" .. "9", "A" .. "Z", "a" .. "z");
my $host = 'is.gd';

my $len = 1;
my @num = qw/0 0 0 3 0/;
my $inuse = 0;

my $maxthreads = 20;
my $semaphore = Thread::Semaphore->new($maxthreads);

#my @numthreads = 1;

sub convert (@) {
    my $out = "";

    for (@_) {
	$out .= $elems[$_];
    }

    return $out;
}

sub fetch ($) {
    my $url = shift;
    my $out = "";
    my $ua = LWP::UserAgent->new;

    print "Fetching from $url\n";

    $ua->max_redirect( 0 );

    my $resp = $ua->head($url);
    if ($resp->is_redirect) {
	my $loc = $resp->header('Location');
	return $loc;
    } else {
	return '';
    }
}

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

sub go ($$@) {
    my ($name, $host, @num) = @_;

    open my $fh, '+>', $name;

    my $url = 'http://' . $host . '/' . convert(@num);
    my $dest = fetch $url;
    print convert(@num), ' -> ', $dest, "\n";
    print $fh convert(@num), "|", $dest, "\n";

    close $fh;

    $semaphore->up();
}

sub boot () {
    my $out = "$host/" . convert(@num);
    threads->detach();
    go($out, $host, @num);
}

mkdir $host;

while (1) {
    increment;
    my $out = "$host/" . convert(@num);
#    my $out = "$host.txt";
    $semaphore->down();
    threads->create(\&boot);
}
