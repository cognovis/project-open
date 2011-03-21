#!/usr/bin/perl
#
# --------------------------------------
# connect.perl: Test LDAP Port @ IP address
#
# The script tries to open a socket connection
# to the specified IP address and port and 
# returns and error or 0 on success.
#
# --------------------------------------


use Net::LDAP;
use Net::LDAP::Schema;
use Net::LDAP::LDIF;
use Net::LDAP::Util qw(ldap_error_text
                         ldap_error_name
                         ldap_error_desc
			 );

# --------------------------------------
# Parameters
# --------------------------------------

my $ip_address = "localhost";
my $port = 389;
my $timeout = 5;

$ldap = Net::LDAP->new($ip_address, port=>$port, timeout=>$timeout) or die "$@";


# --------------------------------------
# Bind
# --------------------------------------

$mesg = $ldap->bind();
# $mesg = $ldap->bind("cn=Manager,dc=whp,dc=fr", password => "welcome");
die "Bad bind: ",$mesg->code, "\n" if $mesg->code;


# --------------------------------------
# Search
# --------------------------------------

# $mesg = $ldap->search(
#                        filter => "uid=stephane"
# );


my($mesg) = $ldap->search(
    base => "dc=project-open,dc=com",
    filter => '(objectclass=*)'
);

die ldap_error_text($mesg->code) if $mesg->code;

die "Bad search: ",$mesg->code, "\n" if $mesg->code;


while( my $entry = $mesg->shift_entry) {
    print "\n";
    print "==============================================\n";
    print "dn: ", $entry->dn, "\n";
    print "==============================================\n";

    foreach my $attr ($entry->attributes) {
	foreach my $value ($entry->get_value($attr)) {
	    print $attr, ": ", $value, "\n";
	}
    }  
}





#my $schema = $ldap->schema;
#
# print $schema->dump();
# @schema_classes = $schema->all_objectclasses;
# @atts = $schema->all_attributes;



