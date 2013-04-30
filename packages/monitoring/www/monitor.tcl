# /www/monitor.tcl

ad_page_contract {
    @author        Philip Greenspun <philg@mit.edu>
    @creation-date 
    @cvs-id        $Id: monitor.tcl,v 1.2 2006/11/11 22:01:17 alessandrol Exp $
} {

}

set connections [ns_server active]


set title "#monitoring.Current_page_requests#"
set context [list "$title"]

# let's build an ns_set just to figure out how many distinct elts; kind of a kludge
# but I don't see how it would be faster in raw Tcl

set scratch [ns_set new scratch]
foreach connection $connections {
    ns_set cput $scratch [lindex $connection 1] 1
}

set distinct [ns_set size $scratch]

set n_connections [llength $connections]
set whole_page "

#monitoring.lt_there_are_a_total_of#

<p>

"

append whole_page "

<table>
<tr><th>#monitoring.conn# #<th>#monitoring.client_IP#<th>#monitoring.state#<th>#monitoring.method#<th>#monitoring.url#<th>#monitoring.n_seconds#<th>#monitoring.bytes#</tr>
"

foreach connection $connections {
    append whole_page "<tr><td>[join $connection <td>]\n"
}

append whole_page "</table>

"

#doc_return 200 text/html $whole_page
