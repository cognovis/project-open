#!/usr/bin/perl -w

# --------------------------------------------------------
# list-projects
# (c) 2010 ]project-open[
# Frank Bergmann (frank.bergmann@project-open.com)


# --------------------------------------------------------
# Libraries

use LWP::UserAgent;

# --------------------------------------------------------
# Connection parameters: 

$rest_server = "http://demo.project-open.net";		# May include port number
$rest_email = "bbigboss\@tigerpond.com";
$rest_password = "ben";


# --------------------------------------------------------
# Request the XML result

$ua = LWP::UserAgent->new;
$req = HTTP::Request->new(GET => "$rest_server/intranet-rest/index");
$req->authorization_basic($rest_email, $rest_password);


print $ua->request($req)->as_string;

exit 0;

