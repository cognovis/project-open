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
# 	main_project_id
#	diagram_width
#	diagram_height
#	diagram_caption

if {"" == $diagram_width} { set diagram_width 1000 }
if {"" == $diagram_height} { set diagram_width 400 }
if {"" == $diagram_caption} { set diagram_caption [lang::message::lookup "" sencha-reporting-portfolio.List_of_projects_over_time "Projects Over Time"] }


# Create a random ID for the diagram
set diagram_id "project_eva_[expr round(rand() * 100000000.0)]"

set x_axis 0
set y_axis 0
set color "yellow"
set diameter 5
set title ""

# Get some basic information about the project and skip the diagram if the project doesn't exist.
db_0or1row project_info "
	select	start_date::date - 10 as diagram_start_date,
		end_date::date + 10 as diagram_end_date
	from	im_projects main_p
	where	main_p.project_id = :main_project_id
"
set show_diagram_p [info exists diagram_start_date]

# Pull out for every day of the diagram the planned work per project.
# Later we will aggregate this amount per month and format the result
# in JSON format for JavaScript use.
set workload_sql "
    	select	day.day,
		to_char(day.day, 'YYYY-MM') as month,
		to_char(day.day, 'YYYY-IW') as week,
		to_char(day.day, 'YYYY-MM-DD') as day,
		main_p.project_id,
		main_p.project_nr,
		main_p.project_name,
		(select	coalesce(sum(planned_units * uom_factor / task_duration_days), 0.0) / 8.0 from (
			select	t.planned_units,
				CASE WHEN t.uom_id = 321 THEN 8.0 ELSE 1.0 END as uom_factor,
				round(0.499 + (extract('epoch' from sub_p.end_date) - extract('epoch' from sub_p.start_date)) / 3600.0 / 24.0) as task_duration_days
			from	im_projects sub_p,
				im_timesheet_tasks t
			where	sub_p.project_id = t.task_id and
				sub_p.project_type_id = [im_project_type_task] and
				sub_p.tree_sortkey between main_p.tree_sortkey and tree_right(main_p.tree_sortkey) and
				planned_units is not null and		-- avoid bad data
				planned_units > 0.0 and	  		-- avoid tasks with 0 estimated work
				sub_p.end_date != sub_p.start_date and	-- exclude milestones
				sub_p.start_date::date <= day.day and
				sub_p.end_date::date >= day.day
		) t) as estimated_days
	from	im_projects main_p,
		im_day_enumerator(:diagram_start_date, :diagram_end_date) day
	where	main_p.project_id = :main_project_id
"
# ad_return_complaint 1 "<pre>[im_ad_hoc_query -format html $workload_sql]</pre>"

# This loop is for all projects and all days in the diagram interval.
# The result is a work_per_month_and_project month_work_hash that contains for
# every month a hash of work per project.
db_foreach workload $workload_sql {

    set period $week

    # Get the double hash (months -> (project_id -> work))
    set v ""
    if {[info exists month_work_hash($period)]} { set v $month_work_hash($period) }

    # ps is a hash table project_id -> days of work (of the specific day)
    array unset ps
    array set ps $v
    set p_days 0
    if {[info exists ps($project_id)]} { set p_days $ps($project_id) }
    set p_days [expr $p_days + $estimated_days]
    set ps($project_id) $p_days
   
    set month_work_hash($period) [array get ps]

    # Sum up the work per project
    set v 0
    if {[info exists project_work_hash($project_id)]} { set v $project_work_hash($project_id) }
    set v [expr $v + $estimated_days]
    set project_work_hash($project_id) $v

    # Project Names
    set project_name_hash($project_id) $project_name
}

# ad_return_complaint 1 "<pre>[array get month_work_hash]</pre>"
# ad_return_complaint 1 "<pre>[join [array get month_work_hash] "\n"]</pre>"




# The list of day
set days [lsort [array names month_work_hash]]

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
    array set ps $month_work_hash($day)

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
