# /admin/monitoring/cassandracle/performance/pct-large-table-scans.tcl

ad_page_contract {
    Displays 1) percentage of large table scans, and 
    2) recent database queries that have resulted in more than 100 disk reads.
    This can help identify queries that are causing performance problems.

    @cvs-id $Id: pct-large-table-scans.tcl,v 1.1.1.2 2006/08/24 14:41:40 alessandrol Exp $
} {
}

set the_query "
select 
  A.Value as large_scans, B.Value as small_scans
from 
  V\$SYSSTAT A, V\$SYSSTAT B 
where 
  A.Name = 'table scans (long tables)' and B.Name = 'table scans (short tables)'"

db_1row mon_table_scan_count $the_query

set page_content "

[ad_header "Table Scans"]

<h2>Table Scans</h2>

[ad_context_bar [list "[ad_conn package_url]/cassandracle" "Cassandracle"] "Table scans"]

<hr>

If you have a high percentage of large table scans, you want to see if
those tables have been indexed, and whether the queries accessing them
are written in such a way to take advantage of the indicies.

<p>

<blockquote>
<table cellpadding=4>
<tr><th># Large Table Scans</th><th># Small Table Scans</th><th>% Large Scans</th></tr>
<tr>
   <td align=right>$large_scans</td>
   <td align=right>$small_scans</td>
   <td align=right>[format %4.2f [expr 100*(double($large_scans)/double($large_scans+$small_scans))]]</td>
</tr>
</table>

</blockquote>

<p>
The SQL:
<pre>
$the_query
</pre>
<p>
SQL queries resulting in more than 100 disk reads:

<blockquote>

<table border=2>
<tr><th>User Name</th><th>Disk Reads</th><th>Loads</th><th>Optimizer Cost</th></tr>
"

set disk_read_query "select 
  sql_text, disk_reads, loads, optimizer_cost, parsing_user_id, serializable_aborts, au.username
from 
  v\$sql, all_users au
where 
  disk_reads > 100
and
  parsing_user_id = au.user_id"

db_foreach mon_disk_reads $disk_read_query {

    append page_content "
<tr>
  <td align=right>$username (id $parsing_user_id)</td>
  <td align=right>$disk_reads</td>
  <td align=right>$loads</td>
  <td align=right>$optimizer_cost</td>
</tr>
<tr>
   <td colspan=4>SQL: $sql_text</td>
</tr>
"
}

append page_content "
</table>
</blockquote>

The SQL:
<pre>
$disk_read_query
</pre>

[annotated_archive_reference 69]

[ad_admin_footer]
"


doc_return 200 text/html $page_content
