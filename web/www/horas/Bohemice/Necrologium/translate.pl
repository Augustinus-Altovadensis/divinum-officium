#!/usr/bin/perl

use utf8;
use open ':std', ':encoding(UTF-8)';

# Module for processing hour scripts.
package horas::Scripting;
use strict;
use warnings;
use Carp;
use Attribute::Handlers;

my $Bin = "../../../../cgi-bin/horas/" ;

BEGIN {
  require Exporter;
  our $VERSION = 1.00;
  our @ISA = qw(Exporter);
  our @EXPORT_OK = qw(
    dispatch_script_function
    parse_script_arguments);
}
use FindBin qw($Bin);
#use lib "$Bin/..";
my %script_functions;
my @deferred_functions;

#use warnings;
#use strict;

#$Bin = "../../../../cgi-bin/horas/" ;

#use "$Bin/Scripting.pm";

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

sub register_script_function {
  my ($function_name, $code_ref, %params) = @_;
  $script_functions{$function_name}{$params{'short'} ? 'shortfunc' : 'func'} = $code_ref;
}

sub UNIVERSAL::ScriptFunc : ATTR(CODE,BEGIN) {&script_attr_handler}
sub UNIVERSAL::ScriptShortFunc : ATTR(CODE,BEGIN) {&script_attr_handler}

sub script_attr_handler {
  my ($pkg, $symbol_ref, $code_ref, $attr, $name_override) = @_;
  my %params = ('short' => ($attr eq 'ScriptShortFunc'));

  if ($name_override || ref($symbol_ref) eq 'GLOB') {
    register_script_function($name_override || *{$symbol_ref}{NAME}, $code_ref, %params);
  } else {

    # Older perls fire the attribute handler before the sub is placed in the
    # symbol table, with the effect that we can't get the sub's name yet. Defer
    # the actual registration till later.
    push @deferred_functions, {
      'package' => $pkg,
      'code' => $code_ref,
      'params' => \%params
      };
  }
}


