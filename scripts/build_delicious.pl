#!/usr/bin/perl

use strict;
use XML::Feed;
use URI;
use URI::Escape qw( uri_escape );

my $DEBUG               = 0;
my $DEFAULT_MAX_ENTRIES = 10;
my $DEFAULT_URL         = 'http://del.icio.us/rss/cwinters';

{
    my ( $dest, $url, $max_entries ) = @ARGV;
    unless ( $dest ) {
	die "Usage: $0 destination-file [url-to-fetch] [max_entries]";
    }

    $url         ||= $DEFAULT_URL;
    $max_entries ||= $DEFAULT_MAX_ENTRIES;

    my $feed = XML::Feed->parse( URI->new( $url ))
        or die XML::Feed->errstr;

    my $temp_dest = "${dest}.tmp";
    open( OUT, '>:utf8', $temp_dest ) || die "Cannot write to $temp_dest: $!";
    print OUT "<ul>\n";
    my $count = 0;
    foreach my $entry ( $feed->entries ) {
	last if ( $count >= $max_entries );
	my $title      = $entry->title();
	my $href_title = $entry->content()->body();
	$href_title =~ s/\&/&amp;/g;
	$href_title =~ s/"/&quot;/g;
	my $href       = $entry->link();
	print OUT qq{  <li><a title="$href_title" href="$href">$title</a> </li>\n};
	$count++;
    }
    print OUT "</ul>\n";
    close( OUT );
    rename( $temp_dest, $dest );
    $DEBUG && print "+ Wrote latest links to $dest\n";
}
