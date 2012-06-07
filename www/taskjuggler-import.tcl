# /packages/intranet-ganttproject/www/taskjuggler-import.tcl
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

set user_id [ad_maybe_redirect_for_registration]
set page_title [lang::message::lookup "" intranet-ganttproject.TaskJuggler_Import "TaskJuggler Import"]
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
# Open the "taskreport.csv" file
# ---------------------------------------------------------------


set project_dir [im_filestorage_project_path $main_project_id]
set tj_folder "taskjuggler"
set tj_dir "$project_dir/$tj_folder"
set csv_file "taskreport.csv"

if {[catch {
    set fl [open "$tj_dir/$csv_file" ]
    set content [read $fl]
    close $fl
} err]} {
    ad_return_complaint 1 "<b>Unable to read $tj_dir/$csv_file</b>:<br><pre>\n$err</pre>"
    ad_script_abort
}


set values [im_csv_get_values $content ";"]

set debug_html ""
foreach line $values {
    set id [lindex $line 0]
    set start [lindex $line 2]
    set end [lindex $line 3]

    set gp_task_id [lindex [split $id "."] end]
    regexp {^t(.*)} $gp_task_id match task_id
    regexp {^(....-..-..)} $start match start_date
    regexp {^(....-..-..)} $end match end_date

    db_dml update_projects "
	update im_projects set
		start_date = :start_date,
		end_date   = :end_date
	where
		project_id = :task_id
    "
    im_audit -object_id $task_id
}


set content [im_ganttproject_gantt_component \
		 -project_id $project_id \
		 -return_url $return_url \
		 -export_var_list [list project_id] \
		 -auto_open 1 \
		 -zoom "in" \
		 -max_col 30 \
		 -max_row 100 \
]


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

