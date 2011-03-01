#!/usr/bin/perl -w

###############################################################################
# cvs_read_all_generate.pl
#
# Copyright (c) 2006 Frank Bergmann
# All rights reserved.
#
# This program is free software; you can redistribute it and modify it under
# the terms of the GPL.

$cvs_root = "/var/cvs/cvsroot/";

$read_all_file = "cvs_read_all.bash";

$command = "ls -1 $cvs_root";
open (PROJS, "$command |") || die "Couldn't execute \"$command\"";
open (T, "> $read_all_file") || die "Couldn't write to \"$read_all_file\"";


while ($line = <PROJS>) {
    chomp($line);
    if ($line =~ /\#/) { next; }

    print T "./cvs_read.pl -cvsdir $cvs_root -rlog $line\n";
}

close(T);
close(PROJS);
print "\n";
