#!/usr/bin/perl

use strict;
use v5.14;
use utf8;
use File::Find::Rule;

my $dest = 'ghpages-flat';
mkdir $dest unless -d $dest;
my $rule = File::Find::Rule->file()->name('*.md');
foreach my $file ( $rule->in('ghpages/blog') ) {
  my @pieces = split('/', $file);
  my $name = pop(@pieces);
  next if ($name eq 'index.md');
  shift @pieces; shift @pieces; # remove 'ghpages' and 'blog'
  my $new_name = join('-', @pieces, $name);
  open(IN, $file) || die "Cannot read $file: $!";
  binmode(IN, ":encoding(UTF-8)");
  open(OUT, '>', "$dest/$new_name") || die "Cannot write to $dest/$new_name: $!";
  binmode(OUT, ":encoding(UTF-8)");

  my $headers_removed = 0;
  while (<IN>) {
    my $line = $_;
    if ($line =~ /<h1>/) {
      $headers_removed++;
      next;
    }
  
    next if $line =~ /^<!\-\- Tags/;
    next if $line =~ /^<!\-\-#include/;
    if ($line =~ /class="post\-footer/) {
      my $date_line = <IN>;
      my $date_close = <IN>;
      next;
    }

    #$line =~ s/’/'/g;
    
    print OUT $_;
  }
  if ($headers_removed > 1) {
    print "HEADERS $headers_removed: $file";
  }
}

