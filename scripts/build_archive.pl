#!/usr/bin/perl

# Builds an embeddable archive listing, plus index pages for every month.

use strict;
use Cwd qw( cwd );
use DateTime;
use DateTime::Format::Strptime;
use XML::Feed;

my $TZ = 'America/New_York';
my $DATE_FMT   = DateTime::Format::Strptime->new( 
    pattern   => '%B %d, %Y', # 'April 13, 2009'
    time_zone => $TZ
 );
my @MONTHS     = qw( foo Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
my $NUM_LATEST = 10;
my $SITE_URL   = 'http://www.cwinters.com'; # leave off trailing '/'

{
    my ( $content_dir) = @ARGV;
    unless ( $content_dir and -d $content_dir ) {
        die "Usage: $0 content-dir";
    }

    my $blog_dir     = "$content_dir/blog";
    my $includes_dir = "$content_dir/includes";
    my $feeds_dir    = "$content_dir/feeds";
    my $archive_file = "$includes_dir/archives.html";
    my $latest_file  = "$includes_dir/latest_items.html";
    my $atom_file    = "$feeds_dir/cwinters.atom";

    my @archives = ();
    my @references = ();

    my @years = read_numbered_dirs( $blog_dir );
    foreach my $year ( @years ) {
        my $year_dir = "$blog_dir/$year";
        my @months = read_numbered_dirs( $year_dir );
        foreach my $month ( @months ) {
            my $month_dir = "$year_dir/$month";
            my @files_in_month = read_files_in_month( $month_dir );
            push @references, @files_in_month;
            my $file_count = scalar @files_in_month;
            my $month_url = "/blog/$year/$month/index.html";
            my $month_name = $MONTHS[$month];
            # 'unshift' so they'll be in date-descending order
            unshift @archives, qq{<a href="$month_url">$month_name/$year</a> ($file_count)  };
            my $tmp_index_file = "$month_dir/index.txt.tmp";
            open( MONTH, "> $tmp_index_file" )
                || die "Cannot write to montly index ($tmp_index_file): $!";
            print MONTH "[%- META \n",
                        "      menu_choice = 'blog'\n",
            			"      page_title  = 'Archive $year/$month' -%]\n\n",
                        "<h1>Archives: $month/$year</h1>\n";
            foreach my $file_info ( @files_in_month ) {
                my $day      = $file_info->{day};
                my $file_url = "/blog/$year/$month/" . $file_info->{path};
                $file_info->{url} = $file_url;
                $file_info->{file_path} = "$year/$month/" . $file_info->{text_path};
                my $title    = $file_info->{title};
                print MONTH qq{$day: <a href="$file_url">$title</a> <br />\n};
            }
            close( MONTH );
            my $full_index_file = "$month_dir/index.txt";
            rename( $tmp_index_file, $full_index_file );
            print "+ Wrote monthly archive to $full_index_file\n";
        }
    }

    my $archive_content = '';
    my $count = 1;
    foreach my $archive_item ( @archives ) {
        $archive_content .= $archive_item;
        $archive_content .= "<br />\n" if ( $count % 2 == 0 );
        $count++;
    }
    write_temp( $archive_file, $archive_content );
    print "+ Wrote archive component to $archive_file\n";

    # grab the last n items so we can generate the blog home and
    # the site home
    my $offset = scalar( @references ) - $NUM_LATEST;
    my @most_recent = reverse splice( @references, $offset, $NUM_LATEST );

    if ( scalar @most_recent == 0 ) {
        print "! Exiting, no items in the 'most recent' list to process\n";
        exit(1);
    }

    my $recent_content = '';
    foreach my $item ( @most_recent ) {
        my $full_path = "$blog_dir/" . $item->{file_path};

        # put the content in the hash since we need it for the feed later
        $item->{content} = strip_line_with_thread( read_content( $full_path ) );

        # work around weird facebook issue where they strip out
        # newlines but don't replace them with a space, running
        # words together (ANNOYING!)
        $item->{content} =~ s/\n/ \n/g;
        my $posted_date = $DATE_FMT->format_datetime( $item->{posted} );
        $recent_content .=  
            qq{\n\n<p class="post-footer align-right"><span class="date">$posted_date</span></p>\n} .
            $item->{content} . "\n" .
            generate_permalink( $item );
    }

    write_temp( $latest_file, $recent_content );
    print "+ Wrote latest $NUM_LATEST items to $latest_file\n";

    # first, install a few updates to XML::Feed::Atom if XML::Feed <= 0.12
    my $xml_feed_version = $XML::Feed::VERSION;
    if ( $xml_feed_version <= 0.12 ) {
        require XML::Feed::Atom;
        sub XML::Feed::Atom::id          { shift->{atom}->id(@_) }
        sub XML::Feed::Atom::updated     { shift->{atom}->updated(@_) }
        sub XML::Feed::Atom::add_link    { shift->{atom}->add_link(@_) }
        print "* Installed additional methods to XML::Feed::Atom\n";
    }

    # now generate the feed
    my $feed = XML::Feed->new( 'Atom' );

    # first global feed info...
    $feed->title( "Chris Winters Blog" );
    $feed->link( 'http://www.cwinters.com/feeds/cwinters.atom' );
    $feed->id( 'http://www.cwinters.com/feeds/cwinters.atom' );
    $feed->tagline( 'More boring geek stuff' );
    $feed->author( 'Chris Winters <chris@cwinters.com>' );
    $feed->modified( $most_recent[0]->{posted} );
    $feed->language( "en-us" );

    # then add each of the items
    foreach my $item ( @most_recent ) {
        my $full_url = $SITE_URL . $item->{url};
        my $entry = XML::Feed::Entry->new( 'Atom' );
        $entry->title( $item->{title} );
        $entry->link( $full_url );
        $entry->author( 'Chris Winters' );
        $entry->modified( $item->{posted} );
        $entry->id( $full_url );
        
        my $content_item = XML::Feed::Content->new({
            body => strip_line_with_tag( $item, 'h1' ),
            type => 'text/html' });
        $entry->content( $content_item );
        
        $feed->add_entry( $entry );
    }

    # ship it!
    write_temp( $atom_file, $feed->as_xml );
    print "+ Wrote latest $NUM_LATEST items as atom feed to $atom_file\n";
}

sub generate_permalink {
    my ( $item ) = @_;
    my $permalink = $item->{url};
    return qq{<p class="align-right">\n} .
           qq{  <a href="$SITE_URL$permalink">Permalink</a>\n} .
           qq{</p>\n};
}

sub read_numbered_dirs {
    my ( $dir ) = @_;
    opendir( DIR, $dir ) || die "Cannot read dirs from ($dir): $!";
    my @numbered = grep { -d "$dir/$_" } grep /^\d+$/, readdir( DIR );
    closedir( DIR );
    return sort @numbered;
}

sub read_files_in_month {
    my ( $dir ) = @_;
    my @days = read_numbered_dirs( $dir );
    my @file_info = ();
    foreach my $day ( @days ) {
        my $day_dir = "$dir/$day";
        my @files = read_files_by_ext( $day_dir, "txt" );	
        foreach my $file ( @files ) {
            my $html = $file;
            $html =~ s/txt$/html/;
            my $path = "$day/$html";
            my $title = get_title( "$day_dir/$file" );
            my $tt_title = $title;
            $tt_title =~ s/'/\\'/g;
            my $mtime = (stat( "$day_dir/$file" ))[9];
            my $posted_on = DateTime->from_epoch( epoch => $mtime, time_zone => $TZ );
            push @file_info, { 
                day       => $day,
                title     => $title,
                tt_title  => $tt_title,
                path      => $path,
                text_path => "$day/$file",
                posted    => $posted_on,
            };
        }
    }
    return @file_info;
}

sub read_files_by_ext {
    my ( $dir, $ext ) = @_;
    #my $cwd = cwd();
    opendir( BYEXT, $dir ) || die "Cannot read files from $dir: $!";
    #chdir( $dir );
    my @files = grep /$ext$/,  grep { -f "$dir/$_" } readdir( BYEXT );    
    closedir( BYEXT );
    return sort { (stat( "$dir/$a" ))[9] <=> (stat( "$dir/$b" ))[9] } @files;
}

sub get_title {
    my ( $file ) = @_;
    my ( $title );
    open( IN, '<', $file ) || die "Cannot read title from $file: $!";
    while ( <IN> ) {
	chomp;
	if ( /page_title\s*=\s*'(.*)'/ ) {
	    $title = $1;
	    $title =~ s/\\'/'/g;
	    last;
	}
    }
    close( IN );
    unless ( $title ) {
	print "WARN: No title found in $file\n";
    }
    return $title;
}

sub read_content {
    my ( $file ) = @_;
    open( IN, '<', $file ) || die "Cannot read content from $file: $!";
    local $/ = undef;
    my $content = <IN>;
    close( IN );

    $content =~ s/\[%.*%\]//sm;
    return $content;
}

sub strip_line_with_tag {
    my ( $item, $tag ) = @_;
    my $content = $item->{content};
    my @new_content = ();
	my $uc_tag = uc( $tag );
	my $lc_tag = lc( $tag );
    foreach my $line ( split( /(\r\n|\n)/, $content ) ) {
        if ( $line !~ /<($lc_tag|$uc_tag)>/ ) {
            push @new_content, $line;
        }
    }
    return join( '', @new_content, "\n", generate_permalink( $item ) );
}

sub strip_line_with_thread {
    my ( $content ) = @_;
    $content =~ s|<!--#include virtual="/includes/thread.html" -->||sm;
    return $content;
}


sub write_temp {
    my ( $file, $content ) = @_;
    my $temp_file = $file . ".tmp";
    open( OUT, '>', $temp_file ) || die "Cannot write to $temp_file: $!";
    print OUT $content;
    close( OUT );
    rename( $temp_file, $file );
}
