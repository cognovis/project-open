#!/usr/bin/perl

use strict;
use warnings;

use Pod::WSDL;
use CGI;


# Get the current base URL of the page.
my $query = new CGI;
my $url = $query->url;
my $baseurl;
if ($url =~ /^(.*)intranet-soap-lite-server.*$/) { $baseurl = $1; }


# Parse the file and return the WSDL
my $pod = new Pod::WSDL (
	source => "./Project.pl",
	location => "${baseurl}intranet-soap-lite-server/cgi-bin/Project.pl",
	pretty => 1,
	withDocumentation => 1
 );

print( $pod->WSDL );




#my @names = $query->param;
#my @keywords = $query->keywords;
#
#print "BaseURL: ", $baseurl, "\n";
#print "Keywords: ",@keywords, "\n";
#print "Names: ", @names, "\n";
#print "URL: ", $query->url, "\n";
#print "Header: ", $query->header, "\n";

