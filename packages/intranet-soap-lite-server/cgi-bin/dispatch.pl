#!/usr/bin/perl -w


# --------------------------------------------------------
# Specify libraries

use SOAP::Transport::HTTP;
use FindBin;
use lib $FindBin::Bin;
use DBI;


# --------------------------------------------------------
# Handle the service

# Accept a SOAP connection, parse the envelope and dispatch.
SOAP::Transport::HTTP::CGI 
    -> dispatch_to('Project') 
    -> handle;

# Exit cleanly
exit(0);

