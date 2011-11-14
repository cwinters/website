#!/usr/bin/perl

use strict;

my ( $dir ) = @ARGV;
$dir ||= '.';

opendir( FILES, $dir ) || die "Cannot read files from $dir: $!";
my @files = grep /\.html$/, readdir( FILES );
closedir( FILES );

foreach my $file ( @files ) {
    my $path = "$dir/$file";
    open( IN, "< $path" ) || die "Cannot read $path: $!";
    my $new_file = $file;
    $new_file =~ s/\.html$/.txt/;
    my $new_path = "$dir/$new_file";
    open( OUT, "> $new_path" ) || die "Cannot write to $new_path: $!";
    my @buffer = ();
    my $title;
    while ( <IN> ) {
	chomp;
	if ( $title ) {
	    print OUT "$_\n";
	}
	else {
	    my $line = $_;
	    if ( m|<h2>(.*)</h2>| ) {
		$title = $1;
		$title =~ s/'/\\'/g;
		print OUT "[%- META\n",
		          "     menu_choice = 'recipe';\n",
			  "     page_title  = '$title'; -%]\n",			    
			  join( "\n", @buffer ),
			  "$line\n";
		@buffer = ();
	    }
	    else {
		push @buffer, $line;
	    }
	}
    }
    close( IN );
    close( OUT );
    print "OK: Wrote $new_path\n";
    unless ( $title ) {
	print "   ...TITLE NOT FOUND\n";
    }
}
