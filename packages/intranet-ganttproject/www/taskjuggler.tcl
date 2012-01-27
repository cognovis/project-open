# /packages/intranet-ganttproject/www/taskjuggler.xml.tcl
#
# Copyright (C) 2003 - 2010 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    Create a TaskJuggler .tpj file for scheduling
    @author frank.bergmann@project-open.com
} {
    project_id:integer 
    {return_url ""}
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set today [db_string today "select to_char(now(), 'YYYY-MM-DD')"]
set user_id [ad_maybe_redirect_for_registration]

set hours_per_day 8.0
set default_currency [ad_parameter -package_id [im_package_cost_id] "DefaultCurrency" "" "EUR"]

set page_title [lang::message::lookup "" intranet-ganttproject.TaskJuggler_Scheduling "TaskJuggler Scheduling"]
set context_bar [im_context_bar $page_title]
if {"" == $return_url} { set return_url [im_url_with_query] }


# ---------------------------------------------------------------
# Get information about the project
# ---------------------------------------------------------------

if {![db_0or1row project_info "
	select	g.*,
                p.*,
		p.project_id as main_project_id,
		p.project_name as main_project_name,
                p.start_date::date as project_start_date,
                p.end_date::date as project_end_date,
		c.company_name,
                im_name_from_user_id(p.project_lead_id) as project_lead_name
	from	im_projects p left join im_gantt_projects g on (g.project_id=p.project_id),
		im_companies c
	where	p.project_id = :project_id
		and p.company_id = c.company_id
"]} {
    ad_return_complaint 1 [lang::message::lookup "" intranet-ganttproject.Project_Not_Found "Didn't find project \#%project_id%"]
    return
}


# ---------------------------------------------------------------
# Create the TJ Header
# ---------------------------------------------------------------

set base_tj "
/*
 * This file has been automatically created by \]project-open\[
 * Please do not edit manually. 
 */

project p$main_project_id \"$project_name\" \"1.0\" $project_start_date - $project_end_date {
    currency \"$default_currency\"
}

"


# ---------------------------------------------------------------
# Create the TJ Footer
# ---------------------------------------------------------------

set taskreport_csv "taskreport.csv"
set taskreport_html "taskreport.html"
set statusreport_html "statusreport.html"
set resourcereport_html "resourcereport.html"
set resourcereport_html "resourcereport.html"
set weekly_calendar_html "weekly_calendar.html"
set gantt_chart_html "gantt_chart.html"

set footer_tj "

# The main report that will be parsed by \]po\[
csvtaskreport \"$taskreport_csv\" {
	columns id, name, start, end, effort, duration, chart
	loadunit days
}

htmltaskreport \"$taskreport_html\"
htmlstatusreport \"$statusreport_html\"

htmltaskreport \"$gantt_chart_html\" {
	headline \"Project Gantt Chart\"
	columns hierarchindex, name, start, end, effort, duration, chart
	loadunit days
}

"



# ---------------------------------------------------------------
# Resource TJ Entries
# ---------------------------------------------------------------

set project_resources_sql "
	select distinct
                p.*,
		im_name_from_user_id(p.person_id) as user_name,
		pa.email,
		uc.*,
		e.*
	from 	users_contact uc,
		acs_rels r,
		im_biz_object_members bom,
		persons p,
		parties pa
		LEFT OUTER JOIN im_employees e ON (pa.party_id = e.employee_id)
	where
		r.rel_id = bom.rel_id
		and r.object_id_two = uc.user_id
		and uc.user_id = p.person_id
		and uc.user_id = pa.party_id
		and r.object_id_one in (
			select	children.project_id as subproject_id
			from	im_projects parent,
				im_projects children
			where	children.project_status_id not in (
					[im_project_status_deleted],
					[im_project_status_canceled]
				)
				and children.tree_sortkey between
					parent.tree_sortkey and
					tree_right(parent.tree_sortkey)
				and parent.project_id = :main_project_id
		   UNION
			select :main_project_id
		)
"

set resource_tj "resource members \"All Members\" {\n"

db_foreach project_resources $project_resources_sql {

    set user_tj "\tresource r$person_id \"$user_name\" {\n"

    if {"" != $hourly_cost} {
	append user_tj "\t\trate [expr $hourly_cost * $hours_per_day]\n"
    }

    # ---------------------------------------------------------------
    # Absences 
    set absences_sql "
	select	ua.start_date::date as absence_start_date,
		ua.end_date::date + 1 as absence_end_date 
	from	im_user_absences ua
	where	ua.owner_id = :person_id and
		ua.end_date >= :project_start_date
	order by start_date
    "
    db_foreach resource_absences $absences_sql {
	append user_tj "\t\tvacation $absence_start_date - $absence_end_date\n"
    }


    # ---------------------------------------------------------------
    # Timesheet Entries
    set timesheet_sql "
	SELECT	child.project_id as child_project_id,
		h.day::date as hour_date,
		h.hours as hour_hours
	FROM	im_projects parent,
		im_projects child,
		im_hours h
	WHERE	parent.project_id = :main_project_id AND
		child.tree_sortkey between parent.tree_sortkey and tree_right(parent.tree_sortkey) AND
		child.project_id = h.project_id AND
		h.user_id = :person_id
    "
    db_foreach timesheet $timesheet_sql {

	set key "r$person_id"
	set bookings ""
	if {[info exists booking_hash($key)]} { set booking $booking_hash($key) }
	append bookings "\t\tbooking t$child_project_id $hour_date +${hour_hours}h\n"
	set booking_hash($key) $bookings
    }


    # ---------------------------------------------------------------
    # Close the resource definition
    append user_tj "\t}\n"
    append resource_tj "$user_tj\n"

}
append resource_tj "}\n"


# ---------------------------------------------------------------
# Task TJ Entries
# ---------------------------------------------------------------

# Start writing out the tasks recursively
set tasks_tj [im_taskjuggler_write_subtasks -depth 0 -default_start $project_start_date $main_project_id]



# ---------------------------------------------------------------
# Bookings Entries
# ---------------------------------------------------------------

set bookings_tj ""
foreach key [array names booking_hash] {
    set bookings $booking_hash($key)
    append bookings_tj "supplement resource $key {\n$bookings\n}\n"
}


# ---------------------------------------------------------------
# Join the various parts
# ---------------------------------------------------------------


set tj_content "
$base_tj
$resource_tj
$tasks_tj
$bookings_tj
$footer_tj
"


# ---------------------------------------------------------------
# Write to file
# ---------------------------------------------------------------

set project_dir [im_filestorage_project_path $main_project_id]

set tj_folder "taskjuggler"
set tj_file "taskjuggler.tjp"

# Create a "taskjuggler" folder
set tj_dir "$project_dir/$tj_folder"
if {[catch {
    if {![file exists $tj_dir]} {
	ns_log Notice "exec /bin/mkdir -p $tj_dir"
	exec /bin/mkdir -p $tj_dir
	ns_log Notice "exec /bin/chmod ug+w $tj_dir"
	exec /bin/chmod ug+w $tj_dir
    } 
} err_msg]} { 
    ad_return_complaint 1 "<b>Error creating TaskJuggler directory</b>:<br>
    <pre>$err_msg</pre>"
    ad_script_abort
}

if {[catch {
    set fl [open "$tj_dir/$tj_file" "w"]
    puts $fl $tj_content
    close $fl
} err]} {
    ad_return_complaint 1 "<b>Unable to write to $tj_dir/$tj_file</b>:<br><pre>\n$err</pre>"
    ad_script_abort
}


# ---------------------------------------------------------------
# Run TaskJuggler
# ---------------------------------------------------------------

set pageroot [ns_info pageroot]
set serverroot [join [lrange [split $pageroot "/"] 0 end-1] "/"]


# Check if exists
if {[catch {
    set cmd "which taskjuggler"
    ns_log Notice "exec $cmd"
    exec bash -c $cmd
} err]} {
    ad_return_complaint 1 "<b>TaskJuggler not Installed</b>:<br>
	\]project-open\[ couldn't find the 'taskjuggler' executable in your installation.<br>
	Please install from <a href='http://www.taskjuggler.org/'>www.taskjuggler.org</a>.<br>
	Here is the detailed error message:<br>&nbsp;<br>
	<pre>$err</pre>
    "
    ad_script_abort
}


# Run TaskJuggler and process the input file
if {[catch {
    set cmd "export HOME=$serverroot; cd $tj_dir; taskjuggler $tj_file"
    ns_log Notice "exec $cmd"
    exec bash -c $cmd
} err]} {

    # Format the tj content with line numbers
    set tj_content_lines [split $tj_content "\n"]
    set ctr 1
    set tj_content_pretty ""
    foreach line $tj_content_lines {
	set ctr_str $ctr
	while {[string length $ctr_str] < 3} { set ctr_str " $ctr_str" }
	append tj_content_pretty "$ctr_str $line\n"
	incr ctr
    }

    ad_return_complaint 1 "<b>Error executing TaskJuggler</b>:<br>
	<pre>
	$err
	</pre>
	<b>Source</b><br>
	Here is the TaskJuggler file that has caused the issue:
	<pre>\n$tj_content_pretty</pre>
    "
    ad_script_abort
}


# ---------------------------------------------------------------------
# Projects Submenu
# ---------------------------------------------------------------------

set bind_vars [ns_set create]
ns_set put $bind_vars project_id $project_id
set parent_menu_id [util_memoize [list db_string parent_menu "select menu_id from im_menus where label='project'" -default 0]]
set menu_label ""

set sub_navbar [im_sub_navbar \
		    -components \
		    -base_url [export_vars -base "/intranet/projects/view" {project_id}] \
		    $parent_menu_id \
		    $bind_vars \
		    "" \
		    "pagedesriptionbar" \
		    $menu_label \
		   ]


# ---------------------------------------------------------------
# Successfull execution
# Parse the output report
# ---------------------------------------------------------------


set content "<pre>$tj_content</pre>"

