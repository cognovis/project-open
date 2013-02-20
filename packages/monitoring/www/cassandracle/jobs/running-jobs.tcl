# /www/admin/monitoring/cassandracle/jobs/running-jobs.tcl

ad_page_contract {

    If you get an "ORA-01031: insufficient privileges" error when
running this page, you probably need to go into svrmgrl and connect
internal, then do:
    grant select on dba_jobs_running to my_oracle_user_name;
    grant select on dba_jobs         to my_oracle_user_name;

    @cvs-id $Id: running-jobs.tcl,v 1.1.1.2 2006/08/24 14:41:40 alessandrol Exp $
} {}

set page_name "Currently Running Jobs"

set page_contents "
[ad_header $page_name]
<table>
<tr><th>ID</th><th>Submitted By</th><th>Security</th><th>Job</th><th>Last OK Date</th><th>Last OK Time</th><th>This Run Date</th><th>This Run Time</th><th>Errors</th></tr>
"

set job_running_info [db_list_of_lists mon_jobs {
    Select R.job, J.Log_User, J.Priv_USER, J.What, R.Last_Date, SUBSTR(R.Last_Sec, 1, 5), 
    R.This_Date, SUBSTR(R.This_Sec, 1, 5), R.Failures 
    from DBA_JOBS_RUNNING R, DBA_JOBS J 
    where R.JOB=J.JOB
}]

if { [llength $job_running_info] == 0 } {
    append page_contents"<tr><td>No Running Jobs found!</td></tr>"
} else {
    foreach row $job_running_info {
	append page_contents "<tr><td>[lindex $row 0]</td><td>[lindex $row 1]</td><td>[lindex $row 2]</td><td>[lindex $row 3]</td><td>[lindex $row 4]</td><td>[lindex $row 5]</td><td>[lindex $row 6]</td><td>[lindex $row 7]</td><td>[lindex $row 8]</td>
</tr>\n"
    }
}

append page_contents "</table>\n
<p>
Here is the SQL responsible for this information:
<p>
<kbd>Select R.job, J.Log_User, J.Priv_USER, J.What, R.Last_Date, SUBSTR(R.Last_Sec, 1, 5), R.This_Date, SUBSTR(R.This_Sec, 1, 5), R.Failures<br>
from DBA_JOBS_RUNNING R, DBA_JOBS J<br>
where R.JOB=J.JOB</kbd>

[ad_admin_footer]
"



doc_return 200 text/html $page_contents
