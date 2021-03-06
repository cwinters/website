#!/usr/bin/perl

use strict;
use v5.14;
use utf8;
use File::Find::Rule;

my $ID_TO_NAME = read_news_ids();

my $dest = 'ghpages-flat';
mkdir $dest unless -d $dest;
my $rule = File::Find::Rule->file()->name('*.md');
foreach my $file ( $rule->in('ghpages/blog') ) {
  process_file($file);
}

sub read_news_ids {
  open(IN, 'news_mapping.txt') || die "Cannot read news_mapping.txt: $!";
  my %m = ();
  while (<IN>) {
    next if /^#/ || /^\s*$/;
    chomp;
    my ($id, $name) = split(/\t/);
    $m{$id} = "/$name";
  }
  return \%m;
}

sub process_file {
  my ($file) = @_;
  my @pieces = split('/', $file);
  my $name = pop(@pieces);
  next if ($name eq 'index.md');
  shift @pieces; shift @pieces; # remove 'ghpages' and 'blog'

  my @tags = scan_tags($file);

  my $new_name = join('-', @pieces, $name);
  open(IN, $file) || die "Cannot read $file: $!";
  binmode(IN, ":encoding(UTF-8)");
  open(OUT, '>', "$dest/$new_name") || die "Cannot write to $dest/$new_name: $!";
  binmode(OUT, ":encoding(UTF-8)");

  my $front_to_see = 1;

  while (<IN>) {
    my $line = $_;

    if ($front_to_see && $line =~ /^\-\-\-/) {
      print OUT $line;
      print OUT "tags: ", join(" ", @tags), "\n";
      $front_to_see = 0;
      next;
    }
    next if $line =~ /<h1>/;
    next if $line =~ /^<!\-\- Tags/;
    next if $line =~ /^<!\-\-#include/;
    if ($line =~ /class="post\-footer/) {
      my $date_line = <IN>;
      my $date_close = <IN>;
      next;
    }

    # Process links 
    my $old_line = $line;
    my $changed = $line =~ s!(("|')(http://(www\.)?cwinters\.com)?/News/show/\?news_id=(\d+)("|'))!$2$ID_TO_NAME->{$5}$2!g;
    if ($changed && ($line =~ /""/ || $line =~ /''/)) {
      die "$file: Failed to match news ID to new path. OLD \n$old_line\nNEW\n$line";
    }

    $line =~ s!(("|')(http://(www\.)?cwinters\.com)?/blog)!!g;

    print OUT $line;
  }
}

sub scan_tags {
  my ($file) = @_;
  open(IN, $file) || die "Cannot read $file: $!";
  my @tags = ();
  while (<IN>) {
    next unless /^<!\-\-\s*Tags:\s*(.*)\s*\-\->\s*$/;
    @tags = split(/;\s*/, $1);
    for (@tags) {
      s/^\s+//;
      s/\s+$//;
      s/\s/\-/g;
    }
    last;
  }
  close(IN);
  my @spaced = grep(/\s/, @tags);
  return @tags;
}

