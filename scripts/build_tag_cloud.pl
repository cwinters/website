#!/usr/bin/perl

# builds a single tag cloud component, plus a page for each tag with a
# list of the tagged items

use strict;
use File::Find;
use HTML::TagCloud;

my $DEFAULT_MAX_TAGS = 75;
my ( $DEST, $SRC );

# key: tag-name
# value: list of hashrefs, each with 'title' and 'path'; 'url' 
# generated after processing
my %TAGS    = ();

{
    my ( $max_tags );
    ( $SRC, $DEST, $max_tags ) = @ARGV;
    unless ( $SRC and -d $SRC and $DEST and -d $DEST ) {
        die "Usage: $0 src-content-dir dest-generated-dir [max-tags]";
    }
    $max_tags ||= $DEFAULT_MAX_TAGS;

    my $cloud_file = "$DEST/includes/tag_cloud.html";
    my $tag_dir    = "$DEST/tags";

    # fill up the %TAGS data structure
    find( \&wanted, $SRC );

    # now dump them out -- first the cloud
    my $cloud = HTML::TagCloud->new();
    while ( my ( $tag, $items ) = each %TAGS ) {
        $cloud->add( $tag, "/tags/$tag.html", scalar @{ $items } );
    }
    open( CLOUD, '>', $cloud_file )
        || die "Cannot write to cloud ($cloud_file): $!";
    print CLOUD $cloud->html_and_css( $max_tags );
    close( CLOUD );
    print "+ Wrote tag cloud $cloud_file\n";

    # then each tag file
    while ( my ( $tag, $items ) = each %TAGS ) {
        my $tag_file = "$tag_dir/$tag.txt";
        open( TAG, '>', $tag_file )
            || die "Cannot write to tag file ($tag_file): $!";
        print TAG qq{<h1>Items tagged with: $tag</h1>\n},
                  qq{<ul>\n};
        foreach my $item ( @{ $items } ) {
            print TAG qq{<li><a href="}, $item->{url}, qq{">}, 
                      $item->{title}, qq{</a></li>\n};
        }
        print TAG qq{</ul>\n};
        close( TAG );
        print "+ Wrote tag file $tag_file\n";
    }
}

sub wanted {
    return unless ( /\.txt$/ );
    my $file = $_;
    my ( $title, @tags ) = read_content( $file );
    if ( @tags ) {
        my $html = $File::Find::name;
        $html =~ s/txt$/html/;
        $html =~ s/^$SRC//;
        my $content = { title => $title,
                        url   => $html };
        foreach my $tag ( @tags ) {
            $TAGS{ $tag } ||= [];
            push @{ $TAGS{ $tag } }, $content;
        }
    }
    $_ = $file;
}

sub read_content {
    my ( $file ) = @_;
    my ( $title );
    my @tags = ();
    open( IN, '<', $file ) || die "Cannot read title from $file: $!";
    while ( <IN> ) {
        chomp;
        my $line = $_;
        if ( $line =~ /page_title\s*=\s*'(.*)'/ ) {
            $title = $1;
            $title =~ s/\\'/'/g;
        }
        # sample: <!-- Tags: shell; solaris; unix -->
        elsif ( $line =~ /^<!\-\- Tags:\s+(.*)\s+\-\->$/ ) {
            @tags = grep /^\S+$/, split( /;\s+/, $1 );
        }
    }
    close( IN );
    return ( $title, @tags );
}
