# /www/intranet/quality/quality-control.tcl

# ---------------------------------------------------------------
# 1. Page Contract
# ---------------------------------------------------------------

ad_page_contract { 
    @author Guillermo Belcic Bardaji
    @cvs-id 
} {
    { group_id "0" }
    { user_id "0" }
    { customer_id "0" }
    group:optional
}
# ---------------------------------------------------------------
# 2. Defaults & Security
# ---------------------------------------------------------------

set administrate_reports 1


set from_condition ""
set second_from_condition ""
set where_condition ""
set second_where_condition ""

if { "0" != $customer_id } {
    set context "Customer: "
    set where_condition "and t.project_id = p.group_id and p.customer_id = :customer_id"
    set second_where_condition "and t.project_id = p.group_id and p.customer_id = :customer_id"
    set from_condition "im_projects p,"
    set second_from_condition "im_projects p,"
}

if { 0 != $user_id } {
    db_1row user_names {
select first_names||' '||last_name as user_name 
from users 
where user_id = :user_id}
    set context "User: $user_name"
    set where_condition "and t.trans_id = :user_id"
    set second_where_condition "and t.trans_id = :user_id"
}

if { $group_id != "0" } {
    set context "Project: "
    set where_condition "and t.project_id = :group_id"
    set second_where_condition "and t.project_id = :group_id"
}
set group_condition ""
if { [info exist group] } {
    set administrate_reports 0
    switch $group {
	"p4" { set group_condition "and er.error_desplacement >= 3.5" }
	"p3" { set group_condition "and er.error_desplacement >= 2.5 and er.error_desplacement < 3.5" }
	"p2" { set group_condition "and er.error_desplacement >= 1.5 and er.error_desplacement < 2.5" }
	"p1" { set group_condition "and er.error_desplacement >= 0.5 and er.error_desplacement < 1.5" }
	"p0" { set group_condition "and er.error_desplacement < 0.5 and er.error_desplacement > -0.5" }
	"n1" { set group_condition "and er.error_desplacement <= -0.5 and er.error_desplacement > -1.5" }
	"n2" { set group_condition "and er.error_desplacement <= -1.5 and er.error_desplacement > -2.5" }
	"n3" { set group_condition "and er.error_desplacement <= -2.5 and er.error_desplacement > -3.5" }
	"n4" { set group_condition "and er.error_desplacement <= -3.5" }
	default { set group_condition "" }
    }
}

# User id already verified by filters
set custom_user_id [ad_get_user_id]
set today [lindex [split [ns_localsqltimestamp] " "] 0]
set page_title "Quality Control - $context --> $group_condition"
set context_bar [ad_context_bar_ws $page_title]

set sql "
select
        t.*,
        im_category_from_id (t.target_language_id) as target_language,
        im_category_from_id (t.source_language_id) as source_language,
        im_category_from_id (t.task_type_id) as task_type,
        im_category_from_id (t.task_status_id) as task_status,
        er.errors
from
        im_tasks t,
	$second_from_condition
	(select
		er.task_id,
		er.errors,
		LN(qr.allowed_error_percentage)/LN(2) - LN((er.errors * 100)/qr.sample_size)/LN(2) as error_desplacement
	 from
		im_trans_quality_reports qr,
        	(select
                	SUM ((qe.minor_errors * 1) + (qe.major_errors * 5) + (qe.critical_errors * 10)) as errors,
                	t.task_id
		from
                	im_trans_quality_entries qe,
                	im_trans_quality_reports qr,
			$from_condition
                	im_tasks t
        	where
                	qe.report_id = qr.report_id
                	and qr.task_id = t.task_id
                	$where_condition
        	group by
                	t.task_id
        	) er
	 where
		er.task_id = qr.task_id
	) er
where
        er.task_id(+) = t.task_id
        $group_condition
	$second_where_condition
"

set html_table_header "
<tr align=center><td class=rowtitle colspan=9>Tasks Quality Control</td></tr>\n
<tr align=center>
  <td class=rowtitle>Task Name</td>
  <td class=rowtitle>Target Language</td>
  <td class=rowtitle>Units</td>
  <td class=rowtitle>Task Type</td>
  <td class=rowtitle>Status</td>
  <td class=rowtitle>Quality Report</td>"

if { $administrate_reports } {
    append html_table_header "
  <td class=rowtitle>Del</td>
  <td class=rowtitle>Assign</td>"
}

append html_table_header "</tr>\n"

set bgcolor(0) " class=roweven"
set bgcolor(1) " class=rowodd"
set ctr 0
set html_table_body ""

db_foreach task_list $sql {
    incr ctr
    if { $errors >= "0" } {
	set html_quality_cell "
<a href=quality-report?[export_url_vars task_id]>$errors</a> pt
<a href=../users/view?user_id=$trans_id>$trans_id</a>"
    } else {
	set html_quality_cell "No report done"
    }
    append html_table_body "<tr $bgcolor([expr $ctr % 2])>
      <td>$task_name</td>
      <td>$target_language</td>
      <td>$task_units</td>
      <td>$task_type</td>
      <td>$task_status</td>
      <td>$html_quality_cell</td>"
    if { $administrate_reports } {
	append html_table_body "<td><input type=checkbox name=del.$task_id></td>
          <td><input type=submit name=assign_report.$task_id value=Assign></td>"
    }

}

if { $administrate_reports } {
    append html_table_body "<tr><td colspan=6></td>
<td><input type=submit name=delete_report value=Del></td>
</tr>"
}


set table "
<form action=quality-actions method=GET>
[export_form_vars group_id]
<table>
$html_table_header
$html_table_body
</table>
</form>
"


set page_body "
$table
<br>
<form action=../projects/view method=POST>
[export_form_vars group_id]
<input type=submit value=Back>
</form>


[expr [expr log(30)/log(2)]-[expr log(5)/log(2)]]
"
db_release_unused_handles

doc_return  200 text/html [im_return_template]





# old sql query, this no make a group distintion


set sql1 "
select
        t.*,
        im_category_from_id (t.target_language_id) as target_language,
        im_category_from_id (t.source_language_id) as source_language,
        im_category_from_id (t.task_type_id) as task_type,
        im_category_from_id (t.task_status_id) as task_status,
        er.errors
from
        im_tasks t,
	$second_from_condition
        (select
                SUM ((qe.minor_errors * 1) + (qe.major_errors * 5) + (qe.critical_errors * 10)) as errors,
                t.task_id
        from
                im_trans_quality_entries qe,
                im_trans_quality_reports qr,
		$from_condition
                im_tasks t
        where
                qe.report_id = qr.report_id
                and qr.task_id = t.task_id
                $where_condition
        group by
                t.task_id
        ) er
where
        er.task_id(+) = t.task_id
	$second_where_condition
"

