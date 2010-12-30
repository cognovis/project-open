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

# Constants
my $debug = 0;
my $prog_name = "ldap-check-port.perl";

# Get arguments from command line
my $ip_address = $ARGV[0];
my $port = $ARGV[1];
print "$prog_name: ip=$ip_address, port=$port\n" if ($debug > 0);

# Check if the port is open
my %porthash = (
		tcp => {
		    $port      => {},
		}
);
my $timeout = 5;
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

if (1 == $port_status) {
    exit 0;
} else {
    print "$prog_name: Port $ip_address:$port not open\n";
    exit 1;
}
