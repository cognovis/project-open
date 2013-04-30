# /admin/monitoring/cassandracle/objects/detail-function-or-procedure.tcl

ad_page_contract {
    Display source code for a PL/SQL function or procedure.
    @cvs-id $Id: detail-function-or-procedure.tcl,v 1.1.1.2 2006/08/24 14:41:40 alessandrol Exp $
} {
    object_name
    owner
}

set page_name $object_name

set the_query "select text
from DBA_SOURCE
where name = :object_name and owner = :owner
order by line"

set description [join [db_list mon_plsql_source $the_query]]


set page_content "
[ad_header $page_name]

<h2>$page_name</h2>

[ad_context_bar  [list "[ad_conn package_url]" "Monitoring"] [list "[ad_conn package_url]/cassandracle" "Cassandracle"] [list \"[ad_conn package_url]/cassandracle/users/\" "Users"] [list "[ad_conn package_url]/cassandracle/users/user-owned-objects" "Objects" ] [list "[ad_conn package_url]/cassandracle/users/one-user-specific-objects?owner=ACS&object_type=FUNCTION" "Functions"] "One"]

<hr>
<p>
<blockquote><pre>$description</pre></blockquote>
<p>
The SQL:
<pre>
$the_query
</pre>
[ad_admin_footer]
"


doc_return 200 text/html $page_content
