# /www/intranet/quality/quality-modules.tcl

# ---------------------------------------------------------------
# 1. Page Contract
# ---------------------------------------------------------------


ad_page_contract {
    @author Guillermo Belcic Bardaji
    @cvs-id
} {
    { user_id 0 }
    { project_id 0 }
    { customer_id 0 }
}
# ---------------------------------------------------------------
# 2. Defaults & Security
# ---------------------------------------------------------------

# User id already verified by filters
set current_user_id [ad_get_user_id]
set today [lindex [split [ns_localsqltimestamp] " "] 0]
set page_title "Quality-modules"
set context_bar [ad_context_bar_ws $page_title]

# ---------------------------------------------------------------
# Modules
# ---------------------------------------------------------------


ad_proc im_absolute1_graf_for_quality { { user_id "0" } { project_id "0" } { customer_id "0" } } {
} {
set from_condition ""
set second_from_condition ""
set where_condition ""
set second_where_condition ""

if { "0" != $customer_id } {
set where_condition "and t.project_id = p.group_id and p.customer_id = :customer_id"
set second_where_condition "and t.project_id = p.group_id and p.customer_id = :customer_id"
set from_condition "im_projects p,"
set second_from_condition "im_projects p,"
}

if { "0" != $user_id } {
set where_condition "and t.trans_id = :user_id"
set second_where_condition "and t.trans_id = :user_id"
}

if { $project_id != "0" } {
set where_condition "and t.project_id = :project_id"
set second_where_condition "and t.project_id = :project_id"
}


set sql_tasks_query "
select
	t.task_id,
	qr.allowed_error_percentage,
	qr.sample_size,
	er.errors
from
	im_tasks t,
	im_trans_quality_reports qr,
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
	qr.task_id = t.task_id
	and er.task_id = t.task_id
	$second_where_condition
order by
	t.task_id DESC
"
set table "
<TABLE BORDER=0 CELLPADDING=0 CELLSPACING=0 BGCOLOR=\"FFFFFF\">
<TR valign=bottom>"
set tatata "
<TD><IMG SRC=../../images/quality_y.gif></TD>\n\n"

set height 90
set width 9

set ltable [list]
set cont 0
db_foreach tasks_query $sql_tasks_query {
    set final_error_percentage [expr [expr floor($errors * 100)] / floor($sample_size)]
    set dif [expr [expr log($allowed_error_percentage)/log(2)] - [expr log($final_error_percentage)/log(2)]]

    if { $cont < 20 && 1} {
	if { $dif >= 3.5 } { 
	    lappend ltable "<TD><IMG SRC=../../images/quality-graf/p4.gif alt=$task_id height=$height width=$width></TD>\n"
	}
	if { $dif >= 2.5 && $dif < 3.5 } { 
	    lappend ltable "<TD><IMG SRC=../../images/quality-graf/p3.gif alt=$task_id height=$height width=$width></TD>\n"
	}
	if { $dif >= 1.5 && $dif < 2.5 } { 
	    lappend ltable "<TD><IMG SRC=../../images/quality-graf/p2.gif alt=$task_id height=$height width=$width></TD>\n"
	}
	if { $dif >= 0.5 && $dif < 1.5 } { 
	    lappend ltable "<TD><IMG SRC=../../images/quality-graf/p1.gif alt=$task_id height=$height width=$width></TD>\n"
	}
	if { $dif > -0.5 && $dif < 0.5 } { 
	    lappend ltable "<TD><IMG SRC=../../images/quality-graf/p0.gif  alt=$task_id height=$height width=$width></TD>\n"
	}
	if { $dif > -1.5 && $dif <= -0.5 } { 
	    lappend ltable "<TD><IMG SRC=../../images/quality-graf/n1.gif alt=$task_id height=$height width=$width></TD>\n"
	}
	if { $dif > -2.5 && $dif <= -1.5 } { 
	    lappend ltable "<TD><IMG SRC=../../images/quality-graf/n2.gif alt=$task_id height=$height width=$width></TD>\n"
	}
	if { $dif > -3.5 && $dif <= -2.5 } { 
	    lappend ltable "<TD><IMG SRC=../../images/quality-graf/n3.gif alt=$task_id height=$height width=$width></TD>\n"
	}
	if { $dif <= -3.5} { 
	    lappend ltable "<TD><IMG SRC=../../images/quality-graf/n4.gif alt=$task_id height=$height width=$width></TD>\n"
	}
	incr cont
	
    }
}
set cont 0
foreach list_of_task_to_table $ltable {
    if { $cont < 20 } {
	append table "[lindex $ltable $cont]"
	incr cont
    }
}

if { $cont < 20 } {
    for {set i $cont} {$i < 20} {incr i} {
	append table "<TD><IMG SRC=../../images/quality-graf/abs-cero.gif alt=$i height=$height width=$width></TD>\n"
    }
}
append table "</TR></TABLE>"
return $table
}



set user_id 5
set project_id 1022
set customer_id 51

set graf1 [im_absolute1_graf_for_quality $user_id "0" "0"]

set page_body "
$graf1"


db_release_unused_handles

doc_return  200 text/html [im_return_template]




set graf1 [im_absolute_graf_for_quality $user_id "0" "0"]
set graf11 [im_relative_graf_for_quality $user_id "0" "0"]
set graf2 [im_absolute_graf_for_quality "0" $project_id "0"]
set graf22 [im_relative_graf_for_quality "0" $project_id "0"]
set graf3 [im_absolute_graf_for_quality "0" "0" $customer_id]
set graf33 [im_relative_graf_for_quality "0" "0" $customer_id]



set bod "


$graf11
----------------------------------------------------
$graf2
$graf22
----------------------------------------------------
$graf3
$graf33
"