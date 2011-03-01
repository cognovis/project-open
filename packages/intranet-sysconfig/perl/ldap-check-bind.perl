#!/usr/bin/perl
#
# -----------------------------------------------------------
# ldap-check-bind.perl: Try to bind to the LDAP server
#
# The uses a BindDN and a password to connect to the LDAP
# server.
#
# -----------------------------------------------------------

use strict;
use warnings;
use Net::LDAP;
use Net::LDAP::Schema;
use Net::LDAP::LDIF;
use Net::LDAP::Util qw(ldap_error_text
                         ldap_error_name
                         ldap_error_desc
			 );

# --------------------------------------
# Constants & Parameters
# --------------------------------------

my $debug = 0;
my $prog_name = "ldap-check-bind.perl";
my $timeout = 2;

my $ip_address	= $ARGV[0];
my $port	= $ARGV[1];
my $ldap_type	= $ARGV[2];			# "ad" (Active Directory) or "ol" (Open LDAP)
my $domain	= $ARGV[3];
my $binddn	= $ARGV[4];
my $bindpw	= $ARGV[5];


if (!defined $bindpw) { $bindpw = ""; }

print "$prog_name: ip_ddress	'$ip_address'\n" if ($debug > 0);
print "$prog_name: port 	'$port'\n" if ($debug > 0);
print "$prog_name: ldap_type	'$ldap_type'\n" if ($debug > 0);
print "$prog_name: domain	'$domain'\n" if ($debug > 0);
print "$prog_name: binddn	'$binddn'\n" if ($debug > 0);
print "$prog_name: bindpw	'$bindpw'\n" if ($debug > 0);


if ("ad" ne $ldap_type && "ol" ne $ldap_type) {
    die "$prog_name: Invalid ldap_type='$ldap_type': Expecting 'ad' or 'ol'\n";
}

# --------------------------------------
# Try to Bind
# --------------------------------------

my $ldap = Net::LDAP->new($ip_address, port=>$port, timeout=>$timeout) or die "$@";

my $mesg = "";
if ("anonymous" eq $binddn) {
    $mesg = $ldap->bind();
} else {
    $mesg = $ldap->bind($binddn, password => $bindpw) or die "$@";
}

if ($mesg->code) {
    print ldap_error_text($mesg->code), "\n";
    exit 1;
}


# --------------------------------------
# Search for any type of users in the domain
# --------------------------------------

my $object_class = "person";
if ("ol" eq $ldap_type) {
    $object_class = "inetOrgPerson";
}

my($search_mesg) = $ldap->search(
    base   => "$domain",
    filter => "objectClass=$object_class"
);
die ldap_error_text($mesg->code) if $mesg->code;



# --------------------------------------
# Check if there was at least on result. 
# Otherwise the Active Directory bind() 
# might have been wrong:
# --------------------------------------

my $result_count = 0;
foreach my $entry ($search_mesg->entries) { 
    $entry->dump if ($debug > 0);
    $result_count++;
}

if ($result_count > 0) {
    print "Successfully bound to server. We found $result_count entries in your LDAP server.";
    exit 0;
} else {
    my $err_msg = "No results found for (objectClass=$object_class) at BaseDN '$domain'.";
    if ("anonymous" eq $binddn) {
	$err_msg .= "\nYou probably haven't enable 'anonymous bind' for your LDAP server.";
    }
    print $err_msg;
    exit 1;
}

