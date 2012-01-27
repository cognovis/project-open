#!/usr/bin/perl
# --------------------------------------------------------
#
# import-pop3
#
# ]project-open[ ERP/Project Management System
# (c) 2008 - 2010 ]project-open[
# frank.bergmann@project-open.com
#
# --------------------------------------------------------


# --------------------------------------------------------
# Check for libraries (below) in the local directory
# Customize common_constants to set database name and user.
use FindBin;
use lib $FindBin::Bin;
use DBI;
use Net::POP3;


# --------------------------------------------------------
# Debug? 0=no output, 10=very verbose
$debug = 1;


# --------------------------------------------------------
# Database Connection Parameters
#
# You don't know the "datasource"? Try run this code to
# extract user information from ]po[
#
# Probe DBI for the installed drivers
# my @drivers = DBI->available_drivers();
# die "No drivers found!\n" unless @drivers; # should never happen
# 
# Iterate through the drivers and list the data sources for each one
# foreach my $driver ( @drivers ) {
#     print "Driver: $driver\n";
#     my @dataSources = DBI->data_sources( $driver );
#     foreach my $dataSource ( @dataSources ) {
#         print "\tData Source is $dataSource\n";
#     }
#     print "\n";
# }


# The name of the ]po[ server
$server = "projop";				# The name of the database instance.
$db_username = "$server";			# By default the same as the server.
$db_pwd = "";					# The DB password. Empty by default.
$db_datasource = "dbi:Pg:dbname=$server";	# How to identify the database


# --------------------------------------------------------
# The POP3 Mail Account

$pop3_server = "pop3.server.com";
$pop3_user = "myuser";
$pop3_pwd = "secret";


# --------------------------------------------------------
# Where to write debugging messages?
$logfile = "/web/$server/log/maildir_import.log";
$maildir = "/web/$server/Maildir";


# --------------------------------------------------------
# Define the date format for debugging messages
$date = `/bin/date +"%Y%m%d.%H%M"` || 
    die "common_constants: Unable to get date.\n";
chomp($date);


# --------------------------------------------------------
# Write a debug line to the log file
open(L, ">> $logfile") || die "import-pop3: Couldn't open $logfile.\n";
print L "$date: import-pop3 $project_id\n";



# --------------------------------------------------------
# Establish the database connection
# The parameters are defined in common_constants.pm
$dbh = DBI->connect($db_datasource, $db_username, $db_pwd) ||
    die "import-pop3: Unable to connect to database.\n";



# --------------------------------------------------------
# Establish a connection to the POP3 server
#
$pop3_conn = Net::POP3->new($pop3_server, Timeout => 60) 
    || die "import-pop3: Unable to connect to POP3 server $pop3_server.\n";

$n = $pop3_conn->login($pop3_user,$pop3_pwd) 
    || die "import-pop3: Unable to connect to POP3 server $pop3_server.\n"; 

if (0 == $n) { 
    print "import-pop3: No messages on server.\n";
    exit 0; 
}

# Get the list of messages
$msgList = $pop3_conn->list(); 

# --------------------------------------------------------
# Loop for each of the mails
foreach $msg (keys(%$msgList)) {
    # Get the mail as a file handle
    $fh = $pop3_conn->getfh($msg);

    
    my $from = "";
    my $to = "";
    my $subject = "";
    my $body = "";
    
    while (my $line = <$fh>) {
	chomp($line);
	
	# Skip less interesting mail fields
	if ($line =~ /^Return-Path:/) { next; }
	if ($line =~ /^Delivered-To:/) { next; }
	if ($line =~ /^X-Original-To:/) { next; }
	if ($line =~ /^Received:/) { next; }
	if ($line =~ /^Date:/) { next; }
	if ($line =~ /^Message-ID:/) { next; }
	if ($line =~ /^User-Agent:/) { next; }
	if ($line =~ /^MIME-Version:/) { next; }
	if ($line =~ /^Content-Type:/) { next; }
	if ($line =~ /^Content-Transfer-Encoding:/) { next; }
	
	# Skip the "id" line
	if ($line =~ /^\tid/) { next; }
	
	# Extract from, to and subject
	if ($line =~ /^From:(.*)/) { $from = $1; next; }
	if ($line =~ /^To:(.*)/) { $to = $1; next; }
	if ($line =~ /^Subject:(.*)/) { $subject = $1; next; }
	
	# Replace quote by double-quote for SQL security
	$line =~ s/'/"/g;

	$body .= $line;
    }
    close(LINES);
    print "\n$from$to$subject$body\n" if ($debug >= 1);

	# --------------------------------------------------------
	# Calculate ticket database fields

	# Ticket Nr: Take current number from the im_ticket_seq sequence
	$sth = $dbh->prepare("SELECT nextval('im_ticket_seq') as ticket_nr");
	$sth->execute() || die "import-pop3: Unable to execute SQL statement.\n";
	my $row = $sth->fetchrow_hashref;
	my $ticket_nr = $row->{ticket_nr};

	# Ticket Name: Ticket Nr + Mail Subject
	my $ticket_name = "$ticket_nr - $subject";

	# Customer ID: Who should pay to fix the ticket?
	# Let's take the "internal" company (=the company running this server).
	$sth = $dbh->prepare("SELECT company_id as company_id from im_companies where company_path = 'internal'");
	$sth->execute() || die "import-pop3: Unable to execute SQL statement.\n";
	my $row = $sth->fetchrow_hashref;
	my $ticket_customer_id = $row->{company_id};

	# Customer's contact: Check database for "From" email
	my $sql = "select party_id from parties where lower(trim(email)) = lower(trim('$from_email'))";
	$sth->execute() || die "import-pop3: Unable to execute SQL statement: \n$sql\n";
	my $row = $sth->fetchrow_hashref;
	my $ticket_customer_contact_id = $row->{party_id};
	if ("" == $ticket_customer_contact_id) { $ticket_customer_contact_id = 0; }

	# Ticket Type:
	#  30102 | Purchasing request
	#  30104 | Workplace move request
	#  30106 | Telephony request
	#  30108 | Project request
	#  30110 | Bug request
	#  30112 | Report request
	#  30114 | Permission request
	#  30116 | Feature request
	#  30118 | Training request
	my $ticket_type_id = 30110;

	# Ticket Status:
	#    30000 | Open
	#    30001 | Closed
	#    30010 | In review
	#    30011 | Assigned
	#    30012 | Customer review
	#    30090 | Duplicate
	#    30091 | Invalid
	#    30092 | Outdated
	#    30093 | Rejected
	#    30094 | Won't fix
	#    30095 | Can't reproduce
	#    30096 | Resolved
	#    30097 | Deleted
	#    30098 | Canceled
	my $ticket_status_id = 30000;

	# Ticket Prio
	# 30201 |	 	1 - Highest
	# 30202	|		2 
	# 30203 |		3 	
	# 30204 |		4 	
	# 30205 |		5 	
	# 30206 |		6 	
	# 30207 |		7 	
	# 30208 |		8 	
	# 30209 |		9 - Lowest
	my $ticket_prio_id = 30205;
	

	# --------------------------------------------------------
	# Insert the basis ticket into the SQL database
	$sth = $dbh->prepare("
		SELECT im_ticket__new (
			nextval('t_acs_object_id_seq')::integer, -- p_ticket_id
			'im_ticket'::varchar,			-- object_type
			now(),					-- creation_date
			0::integer,				-- creation_user
			'0.0.0.0'::varchar,			-- creation_ip
			null::integer,				-- (security) context_id
	
			'$ticket_name'::varchar,
			'$ticket_customer_id'::integer,
			'$ticket_type_id'::integer,
			'$ticket_status_id'::integer
		) as ticket_id
	");
	$sth->execute() || die "import-pop3: Unable to execute SQL statement.\n";
	my $row = $sth->fetchrow_hashref;
	my $ticket_id = $row->{ticket_id};

	# Update ticket field stored in the im_tickets table
	my $sql = "
		update im_tickets set
			ticket_type_id			= '$ticket_type_id',
			ticket_status_id		= '$ticket_status_id',
			ticket_customer_contact_id	= '$ticket_customer_contact_id',
			ticket_prio_id			= '$ticket_prio_id'
		where
			ticket_id = $ticket_id
	";
	$sth = $dbh->prepare($sql);
	$sth->execute() || die "import-pop3: Unable to execute SQL statement: \n$sql\n";

	# Update ticket field stored in the im_projects table
	$sth = $dbh->prepare("
		update im_projects set
			project_name		= '$ticket_name',
			project_nr		= '$ticket_nr'
		where
			project_id = $ticket_id;
	");
	$sth->execute() || die "import-pop3: Unable to execute SQL statement: \n$sql\n";


	# --------------------------------------------------------
	# Add a Forum Topic Item into the ticket

	# Get the next topic ID
	$sth = $dbh->prepare("SELECT nextval('im_forum_topics_seq') as topic_id");
	$sth->execute() || die "import-pop3: Unable to execute SQL statement.\n";
	my $row = $sth->fetchrow_hashref;
	my $topic_id = $row->{topic_id};

	my $topic_type_id = 1108; # Note
	my $topic_status_id = 1200; # open

	# Insert a Forum Topic into the ticket container
	my $sql = "
		insert into im_forum_topics (
			topic_id, object_id, parent_id,
			topic_type_id, topic_status_id, owner_id,
			subject, message
		) values (
			'$topic_id', '$ticket_id', null,
			'$topic_type_id', '$topic_status_id', '$ticket_customer_contact_id',
			'$subject', '$body'
		)
	";
	$sth = $dbh->prepare($sql);
	$sth->execute() || die "import-pop3: Unable to execute SQL statement: \n$sql\n";


	# --------------------------------------------------------
	# Start a new dynamic workflow around the ticket

	# Get the next topic ID
	$sth = $dbh->prepare("SELECT aux_string1 from im_categories where category_id = '$ticket_type_id'");
	$sth->execute() || die "import-pop3: Unable to execute SQL statement: \n$sql\n";
	my $row = $sth->fetchrow_hashref;
	my $workflow_key = $row->{aux_string1};

	if ("" ne $workflow_key) {
	    print "import-pop3: Starting workflow '$workflow_key'\n" if ($debug);
	    my $sql = "
		select workflow_case__new (
			null,
			'$workflow_key',
			null,
			'$ticket_id',
			now(),
			0,
			'0.0.0.0'
		) as case_id
	    ";
	    $sth = $dbh->prepare($sql) || die "import-pop3: Unable to prepare SQL statement: \n$sql\n";
	    $sth->execute() || die "import-pop3: Unable to execute SQL statement: \n$sql\n";
	    my $row = $sth->fetchrow_hashref;
	    my $case_id = $row->{case_id};

	    my $sql = "
		select workflow_case__start_case (
			'$case_id',
			'$ticket_customer_contact_id',
			'0.0.0.0',
			null
		)
	    ";
	    $sth = $dbh->prepare($sql) || die "import-pop3: Unable to prepare SQL statement: \n$sql\n";
	    $sth->execute() || die "import-pop3: Unable to execute SQL statement: \n$sql\n";

	}

}


# --------------------------------------------------------
# Close the connection to the POP3 server
$pop3_conn->quit();



# --------------------------------------------------------
# check for problems which may have terminated the fetch early
$sth->finish;
warn $DBI::errstr if $DBI::err;


# --------------------------------------------------------
# Close the database connection
$dbh->disconnect ||
	warn "Disconnection failed: $DBI::errstr\n";


# --------------------------------------------------------
# Close open filehandles
close(L);


# --------------------------------------------------------
# Return a successful execution ("0"). Any other value
# indicates an error. Return code meaning still needs
# to be determined, so returning "1" is fine.
exit(0);
