# /admin/monitoring/cassandracle/users/concurrent-active-users.tcl

ad_page_contract {
    From an Oracle license point of view, how many users are on the system now 
    and how does this compare to the limits? 

    @cvs-id $Id: concurrent-active-users.tcl,v 1.1.1.2 2006/08/24 14:41:41 alessandrol Exp $
} {
}

set page_name "Concurrent Active Users"

set the_query "select sessions_max, sessions_warning, sessions_current,
  sessions_highwater, users_max 
from V\$LICENSE"

db_1row mon_active_users $the_query

if {$sessions_max=="0"} {set sessions_max "unspecified."}
if {$sessions_warning=="0"} {set sessions_warning "No warning level specified."}
if {$users_max=="0"} {set users_max "unspecified."}

set page_content "

[ad_header "$page_name"]

<h2>$page_name</h2>

[ad_context_bar [list "[ad_conn package_url]/cassandracle" "Cassandracle"] [list \"[ad_conn package_url]/cassandracle/users/\" "Users"] [list "[ad_conn package_url]/cassandracle/users/user-owned-objects.tcl" "Objects" ] "One Object"]

<hr>
<ul>

<h4>What you paid for</h4>

<li>LICENSE_MAX_SESSIONS: $sessions_max
<li>LICENSE_SESSIONS_WARNING: $sessions_warning
<li>LICENSE_MAX_USERS: $users_max

<h4>What you're actually doing</h4>

<li>Number current sessions: $sessions_current
<li>Sessions Highwater Mark: $sessions_highwater

</ul>

The SQL:

<pre>
$the_query
</pre>

[ad_admin_footer]
"


doc_return 200 text/html $page_content
