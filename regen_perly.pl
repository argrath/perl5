#!/usr/bin/perl
#
# regen_perly.pl, DAPM 12-Feb-04
#
# Copyright (c) 2004, 2005 Larry Wall
#
# Given an input file perly.y, run bison on it and produce
# the following output files:
#
# perly.h	standard bison header file with minor doctoring of
#		#line directives plus adding a #ifdef PERL_CORE
#
# perly.tab	the parser table C definitions extracted from the bison output
#
# perly.act	the action case statements extracted from the bison output
#
# Note that perly.c is *not* regenerated - this is now a static file which
# is not dependent on perly.y any more.
#
# If a filename of the form foo.y is given on the command line, then
# this is used instead as the basename for all the files mentioned
# above.
#
# Note that temporary files of the form perlytmp.h and perlytmp.c are
# created and then deleted during this process
#
# Note also that this script is intended to be run on a UNIX system;
# it may work elsewhere but no specific attempt has been made to make it
# portable.

sub usage { die "usage: $0 [ -b bison_executable ] [ file.y ]\n" }

use warnings;
use strict;

my $bison = 'bison';

if (@ARGV >= 2 and $ARGV[0] eq '-b') {
    shift;
    $bison = shift;
}

my $y_file = shift || 'perly.y';

usage unless @ARGV==0 && $y_file =~ /\.y$/;

(my $h_file    = $y_file) =~ s/\.y$/.h/;
(my $act_file  = $y_file) =~ s/\.y$/.act/;
(my $tab_file  = $y_file) =~ s/\.y$/.tab/;
(my $tmpc_file = $y_file) =~ s/\.y$/tmp.c/;
(my $tmph_file = $y_file) =~ s/\.y$/tmp.h/;

# the yytranslate[] table generated by bison is ASCII/EBCDIC sensitive

die "$0: must be run on an ASCII system\n" unless ord 'A' == 65;

# check for correct version number. The constraints are:
#  * must be >= 1.24 to avoid licensing issues.
#  * it must generate the yystos[] table. Version 1.28 doesn't generate
#    this; 1.35+ does
#  * Must produce output which is extractable by the regexes below
#  * Must produce the right values.
# These last two contstraints  may well be met by earlier versions, but
# I simply haven't tested them yet. If it works for you, then modify
# the test below to allow that version too. DAPM Feb 04.

my $version = `$bison -V`;
unless ($version =~ /\b(1\.875[a-z]?|2\.0)\b/) { die <<EOF; }

You have the wrong version of bison in your path; currently 1.875
or 2.0 is required.  Try installing
    http://ftp.gnu.org/gnu/bison/bison-2.0.tar.gz
or
    http://ftp.gnu.org/gnu/bison/bison-1.875.tar.bz2
or similar.  Your bison identifies itself as:

$version
EOF

# creates $tmpc_file and $tmph_file
my_system("$bison -d -o $tmpc_file $y_file");

open CTMPFILE, $tmpc_file or die "Can't open $tmpc_file: $!\n";
my $clines;
{ local $/; $clines = <CTMPFILE>; }
die "failed to read $tmpc_file: length mismatch\n"
    unless length $clines == -s $tmpc_file;
close CTMPFILE;

my ($actlines, $tablines) = extract($clines);

chmod 0644, $act_file;
open ACTFILE, ">$act_file" or die "can't open $act_file: $!\n";
print ACTFILE $actlines;
close ACTFILE;
chmod 0444, $act_file;

chmod 0644, $tab_file;
open TABFILE, ">$tab_file" or die "can't open $tab_file: $!\n";
print TABFILE $tablines;
close TABFILE;
chmod 0444, $tab_file;

unlink $tmpc_file;

# Wrap PERL_CORE round the symbol definitions. Also,  the
# C<#line 123 "perlytmp.h"> gets picked up by make depend, so change it.

open TMPH_FILE, $tmph_file or die "Can't open $tmph_file: $!\n";
chmod 0644, $h_file;
open H_FILE, ">$h_file" or die "Can't open $h_file: $!\n";
my $endcore_done = 0;
while (<TMPH_FILE>) {
    print H_FILE "#ifdef PERL_CORE\n" if $. == 1;
    if (!$endcore_done and /YYSTYPE_IS_DECLARED/) {
	print H_FILE "#endif /* PERL_CORE */\n";
	$endcore_done = 1;
    }
    s/"perlytmp.h"/"perly.h"/;
    print H_FILE $_;
}
close TMPH_FILE;
close H_FILE;
chmod 0444, $h_file;
unlink $tmph_file;

print "rebuilt:  $h_file $tab_file $act_file\n";

exit 0;


sub extract {
    my $clines = shift;
    my $tablines;
    my $actlines;

    $clines =~ m@
	(?:
	    ^/* YYFINAL[^\n]+\n		#optional comment
	)?
	\# \s* define \s* YYFINAL	# first #define
	.*?				# other defines + most tables
	yystos\[\]\s*=			# start of last table
	.*?
	}\s*;				# end of last table
    @xms
	or die "Can't extract tables from $tmpc_file\n";
    $tablines = $&;


    $clines =~ m@
	switch \s* \( \s* \w+ \s* \) \s* { \s*
	(
	    case \s* \d+ \s* : \s*
	    \#line [^\n]+"perly\.y"
	    .*?
	)
	}
	\s*
	( \s* /\* .*? \*/ \s* )*	# optional C-comments
	\s*
	(
	    \#line[^\n]+\.c"
	|
	    \#line[^\n]+\.simple"
	)
    @xms
	or die "Can't extract actions from $tmpc_file\n";
    $actlines = $1;

    return $actlines. "\n", $tablines. "\n";
}

sub my_system {
    system(@_);
    if ($? == -1) {
	die "failed to execute comamnd '@_': $!\n";
    }
    elsif ($? & 127) {
	die sprintf "command '@_' died with signal %d\n",
	    ($? & 127);
    }
    elsif ($? >> 8) {
	die sprintf "command '@_' exited with value %d\n", $? >> 8;
    }
}
