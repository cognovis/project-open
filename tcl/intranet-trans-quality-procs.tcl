# /packages/intranet-trans-quality/tcl/intranet-trans-quality-procs.tcl
#
# Copyright (C) 2003-2004 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    @author guillermo.belcic@project-open.com
    @author frank.bergmann@project-open.com
}


# ----------------------------------------------------------------------
# 
# ----------------------------------------------------------------------

ad_proc im_absolute_graf_for_quality { { user_id "0" } { project_id "0" } { customer_id "0" } } {
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
    set tatata "<TD><IMG SRC=../../images/quality_y.gif></TD>\n\n"

    set height 90
    set width 9

    set ltable [list]
    set cont 0
    db_foreach tasks_query $sql_tasks_query {
	set final_error_percentage [expr [expr floor($errors * 100)] / floor($sample_size)]
	set dif [expr [expr log($allowed_error_percentage)/log(2)] - [expr log($final_error_percentage)/log(2)]]
	if { $cont < 20 } {
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


ad_proc im_relative_graf_for_quality { { user_id "0" } { project_id "0" } { customer_id "0" } } {
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
	set url_append "customer_id=$customer_id"
    }
    
    if { "0" != $user_id } {
	set where_condition "and t.trans_id = :user_id"
	set second_where_condition "and t.trans_id = :user_id"
	set url_append "user_id=$user_id"
    }
    
    if { $project_id != "0" } {
	set where_condition "and t.project_id = :project_id"
	set second_where_condition "and t.project_id = :project_id"
	set url_append "group_id=$project_id"
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
    
    set erros ""
    set p0 0
set p1 0
set p2 0
set p3 0
set p4 0
set n1 0
set n2 0
set n3 0
set n4 0
    set percentage [list]
    db_foreach tasks_query $sql_tasks_query {
	set final_error_percentage [expr [expr floor($errors * 100)] / floor($sample_size)]
	set dif [expr [expr log($allowed_error_percentage)/log(2)] - [expr log($final_error_percentage)/log(2)]]
	if { $dif <= -3.5 } { 
	    incr n4 
	}
	if {$dif <= -2.5 && $dif > -3.5 } { 
	    incr n3 
	}
	if {$dif <= -1.5 && $dif > -2.5 } { 
	    incr n2 
	}
	if { $dif <= -0.5 && $dif > -1.5 } { 
	    incr n1 
	}
	if { $dif < 0.5 && $dif > -0.5 } { 
	    incr p0
	}
	if { $dif >= 0.5 && $dif < 1.5 } { 
	    incr p1 
	}
	if { $dif >=1.5 && $dif < 2.5 } { 
	    incr p2 
	}
	if { $dif >= 2.5 && $dif < 3.5} { 
	    incr p3 
	}
	if { $dif >=3.5} { 
	    incr p4 
	}
	lappend values "$task_id [expr log($final_error_percentage)/log(2)]"
    }
    set url_for_control "../quality/quality-control"
    set sum [expr $n4 + $n3 + $n2 + $n1 + $p0 + $p1 + $p2 + $p3 + $p4]
    set height 94
    set table "
<TABLE BORDER=0 CELLPADDING=0 CELLSPACING=0 BGCOLOR=\"FFFFFF\" HEIGHT=$height>
<TR valign=bottom>
<TD>
<a href=$url_for_control?$url_append&group=n4>
<IMG SRC=../../images/quality-graf/barra.gif WIDTH=28 HEIGHT=[expr [expr $n4 * $height] / $sum] alt=$n4 border=0></a></TD>\n
<TD>
<a href=$url_for_control?$url_append&group=n3>
<IMG SRC=../../images/quality-graf/barra.gif WIDTH=28 HEIGHT=[expr [expr $n3 * $height] / $sum] alt=$n3 border=0></a></TD>\n
<TD>
<a href=$url_for_control?$url_append&group=n2>
<IMG SRC=../../images/quality-graf/barra.gif WIDTH=28 HEIGHT=[expr [expr $n2 * $height] / $sum] alt=$n2 border=0></a></TD>\n
<TD>
<a href=$url_for_control?$url_append&group=n1>
<IMG SRC=../../images/quality-graf/barra.gif WIDTH=28 HEIGHT=[expr [expr $n1 * $height] / $sum] alt=$n1 border=0></a></TD>\n
<TD background=../../images/quality-graf/fondo-central.gif WIDTH=28 HEIGHT=$height>
<a href=$url_for_control?$url_append&group=p0>
<IMG SRC=../../images/quality-graf/barra-central.gif WIDTH=28 HEIGHT=[expr [expr $p0 * $height] / $sum] alt=$p0 border=0></a></TD>\n
<TD>
<a href=$url_for_control?$url_append&group=p1>
<IMG SRC=../../images/quality-graf/barra.gif WIDTH=28 HEIGHT=[expr [expr $p1 * $height] / $sum] alt=$p1 border=0></a></TD>\n
<TD>
<a href=$url_for_control?$url_append&group=p2>
<IMG SRC=../../images/quality-graf/barra.gif WIDTH=28 HEIGHT=[expr [expr $p2 * $height] / $sum] alt=$p2 border=0></a></TD>\n
<TD>
<a href=$url_for_control?$url_append&group=p3>
<IMG SRC=../../images/quality-graf/barra.gif WIDTH=28 HEIGHT=[expr [expr $p3 * $height] / $sum] alt=$p3 border=0></a></TD>\n
<TD>
<a href=$url_for_control?$url_append&group=p4>
<IMG SRC=../../images/quality-graf/barra.gif WIDTH=28 HEIGHT=[expr [expr $p4 * $height] / $sum] alt=$p4 border=0></a></TD>\n
</TR>
<TR>
<TD colspan=4><IMG SRC=../../images/quality-graf/abs-neg.gif WIDTH=112 HEIGHT=11></TD>
<TD><IMG SRC=../../images/quality-graf/abs-zero.gif WIDTH=28 HEIGHT=11></TD>
<TD colspan=4><IMG SRC=../../images/quality-graf/abs-pos.gif WIDTH=112 HEIGHT=11></TD>
</TR>
</TABLE>
"
    return $table
}


ad_proc im_quality_project_component { group_id current_user_id { return_url "" } } {
    this proc maka a component that containt a link a the quality controler
    page and if this project has some quality evaluations is show the 
    relative grafic
} {
    
    db_0or1row sql_n_tasks {
select
	count(qr.task_id) as n_reports
from
	im_tasks t,
	im_trans_quality_reports qr
where
	qr.task_id = t.task_id
	and t.project_id = :group_id
    }

    if { $n_reports < 1 } {
	set first_line "<li>no quality reports has been in this project</li>"
    } else {
	set first_line "[im_relative_graf_for_quality "0" "$group_id" "0"]<br>"
    }
    
    set second_line "<a href=../quality/quality-control?[export_url_vars group_id]>Add a Quality Report</a>"
    
    return "<ul>
$first_line
<li>$second_line</li>
</ul>\n"

}
