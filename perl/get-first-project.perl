#!/usr/bin/perl -w

# --------------------------------------------------------
# get-project.perl
# (c) 2010 ]project-open[
# Frank Bergmann (frank.bergmann@project-open.com)
# Get the XML of the project with the specified ID


# --------------------------------------------------------
# Libraries

use LWP::UserAgent;


# --------------------------------------------------------
# Connection parameters: 

$rest_server = "http://demo.project-open.net";		# May include port number
$rest_email = "bbigboss\@tigerpond.com";
$rest_password = "ben";


# --------------------------------------------------------
# Expect the project_id as the command line argument

my $project_id = @ARGV[0];

print "project_id=$project_id\n";



# --------------------------------------------------------
# Get the XML for the project

$ua = LWP::UserAgent->new;
$req = HTTP::Request->new(GET => "$rest_server/intranet-rest/im_project/$project_id");
$req->authorization_basic($rest_email, $rest_password);




# --------------------------------------------------------
# Get the first project of the list






print $ua->request($req)->as_string;








exit 0;

