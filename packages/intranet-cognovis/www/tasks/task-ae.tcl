# /packages/intranet-cognovis/tasks/task-ae.tcl
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
    { parent_id:integer 0 }
    { project_id "" }
    { project_nr "" }
    { return_url "" }
    { edit_p "" }
    { message "" }
    { project_status_id 76}
}

# This is a task !
set project_type_id 100


# ------------------------------------------------------------------
# Default & Security
# ------------------------------------------------------------------

if {$parent_id == 0 && $project_id ne ""} {
    set parent_id $project_id
}

set user_id [ad_maybe_redirect_for_registration]
set focus "task.var_name"
set page_title [_ intranet-timesheet2-tasks.New_Timesheet_Task]
set base_component_title [_ intranet-timesheet2-tasks.Timesheet_Task]
set context [list $page_title]
if {"" == $return_url} { set return_url [im_url_with_query] }
set current_user_id $user_id

set normalize_project_nr_p [parameter::get_from_package_key -package_key "intranet-core" -parameter "NormalizeProjectNrP" -default 1]


# Check if this is really a task.
if {[info exists task_id]} {
    set object_type [db_string otype "select object_type from acs_objects where object_id = :task_id" -default ""]
    switch $object_type {
	"" - im_timesheet_task {
	    # Just continue
	}
	im_project { 
	    ad_returnredirect [export_vars -base "/intranet/projects/view" {{project_id $task_id}}]
	    ad_script_abort
	}
	default {
	    ad_returnredirect [export_vars -base "/intranet/projects/view" {{project_id $parent_id}}]
	    ad_script_abort
	}
    }


}

# Check the case if there is no project specified. 
# This is only OK if there is a task_id specified (new task for project).

if {0 == $parent_id} {
    if {[info exists task_id]} {
	set project_id [db_string project_from_task "select project_id from im_timesheet_tasks_view where task_id = :task_id" -default 0]
	set parent_id $project_id
	set return_url [export_vars -base "/intranet-cognovis/tasks/view" {task_id}]
    } else {
	ad_return_complaint 1 "You need to specify atleast a task or a project"
	return
    }
}

set ::super_project_id $parent_id

set project_name_title [db_string project_name "select project_name from im_projects where project_id=:parent_id" -default "Unknown"]


append page_title " for '$project_name_title'"

im_project_permissions $user_id $parent_id project_view project_read project_write project_admin

# user_admin_p controls the "add members" link of the member components
set user_admin_p $project_admin


if {!$project_read && ![im_permission $user_id view_timesheet_tasks_all]} {
    ad_return_complaint 1 "You have insufficient privileges to see timesheet tasks for this project"
    return
}

if {!$project_write && ![im_permission $user_id "add_timesheet_tasks"]} {
    ad_return_complaint 1 "You have insufficient privileges to add/modify timesheet tasks for this project"
    return
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
	db_dml insert_task {}
    }

}

# ------------------------------------------------------------------
# Build the form
# ------------------------------------------------------------------


set include_empty 1
set department_only_p 0

if {[info exists project_id]} {
    set company_id [db_string cid "select company_id from im_projects where project_id = :project_id" -default ""]
}


set actions [list]
if {$project_write} {
    set actions [list [list [lang::message::lookup "" intranet-core.Action_Edit "Edit"] edit] ]
}

if {[im_permission $user_id add_tasks] && $project_write} {
    lappend actions {"Delete" delete}
}


ad_form \
    -name task \
    -cancel_url $return_url \
    -action task-ae \
    -actions $actions \
    -has_edit 1 \
    -export {next_url user_id return_url} \
    -form {
	task_id:key
    }

# Fix for problem changing to "edit" form_mode
#set form_action [template::form::get_action "task"]
#if {"" != $form_action} { set form_mode "edit" }



# Add DynFields to the form
set my_task_id 0
if {[info exists task_id]} { set my_task_id $task_id }

im_dynfield::append_attributes_to_form \
    -object_type "im_timesheet_task" \
    -form_id task \
    -object_id $my_task_id \
    -object_subtype_id 100


ad_form -extend -name task -on_request {

    # Set default CostCenter to the user's department, or otherwise the most used CostCenter

    set cost_center_id [db_string default_cost_center "select department_id from im_employees where employee_id = :user_id" -default ""]
    if {"" == $cost_center_id} {
	set cost_center_id [db_string default_cost_center {} -default ""]
    }

} -edit_request {

} -new_data {
    if {!$project_write && ![im_permission $user_id "add_timesheet_tasks"]} {
	ad_return_complaint 1 "You have insufficient privileges to add/modify timesheet tasks for this project"
	ad_script_abort
    }

    set project_nr [string tolower $project_nr]
    if {$project_nr eq ""} {
	set project_nr [lang::util::suggest_key $project_name]
    }

    if {![exists_and_not_null uom_id]} {
	# Set default UoM to Hour
	set uom_id [im_uom_hour]
    }

    if {![exists_and_not_null material_id]} {
	# most used material...
	set default_material_id [db_string default_material_id {} -default ""]
	
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
	
	# Set default Material to most used Material
	set material_id $default_material_id
    }

    ds_comment "material:: $material_id"
    db_string task_insert {}

    if {[info exists start_date]} {set start_date [template::util::date get_property sql_date $start_date]}
    if {[info exists end_date]} {set end_date [template::util::date get_property sql_timestamp $end_date]}
    
    
    im_dynfield::attribute_store \
	-object_type "im_timesheet_task" \
	-object_id $task_id \
	-form_id task
    
    # Add the users of the parent_project to the ts-task
    set pm_role_id [im_biz_object_role_project_manager]
    im_biz_object_add_role $current_user_id $task_id $pm_role_id

    db_foreach select_members {} {
	im_biz_object_add_role $user_id $task_id $role_id
    }
    
    # Write Audit Trail
    im_project_audit -project_id $task_id -action create
    
    # Update percent_completed
    im_timesheet_project_advance $task_id
} -edit_data {

    if {!$project_write && ![im_permission $user_id "add_timesheet_tasks"]} {
	ad_return_complaint 1 "You have insufficient privileges to add/modify timesheet tasks for this project"
	ad_script_abort
    }

    if {[info exists start_date]} {set start_date [template::util::date get_property sql_date $start_date]}
    if {[info exists end_date]} {set end_date [template::util::date get_property sql_timestamp $end_date]}

    im_dynfield::attribute_store \
	-object_type "im_timesheet_task" \
	-object_id $task_id \
	-form_id task

    # Write Audit Trail
    im_project_audit -project_id $task_id -action update

    # Check closed task
    
    
    # Update percent_completed
    im_timesheet_project_advance $parent_id

} -on_submit {

} -after_submit {

    callback im_timesheet_task_after_update -object_id $task_id

    ad_returnredirect $return_url
    ad_script_abort
    
}

# ---------------------------------------------------------------
# Project Menu
# ---------------------------------------------------------------

# Setup the subnavbar
set bind_vars [ns_set create]
ns_set put $bind_vars project_id $parent_id
set project_menu_id [db_string parent_menu "select menu_id from im_menus where label='project'" -default 0]
set sub_navbar [im_sub_navbar \
    -components \
    -base_url "/intranet/projects/view?project_id=$parent_id" \
    $project_menu_id \
    $bind_vars "" "pagedesriptionbar" "project_timesheet_task"] 


