#!/usr/bin/perl -w
#
# -----------------------------------------------------------------
# ldap-check-port.perl: Test LDAP Port @ IP address
#
# The script tries to open a socket connection to the specified IP 
# address and port and returns and error or 0 on success.
# Arguments:
#	ip-address
#	port
#
# -----------------------------------------------------------------

use strict;
use warnings;
use IO::Socket::PortState qw(check_ports);
use Net::Ping;


# Constants
my $debug = 0;
my $prog_name = "ldap-check-port.perl";
my $timeout = 2;


# -----------------------------------------------------------------
# Get arguments from command line
#
my $ip_address = $ARGV[0];
my $port = $ARGV[1];
print "$prog_name: ip=$ip_address, port=$port\n" if ($debug > 0);


# -----------------------------------------------------------------
# Check if we can ping the computer
#
my $ping = Net::Ping->new();
my $ping_p = $ping->ping($ip_address, $timeout);
$ping->close();


# -----------------------------------------------------------------
# Check if the port is open
#
my %porthash = (
		tcp => {
		    $port      => {},
		}
);
check_ports($ip_address, $timeout, \%porthash);

my $port_status = $porthash{"tcp"}->{$port}->{open};
print "$prog_name: open=$port_status\n" if ($debug > 0);
if ($debug > 0) {
    for my $proto (keys %porthash) {
	for(keys %{$porthash{$proto}}) {
	    print $prog_name, ": ", $_, " - ", $proto, " - ", $porthash{$proto}->{$_}->{open}, "\n";
	}
    }
}

# -----------------------------------------------------------------
# Report open status
#
if (1 == $port_status) {
    print "Success: LDAP Port '$ip_address:$port' is open\n";
    exit 0;
} else {
    print "Failure: LDAP Port '$ip_address:$port' is not open\n";
    print "IP '$ip_address' can not be pinged \n" if ($ping_p == 0);
    print "IP '$ip_address' can be pinged \n" if ($ping_p == 1);
    exit 1;
}

