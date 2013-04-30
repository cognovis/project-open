# /admin/monitoring/cassandracle/tablespaces/space-usage.tcl

ad_page_contract {
    Displays summary disk space usage information for all tablespaces.

    @cvs-id $Id: space-usage.tcl,v 1.1.1.2 2006/08/24 14:41:41 alessandrol Exp $
} {
}

set block_size [db_string mon_block_size "select value from V\$PARAMETER where name='db_block_size'"]

set page_content "

[ad_header "Space usage"]

<h2>Space usage</h2>

[ad_context_bar [list "[ad_conn package_url]/cassandracle" "Cassandracle"] "Space Usage"]

<hr>
Database Block Size is $block_size  bytes.<br>
<table>
<tr><th>Tablespace</th><th>File</th><th>Bytes Remaining</th><th>Blocks Remaining</th><th>Total Blocks</th><th>Maximum Extended Size (Bytes)</th><th>Extension Increment (Bytes)</th></tr>
"

set the_query "
select 
  FS.tablespace_name, File_Name, SUM(FS.Blocks) as remaining, 
  DF.Blocks as total_space, SUM(FS.bytes), maxextend*$block_size, 
  inc*$block_size 
from
   DBA_FREE_SPACE FS, DBA_DATA_FILES DF, SYS.FILEXT\$ 
where 
  FS.File_Id = DF.File_id and FS.File_id=File#(+)
group by 
  FS.tablespace_name, File_Name, DF.Blocks, maxextend, inc 
order by 
  FS.tablespace_name, File_Name"

set tablespace_usage_info [db_list_of_lists mon_tablespace_info $the_query]

if {[llength $tablespace_usage_info]==0} {
    append page_content "<tr><td>No tablespaces found!</td></tr>"
} else {
    set current_tablespace ""
    set ts_total_sum 0
    set ts_remaining_sum 0
    
    foreach row $tablespace_usage_info {
	if {[lindex $row 6]==""} {
	    set last_columns "<td valign=top align=right><font color=\"red\">Autoextend Off</font></td><td valign=top align=right><font color=\"red\">Autoextend Off</font></td>"
	} else {
	    set last_columns "<td valign=top align=right>[lindex $row 5]</td><td valign=top align=right>[lindex $row 6]</td>"
	}

    if {$current_tablespace==""} {
	set include_summary 0
	append page_content "<tr><td valign=top align=left>[lindex $row 0]</td><td valign=top align=left>[lindex $row 1]</td><td valign=top align=right>[lindex $row 4]<td valign=top align=right>[lindex $row 2]</td><td valign=top align=right>[lindex $row 3]</td>$last_columns</tr>\n"
	set current_tablespace [lindex $row 0]
	incr ts_total_sum [lindex $row 3]
	incr ts_remaining_sum [lindex $row 2]
	continue
   }
    if {[lindex $row 0]!=$current_tablespace} {
	#finish the remaining tablespace
	if {$include_summary} {
	    append page_content "\n<tr><td colspan=4 align=right>Sum for $current_tablespace: $ts_remaining_sum out of $ts_total_sum blocks remain.</td></tr>\n"
	}
	set ts_total_sum 0
	set ts_remaining_sum 0
	set include_summary 0
	append page_content "<tr><td valign=top align=left>[lindex $row 0]</td><td valign=top align=left>[lindex $row 1]</td><td valign=top align=right>[lindex $row 4]<td valign=top align=right>[lindex $row 2]</td><td valign=top align=right>[lindex $row 3]</td>$last_columns</tr>\n"
	incr ts_total_sum [lindex $row 3]
	incr ts_remaining_sum [lindex $row 2]
    } else {
	append page_content "<tr><td>&nbsp;</td><td valign=top align=left>[lindex $row 1]</td><td valign=top align=right>[lindex $row 4]<td valign=top align=right>[lindex $row 2]</td><td valign=top align=right>[lindex $row 3]</td>$last_columns</tr>\n"
	set include_summary 1
	incr ts_total_sum [lindex $row 3]
	incr ts_remaining_sum [lindex $row 2]
    }
}

}
append page_content "</table>\n
<p>
The SQL:
<pre>
$the_query
</pre>
[annotated_archive_reference "318 and 334"]
<p>

[ad_admin_footer]
"


doc_return 200 text/html $page_content
