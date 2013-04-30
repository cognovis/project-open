# /admin/monitoring/cassandracle/users/user-owned-objects.tcl

ad_page_contract {
    Displays the number and type of objects owned by each database user.

    cvs-id user-owned-objects.tcl,v 3.3.2.4 2000/07/21 03:57:41 ron Exp
} {
}


set page_content "

[ad_header "User owned objects"]

<h2>User owned objects</h2>

[ad_context_bar [list "[ad_conn package_url]/cassandracle" "Cassandracle"] [list "[ad_conn package_url]/cassandracle/users/index" "Users"] "Objects"]

<hr>
<table>
<tr><th>Owner</th><th>Object Type</th><th>Count</th></tr>
"

set the_query "
select 
  owner, object_type, count(*)
from
  dba_objects
where
  owner<>'SYS'
group by
  owner, object_type"

set object_ownership_info [db_list_of_lists mon_user_objects $the_query]

if {[llength $object_ownership_info]==0} {
    ns_write "<tr><td>No objects found!</td></tr>"
} else {
    set current_user ""
    
    foreach row $object_ownership_info {
	if {$current_user==""} {
	    set current_user [lindex $row 0]
	    append page_content "<tr><td valign=top align=left>[lindex $row 0]</td><td valign=top align=left><a href=\"one-user-specific-objects?owner=$current_user&object_type=[lindex $row 1]\">[lindex $row 1]</a></td><td valign=top align=right>[lindex $row 2]</td></tr>\n"
	    continue
	}
	if {[lindex $row 0]!=$current_user} {
	    set current_user [lindex $row 0]
	    append page_content "<tr><td valign=top align=left>[lindex $row 0]</td><td valign=top align=left><a href=\"one-user-specific-objects?owner=$current_user&object_type=[lindex $row 1]\">[lindex $row 1]</a></td><td valign=top align=right>[lindex $row 2]</td></tr>\n"
	} else {
	    append page_content "<tr><td>&nbsp;</td><td valign=top align=left><a href=\"one-user-specific-objects?owner=$current_user&object_type=[lindex $row 1]\">[lindex $row 1]</a></td><td valign=top align=right>[lindex $row 2]</td></tr>\n"
	}
    }
}

append page_content "</table>\n
<p>
The SQL:
<pre>
$the_query
</pre>
[ad_admin_footer]
"


doc_return 200 text/html $page_content
