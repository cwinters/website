#!/usr/bin/perl

# build an index for a particular directory, just reading all its
# files and pulling the 'title' from each

use strict;

{
    my ( $dir, $menu_choice, $index_title ) = @ARGV;
    unless ( $dir and -d $dir and $menu_choice and $index_title ) {
        die "Usage: $0 dir menu-choice index-title\n";
    }
    my $tmp_index_file = "$dir/index.txt.tmp";
    open( INDEX, "> $tmp_index_file" )
      || die "Cannot write to index ($tmp_index_file): $!";
    my $tt_title = $index_title;
    $tt_title =~ s/'/\\'/g;
    print INDEX "[%- META \n",
                "      menu_choice = '$menu_choice'\n",
		"      page_title  = '$tt_title' -%]\n\n",
		"<h1>$index_title</h1>\n";
    foreach my $file ( read_files_by_ext( $dir, 'txt' ) ) {
        next if ( $file eq 'index.txt' );
        my $html = $file;
        $html =~ s/txt$/html/;
        my $title = get_title( "$dir/$file" );	
        print INDEX qq{<a href="$html">$title</a><br />\n};
    }
    close( INDEX );
    my $full_index_file = "$dir/index.txt";
    rename( $tmp_index_file, $full_index_file );

    print "+ Wrote index file $full_index_file\n";
}

sub read_files_by_ext {
    my ( $dir, $ext ) = @_;
    opendir( BYEXT, $dir ) || die "Cannot read files from $dir: $!";
    my @files = grep /$ext$/,  grep { -f "$dir/$_" } readdir( BYEXT );
    closedir( BYEXT );
    return sort @files;
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
