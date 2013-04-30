# /admin/monitoring/cassandracle/users/one-session-info.tcl

ad_page_contract {
    Show information about a particular database session.

    @cvs-id $Id: one-session-info.tcl,v 1.1.1.2 2006/08/24 14:41:41 alessandrol Exp $
} {
    sid:integer     
}

set session_query "select 
  S.username, S.osuser, S.machine, S.terminal, 
  S.process, P.spid, S.program session_info, S.serial#  as serial
from 
  V\$SESSION S, V\$PROCESS P
where 
  P.Addr = S.Paddr and S.sid=:sid"

db_1row mon_session_info $session_query

if { ![empty_string_p $username] } {
    set page_name "Session Information for $username"
} else {
    set page_name "Session Information for sid #$sid"
}

ad_return_top_of_page "

[ad_header "Session #$sid"]

<h2>Session #$sid</h2>

[ad_context_bar [list "[ad_conn package_url]/cassandracle" "Cassandracle"] [list "sessions-info" "Open sessions"]  "One session"]

<hr>
<blockquote>
<table>
<tr><td>Session Id</td><td>$sid</td></tr>
<tr><td>Serial #</td><td>$serial</td></tr>
<tr><td>Username:</td><td>$username</td></tr>
<tr><td>Local Account:</td><td>$osuser</td></tr>
<tr><td>Connecting From:</td><td>$machine ($terminal)</td></tr>
<tr><td>Client PID:</td><td>$process</td></tr>
<tr><td>Server PID:</td><td>$spid</td></tr>
<tr><td>Client Progam:</td><td>$session_info</td></tr>
</table>
</blockquote>

<p>
You may be interested in <a href=\"sessions-info\">a list of all active sessions</a>.
<p>
Here is the SQL responsible for this information: <p>
<pre>
$session_query
</pre>

[annotated_archive_reference 393]

<p>

Looking for current SQL available from this user:<br>
<blockquote><kbd>
"

set select_session_sql "
select 
  sql_text 
from 
  v\$sqltext st, v\$session s 
where 
  s.sql_address=st.address and s.sql_hash_value=st.hash_value and s.sid=:sid
order by 
  piece"

set sql_text [string trim [join [db_list mon_session_sql $select_session_sql] ""]]

if {$sql_text==""} {
    set sql_text "No SQL available to report for this session."
}

db_release_unused_handles

ns_write "
$sql_text
</kbd></blockquote>
<p>
Here is the SQL responsible for this information: <P>
<pre>
$select_session_sql
</pre>

<p>
[ad_admin_footer]
"
