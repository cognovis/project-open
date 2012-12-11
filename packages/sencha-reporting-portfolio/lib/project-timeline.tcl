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
#	diagram_project_status_id
#	diagram_aggregation_level
#	diagram_type

if {"" == $diagram_width} { set diagram_width 1000 }
if {"" == $diagram_height} { set diagram_width 400 }
if {"" == $diagram_start_date} { set diagram_start_date [db_string diagram_start_date "select now()::date - 1000"] }
if {"" == $diagram_end_date} { set diagram_end_date [db_string diagram_end_date "select now()::date + 360"] }
if {"" == $diagram_caption} { set diagram_caption [lang::message::lookup "" sencha-reporting-portfolio.List_of_projects_over_time "Projects Over Time"] }
if {"" == $diagram_aggregation_level} { set diagram_aggregation_level "month" }
if {"" == $diagram_dimension} { set diagram_dimension "projects" }
if {"" == $diagram_group_id && "" == $diagram_user_id} { set diagram_group_id [im_profile_skill_profile] }



# Create a random ID for the diagram
set diagram_id "object_timeline_[expr round(rand() * 100000000.0)]"

set x_axis 0
set y_axis 0
set color "yellow"
set diameter 5
set title ""


# ad_return_complaint 1 $diagram_dimension

# -----------------------------------------------------------------------
# Build the SQL
# -----------------------------------------------------------------------

set project_status_sql ""
if {"" != $diagram_project_status_id} {
    set project_status_sql "and main_p.project_status_id in (select * from im_sub_categories(:diagram_project_status_id))"
}

set user_group_sql ""
if {"" != $diagram_group_id} {
    set user_group_sql "and p.person_id in (select member_id from group_distinct_member_map where group_id = :diagram_group_id)"
}
if {"" != $diagram_user_id} {
    set user_group_sql "and p.person_id in (:diagram_user_id)"
}


set workload_base_sql "
	    	select	day.day,
			to_char(day.day, 'YY-MM-DD') as date_day,
			to_char(day.day, 'YY-IW') as date_week,
			to_char(day.day, 'YY-MM') as date_month,
			main_p.project_id,
			p.person_id,
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
					extract(epoch from sub_p.end_date - sub_p.start_date) > 0 and
					r.object_id_one = t.task_id and
					r.object_id_two = p.person_id and
					r.rel_id = bom.rel_id
			) t) as estimated_hours
		from	im_projects main_p,
			persons p,
			im_day_enumerator(:diagram_start_date, :diagram_end_date) day
		where	main_p.parent_id is null and
			main_p.start_date <= day.day and
			main_p.end_date >= day.day and
			main_p.end_date > main_p.start_date and
			p.person_id in (select member_id from group_distinct_member_map where group_id = [im_profile_skill_profile]) and
			main_p.project_status_id not in (select * from im_sub_categories([im_project_status_closed]))
			$project_status_sql
			$user_group_sql
"



switch $diagram_dimension {
    projects {
	set workload_sql "
	    	select	date_day,
			date_week,
			date_month,
			t.project_id as object_id,
			acs_object__name(t.project_id) as object_name,
			sum(estimated_hours) as estimated_hours
		from	($workload_base_sql) t
		group by
			t.project_id, date_day, date_week, date_month
	"
    }
    users {
	set workload_sql "
	    	select	date_day,
			date_week,
			date_month,
			t.person_id as object_id,
			im_name_from_user_id(t.person_id) as object_name,
			sum(estimated_hours) as estimated_hours
		from	($workload_base_sql) t
		group by
			t.person_id, date_day, date_week, date_month
	"

    }
}

# ad_return_complaint 1 "<pre>[im_ad_hoc_query $workload_sql]</pre>"

db_foreach workload $workload_sql {

    if {[regexp {^(..)-(..)-(..)$} $date_day match year month day]} { set date_day "$year-$month-$day" }
    if {[regexp {^(..)-(..)$} $date_week match year week]} { set date_week "$year-$week" }


    switch $diagram_aggregation_level {
	day {
	    # Get the double day_hash (date_days -> (object_id -> work))
	    set v ""
	    if {[info exists day_hash($date_day)]} { set v $day_hash($date_day) }
	    # ps is a day_hash table object_id -> hours of work (of the specific day)
	    array unset ps
	    array set ps $v
	    set p_hours 0
	    if {[info exists ps($object_id)]} { set p_hours $ps($object_id) }
	    set p_hours [expr $p_hours + $estimated_hours]
	    set ps($object_id) $p_hours
	    set day_hash($date_day) [array get ps]
	}
	week {
	    # Sum up per week
	    set v ""
	    if {[info exists week_hash($date_week)]} { set v $week_hash($date_week) }
	    # ps is a week_hash table object_id -> hours of work (of the specific week)
	    array unset ps
	    array set ps $v
	    set p_hours 0
	    if {[info exists ps($object_id)]} { set p_hours $ps($object_id) }
	    set p_hours [expr $p_hours + $estimated_hours]
	    set ps($object_id) $p_hours
	    set week_hash($date_week) [array get ps]
	}
	month {
	    # Sum up per month
	    set v ""
	    if {[info exists month_hash($date_month)]} { set v $month_hash($date_month) }
	    # ps is a month_hash table object_id -> hours of work (of the specific month)
	    array unset ps
	    array set ps $v
	    set p_hours 0
	    if {[info exists ps($object_id)]} { set p_hours $ps($object_id) }
	    set p_hours [expr $p_hours + $estimated_hours]
	    set ps($object_id) $p_hours
	    set month_hash($date_month) [array get ps]
	}
    }
   
    # Sum up the work per object
    set v 0
    if {[info exists object_work_hash($object_id)]} { set v $object_work_hash($object_id) }
    set v [expr $v + $estimated_hours]
    set object_work_hash($object_id) $v

    # Object Names
    set object_name_hash($object_id) $object_name
}


# ------------------------------------------------------------
# Debug
# ------------------------------------------------------------

if {0} {
    set debug ""
    foreach key [lsort [array names day_hash]] {
	set val $day_hash($key)
	append debug "$key - $val\n"
    }
    ad_return_complaint 1 "<pre>$debug</pre>"
}

# show work per object
# ad_return_complaint 1 "<pre>[join [array get object_work_hash] "\n"]</pre>"



# ------------------------------------------------------------
# Aggregate by day
# ------------------------------------------------------------

set days [lsort [array names day_hash]]
set weeks [lsort [array names week_hash]]
set months [lsort [array names month_hash]]

set oids [list]
foreach oid [array names object_work_hash] {
   set v $object_work_hash($oid)
   if {$v > 0} { lappend oids $oid }
}
set oids [lsort $oids]
set object_count [llength $oids]


set data_list [list]
switch $diagram_aggregation_level {
    day {
	foreach day $days {
	    array unset ps
	    array set ps $day_hash($day)
	    
	    set data_line "{date: '$day'"
	    foreach oid $oids {
		set v 0.0
		if {[info exists ps($oid)]} { set v $ps($oid) }
		set v [expr round(1000.0 * $v) / 1000.0]
		append data_line ", '$object_name_hash($oid)': $v"
	    }
	    
	    if {"" != $diagram_availability} {
		append data_line ", 'availability': $diagram_availability"
	    }
	    
	    append data_line "}"
	    lappend data_list $data_line
	}
    }
    month {
	foreach month $months {
	    array unset ps
	    array set ps $month_hash($month)
	    
	    set data_line "{date: '$month'"
	    foreach oid $oids {
		set v 0.0
		if {[info exists ps($oid)]} { set v $ps($oid) }
		set v [expr round(1000.0 * $v) / 1000.0]
		append data_line ", '$object_name_hash($oid)': $v"
	    }
	    
	    if {"" != $diagram_availability} {
		set av [expr $diagram_availability * 22.0]
		append data_line ", 'availability': $av"
	    }
	    
	    append data_line "}"
	    lappend data_list $data_line
	}
    }
    default {
	foreach week $weeks {
	    array unset ps
	    array set ps $week_hash($week)
	    
	    set data_line "{date: '$week'"
	    foreach oid $oids {
		set v 0.0
		if {[info exists ps($oid)]} { set v $ps($oid) }
		set v [expr round(1000.0 * $v) / 1000.0]
		append data_line ", '$object_name_hash($oid)': $v"
	    }
	    
	    if {"" != $diagram_availability} {
		set av [expr $diagram_availability * 5.0]
		append data_line ", 'availability': $av"
	    }
	    
	    append data_line "}"
	    lappend data_list $data_line
	}
    }
}

# ------------------------------------------------------------
# Prepare JSON data for diagram
# ------------------------------------------------------------

set data_json "\[\n"
append data_json [join $data_list ",\n"]
append data_json "\n\]\n"

set object_list [list]
foreach oid $oids {
    lappend object_list "'$object_name_hash($oid)'"
}
set object_fields_json [join $object_list ", "]

if {"" != $diagram_availability} { lappend object_list "'availability'" }
set all_fields_json [join $object_list ", "]
