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
		) t) as planned_work
	from	im_projects main_p,
		im_day_enumerator(:diagram_start_date, :diagram_end_date) day
	where	main_p.project_id = :main_project_id
"
# ad_return_complaint 1 "<pre>[im_ad_hoc_query -format html $workload_sql]</pre>"

# planned_work_in_period: Planned employee work per day, week or month
# planned_work_accumulated_in_period: Accumulated planned work since the start of the project


# Aggregate the values from SQL by period (week or month)
db_foreach workload $workload_sql {
    # Here we determine weather we want to aggregate per day, week or month
    set period $week

    set w 0.0
    if {[info exists planned_work_in_period($period)]} { set w $planned_work_in_period($period) }
    set w [expr $w + $planned_work]
    set planned_work_in_period($period) $w
}

# Calculate the aggregated values
set accumulated_w 0.0
foreach period [lsort [array names planned_work_in_period]] {
    set accumulated_w [expr $accumulated_w + $planned_work_in_period($period)]
    set planned_work_accumulated_in_period($period) $accumulated_w
}
# ad_return_complaint 1 [array get planned_work_accumulated_in_period]


# --------------------------------------------------------------
# Build the JSON data for the diagram stores
# --------------------------------------------------------------

set data_lines [list]
foreach period [lsort [array names planned_work_in_period]] {
    set data_line "{date: '$day'"
    append data_line ", 'planned_work': $planned_work_in_period($period)"
    append data_line ", 'planned_work_accumulated': $planned_work_accumulated_in_period($period)"
    append data_line "}"
    lappend data_lines $data_line
}

set data_json "\[\n"
append data_json [join $data_lines ",\n"]
append data_json "\n\]\n"

set fields_json "'planned_work', 'planned_work_accumulated'"
set fields_json "'planned_work'"
