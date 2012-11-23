# /packages/intranet-sencha/lib/milestone-tracker.tcl
#
# Copyright (C) 2011 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ----------------------------------------------------------------------
# 
# ---------------------------------------------------------------------

# The following variables are expected in the environment
# defined by the calling /tcl/*.tcl libary:
#	project_id
#	title
#	diagram_width
#	diagram_height

if {![info exists project_id]} { set project_id 59146 }
set diagram_width 300
set diagram_height 300
set title "Milestones"

set year 2000
set month "01"
set day "01"

# project_id may be overwritten by SQLs below
set org_project_id $project_id


# Create a random ID for the diagram
set diagram_rand [expr round(rand() * 100000000.0)]
set diagram_id "milestone_tracker_$diagram_rand"


# Check if there is at least one correctly defined
# milestone in the project.
set milestone_count [db_string milestone_count "
	select	count(*)
	from	im_projects parent, 
		im_projects child 
	where	parent.project_id = :org_project_id and 
		child.parent_id = parent.project_id and
		(child.milestone_p = 't' 
		OR child.project_type_id in ([join [im_sub_categories [im_project_type_milestone]] ","]))
"]

if {$milestone_count} {
    set milestone_sql "and (child.milestone_p = 't' OR child.project_type_id in ([join [im_sub_categories [im_project_type_milestone]] ","]))"
} else {
    # There are no milestones defined, so just
    # just show all sub-projects
    set milestone_sql "and child.project_type_id not in ([im_project_type_ticket], [im_project_type_task])"
}


# Pull out the history of the project's milestones over time.
# Start to pull out the different days for which audit info
# is available and build the medium of the respective start-
# and end dates.
set base_sql "
		select	audit.*,
			last_modified::date as audit_date
		from	im_projects parent, 
			im_projects child,
			im_projects_audit audit
		where	parent.project_id = :org_project_id and 
			child.parent_id = parent.project_id
			$milestone_sql and
			audit.project_id = child.project_id
"

# Get the list of available milestones
set milestone_ids_sql "
	select	distinct
		project_id
	from	($base_sql) b
	where	end_date is not null
"
set milestone_ids [db_list milestone_ids $milestone_ids_sql]

# Get the list of distinct dates when changes have ocurred
set date_sql "
	select distinct
		audit_date
	from	($base_sql) d
	where	end_date is not null
	order by audit_date
"
set audit_dates [db_list audit_dates $date_sql]

# Calculate start and end date for X axis and
# format the start and end date for JavaScript
db_1row start_end "
	select	min(audit_date) as audit_start_date,
		max(audit_date) as audit_end_date
	from	($date_sql) t
"
# ad_return_complaint 1 "$audit_start_date - $audit_end_date"
regexp {^(....)\-(..)\-(..)$} $audit_start_date match year month day
set audit_start_date_js "new Date($year, $month, $day)"
regexp {^(....)\-(..)\-(..)$} $audit_end_date match year month day
set audit_end_date_js "new Date($year, $month, $day)"


# Select out the project start as base for the Y axis
set reference_start_julian [db_string ref_julian "select to_char(start_date, 'J') from im_projects where project_id = :org_project_id"]

# Get the average end_date for each of the days for each of the milestones
set changes_sql "
	select	b.project_id,
		b.audit_date,
		round(avg(to_char(b.end_date, 'J')::float)) as end_julian
	from	($date_sql) d
		LEFT OUTER JOIN ($base_sql) b ON (d.audit_date = b.audit_date)
	group by b.project_id, b.audit_date
	order by b.audit_date, b.project_id
"

# Write the data into separate hash array per milestone
db_foreach milestone_end_dates $changes_sql {
    set cmd "set m${project_id}($audit_date) [expr $end_julian - $reference_start_julian]"
    eval $cmd
}

if {0} {
    set debug ""
    foreach id $milestone_ids {
	append debug "$id\n"
	append debug [array get m{$id}]
	append debug "\n"
    }
    ad_return_complaint 1 "<pre>$debug</pre>"
}

# ToDo: We may have to fill "holes" in the array 
# for milestones that don't have audit values for
# specific audit days.

set data_list {}
foreach audit_date $audit_dates {

    # Reformat date for javascript
    regexp {^(....)\-(..)\-(..)$} $audit_date match year month day
    set data_line "{date: new Date($year, $month, $day)"
    foreach id $milestone_ids {
	set hash "m$id"
	set cmd "set v \$${hash}($audit_date)"
	eval $cmd
	append data_line ", m$id: $v"
    }
    append data_line "}"
    lappend data_list $data_line
}


# Compile JSON for data
set data_json "\[\n"
append data_json "\t\t[join $data_list ",\n\t\t"]"
append data_json "\t\]\n"



# Compile JSON for field names
set fields {}
foreach id $milestone_ids {
    lappend fields "'m$id'"
}
set fields_joined [join $fields ", "]
set fields_json "\['date', $fields_joined\]"


# ad_return_complaint 1 $fields_joined
# ad_return_complaint 1 "<pre>$fields_json\n\n$data_json</pre>"
