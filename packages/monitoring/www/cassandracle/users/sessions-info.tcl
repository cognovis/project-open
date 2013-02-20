# /admin/monitoring/cassandracle/users/sessions-info.tcl

ad_page_contract {
    Show information about every current database session.

    @author Dave Abercrombie (abe@arsdigita.com)
    @creation-date 08 December 1999
    @cvs-id $Id: sessions-info.tcl,v 1.1.1.2 2006/08/24 14:41:41 alessandrol Exp $
} {
}

set show_sql_p "t"

set page_content "

[ad_header "Open sessions"]

<h2>Open sessions</h2>

[ad_context_bar [list "[ad_conn package_url]/cassandracle" "Cassandracle"] "Open sessions"]

<hr>
"

set session_sql "
select
     v\$session.sid,
     username,
     osuser,
     process,
     program,
     type,
     terminal,
     to_char(logon_time, 'YYYY-MM-DD HH24:MI') as logon_time,
     round((sysdate-logon_time)*24,2) as hours_ago,
     serial# as serial,
     v\$session_wait.seconds_in_wait as n_seconds,
     status
from v\$session, v\$session_wait
where v\$session.sid = v\$session_wait.sid
order by username
"

# start building table -----------------------------------

# specify output columns       1         2         3              4         5                6         7           8           9           10 
set description_columns [list "Session" "Serial#"  "Oracle user" "Program" "Seconds in wait"  "Active/Inactive" "UNIX user" "UNIX pid" "Type" "tty" "Logged in" "Hours ago" ]
set column_html ""
foreach column_heading $description_columns {
    append column_html "<th>$column_heading</th>"
}

# begin main table
append page_content "
<table border=1>
<tr>$column_html</tr>
"

# run query and output rows
db_foreach mon_session_info $session_sql {

    # start row
    set row_html "<tr>\n"

    # 1) session
    append row_html "   <td><a href=\"one-session-info?sid=$sid\">$sid</a></td>\n"

    # 2) Serial number
    append row_html "   <td>$serial</td>"

    # 3) Oracle user
    if { [string compare $username ""]==0 } {
        set username "&nbsp;"
    }
   
    append row_html "   <td>$username</td>\n"

    # 4) Program
    append row_html "   <td>$program</t>\n"

    # 5) Session length
    append row_html "    <td>$n_seconds</td>\n"

    # 6) Session length
    append row_html "    <td>$status</td>\n"

    # 7) Unix user
    append row_html "   <td>$osuser</td>\n"

    # 8) Unix PID
    append row_html "   <td>$process</td>\n"

    # 9) session type
    append row_html "   <td>$type</td>\n"

    # 10) tty
    if { [string compare $terminal ""]==0 } {
        set terminal "&nbsp;"
    }
    append row_html "   <td>$terminal</td>\n"

    # 10) logged in
    append row_html "   <td>$logon_time</td>\n"

    # 11) hours ago
    append row_html "   <td>$hours_ago</td>\n"

    # close up row
    append row_html "</tr>\n"

    # write row
    append page_content $row_html
}

# close up table
append page_content "</table>\n
<p>
See <a href=http://www.arsdigita.com/asj/oracle-tips#sessions target=other>\"Be Wary of SQLPlus\"</a> in <a href=http://www.arsdigita.com/asj/oracle-tips target=other>Oracle Tips</a> for how this page can be useful in killing hung database sessions.
(Any queries that are ACTIVE and have a high \"Seconds in wait\"
are good canidates to consider killing.)

[ad_admin_footer]
"


doc_return 200 text/html $page_content
