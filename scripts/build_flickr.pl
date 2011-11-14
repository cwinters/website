#!/usr/bin/perl

use strict;
use XML::Feed;
use URI;
use URI::Escape qw( uri_escape );

my $DEFAULT_MAX_ENTRIES = 10;
my $DEFAULT_URL = 'http://api.flickr.com/services/feeds/photos_public.gne?id=62037332@N00&lang=en-us&format=rss_200';

{
    my ( $dest, $url, $max_entries ) = @ARGV;
    unless ( $dest ) {
	die "Usage: $0 destination-file [ url-to-fetch ] [ max_entries ]\n",
	    "  Default URL: $DEFAULT_URL\n",
	    "  Default max entries: $DEFAULT_MAX_ENTRIES\n";
    }

    $url         ||= $DEFAULT_URL;
    $max_entries ||= $DEFAULT_MAX_ENTRIES;

    my $feed = XML::Feed->parse( URI->new( $url ))
        or die XML::Feed->errstr;

    my $temp_dest = "${dest}.tmp";
    open( OUT, "> $temp_dest" ) || die "Cannot write to $temp_dest: $!";
    my $count = 0;
    foreach my $entry ( $feed->entries ) {
	last if ( $count >= $max_entries );
        my $photo_data = parse_flickr_content( $entry->content->body );
	print OUT qq{<a href="$photo_data->{link}"\n},
	          qq{     title="$photo_data->{title}"><img\n},
		  qq{  src="$photo_data->{img_src}"\n},
                  qq{  width="$photo_data->{width}"\n},
		  qq{  height="$photo_data->{height}"\n},
		  qq{  border="0" /></a>\n},
		  qq{<br />\n};
	$count++;
    }
    close( OUT );
    rename( $temp_dest, $dest );
    print "+ Wrote latest photos to $dest\n";
}

sub parse_flickr_content {
    my ( $content ) = @_;
    $content =~ s|^.*?</p>||;
    my ( $link )    = $content =~ m|<a href="([^"]+)"|;
    my ( $title )   = $content =~ m|title="([^"]+)"|;
    my ( $img_src ) = $content =~ m|src="([^"]+)"|;
    my ( $width, $height ) = $content =~ m|width="(\d+)"\s+height="(\d+)"|;
    return {
        link  => $link,  title  => $title, img_src => $img_src,
        width => $width, height => $height
    };
}
