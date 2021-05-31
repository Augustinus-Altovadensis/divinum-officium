#!/usr/bin/perl
use utf8;
use open ':std', ':encoding(UTF-8)';

#use warnings;
#use strict;

my $Bin = "/Users/jirka/Documents/GitHub/divinum-officium/web/cgi-bin/horas/" ;
require "$Bin/altovadum.pl" ;


my $filename = $ARGV[0];
my $i = 0;
my $line;

open(FH, '<', $filename) or die $!;

while(<FH>){
	$line = $_;

	$line = translate_cz ( "$line" );

	print $line;
   	#$i++;
   	#if ( $i > 30 ) { last; }
}

close(FH);
