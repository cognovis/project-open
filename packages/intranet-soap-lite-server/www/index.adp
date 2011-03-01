<master>

<h1>SOAP::Lite Generic Server</h1>

<p>
This server allows remote SOAP clients to CRUD (Create, Update &amp; Delete)
]project-open[ objects.

<p>
For each ]po[ object (stripping off the "acs_" or "im_" prefix) there are the following methods:
<ul>
<li>get_object(integer) -> array of strings<br>
    Takes an object_id and returns the list of fields of the object.<br>

<li>select_object(array of strings) -> array of integer<br>
    Takes a list of SQL conditions and returns a list of object_id's<br>

<li>object_nr2object_id (string) -> string<br>
    Deprecated.<br>
</ul>


<h1>Installation/Configuration</h1>

<p>
In order to install the SOAP server you need to edit your ]po[ configuration
file at ~/etc/config.tcl. Please add the following code before the
"Socket driver module (HTTP)" lines:

<pre>
#---------------------------------------------------------------------
#
# CGI - nscgi
#
#---------------------------------------------------------------------

ns_section ns/server/${server}/module/nscgi
set cgidir "${serverroot}/packages/intranet-soap-lite-server/cgi-bin"
set cgiurl "/intranet-soap-lite-server/cgi-bin"

ns_param        Map             "GET $cgiurl $cgidir"
ns_param        Map             "POST $cgiurl $cgidir"
ns_param        Map             "POST /*.pl"
ns_param        Interps         CGIinterps
ns_param        Environment     CGIenvironment

ns_section "ns/interps/CGIinterps"
ns_param .pl "/usr/bin/perl"

</pre>

<p>
Also, please add the following line as the last line in the "ns_section ns/server/${server}/modules"
section in order to enable the nscgi AOLserver module:

<pre>
ns_param   nscgi              ${bindir}/nscgi.so
</pre>

<p>
After restarting the server please point your browser to the following URL:

<ul>
<li>
<a http="http://localhost/intranet-soap-lite-server/cgi-bin/po-project-wsdl.pl">http://localhost/intranet-soap-lite-server/cgi-bin/po-project-wsdl.pl</a>
</ul>

<p>
You should get a WSDL for the "Project" service.



