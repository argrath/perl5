#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}
use strict;

require './test.pl';

plan(4);

like(runperl(switches => ['-Irun/flib', '-Mbroken'], stderr => 1),
     qr/^Global symbol "\$x" requires explicit package name at run\/flib\/broken.pm line 6\./,
     "Ensure -Irun/flib produces correct filename in warnings");

like(runperl(switches => ['-Irun/flib/', '-Mbroken'], stderr => 1),
     qr/^Global symbol "\$x" requires explicit package name at run\/flib\/broken.pm line 6\./,
     "Ensure -Irun/flib/ produces correct filename in warnings");

like(runperl(switches => ['-Irun/flib', '-Mt2', '-e "print t2::id()"'], stderr => 1),
     qr/^t2pmc$/,
     "Ensure -Irun/flib loads pmc");

like(runperl(switches => ['-Irun/flib/', '-Mt2', '-e "print t2::id()"'], stderr => 1),
     qr/^t2pmc$/,
     "Ensure -Irun/flib/ loads pmc");
