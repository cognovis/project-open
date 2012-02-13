# /packages/intranet-timesheet2-task/www/new.tcl
#
# Copyright (c) 2003-2008 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    @param form_mode edit or display
    @author frank.bergmann@project-open.com
} {
    task_id:integer,optional
    { project_id:integer 0 }
    { return_url "" }
    edit_p:optional
    message:optional
    { task_status_id 76 }
}


# ------------------------------------------------------------------
# Default & Security
# ------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set action_url "/intranet-timesheet2-tasks/view"
set focus "task.var_name"
set page_title [_ intranet-timesheet2-tasks.New_Timesheet_Task]
set base_component_title [_ intranet-timesheet2-tasks.Timesheet_Task]
set context [list $page_title]
set current_user_id $user_id

set current_url [ad_conn url]
set normalize_project_nr_p [parameter::get_from_package_key -package_key "intranet-core" -parameter "NormalizeProjectNrP" -default 1]

# Check if this is really a task.
if {[info exists task_id]} {
    set object_type [db_string otype "select object_type from acs_objects where object_id = :task_id" -default ""]
    switch $object_type {
	"" { ad_returnredirect [export_vars -base "/intranet/projects/view" {{project_id $project_id}}]}
	im_project { ad_returnredirect [export_vars -base "/intranet/projects/view" {{project_id $task_id}}]}
	default {}
    }
}

# Check the case if there is no project specified. 
# This is only OK if there is a task_id specified (new task for project).

if {[info exists task_id]} {
    set project_id [db_string project_from_task "select project_id from im_timesheet_tasks_view where task_id = :task_id" -default 0]
    set return_url [export_vars -base "/intranet-timesheet2-tasks/view" {task_id}]
} elseif {0 == $project_id} {
    ad_return_complaint 1 "You need to specify atleast a task or a project"
    return
}

set project_name [db_string project_name "select project_name from im_projects where project_id=:project_id" -default "Unknown"]

append page_title " for <a href='[export_vars -base "/intranet/projects/view" {{project_id $project_id}}]'>'$project_name'</a>"

if {![info exists task_id]} { set form_mode "edit" }

im_project_permissions $user_id $project_id project_view project_read project_write project_admin

# user_admin_p controls the "add members" link of the member components
set user_admin_p $project_admin

if {!$project_read && ![im_permission $user_id view_timesheet_tasks_all]} {
    ad_return_complaint 1 "You have insufficient privileges to see timesheet tasks for this project"
}


set button_pressed [template::form get_action task]
if {"delete" == $button_pressed} {

    if {!$project_write} {
	ad_return_complaint 1 [lang::message::lookup "" intranet-timesheet2-tasks.No_permission_to_delete_a_task "You don't have the permission to delete a task"]
	ad_script_abort
    }
    db_exec_plsql task_delete {}
    ad_returnredirect $return_url

}


# ------------------------------------------------------------------
# Check if converted from a project
# ------------------------------------------------------------------

# ... then no entry in im_timesheet_tasks will be available and
# the select_query below will fail

if {[info exists task_id]} {

    set project_exists_p [db_string project_exists "
	select	count(*)
	from	im_projects
	where	project_id = :task_id
		and not exists (
			select	task_id
			from	im_timesheet_tasks
			where	task_id = :task_id
		)
    "]

    if {$project_exists_p} {


	# Create a new task entry
	db_dml insert_task "
		insert into im_timesheet_tasks (
			task_id, material_id, uom_id
		) values (
			:task_id, :default_material_id, [im_uom_hour]
		)
	"
    }
}

set company_id ""
if {[info exists project_id]} { set company_id [db_string cid "select company_id from im_projects where project_id = :project_id" -default ""] }
set parent_project_options [im_project_options -include_empty 0 -exclude_subprojects_p 0 -company_id $company_id]

set actions [list]
if {$project_write} {
    set actions [list [list [lang::message::lookup "" intranet-core.Action_Edit "Edit"] edit] ]
}

if {[im_permission $user_id add_tasks] && $project_write} {
    lappend actions {"Delete" delete}
}

set full_name_help [lang::message::lookup "" intranet-timesheet2-tasks.form_full_name_help "Full name for this task, indexed by the full-text search engine."]
set short_name_help [lang::message::lookup "" intranet-timesheet2-tasks.form_short_name_help "Short name or abbreviation for this task."]
set project_help [lang::message::lookup "" intranet-timesheet2-tasks.form_project_help "To which project does this task belong?"]
set material_help [lang::message::lookup "" intranet-timesheet2-tasks.form_material_help "The material determines how much you will charge your customer per unit."]
set cost_center_help [lang::message::lookup "" intranet-timesheet2-tasks.form_cost_center_help "Can you assign the costs for this task to a specific cost center? Use your best guess."]

set planned_help [lang::message::lookup "" intranet-timesheet2-tasks.form_planned_units_help "How many hours do you plan for this task (best guess)?"]
set billable_help [lang::message::lookup "" intranet-timesheet2-tasks.form_billable_units_help "How many hours will you be able to bill to your customer?"]
set percentage_completed_help [lang::message::lookup "" intranet-timesheet2-tasks.form_percentage_completed_help "How much of this task has already been done? Default is '0'."]

# ---------------------------------------------------------------
# Project Menu
# ---------------------------------------------------------------

# Setup the subnavbar
set bind_vars [ns_set create]
ns_set put $bind_vars project_id $project_id
set project_menu_id [db_string parent_menu "select menu_id from im_menus where label='project'" -default 0]
set sub_navbar [im_sub_navbar \
    -base_url "/intranet/projects/view?project_id=$project_id" \
    -components \
    $project_menu_id \
    $bind_vars "" "pagedesriptionbar" "project_timesheet_task"] 


