# /admin/monitoring/cassandracle/performance/data-block-waits.tcl

ad_page_contract {
    Displays cumulative Data Block Waits since database startup.
    @cvs-id $Id: data-block-waits.tcl,v 1.1.1.2 2006/08/24 14:41:40 alessandrol Exp $
} {
}

set the_query "select
  A.Value as writers, B.Count as waits 
from V\$PARAMETER A, V\$WAITSTAT B
where 
  (A.Name = 'db_writers' or A.Name = 'dbwr_io_slaves')
  and B.Class = 'data block'"

db_1row mon_data_block_waits $the_query


set page_content "
[ad_header "Data Block Waits"]

<h2>Data Block Waits</h2>

[ad_context_bar [list "[ad_conn package_url]/cassandracle" "Cassandracle"] "Data Block Waits"]

<hr>

<blockquote>

<table cellpadding=4>
<tr><th>Number of DBWR processes</th><th>Cumulative Data Block Waits</th></tr>
<tr>
  <td align=right>$writers</td>
  <td align=right>$waits</td>
</tr>
</table>

</blockquote>

Data Block Waits are cumulative since database startup.  If the number
is excessive, you can increase the number of DBWR processes.

<p>
The SQL:
<pre>
$the_query
</pre>

[annotated_archive_reference 78]

[ad_admin_footer]
"


doc_return 200 text/html $page_content