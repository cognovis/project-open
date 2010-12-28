#!/usr/bin/perl -w
use strict;
use warnings;
use IO::Socket::PortState qw(check_ports);

my %porthash = (
		tcp => {
		    22      => {},
		    443     => {},
		    80      => {},
		    53      => {},
		    30032   => {},
		    13720   => {},
		    13782   => {},
		    
		}
		);
my $timeout = 5;
my $host = 'localhost';

check_ports($host, $timeout, \%porthash);

for my $proto (keys %porthash) {
    for(keys %{$porthash{$proto}}) {
	print $_, " - ", $porthash{$proto}->{$_}->{open}, "\n";
    }
}



