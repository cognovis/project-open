# /packages/sencha-reporting-portfolio/lib/project-timeline.tcl
#
# Copyright (C) 2012 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ----------------------------------------------------------------------
# 
# ---------------------------------------------------------------------

# The following variables are expected in the environment
# defined by the calling /tcl/*.tcl libary:
#	diagram_width
#	diagram_height
#	diagram_start_date
# 	diagram_end_date
#	diagram_caption

if {"" == $diagram_width} { set diagram_width 1000 }
if {"" == $diagram_height} { set diagram_width 400 }
if {"" == $diagram_start_date} { set diagram_start_date [db_string diagram_start_date "select now()::date - 1000"] }
if {"" == $diagram_end_date} { set diagram_end_date [db_string diagram_end_date "select now()::date + 360"] }
if {"" == $diagram_caption} { set diagram_caption [lang::message::lookup "" sencha-reporting-portfolio.List_of_projects_over_time "Projects Over Time"] }


# Create a random ID for the diagram
set diagram_id "project_timeline_[expr round(rand() * 100000000.0)]"

set x_axis 0
set y_axis 0
set color "yellow"
set diameter 5
set title ""

set user_sql ""
if {"" != $diagram_user_id} { 
    set user_sql "
	and t.task_id in (select object_id_one from acs_rels where object_id_two = $diagram_user_id)
    " 
}

set workload_sql "
    	select	day.day,
		to_char(day.day, 'YYYY-MM') as month,
		main_p.project_id,
		main_p.project_nr,
		main_p.project_name,
		abs(coalesce(main_p.end_date::date - main_p.start_date::date, 0.0)) as project_duration_days,
		(select	coalesce(sum(planned_units * uom_factor), 0.0) / 8.0 from (
			select	t.planned_units,
				CASE WHEN t.uom_id = 321 THEN 8.0 ELSE 1.0 END as uom_factor
			from	im_projects sub_p,
				im_timesheet_tasks t
			where	sub_p.project_id = t.task_id and
				sub_p.tree_sortkey between main_p.tree_sortkey and tree_right(main_p.tree_sortkey)
				$user_sql
		) t) as estimated_days
	from	im_projects main_p,
		im_day_enumerator(:diagram_start_date, :diagram_end_date) day
	where	main_p.parent_id is null and
		main_p.project_status_id in (select * from im_sub_categories([im_project_status_open])) and
		main_p.start_date <= day.day and
		main_p.end_date >= day.day and
		main_p.end_date > main_p.start_date
"
# ad_return_complaint 1 "<pre>[im_ad_hoc_query $workload_sql]</pre>"

db_foreach workload $workload_sql {

    # Fix issues with duration in order to avoid errors...
    if {"" == $project_duration_days || $project_duration_days < 1} { set project_duration_days 1 }

    # Get the double hash (months -> (project_id -> work))
    set v ""
    if {[info exists hash($month)]} { set v $hash($month) }

    # ps is a hash table project_id -> days of work (of the specific day)
    array unset ps
    array set ps $v
    set p_days 0
    if {[info exists ps($project_id)]} { set p_days $ps($project_id) }
    set p_days [expr $p_days + $estimated_days / $project_duration_days]
    set ps($project_id) $p_days
   
    set hash($month) [array get ps]

    # Sum up the work per project
    set v 0
    if {[info exists project_work_hash($project_id)]} { set v $project_work_hash($project_id) }
    set v [expr $v + $estimated_days / $project_duration_days]
    set project_work_hash($project_id) $v

    # Project Names
    set project_name_hash($project_id) $project_name
}

# ad_return_complaint 1 "<pre>[join [array get hash] "\n"]</pre>"




# The list of day
set days [lsort [array names hash]]

set pids [list]
foreach pid [array names project_work_hash] {
   set v $project_work_hash($pid)
   if {$v > 0} { lappend pids $pid }
}

set pids [lsort $pids]
set project_count [llength $pids]
set data_list [list]
foreach day $days {
    array unset ps
    array set ps $hash($day)

    set data_line "{date: '$day'"
    foreach pid $pids {
    	set v 0.0
	if {[info exists ps($pid)]} { set v $ps($pid) }
	set v [expr round(1000.0 * $v) / 1000.0]
	append data_line ", '$project_name_hash($pid)': $v"
    }
    append data_line "}"
    lappend data_list $data_line
}

set data_json "\[\n"
append data_json [join $data_list ",\n"]
append data_json "\n\]\n"

set project_list [list]
foreach pid $pids {
    lappend project_list "'$project_name_hash($pid)'"
}
set project_json [join $project_list ", "]

# ad_return_complaint 1 "<pre>$data_json</pre>"
