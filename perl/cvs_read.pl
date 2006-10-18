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
# cvsplot is a perl script which is used to extract information from CVS and
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

# Whether debugging is enabled or not.
$debug = 0;

# Additional global arguments to use with CVS commands.
$cvs_global_args = "";

# The start date in which to gather statistics.
$start_date = "";

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

# The branch that we are collecting statistics from.  By default, the main
# branch is used.
$branch_tag = "";

# Parallel arrays of file patterns which indicate whether it is an include
# or exclude pattern, and what the regular expression is.
@pattern_include = ();
@pattern_regexp = ();



# --------------------------------------------------------
# Database Connection Parameters

$db_datasource = "dbi:Pg:dbname=projop";
$db_username = "projop";
$db_pwd = "";


# A hash (by filename) of a hash (by version) of lines added.
%file_version_delta = ();

# A hash (by filename) of a hash (by version) of the file state.
%file_version_state = ();

# A hash (by filename) of a hash (by version) of the author.
%file_version_author = ();

# A hash (by filename) of the magic branch number.
%file_branch_number = ();

# A hash (by filename) of the number of branch revisions made.
%file_number_branch_revisions = ();

# Determine if this process is running under Windows.
$osname = $Config{'osname'};
$windows = (defined $osname && $osname eq "MSWin32") ? 1 : 0;



# --------------------------------------------------------
# Establish the database connection
# The parameters are defined in common_constants.pm
$dbh = DBI->connect($db_datasource, $db_username, $db_pwd) ||
    die "cvs_read: Unable to connect to database.\n";


# --------------------------------------------------------
# Main Activitiy

check_missing_modules();
process_command_line_arguments();
get_cvs_statistics2();


# --------------------------------------------------------
# Disconnect from DB
$dbh->disconnect();




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
# Method for writing out help if modules are missing.
sub check_missing_modules
{
    my @missing = ();

    # Load the Date::Manip module.
    eval
    {
	require Date::Manip;
    };
    if ($@)
    {
	push @missing, 'Date::Manip';
    }

    # Load the String::ShellQuote module for UNIX platforms.
    eval
    {
	if (! $windows)
	{
	    require String::ShellQuote;
	}
    };
    if ($@)
    {
	push @missing, 'String::ShellQuote';
    }
    
    # Check if there are any missing modules.
    return if $#missing == -1;

    # First, output the generic "missing module" message.
    print "\n";
    print "Cvsplot requires some Perl modules which are missing " .
	  "from your system.\n";

    if ($windows) {
	print "These can be installed by issuing the following commands:\n\n";
	foreach my $module (@missing) {
	    $module =~ s/:://g;
	    print 'C:\> ' . "ppm install $module\n";
	}
	print "\n";
    }
    else
    {
	print "They can be installed by running (as root) the following:\n";
	foreach my $module (@missing) {
	    print "   perl -MCPAN -e 'install \"$module\"'\n";
	}
	print "\n";
	print "Modules can also be downloaded from http://www.cpan.org.\n\n";
    }
    exit;
}


###############################################################################
# Check whether the supplied file is to be examined or not depending on what
# the user set for the -include and -exclude options.  Return true if the
# file is to be included.  If no -include or -exclude options have been
# set by the user, return true by default.
#
sub include_file
{
    my ($filename) = @_;

    # If there are no settings, include everything.
    if ($#pattern_regexp == -1)
    {
	return 1;
    }

    # Go through the pattern_regexp array, and see if there is any matches.
    for ($i = 0; $i <= $#pattern_regexp; $i++)
    {
	if ($filename =~ /$pattern_regexp[$i]/)
	{
	    # Got a match, return whether or not the file should be included
	    # or not.
	    return $pattern_include[$i];
	}
    }

    # No matches, don't include this file.
    return 0;
}





###############################################################################
# Using "cvs log" and a few other commands, gather all of the necessary
# statistics.
#
sub get_cvs_statistics
{
    if ($debug && defined $osname)
    {
        print "Platform is $osname\n";
    }

    # Explicitly set the timezone for window platforms, so that DateManip
    # works.
    if ($windows)
    {
        $ENV{TZ} = "C";
    }

    my $working_file = "";
    my $relative_working_file = "";
    my $working_cvsdir = "";
    my $search_file = 0;

    # Change to the directory nominated by $cvsdir, and save the current
    # directory, only if we aren't using the -rlog option.
    if ($rlog_module eq "")
    {
	$saved_cwd = cwd();
	chdir $cvsdir || die "Failed to change to directory \"$cvsdir\": $!";
    }
    else
    {
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

    # Initialize comment part
    $comment = "";

    # Build up the command string appropriately, depending on what options
    # have been set.
    my $command = ($rlog_module eq '') ? "cvs $cvs_global_args log" :
	sprintf("cvs $cvs_global_args -d %s rlog %s",
		quote($cvsdir), quote($rlog_module));

    print "Executing \"$command\"\n" if $debug;

    open (CVSLOG, "$command |") || die "Couldn't execute \"$command\"";
    while (<CVSLOG>)
    {
	if ($search_file == 1)
	{
	    # Need to locate the name of the working file
	    if (/^RCS file: (.*),v$/)
	    {
		$working_file = $1;
		$working_file =~ s/Attic\///g;
		$relative_working_file = "";

		# Check if this file is to be included or not.
		if (include_file($working_file))
		{
		    # Yep, search for more details on this file.
		    $search_file = 0;

		    if ($branch_tag eq "")
		    {
			# Main branch to be investigated only.
			$file_branch_number{$working_file} = "1";
			$file_number_branch_revisions{$working_file} = 0;
		    }
		    print "Including file \"$working_file\"\n" if $debug;
		}
		else
		{
		    print "Excluding file \"$working_file\"\n" if $debug;
		}
	    }
	}
	else
	{
	    # Collective the relative part for those runs that don't use
	    # -rlog.
	    if (/^Working file: (.*)$/)
	    {
		$relative_working_file = $1;
	    }
	    # Handle repositories working off an explicit numbering scheme,
	    # such as 8.1.  Only do this if the user hasn't specified an
	    # explicit branch to gather statistics over.  In most cases,
	    # the result will still be 1, but this handles the stranger
	    # repositories out there.
	    elsif ($branch_tag eq "" && /^head: (\d+)\./) {
		$file_branch_number{$working_file} = $1;       
	    }
	    # If we are collecting statistics on a branch, determine the magic
	    # branch number for this file.
	    elsif ( (! defined $file_branch_number{$working_file}) &&
		 (/^\s*${branch_tag}: ([\d\.]+)\.0\.(\d+)$/) )
	    {
		$file_branch_number{$working_file} = "${1}.${2}";
		$file_number_branch_revisions{$working_file} = 0;
		if ($debug)
		{
		    print "Got branch $file_branch_number{$working_file}";
		    print " for file \"$working_file\"\n";
		}
	    }
	    elsif (/^keyword substitution: b$/)
	    {
		# This is a binary file, ignore it.
		undef($file_branch_number{$working_file});
		undef($file_number_branch_revisions{$working_file});
		$search_file = 1;
		print "Excluding binary file \"$working_file\"\n" if $debug;
	    }
	    elsif (/^=============================================================================$/)
	    {
		# End of the log entry for this file, start parsing for the
		# next file.
		$search_file = 1;
		next;
	    }
	    elsif (/^----------------------------$/)
	    {
		print "----------------------------\n";
		$comment = "";

		# Matched the description separator.  If a branch has been
		# specified, but this file doesn't exist on it, skip this file.
		if (($branch_tag ne "") &&
		    (! defined $file_branch_number{$working_file}))
		{
		    if ($debug)
		    {
			print "File \"$working_file\" not on branch\n";
		    }
		    $search_file = 1;
		    next;
		}

		# Read the revision line, and record the appropriate
		# information.
		$_ = <CVSLOG>;

		if (/^revision ([\d\.]+)$/)
		{
		    # Record the revision, and whether it is part of the tag
		    # of interest.
		    $revision = $1;
		    if ($revision =~
			/^$file_branch_number{$working_file}\.\d+$/)
		    {
			$file_on_branch = 1;
			$file_number_branch_revisions{$working_file}++;
		    }
		    else
		    {
			$file_on_branch = 0;
		    }
		    if ($debug)
		    {
			print "Got branch number: $file_branch_number{$working_file} rev $revision on branch: $file_on_branch\n";
		    }
		}
		else
		{
		    # Problem in parsing, skip it.
		    print "Couldn't parse line: $_\n";
		    $search_file = 1;
		    next;
		}
		    
		$_ = <CVSLOG>;		# Read the "date" line.
		if (/^date: (\d\d\d\d\/\d\d\/\d\d \d\d:\d\d:\d\d); .* author: (.*); .* state: (.*);.*lines: \+(\d+) \-(\d+).*$/)
		{
		    # Note for some CVS clients, state dead is presented in
		    # this this way, as the following pattern.
		    $date = $1;
		    $author = $2;
		    $users{$author} = 1;
		    $state = $3;
		    $lines_added = $4;
		    $lines_removed = $5;

		    if ("" eq $lines_added) { $lines_added = 0; }
		    if ("" eq $lines_removed) { $lines_removed = 0; }

		    # This revision lives on the branch of interest.
		    if ($file_on_branch)
		    {
			$sql = qq { INSERT INTO im_cvs_activity (
				line_id, 
				filename, cvs_project,
				revision, date,
				author, state, lines_add, lines_del,
				note
			   ) values (
				nextval('im_cvs_activity_line_seq'),
				'$working_file', '$rlog_module',
				'$revision',
				'$date'::timestamp,
				'$author',
				'$state',
				$lines_added,
				$lines_removed,
				'$comment'
			) };
			$dbh->do($sql) || print "cvs_read: Error executing '$sql'\n";
		    }
	        }
		elsif (/^date: (\d\d\d\d\/\d\d\/\d\d \d\d:\d\d:\d\d); .* author: (.*); .* state: dead;.*$/)
		{
		    # File has been removed.
		    $date = $1;
		    $author = $2;
		    $users{$author} = 1;

		}
		elsif (/^date: (\d\d\d\d\/\d\d\/\d\d \d\d:\d\d:\d\d); .* author: (.*); .* state: ([^;]*);.*$/)
		{
		    $date = $1;
		    $author = $2;
		    $users{$author} = 1;
		    $state = $3;

		    $lines_added = 0;
		    $lines_removed = 0;

		    # Unfortunately, cvs log doesn't indicate the number of
		    # lines an initial revision is created with, so find this
		    # out using the following cvs command.  Note the regexp
		    # below has an optional drive delimeter to support DOS
		    # installations.
		    my $lccmd = "";
		    if ($rlog_module ne "")
		    {
			print "Working cvsdir is: $working_cvsdir working file: $working_file\n" if $debug;

			# For DOS-based repositories, the filename may contain
			# a drive letter.  Also need to be flexible with the
			# pathname separator.
			if (! ($working_file =~ /^([A-z]:)?${working_cvsdir}[\/\\](.*)$/))
			{
			    print STDERR "-cvsdir argument $working_cvsdir doesn't match ";
			    print STDERR "repository filename prefix $working_file\n";
			    print STDERR "Please correct your -cvsdir argument and try again\n";
			    exit 1;
			}
			$lccmd = sprintf("cvs $cvs_global_args -d %s co -r %s -p %s",
					 quote($cvsdir),
					 quote($revision),
					 quote($2));
		    }
		    else
		    {
			$lccmd = sprintf("cvs $cvs_global_args update -r %s -p %s",
					 quote($revision),
					 quote($relative_working_file));
		    }
		    print "Executing $lccmd\n" if $debug;
		    
		    my $WTR = gensym();
		    my $RDR = gensym();
		    my $ERR = gensym();
		    my $pid = open3($WTR, $RDR, $ERR, $lccmd);
		    for ($number_lines = 0; defined <$RDR>; $number_lines++) {}
		    close ($RDR);
		    my $error_string = "";
		    while (<$ERR>)
		    {
			$error_string .= $_;
		    }
		    waitpid $pid, 0;
		    
		    if ($?) {
			print "CVS command failed: \"$lccmd\" status $?\n";
			print "$error_string\n";
			exit 1;
		    }
		    
		    print "$working_file 1.1 = $number_lines lines\n" if $debug;
		    
		    $file_version_delta{$working_file}{$revision} =
			$number_lines;
		    $file_version_state{$working_file}{$revision} = $state;
		    $file_version_author{$working_file}{$revision} = $author;

		    if ("" eq $lines_added) { $lines_added = 0; }
		    if ("" eq $lines_removed) { $lines_removed = 0; }

		    # This revision lives on the branch of interest.
		    if ($file_on_branch)
		    {
			$sql = qq { INSERT INTO im_cvs_activity (
				line_id, 
				filename, cvs_project,
				revision, date,
				author, state, lines_add, lines_del,
				note
			   ) values (
				nextval('im_cvs_activity_line_seq'),
				'$working_file', '$rlog_module',
				'$revision',
				'$date'::timestamp,
				'$author',
				'$state',
				'$lines_added',
				'$lines_removed',
				'$comment'
			) };
			$dbh->do($sql) || print "cvs_read: Error executing '$sql'\n";
		    }
		}
		else
		{
		    print "Couldn't parse date line: $_";
		}
	    } else {
		print "Comment: $_";
		$comment .= $_;
	    }
	     
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
	sprintf("cvs $cvs_global_args -d %s rlog %s",
		quote($cvsdir), quote($rlog_module));

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
    @pieces = split("----------------------------", $content);
    print "======================================\n";

    @pieces = reverse(@pieces);
    $head = pop(@pieces);

    if ($head =~ /RCS file: (.*),v/) {
	$working_file = $1;
	$working_file =~ s/Attic\///g;
	$relative_working_file = "";
    }
    print "working_file = $working_file\n";
    print "------------------------------------------------------------";

    
    @pieces = reverse(@pieces);

    foreach $descr (@pieces) {

	my @lines = split("\n", $descr);

	foreach $line (@lines) {

	    if ($line =~ /^revision ([\d\.]+)$/) {
		# Record the revision, and whether it is part of the tag of interest.
		$revision = $1;
		print "revision = $revision\n";
	    }
	    
	    elsif (/^date: (\d\d\d\d\/\d\d\/\d\d \d\d:\d\d:\d\d); .* author: (.*); .* state: (.*);.*lines: \+(\d+) \-(\d+).*$/) {
		    # Note for some CVS clients, state dead is presented in
		    # this this way, as the following pattern.
		    $date = $1;
		    $author = $2;
		    $users{$author} = 1;
		    $state = $3;
		    $lines_added = $4;
		    $lines_removed = $5;

		    if ("" eq $lines_added) { $lines_added = 0; }
		    if ("" eq $lines_removed) { $lines_removed = 0; }

		    # This revision lives on the branch of interest.
		    if ($file_on_branch)
		    {
			$sql = qq { INSERT INTO im_cvs_activity (
				line_id, 
				filename, cvs_project,
				revision, date,
				author, state, lines_add, lines_del,
				note
			   ) values (
				nextval('im_cvs_activity_line_seq'),
				'$working_file', '$rlog_module',
				'$revision',
				'$date'::timestamp,
				'$author',
				'$state',
				$lines_added,
				$lines_removed,
				'$comment'
			) };
			$dbh->do($sql) || print "cvs_read: Error executing '$sql'\n";
		    }
	        }












	}

	print "---------------------------\n";
	
    }

    print "======================================\n";

}










# Variable to store results when calling get_line_count.
%memorise_line_count = ();


###############################################################################
# Return the number of lines that constitute a particular revision of a file.
#
sub get_line_count
{
    my ($filename, $revision) = @_;

    my $count = get_line_count_inner($filename, $revision);

    # Store this result for future intermediate calculations.
    $memorise_line_count{$filename}{$revision} = $count;

    if ($debug)
    {
	print "get_line_count($filename, $revision) = $count\n";
    }

    return $count;
}

sub get_line_count_inner
{
    my ($filename, $revision) = @_;
    my $count = 0;
    my $finished = 0;

    while (!$finished)
    {
	if (defined $memorise_line_count{$filename}{$revision})
	{
	    $count += $memorise_line_count{$filename}{$revision};
	    $finished = 1;
	}
	elsif (! defined($file_version_state{$filename}{$revision}))
	{
	    # Case where we are looking for a revision that hasn't
	    # been found in the output of the CVS log command. This is
	    # usually because a developer decided to start the file
	    # revision at something other than 1.1.
	    $memorise_line_count{$filename}{$revision} = 0;
	    $finished = 1;
	}
	elsif ($revision eq "1.1")
	{
	    # Base case where the revision is 1.1
	    $memorise_line_count{$filename}{$revision} =
		$file_version_delta{$filename}{$revision};
	    $count += $memorise_line_count{$filename}{$revision};
	    $finished = 1;
	}
	elsif ($file_version_state{$filename}{$revision} eq "dead")
	{
	    # Case where file has been removed.  The file count is
	    # effectively the previous version's count.
	    $revision =~ /^([\d\.]+)\.(\d+)$/;
	    $previous_subrevision = $2 - 1;
	    $previous_revision = "${1}.${previous_subrevision}";
	    $revision = $previous_revision;
	}
	elsif ($revision =~ /^([\d\.]+)\.\d+\.1$/)
	{
	    # Case where need to decend down branch point and find the
	    # contributions made there.
	    $branch_point_revision = $1;
	    if (! defined($file_version_delta{$filename}{$revision}))
	    {
		print "file_version_data not defined for $filename $revision\n";
	    }
	    $count += $file_version_delta{$filename}{$revision};
	    $revision = $branch_point_revision;
	}
	elsif ($revision =~ /^([\d\.]+)\.(\d+)$/)
	{
	    # Need to determine previous revision number + this revision's
	    # contribution.
	    $previous_subrevision = $2 - 1;
	    $previous_revision = "${1}.${previous_subrevision}";
	    if (! defined($file_version_delta{$filename}{$revision}))
	    {
		print "[2] file_version_data not defined for $filename $revision\n";
	    }
	    $count += $file_version_delta{$filename}{$revision};
	    $revision = $previous_revision;
	}
	else
	{
	    print "Unhandled case for file $filename revision $revision\n";
	    exit 0;
	}

    }

    return $count;
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
    print "cvsplot.pl -cvsdir <dir> [-rlog <module>] db_host:port\n";
    print "            \n\n";
    exit 1;
}
