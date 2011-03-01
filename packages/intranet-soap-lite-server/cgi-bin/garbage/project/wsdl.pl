#!/usr/bin/perl

use strict;
use warnings;

use Pod::WSDL;
my $pod = new Pod::WSDL (
			 source => "./project.pl",
			 location => 'http://localhost/intranet-soap-lite-server/project.pl',
			 pretty => 1,
			 withDocumentation => 1
			 );
print( $pod->WSDL );

