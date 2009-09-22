#!/usr/bin/perl -w

###############################################################################
# cvs_read.pl
#
# This file is based on the cvsplot.pl script of David Sitsky.
# We have extended his script to include an interface for the 
# ]project-open[ database.
#
# Copyright (c) 2001, 2002, 2003, 2004 David Sitsky.
# Copyright (c) 2006 Frank Bergmann
# All rights reserved.
#
# cvs_read.pl is a perl script which is used to extract information from CVS and
# plots the total number of lines and number of files in a selected file set
# against time.
#
# File sets can be specified using regular expressions.
# The start and end dates may also be specified.
#
# This program is free software; you can redistribute it and modify it under
# the terms of the GPL.

use Config;
use Cwd;
use Symbol;
use IPC::Open3;
use DBI;
use String::ShellQuote;

# Whether debugging is enabled or not.
$debug = 0;

# Additional global arguments to use with CVS commands.
$cvs_global_args = "";

# The start date in which to gather statistics.
$start_date = "2008-01-01";

# The final date in which to gather statistics.
$end_date = "";

# Indicate whether to count the number of lines _changed_, or the
# the number of lines added.
$count_lines_changed = 0;

# The directory is which to gather the cvs statistics (where the cvs log
# command is run from), or the directory of the CVS repository, if the
# -rlog option is used.
$cvsdir = "";

# The module to run cvs rlog over, if the -rlog option is specified.
$rlog_module = "";

# Determine if this process is running under Windows.
$osname = $Config{'osname'};
$windows = (defined $osname && $osname eq "MSWin32") ? 1 : 0;



# --------------------------------------------------------
# Prepare Activitiy
process_command_line_arguments();

# Main Activitiy
get_cvs_statistics2();



###############################################################################
# Utility method for quoting an argument for a shell command.  ShellQuote
# is good for UNIX boxes, but doesn't work for DOS platforms as it uses
# single quotes, while DOS needs double quotes.  Its a shame shell_quote
# isn't cross-platform.
sub quote
{
    my ($arg) = @_;

    if ($windows)
    {
        return "\"$arg\"";
    }
    else
    {
        String::ShellQuote::shell_quote($arg);
    }
}

###############################################################################
# Using "cvs log" and a few other commands, gather all of the necessary
# statistics.
#
sub get_cvs_statistics2
{
    # Explicitly set the timezone for window platforms, so that DateManip works.
    if ($windows) { $ENV{TZ} = "C"; }

    my $working_file = "";
    my $relative_working_file = "";
    my $working_cvsdir = "";
    my $search_file = 0;

    # Change to the directory nominated by $cvsdir, and save the current
    # directory, only if we aren't using the -rlog option.
    if ($rlog_module eq "") {
	$saved_cwd = cwd();
	chdir $cvsdir || die "Failed to change to directory \"$cvsdir\": $!";
    } else {
	# Remove the accessor part, and just get the pathname.
	$cvsdir =~ /([^:]+)$/;
	$working_cvsdir = $1;
	print "Got working_cvsdir as $working_cvsdir\n" if $debug;

	# Since this is used in a regexp below, need to make sure DOS pathnames
	# are correctly matched against.
	$working_cvsdir =~ s/\\/\\\\/g;
    }

    # Flag to indicate what the state is when parsing the output from cvs log.
    # true indicates that the parser is waiting for the start of a cvs log
    # entry.
    $search_file = 1;

    # Build up the command string appropriately, depending on what options
    # have been set.
    my $command = ($rlog_module eq '') ? "cvs $cvs_global_args log" :
	sprintf("cvs $cvs_global_args -q -d %s rlog %s", quote($cvsdir), quote($rlog_module));

    print "Executing \"$command\"\n" if $debug;
    open (CVSLOG, "$command |") || die "Couldn't execute \"$command\"";


    $content = "";
    while (<CVSLOG>)
    {
	if (/^=============================================================================$/) {
	    parse_cvs_file($content);
	    $content = "";
	} else {
	    $content .= $_;
	}
    }
    close(CVSLOG);

    # Go back to the original directory if we aren't using the -rlog option.
    if ($rlog_module eq "")
    {
	chdir $saved_cwd;
    }
}



###############################################################################
# Method for writing out help if modules are missing.
sub parse_cvs_file
{
    my ($content) = @_;

    my $working_file = ""; 
    my $relative_working_file = "";

    @pieces = split("----------------------------", $content);

    @pieces = reverse(@pieces);
    $head = pop(@pieces);

    if ($head =~ /RCS file: (.*),v/) {
	$working_file = $1;
	$working_file =~ s/Attic\///g;
	$relative_working_file = "";
    }
    
    @pieces = reverse(@pieces);
    foreach $descr (@pieces) {

	my $comment = "";
	my $date = "";
	my $author = "";
	my $state = "";
	my $revision = "";
	my $lines_added = "";
	my $lines_removed = "";
	my $rest = "";
	my $branches = "";

#	if ($descr =~ /date: ([\d\/]+) ([\d\:]+)\;/) { $date = "$1 $2";	}
#	if ($descr =~ /author: ([\w]+)\;/) { $author = $1; }
#	if ($descr =~ /state: ([\w]+)\;/) { $state = $1; }
#	if ($descr =~ /^revision ([\d\.]+)/) { $revision = $1; }
	
	my @lines = split("\n", $descr);
	foreach $line (@lines) {

	    if ($line =~ /^revision ([\d\.]+)$/) {

		$revision = $1;
		print "> revision = $revision\n" if $debug;
		
	    } elsif ($line =~ /^branches:\s*([\S]+);/) {

		# branches:  1.1.2;
		$branches = $1;
		print "> branches: $branches\n" if $debug;

	    } elsif ( $line =~ /^date: (\d\d\d\d\/\d\d\/\d\d \d\d:\d\d:\d\d);.*?author: (.*);.*?state: (\w*);(.*)$/) {
		
		# date: 2005/08/05 17:54:48;  author: cvs;  state: dead;
		$date = $1;
		$author = $2;
		$state = $3;
		$rest = $4;

		if ($rest =~ /.*?lines: \+([\d]+) \-([\d]+)/) {
		    $lines_added = $1;
		    $lines_removed = $2;
		}

		print "> date: $date; author: $author; state: $state; rest: lines: +$lines_added -$lines_removed\n" if $debug;
		
	    } else {
		$comment .= "$line\n";
	    }
	}

	if ("" eq $lines_added) { $lines_added = 0; }
	if ("" eq $lines_removed) { $lines_removed = 0; }

	$comment =~ s/\n/\\n/g;
	$comment =~ s/\t/\\t/g;

	print "$working_file	$rlog_module	$revision	$date	$author	$state	$lines_added	$lines_removed	$comment\n";
    }	
}



###############################################################################
# Process the command line arguments and perform sanity checks.
#
sub process_command_line_arguments
{
    for ($i = 0; $i <= $#ARGV; )
    {
	if ($ARGV[$i] eq "-debug")
	{
	    $debug = 1;
	    $i++;
	}
	elsif ($ARGV[$i] eq "-cvs-global-args")
	{
	    $cvs_global_args = $ARGV[$i+1];
	    $i += 2;
	}
	elsif ($ARGV[$i] eq "-countchangedlines")
	{
	    $count_lines_changed = 1;
	    $i++;
	}
	elsif ($ARGV[$i] eq "-start")
	{
	    $start_date = Date::Manip::ParseDate($ARGV[$i+1]);
	    $i += 2;
	}
	elsif ($ARGV[$i] eq "-end")
	{
	    $end_date = Date::Manip::ParseDate($ARGV[$i+1]);
	    $i += 2;
	}
        elsif ($ARGV[$i] eq "-cvsdir")
        {
            $cvsdir = $ARGV[$i+1];
            $i += 2;
        }
	elsif ($ARGV[$i] eq "-rlog")
	{
	    $rlog_module = $ARGV[$i+1];
	    $i += 2;
	}
	else
	{
	    print "Unrecognized option: $ARGV[$i]\n";
	    usage();
	}
    }


    # Check the mandatory arguments have been set.
    if ($cvsdir eq "")
    {
	print "error: Not all mandatory arguments specified.\n\n";
	usage();
    }


    # If both the start and end dates are specified, check that the start date
    # occurs before the end date.
    if ($start_date ne "" && $end_date ne "" &&
	&Date_Cmp($start_date, $end_date) >= 0)
    {
	print "error: Start date specified must occur before the end date.\n\n";
	usage();
    }

    # If the -rlog option has been specified, need to make sure that the
    # CVS version install is >= 1.11.1, as it is not supported in earlier
    # versions.
    if ($rlog_module ne "")
    {
	my $WTR = gensym();
	my $RDR = gensym();
	my $ERR = gensym();
	my $pid = open3($WTR, $RDR, $ERR, "cvs $cvs_global_args rlog");
	my $deprecated_found = 0;
        while (<$ERR>)
        {
            $deprecated_found = 1 if (/deprecated/);
        }
        close $WTR;
        close $RDR;
        close $ERR;
        waitpid $pid, 0;
	if ($deprecated_found)
        {
	    print "error: -rlog option requires CVS version >= 1.11.1\n\n";
	    exit 1;
        }
    }
}
	    
###############################################################################
# Print out a usage message.
#
sub usage
{
    print "cvs_read version 1.0 - ";
    print "Copyright David Sitsky, Frank Bergmann\n\n";
    print "cvs_read reads statistics from CVS and writes it to a ]po[ database.\n\n";
    print "usage:\n";
    print "cvs_read.pl -cvsdir <dir> [-rlog <module>]\n";
    print "\nExample:\n";
    print "cvs_read.pl -cvsdir :pserver:anonymous\@cvs.project-open.net:/home/cvsroot -rlog intranet-hr\n";
    print "            \n\n";
    exit 1;
}
