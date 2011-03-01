#!/usr/bin/perl -w

#use SOAP::Lite;
use SOAP::Lite (+trace => "all", maptype => {} );

$soap_response = SOAP::Lite
    -> uri('http://munich.project-open.net/Project')
    -> proxy('http://munich.project-open.net/intranet-soap-lite-server/cgi-bin/Project.pl')
    -> select_project("project_nr = '2009_0001'");


#    -> on_action( sub { join '/', 'http://munich.project-open.net/Project', $_[1] } )
#    -> select_project("project_nr = '2009_0001'");
#    -> hello_world();


print $soap_response->result;



#@res = $soap_response->paramsout;
#$res = $soap_response->result;                               
#print "Result is $res, outparams are @res\n";
