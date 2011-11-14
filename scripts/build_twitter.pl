#!/usr/bin/perl

use strict;
use Data::Dumper;
use Net::Twitter;

my $USERNAME = 'cwinters';
my $PASSWORD = 'twitterr0cks';

{

    my ( $dest ) = @ARGV;
    unless ( $dest ) {
        die "Usage: $0 destination-file";
    }
    my $tw = Net::Twitter->new( username => $USERNAME,
                                password => $PASSWORD );
    my $items = $tw->user_timeline({ count => 10,
                                     id    => $USERNAME });
    if ( scalar @{ $items } ) {
        my $content = '';
        my $user_image_url = $items->[0]{user}{profile_image_url};
        $content = qq{<a href="http://twitter.com/$USERNAME"><img src="$user_image_url" border="0" align="left" /></a>\n};
        foreach my $item ( @{ $items } ) {
            my $time = $item->{created_at};
            my $url = "http://twitter.com/$USERNAME/statuses/" . $item->{id};
            $content .= qq{&gt; <a href="$url" style="text-decoration: none" title="Posted at $time">$item->{text}</a> <br />\n};
        }
        open( OUT, '>:utf8', $dest ) || die "Cannot write to $dest: $!";
        print OUT $content;
        close( OUT );
    }
}
