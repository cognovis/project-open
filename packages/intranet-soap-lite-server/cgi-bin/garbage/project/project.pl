#!/usr/bin/perl -w


# --------------------------------------------------------
# Parameters

# Where to write debugging messages?
$logfile = "/tmp/po-project.log";

# Write a debug line to the log file
open(L, ">> $logfile") || die "Couldn't open $logfile";

# Define the date format for debugging messages
$date = `/bin/date +"%Y%m%d.%H%M"` || die "common_constants: Unable to get date\n";
chomp($date);

# Database connection: Please add the following line to /var/lib/pgsql/data/pg_hba.conf:
# so that a local user doesn't need to provide a password:
# local   all         all                               trust

$db_pwd = "";
$db_datasource = "dbi:Pg:dbname=po34demo";
$db_username = "po34demo";


# --------------------------------------------------------
# Specify libraries

use SOAP::Transport::HTTP;
use FindBin;
use lib $FindBin::Bin;
use DBI;


# --------------------------------------------------------
# Handle the service



# Accept a SOAP connection, parse the envelope and dispatch.
SOAP::Transport::HTTP::CGI 
    -> dispatch_to('Project') 
    -> handle;

# Close the debug file
close(L);

# Exit cleanly
exit(0);


# --------------------------------------------------------
# WSDL Definition
# --------------------------------------------------------

=begin WSDL
    
    _IN hi $string A foo
    _DOC This is a test soap web service that prints a list of the current DBAs
    _RETURN $string Returns a string containing the current DBAs
    
=end WSDL



# --------------------------------------------------------
package Project;
# --------------------------------------------------------


# Convert a symbolic description of the project_nr into a ]po[ ID
sub project_nr2project_id {
    my ($class, $p_nr) = @_;
    print main::L "Project: project_nr2project_id($p_nr):\n";

    # Prepare & execute SQL statement
    $dbh = DBI->connect($main::db_datasource, $main::db_username, $main::db_pwd) 
	|| print main::L "Project: project_nr2project_id: Unable to connect to database with parameters
	db_datasource=$main::db_datasource, db_username=$main::db_username, db_pwd=$main::db_pwd.\n";

    # Execute SQL statement
    $sth = $dbh->prepare("
        SELECT  p.project_id
        FROM    im_projects p
        WHERE   p.project_nr = '$p_nr'
    ");
    $sth->execute();

    # Retrieve the returned rows of data. There should be
    # exactly one returned row.
    $numres = $sth->rows;
    print main::L "project_nr2project_id: Exactly 1 row expected but retreived $numres.\n" if (1 != $numres);
    my $row = $sth->fetchrow_hashref;
    my $project_id = $row->{project_id};

    print main::L "Project: project_nr2project_id($p_nr): project_id='$project_id'\n";

    # Finish the SQL command
    $sth->finish;

    # check for problems which may have terminated the fetch early
    warn $DBI::errstr if $DBI::err;

    # Close the database connection
    $dbh->disconnect || warn "Disconnection failed: $DBI::errstr\n";

    # Return the results to the calling process via Web services
#    return $project_id;

    # Fully qualify output for interoperability with .Net
    return SOAP::Data->name('myname') 
	->type('int')
	->uri('http://munich.project-open.net/Project')
	->value($project_id);
}



# Retreive all values for a specific project
sub get_project {
    my ($class, $p_id) = @_;
    print main::L "Project: get($p_id):\n";

    # Prepare & execute SQL statement
    $dbh = DBI->connect($main::db_datasource, $main::db_username, $main::db_pwd) 
	|| print main::L "Project: project_nr2project_id: Unable to connect to database with parameters
	db_datasource=$main::db_datasource, db_username=$main::db_username, db_pwd=$main::db_pwd.\n";

    # Execute SQL statement
    $sth = $dbh->prepare("
        SELECT  p.*
        FROM    im_projects p
        WHERE   p.project_id = '$p_id'
    ");
    $sth->execute();

    # Retrieve the returned rows of data. There should be
    # exactly one returned row.
    $numres = $sth->rows;
    print main::L "project_nr2project_id: Exactly 1 row expected but retreived $numres.\n" if (1 != $numres);
    my $row = $sth->fetchrow_hashref;

    my $project_nr = $row->{project_nr};
    print main::L "Project: get($p_id): project_nr='$project_nr'\n";


    # Extract results to a hash array
    my $hash = SOAP::Data->type('unordered_hash' => $row);

    # Finish the SQL command
    $sth->finish;

    # check for problems which may have terminated the fetch early
    warn $DBI::errstr if $DBI::err;

    # Close the database connection
    $dbh->disconnect || warn "Disconnection failed: $DBI::errstr\n";

    return $hash;
}

sub hi {
    print main::L "Project: hi:\n";
    return "hello, world";     
}

sub bye {                    
    print main::L "Project: bye:\n";
    return "goodbye, cruel world";
}

sub languages {
    print main::L "Project: languages: Returning 'Perl'\n";
    return ("Perl", "C", "sh");
}

