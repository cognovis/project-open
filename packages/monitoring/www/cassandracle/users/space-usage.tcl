# /admin/monitoring/cassandracle/users/space-usage.tcl

ad_page_contract {
    Display constraints that have been defined by one user
    @cvs-id $Id: space-usage.tcl,v 1.1.1.2 2006/08/24 14:41:41 alessandrol Exp $
} {
}

set page_name "Tablespace Block Allocation by User"

set page_content "
[ad_header $page_name]
This table sums up the blocks allocated in each segment of a tablespace by a user.<p>
<table>
<tr><th>User</th><th>Tablespace Name</th><th>Blocks Allocated</th><th>Total Space for this Tablespace</th></tr>
"

#"select username, tablespace_name, blocks, max_blocks from dba_ts_quotas order by username, tablespace_name"

set the_query {
    select S.owner, S.tablespace_name, sum(S.blocks), DF.Blocks 
    from dba_segments S, DBA_DATA_FILES DF 
    where S.tablespace_name=DF.tablespace_name 
    group by S.owner, S.tablespace_name, DF.Blocks 
    order by S.owner, S.tablespace_name, DF.blocks
}

set tablespace_usage_info [db_list_of_lists mon_space_usage $the_query]

if {[llength $tablespace_usage_info]==0} {
    append page_content "<tr><td>No data segments found!</td></tr>"
} else {
    set current_user ""
    
    foreach row $tablespace_usage_info {
    if {$current_user==""} {
	append page_content "<tr><td valign=top align=left>[lindex $row 0]</td><td valign=top align=left>[lindex $row 1]</td><td valign=top align=right>[lindex $row 2]</td><td valign=top align=right>[lindex $row 3]</td></tr>\n"
	set current_user [lindex $row 0]
	continue
   }
   if {[lindex $row 0]!=$current_user} {
	#finish the remaining tablespace
	append page_content "<tr><td valign=top align=left>[lindex $row 0]</td><td valign=top align=left>[lindex $row 1]</td><td valign=top align=right>[lindex $row 2]</td><td valign=top align=right>[lindex $row 3]</td></tr>\n"
       set current_user [lindex $row 0]
    } else {
	append page_content "<tr><td>&nbsp;</td><td valign=top align=left>[lindex $row 1]</td><td valign=top align=right>[lindex $row 2]</td><td valign=top align=right>[lindex $row 3]</td></tr>\n"
    }
}
}
append page_content "</table>\n
<p>
Here is the SQL responsible for this information: <p>
<kbd>$the_query</kbd>
[ad_admin_footer]
"


doc_return 200 text/html $page_content