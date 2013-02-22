# /admin/monitoring/cassandracle/objects/describe-object.tcl

ad_page_contract {
    Does the same query as the "DESCRIBE" command in SQL*PLUS to display information
    about any object.
    @cvs-id $Id: describe-object.tcl,v 1.1.1.2 2006/08/24 14:41:40 alessandrol Exp $
} {
    object_name
}
    
set page_name "Description of $object_name"

set object_info [split $object_name .]
set owner [lindex $object_info 0]
set object_name [lindex $object_info 1]

set describe_query "
select
  column_name, 
  data_type || '(' || data_length || ') ' || 
    DECODE(nullable, 'Y', '', 'N', 'NOT NULL', '?') as data_type
from dba_tab_columns 
where owner = :owner and table_name = :object_name"

set page_content "
[ad_header $page_name]
<h2>$page_name</h2>

<table>
<tr><th>Column Name</th><th>Data Type</th></tr>
"

db_foreach mon_object_describe $describe_query {
    append page_content "<tr><td>$column_name</td><td>$data_type</td></tr>"
} if_no_rows {
    append page_content "<tr><td>No data found</td></tr>"
}

append page_content "</table>\n
<p>
Here is the SQL responsible for this information: <p>
<kbd>describe $object_name</kbd>

[ad_admin_footer]
"


doc_return 200 text/html $page_content