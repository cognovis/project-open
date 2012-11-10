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

# Calculate estimated hours. Simple case: No users to take into account:
set estimated_hours_sql "
		(select	coalesce(sum(planned_units * uom_factor), 0.0) from (
			select	t.planned_units / (extract(epoch from sub_p.end_date - sub_p.start_date) / 3600.0 / 24.0),
				CASE WHEN t.uom_id = 321 THEN 8.0 ELSE 1.0 END as uom_factor
			from	im_projects sub_p,
				im_timesheet_tasks t
			where	sub_p.project_id = t.task_id and
				sub_p.tree_sortkey between main_p.tree_sortkey and tree_right(main_p.tree_sortkey) and
				sub_p.start_date <= day.day and
				sub_p.end_date >= day.day
		) t) as estimated_hours
"

# Calculate estimated hours for a specific user:
if {"" != $diagram_user_id} { 
    set estimated_hours_sql "
		(select	coalesce(sum(planned_units * uom_factor), 0.0) from (
			select	t.planned_units / (extract(epoch from sub_p.end_date - sub_p.start_date) / 3600.0 / 24.0) * bom.percentage / 100.0 as planned_units,
				CASE WHEN t.uom_id = 321 THEN 8.0 ELSE 1.0 END as uom_factor
			from	im_projects sub_p,
				im_timesheet_tasks t,
				acs_rels r,
				im_biz_object_members bom
			where	sub_p.project_id = t.task_id and
				sub_p.tree_sortkey between main_p.tree_sortkey and tree_right(main_p.tree_sortkey) and
				sub_p.start_date <= day.day and
				sub_p.end_date >= day.day and
				r.object_id_one = t.task_id and
				r.object_id_two = :diagram_user_id and
				r.rel_id = bom.rel_id
		) t) as estimated_hours
    "
}

set workload_sql "
    	select	day.day,
		to_char(day.day, 'YYYY-MM-DD') as month,
		main_p.project_id,
		main_p.project_nr,
		main_p.project_name,
		$estimated_hours_sql
	from	im_projects main_p,
		im_day_enumerator(:diagram_start_date, :diagram_end_date) day
	where	main_p.parent_id is null and
		main_p.project_status_id in (select * from im_sub_categories([im_project_status_open])) and
		main_p.start_date <= day.day and
		main_p.end_date >= day.day and
		main_p.end_date > main_p.start_date
	order by day.day
"
# ad_return_complaint 1 "<pre>[im_ad_hoc_query $workload_sql]</pre>"

db_foreach workload $workload_sql {

    # Get the double hash (months -> (project_id -> work))
    set v ""
    if {[info exists hash($month)]} { set v $hash($month) }

    # ps is a hash table project_id -> hours of work (of the specific day)
    array unset ps
    array set ps $v
    set p_hours 0
    if {[info exists ps($project_id)]} { set p_hours $ps($project_id) }
    set p_hours [expr $p_hours + $estimated_hours]
    set ps($project_id) $p_hours
   
    set hash($month) [array get ps]

    # Sum up the work per project
    set v 0
    if {[info exists project_work_hash($project_id)]} { set v $project_work_hash($project_id) }
    set v [expr $v + $estimated_hours]
    set project_work_hash($project_id) $v

    # Project Names
    set project_name_hash($project_id) $project_name
}


# ------------------------------------------------------------
# Debug
# ------------------------------------------------------------

if {0} {
    set debug ""
    foreach key [lsort [array names hash]] {
	set val $hash($key)
	append debug "$key - $val\n"
    }
    ad_return_complaint 1 "<pre>$debug</pre>"
}

# show work per project
# ad_return_complaint 1 "<pre>[join [array get project_work_hash] "\n"]</pre>"



# ------------------------------------------------------------
# Aggregate by day
# ------------------------------------------------------------

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

    if {"" != $diagram_availability} {
	append data_line ", 'availability': $diagram_availability"
    }

    append data_line "}"
    lappend data_list $data_line
}



# ------------------------------------------------------------
# 
# ------------------------------------------------------------

set data_json "\[\n"
append data_json [join $data_list ",\n"]
append data_json "\n\]\n"

set project_list [list]
foreach pid $pids {
    lappend project_list "'$project_name_hash($pid)'"
}
set project_json [join $project_list ", "]

# ad_return_complaint 1 "<pre>$data_json</pre>"
