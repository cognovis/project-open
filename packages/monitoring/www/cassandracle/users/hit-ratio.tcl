# /admin/monitoring/cassandracle/users/hit-ratio.tcl

ad_page_contract {
    Display constraints that have been defined by one user

    @cvs-id $Id: hit-ratio.tcl,v 1.1.1.2 2006/08/24 14:41:41 alessandrol Exp $
} {
}

set page_content "

[ad_header "Hit ratio"]

<h2>Hit ratio</h2>

[ad_context_bar [list "[ad_conn package_url]/cassandracle" "Cassandracle"] "Hit ratio"]

<hr>

The hit ratio is the percentage of block gets that were satisfied from
the block cache in the SGA (RAM).  The number of physical reads shows
the times that Oracle had to go to disk to get table information.  Hit
ratio should be at least 98% for anything except a data warehouse.

<blockquote>
<table>
<tr><th>Username</th><th>Consistent Gets</th><th>Block Gets</th><th>Physical Reads</th><th>Hit Ratio</th></tr>
"


set the_query "
select 
  username, consistent_gets, block_gets, physical_reads 
from 
  V\$SESSION, V\$SESS_IO 
where
  V\$SESSION.SID = V\$SESS_IO.SID and (Consistent_gets + block_gets > 0) and Username is not null"

set object_ownership_info [db_list_of_lists mon_hit_ratio $the_query]

if {[llength $object_ownership_info]==0} {
    append page_content "<tr><td>No objects found!</td></tr>"
} else {
    foreach row $object_ownership_info {
	append page_content "<tr><td>[lindex $row 0]</td><td align=right>[lindex $row 1]</td><td align=right>[lindex $row 2]</td><td align=right>[lindex $row 3]</td><td align=right>[format %4.2f [expr 100*(double([lindex $row 1]+[lindex $row 2]-[lindex $row 3])/double([lindex $row 1]+[lindex $row 2]))]]%</td></tr>\n"
    }
}
append page_content "</table>

</blockquote>

<p>

The SQL:

<pre>
$the_query
</pre>

[annotated_archive_reference 38]

[ad_admin_footer]
"


doc_return 200 text/html $page_content
