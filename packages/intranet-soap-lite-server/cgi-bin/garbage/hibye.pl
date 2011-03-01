#!/usr/bin/perl -w

use SOAP::Transport::HTTP;

SOAP::Transport::HTTP::CGI 
    -> dispatch_to('Demo') 
    -> handle;

package Demo;

sub hi {
    return SOAP::Data->name('myname')
        ->type('string')
        ->uri('http://munich.project-open.net/Demo')
        ->value("Hello, World");
}

sub bye {                    
    return "goodbye, cruel world";
}

sub languages {
    return ("Perl", "C", "sh");
}

