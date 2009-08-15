#!/usr/bin/perl

use warnings;
use strict;

use threads;
use Thread::Queue;

require LWP::UserAgent;

my @elems = ("0" .. "9", "A" .. "Z", "a" .. "z");
my $host = 'is.gd';

#my $fh :shared;

my $len = 1;
my @num = qw/0 0 0 0 0/;
my $inuse = 0;

my $maxthreads = 20;
my $stream = Thread::Queue->new();

#my @numthreads = 1;

sub convert (@) {
    my $out = "";

    for (@_) {
	$out .= $elems[$_];
    }

    return $out;
}

sub fetch ($$) {
    my ($url, $ua) = @_;
    my $out = "";

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

sub go ($$$@) {
    my ($ua, $out, $host, @num) = @_;

    open my $fh, '>>', $host . "/" . convert(@num);
#    open my $fh, '+>', $host . ".txt";


    my $url = 'http://' . $host . '/' . convert(@num);
    my $dest = fetch $url, $ua;
    print convert(@num), ' -> ', $dest, "\n";
    print $fh convert(@num), "|", $dest, "\n";

    close $fh;
}

sub boot () {
    my $ua = LWP::UserAgent->new();

    while (1) {
	my ($host, @num) = @{$stream->dequeue()};
	my $out = "$host/" . convert(@num);
	go($ua, $out, $host, @num);
    }
}

mkdir $host;



while ($maxthreads > 0) {
    threads->create(\&boot);
    $maxthreads--;
}

while (1) {
    if ($stream->pending < 10) {
	increment;

	my @ary :shared = ($host, @num);
	$stream->enqueue(\@ary);
    } else {
	sleep 0.1;
    }
}


