#!/usr/bin/perl

# URL Shortener Scraper
# Copyright 2009 Duncan Smith
# BSD license

use warnings;
use strict;

use threads;
use Thread::Queue;

require LWP::UserAgent;

# Host to scrape.
my $host = shift @ARGV;

# Modify this if e.g. the host is all-numeric or case-insensitive.
# Interestingly, if you are scraping a site like shorl.com, who uses
# syllables instead of characters, you can have this be a list of
# those syllables.
my @elems = ("0" .. "9", "A" .. "Z", "a" .. "z");
if ($ARGV != 0) {
    @elems = @ARGV;
}

print "Fetching from $host with characters ".join(",", @elems)."\n";

#abcdefghijklmnopqrstuvwxyz

# Starting point
my @num = qw/1 6 36 0 0/;

# Stopping point
my @last = qw/2 51 0 0 0/;

my $maxthreads = 30;
my $maxmsgs = $maxthreads * 10;

# Queue of URLs (actually references to lists of parameters for URLs) to be fetched
my $stream = Thread::Queue->new();

# Queue of fetched redirects to be written (as string form, ready to write)
my $writer = Thread::Queue->new();

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

    my $resp = $ua->get($url);
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

    my $url = 'http://' . $host . '/' . convert(@num);
    my $dest = fetch $url, $ua;
    $writer->enqueue(convert(@num) . "|" . $dest . "\n");

}

# This is a worker thread to fetch URLs.  There are $maxthreads of these
sub boot () {
    my $ua = LWP::UserAgent->new(agent => "Eat Delicious Poop");

    while (1) {
	my ($host, @num) = @{$stream->dequeue()};
	my $out = "$host/" . convert(@num);
	go($ua, $out, $host, @num);
    }
}

# This is a worker thread to write fetched URLs.  There is only one of these.
sub writer () {
    open my $fh, '>>', $host . ".txt";
    print "Opened $host.txt\n";


    while (1) {
	my $line = $writer->dequeue();
	if (!defined $line) {
	    threads->exit();
	}
	print "R: " .  $stream->pending . "  W: " . $writer->pending . "  URL: " . $host . "/" . substr(substr($line, 0, 70), 0, -1) . "\n";
	print $fh $line;
    }
}

# Create the thread to write to the file
my $writerthread = threads->create(\&writer);

# Create the worker threads
while ($maxthreads > 0) {
    threads->create(\&boot);
    $maxthreads--;
}

# URL-generating loop
while (1) {
    if ($stream->pending < $maxmsgs) {
	increment;

	my @ary :shared = ($host, @num);
	$stream->enqueue(\@ary);
	if (@num ~~ @last) {
	    last;
	}
    } else {
	sleep 1;
    }
}

while ($stream->pending > 0) {
    sleep 1;
}

$writer->enqueue(undef);

$writerthread->join();

exit;
