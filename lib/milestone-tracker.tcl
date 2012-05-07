# /packages/sencha-reporting-portfolio/lib/milestone-tracker.tcl
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
#	project_id
#	diagram_title
#	diagram_width
#	diagram_height

if {![info exists diagram_width]} { set diagram_width 300 }
if {![info exists diagram_height]} { set diagram_height 300 }

set year 2000
set month "01"
set day "01"

# project_id may be overwritten by SQLs below
set main_project_id $project_id


# Create a random ID for the diagram
set diagram_rand [expr round(rand() * 100000000.0)]
set diagram_id "milestone_tracker_$diagram_rand"


# Check if there is at least one correctly defined
# milestone in the project.
set milestone_count [db_string milestone_count "
	select	count(*)
	from	im_projects parent, 
		im_projects child 
	where	parent.project_id = :main_project_id and 
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

# ToDo: Remove: Debugging
set milestone_sql ""

# Pull out the history of the project's milestones over time.
# Start to pull out the different days for which audit info
# is available and build the medium of the respective start-
# and end dates.
set base_sql "
		select	audit.*
		from	im_projects parent, 
			im_projects child,
			im_audits audit
		where	parent.project_id = $main_project_id and 
			child.parent_id = parent.project_id
			$milestone_sql and
			(audit.audit_object_id = child.project_id or audit.audit_object_id = parent.project_id)
"

# ad_return_complaint 1 "<pre>xxx\n[join [db_list_of_lists base $base_sql] "\n"]\n$base_sql</pre>"


# Get the list of available milestones
set milestone_ids_sql "
	select	distinct
		audit_object_id as project_id,
		acs_object__name(audit_object_id) as project_name
	from	($base_sql) b
	order by project_name
"
set milestone_ids {}
db_foreach milestones $milestone_ids_sql {
    lappend milestone_ids $project_id
    set milestone_hash($project_id) $project_name
}


# Get the list of distinct dates when changes have ocurred
set date_sql "
	select distinct
		audit_date::date
	from	($base_sql) d
	order by audit_date
"
set audit_dates [db_list audit_dates $date_sql]

# ad_return_complaint 1 "<pre>$audit_dates</pre>"



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
db_1row info "
select	start_date::date as main_project_start_date
from	im_projects
where	project_id = :main_project_id
"

# Get the average end_date for each of the days for each of the milestones
set changes_sql "
select	t.project_id,
	t.audit_date,
	avg(end_date_julian)::integer as end_date_julian,
	to_date(round(avg( end_date_julian ))::text, 'J') as end_date
from
	(select	b.audit_object_id as project_id,
		b.audit_date::date as audit_date,
		to_char(im_audit_value(b.audit_value, 'end_date')::date, 'J')::integer as end_date_julian
	from	($date_sql) d
		LEFT OUTER JOIN ($base_sql) b ON (d.audit_date::date = b.audit_date::date)
	) t
group by
	t.project_id, t.audit_date
order by
	t.audit_date, t.project_id
"

# Write the data into separate hash array per milestone
set y_axis_min_date $main_project_start_date
set y_axis_max_date "2000-01-01"
db_foreach milestone_end_dates $changes_sql {
    set key "$project_id-$audit_date"
    regexp {^(....)\-(..)\-(..)$} $end_date match year month day
    set hash($key) "new Date($year, $month, $day)"

    if {[string compare $end_date $y_axis_max_date] > 0} { set y_axis_max_date $end_date }
    if {[string compare $end_date $y_axis_min_date] < 0} { set y_axis_min_date $end_date }
}

regexp {^(....)\-(..)\-(..)$} $y_axis_min_date match year month day
set y_axis_min_date_js "new Date($year, $month, $day)"

regexp {^(....)\-(..)\-(..)$} $y_axis_max_date match year month day
set y_axis_max_date_js "new Date($year, $month, $day)"

# ad_return_complaint 1 "$y_axis_min_date - $y_axis_max_date"

# -----------------------------------------------------------------
# Format the data JSON and HTML
# -----------------------------------------------------------------

set data_list {}
set debug_html "<table>"

# Header row
set row "<td class=rowtitle>Date</td>"
foreach id $milestone_ids {
    set milestone_name $milestone_hash($id)
    append row "<td class=rowtitle>$milestone_name</td>\n"
}
append debug_html "<tr class=rowtitle>$row</tr>\n"

# Loop through all available audit records and write out data and HTML lines
foreach audit_date $audit_dates {

    # Reformat date for javascript
    regexp {^(....)\-(..)\-(..)$} $audit_date match year month day
    set data_line "{date: new Date($year, $month, $day)"

    # Loop through the columns
    set row "<td>$audit_date</td>"
    foreach id $milestone_ids {
	set v "''"
	set key "$id-$audit_date"
	if {[info exists hash($key)]} { set v $hash($key) }
	append data_line ", m$id: $v"
	append row "<td><nobr>$v</nobr></td>\n"
    }
    append data_line "}"
    lappend data_list $data_line

    append debug_html "<tr class=rowtitle>$row</tr>\n"
}
append debug_html "</table>"

# ad_return_complaint 1 $debug_html



# ad_return_complaint 1 "<pre>[join $data_list "\n"]</pre>"

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

# Complile the series specs
set series {}
foreach id $milestone_ids {
    set milestone_name $milestone_hash($id)
    lappend series "{
	type: 'line', 
	title: '$milestone_name', 
	axis: \['left','bottom'\], 
	xField: 'date', 
	yField: 'm$id', 
	markerConfig: { radius: 5, size: 5 },
	tips: {
	        trackMouse: false,
		anchor: 'right',
  		width: 200,
  		height: 30,
  		renderer: function(storeItem, item) {
			var t = item.series.title;
			this.setTitle(t);
 	        }
        }
    }
    "
}
set series_json [join $series ", "]

# ad_return_complaint 1 $fields_joined
# ad_return_complaint 1 "<pre>$fields_json\n\n$data_json</pre>"

