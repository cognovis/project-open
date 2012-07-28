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
    { edit_p "" }
    { message "" }
    { task_status_id "" }
    { task_type_id "9500"}
}

# ------------------------------------------------------------------
# Default & Security
# ------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set action_url "/intranet-timesheet2-tasks/new"
set focus "task.var_name"
set page_title [_ intranet-timesheet2-tasks.New_Timesheet_Task]
set base_component_title [_ intranet-timesheet2-tasks.Timesheet_Task]
set context [list $page_title]
if {"" == $return_url} { set return_url [im_url_with_query] }
set current_user_id $user_id

set normalize_project_nr_p [parameter::get_from_package_key -package_key "intranet-core" -parameter "NormalizeProjectNrP" -default 1]

# Check if this is really a task.
if {[info exists task_id]} {

    set object_type_id [db_string otype "select p.project_type_id from im_projects p where p.project_id = :task_id" -default ""]
    switch $object_type_id {
	"" {
	    # New timesheet task: Just continue 
	}
	100 {
	    # This is a timesheet task: Just continue
	}
	101 { 
	    # A ticket: Redirect
	    ad_returnredirect [export_vars -base "/intranet-helpdesk/new" {{form_mode DISPLAY} {ticket_id $task_id}}]
	    ad_script_abort
	}
	default {
	    ad_returnredirect [export_vars -base "/intranet/projects/view" {{project_id $task_id}}]
	    ad_script_abort
	}
    }


}



# Check the case if there is no project specified. 
# This is only OK if there is a task_id specified (new task for project).


if {0 == $project_id} {

    if {[info exists task_id]} {
	set project_id [db_string project_from_task "select project_id from im_timesheet_tasks_view where task_id = :task_id" -default 0]
	if {$return_url eq ""} {
	    set return_url [export_vars -base "/intranet/projects/view" {project_id}]
	}
    } else {
	ad_return_complaint 1 "You need to specify atleast a task or a project"
	return
    }
}



set project_name [db_string project_name "select project_name from im_projects where project_id=:project_id" -default "Unknown"]
append page_title " for '$project_name'"
im_project_permissions $user_id $project_id project_view project_read project_write project_admin

# user_admin_p controls the "add members" link of the member components
set user_admin_p $project_admin

# Is the current user allowed to edit the timesheet task hours?
set edit_task_estimates_p [im_permission $user_id edit_timesheet_task_estimates]

if {!$project_write} {
    ad_return_complaint 1 "You have insufficient privileges to add/modify timesheet tasks for this project"
    return
}

# most used material...
set default_material_id [db_string default_cost_center "
	select material_id
	from im_timesheet_tasks_view
	group by material_id
	order by count(*) DESC
	limit 1
" -default ""]

# Catch the case that there is no materials yet.
if {"" == $default_material_id} { set default_material_id [im_material_default_material_id] }

# Deal with no default material
if {"" == $default_material_id || 0 == $default_material_id} {
     ad_return_complaint 1 "
      <b>No default 'Material'</b>:<br>
      It seems somebody has deleted all materials in the system.<br>
      Please tell your System Administrator to go to Home - Admin -
      Materials and create at least one Material.
    "
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

# ------------------------------------------------------------------
# Build the form
# ------------------------------------------------------------------

set type_options [im_timesheet_task_type_options -include_empty 0]
set material_options [im_material_options -include_empty 0]

set company_id ""
if {[info exists project_id]} { set company_id [db_string cid "select company_id from im_projects where project_id = :project_id" -default ""] }
set parent_project_options [im_project_options \
				-include_empty 0 \
				-exclude_subprojects_p 0 \
				-exclude_tasks_p 0 \
				-company_id $company_id \
]

set actions [list]
if {$project_write} {
    set actions [list [list [lang::message::lookup "" intranet-core.Action_Edit "Edit"] edit] ]
}

if {[im_permission $user_id add_tasks] && $project_write} {
    lappend actions {"Delete" delete}
}

set full_name_help [im_gif help [lang::message::lookup "" intranet-timesheet2-tasks.form_full_name_help "Full name for this task, indexed by the full-text search engine."]]
set short_name_help [im_gif help [lang::message::lookup "" intranet-timesheet2-tasks.form_short_name_help "Short name or abbreviation for this task."]]
set project_help [im_gif help [lang::message::lookup "" intranet-timesheet2-tasks.form_project_help "To which project does this task belong?"]]


ad_form \
    -name task \
    -cancel_url $return_url \
    -action $action_url \
    -actions $actions \
    -has_edit 1 \
    -export {next_url user_id return_url} \
    -form {
	task_id:key
	{task_name:text(text) {label "[_ intranet-timesheet2-tasks.Name]"} {html {size 50}} {after_html $full_name_help}}
	{task_nr:text(text) {label "[_ intranet-timesheet2-tasks.Short_Name]"} {html {size 30}} {after_html $short_name_help}}
	{project_id:text(select) {label "[_ intranet-core.Project]"} {options $parent_project_options} {after_html $project_help}}
	{task_type_id:text(hidden) {label "[_ intranet-timesheet2-tasks.Type]"} {options $type_options} }
    }

# Add DynFields to the form
set my_task_id 0
if {[info exists task_id]} { set my_task_id $task_id }

im_dynfield::append_attributes_to_form \
    -object_type "im_timesheet_task" \
    -object_subtype_id 100 \
    -form_id task \
    -object_id $my_task_id \
    -object_subtype_id $task_type_id

# Set default type to "Task"

ad_form -extend -name task -on_request {

    # Populate elements from local variables
    # ToDo: Check if these queries get too slow if the
    # system is in use during a lot of time...

    # Set default UoM to Hour
    set uom_id [im_uom_hour]

    # Set default CostCenter to the user's department, or otherwise the most used CostCenter

    set cost_center_id [db_string default_cost_center "select department_id from im_employees where employee_id = :user_id" -default ""]
    if {"" == $cost_center_id} {
    set cost_center_id [db_string default_cost_center "
	select cost_center_id 
	from im_timesheet_tasks_view 
	group by cost_center_id 
	order by count(*) DESC 
	limit 1
    " -default ""]
    }

    # Set default Material to most used Material
    set material_id $default_material_id

} -edit_request {
    db_1row task_info {
	select t.*,
	        p.parent_id as project_id,
	        p.project_name as task_name,
	        p.project_nr as task_nr,
	        p.percent_completed,
	        p.project_type_id,
	        t.task_type_id,
	        p.project_status_id,
	        t.task_status_id,
	        start_date, 
	        end_date, 
		p.reported_hours_cache,
		p.reported_hours_cache as reported_units_cache,
	        p.note
	from
	        im_projects p,
	        im_timesheet_tasks t
	where
	        t.task_id = :task_id and
		p.project_id = :task_id
    }	
    set end_date [template::util::date::from_ansi $end_date]
    set start_date [template::util::date::from_ansi $start_date]    

} -new_data {

    if {!$project_write} {
	ad_return_complaint 1 "You have insufficient privileges to add/modify timesheet tasks for this project"
	ad_script_abort
    }

    # Issue from Anke@opus5: project_path is unique
    # ToDo: Make path unique, or distinguish between
    # task_nr and project_path

    if {![exists_and_not_null uom_id]} {
	# Set default UoM to Hour
	set uom_id [im_uom_hour]
    }

    if {![exists_and_not_null material_id]} {
	# Set default Material to most used Material
	set material_id $default_material_id
    }

    set task_nr [string tolower $task_nr]
    if {[info exists start_date]} {set start_date [template::util::date get_property sql_date $start_date]}
    if {[info exists end_date]} {set end_date [template::util::date get_property sql_timestamp $end_date]}

    if {[catch {

	db_string task_insert {}

        im_dynfield::attribute_store \
            -object_type "im_timesheet_task" \
            -object_id $task_id \
            -form_id task

	# Add the users of the parent_project to the ts-task
	set pm_role_id [im_biz_object_role_project_manager]
	im_biz_object_add_role $current_user_id $task_id $pm_role_id
	set member_sql "
		select	object_id_two as user_id,
			bom.object_role_id as role_id
		from	acs_rels r,
			im_biz_object_members bom
		where	r.rel_id = bom.rel_id and
			object_id_one = :project_id
	"
	db_foreach members $member_sql {
	    im_biz_object_add_role $user_id $task_id $role_id
	}

	# Write Audit Trail
	im_project_audit -project_id $task_id -action after_create

    } err_msg]} {
	ad_return_complaint 1 "<b>Error inserting new task</b>:
	<pre>$err_msg</pre>"
    }

    # Update percent_completed
    im_timesheet_project_advance $task_id

    # Send a notification for this task
    set params [list  [list base_url "/intranet-timesheet2-tasks/"]  [list task_id $task_id] [list return_url ""] [list no_write_p 1]]
    
    set result [ad_parse_template -params $params "/packages/intranet-timesheet2-tasks/lib/task-info"]
    set task_url [export_vars -base "[ad_url]/intranet-timesheet2-tasks/view" -url {task_id}]
    notification::new \
        -type_id [notification::type::get_type_id -short_name project_notif] \
        -object_id $project_id \
        -response_id "" \
        -notif_subject "New Task: $task_name" \
        -notif_html "<h1><a href='$task_url'>$task_name</h1><p /><div align=left>[string trim $result]</div>"



} -edit_data {

    if {!$project_write} {
	ad_return_complaint 1 "You have insufficient privileges to add/modify timesheet tasks for this project"
	ad_script_abort
    }

    set task_nr [string tolower $task_nr]
    if {[info exists start_date]} {set start_date [template::util::date get_property sql_date $start_date]}
    if {[info exists end_date]} {set end_date [template::util::date get_property sql_timestamp $end_date]}

    db_dml project_update {}

    im_dynfield::attribute_store \
	-object_type "im_timesheet_task" \
	-object_id $task_id \
	-form_id task

    # Update percent_completed
    im_timesheet_project_advance $task_id

    # Reset the time_phase date for this relationship
    if {[info exists rel_id]} {
	im_biz_object_delete_timephased_data -rel_id $rel_id
    }

    # Write Audit Trail
    im_project_audit -project_id $task_id -action after_update

    # Send a notification for this task
    set params [list  [list base_url "/intranet-timesheet2-tasks/"]  [list task_id $task_id] [list return_url ""] [list no_write_p 1]]
    
    set result [ad_parse_template -params $params "/packages/intranet-timesheet2-tasks/lib/task-info"]
    set task_url [export_vars -base "[ad_url]/intranet-timesheet2-tasks/view" -url {task_id}]
    notification::new \
        -type_id [notification::type::get_type_id -short_name project_notif] \
        -object_id $project_id \
        -response_id "" \
        -notif_subject "Edit: $task_name" \
        -notif_html "<h1><a href='$task_url'>$task_name</h1><p /><div align=left>[string trim $result]</div>"


} -on_submit {
	ns_log Notice "new: on_submit"

} -after_submit {

    ad_returnredirect $return_url
    ad_script_abort
    
} -validate {
    {task_nr
	{ [string length $task_nr] < 30 }
	"[lang::message::lookup {} intranet-timesheet2-tasks.Short_Name_too_long {Short Name too long (max 30 characters).}]" 
    }
    {task_nr
	{ [regexp {^[a-zA-Z0-9_]+$} $task_nr match] }
	"Short Name contains non-alphanum characters." 
    }
}


# ---------------------------------------------------------------
# Project Menu
# ---------------------------------------------------------------

# Setup the subnavbar
set bind_vars [ns_set create]
ns_set put $bind_vars project_id $project_id
set project_menu_id [db_string parent_menu "select menu_id from im_menus where label='project'" -default 0]
set sub_navbar [im_sub_navbar \
    -components \
    -base_url "/intranet/projects/view?project_id=$project_id" \
    $project_menu_id \
    $bind_vars "" "pagedesriptionbar" "project_timesheet_task"] 


