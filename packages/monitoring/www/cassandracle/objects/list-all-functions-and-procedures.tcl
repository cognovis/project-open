# www/admin/monitoring/cassandracle/list-all-functions-and-procedures.tcl

ad_page_contract {

queries Oracle for all Functions and Procedures by user.

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @cvs-id $Id: list-all-functions-and-procedures.tcl,v 1.1.1.2 2006/08/24 14:41:40 alessandrol Exp $

} {

}

set page_name "PL/SQL Functions and Procedures by User"
set num_rows_in_table 25

set page_content "
[ad_header $page_name]
<h2>$page_name</h2>

[ad_context_bar [list "[ad_conn package_url]" "Monitoring"] \
	[list "[ad_conn package_url]/cassandracle" "Cassandracle"] \
	"All Functions and Procedures"]

<hr>
<p>
<table width=90%>
"

set table_fragment "<tr bgcolor=eeeeee><th>Owner</th><th>Object Name</th><th>Object Type</th><th>Date Created</th><th>Status</th></tr>\n"

# replace with a doc_body_flush in new document api

#ad_return_top_of_page $page_content

set sql_query "
select
  owner, object_name, object_type, created, status
from
  dba_objects
where
  (object_type='FUNCTION' or object_type='PROCEDURE')
order by
  owner, object_name"

set object_info [db_list_of_lists mon_dba_objects $sql_query ]


if {[llength $object_info]==0} {
    append page_content "<tr><td colspan=5>No Procedures or Functions found! for $owner</td></tr>\n"
} else {
    set tableP 0
    set ctr 0
    set current_owner ""
    foreach row $object_info {
	incr ctr
	if { $ctr==1 || $current_owner != [lindex $row 0 ] } {
	    set current_owner [lindex $row 0 ]
	    if { $tableP } {
		append page_content "</table>\n"
		#ns_write $page_content
	    }
		
	    append page_content "<table width=90%>$table_fragment\n<tr><td valign=top align=left>[lindex $row 0]</td><td valign=top align=left><a href=\"detail-function-or-procedure?owner=[lindex $row 0]&object_name=[lindex $row 1]\">[lindex $row 1]</a></td><td valign=top align=right>[lindex $row 2]</td><td valign=top align=right>[lindex $row 3]</td><td valign=top align=right>[lindex $row 4]</td></tr>\n"
	    set tableP 1
	} else {
	    append page_content "<tr><td>&nbsp;</td><td valign=top align=left><a href=\"detail-function-or-procedure?owner=[lindex $row 0]&object_name=[lindex $row 1]\">[lindex $row 1]</a></td><td valign=top align=right>[lindex $row 2]</td><td valign=top align=right>[lindex $row 3]</td><td valign=top align=right>[lindex $row 4]</td></tr>\n"
	}
	if { $ctr > $num_rows_in_table } {
	    set ctr 0
	}
    }
    append page_content "</table>\n"
}

append page_content "
<p>

The SQL:

<pre>
$sql_query
</pre>
[ad_admin_footer]
"

doc_return 200 text/html $page_content

