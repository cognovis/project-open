# /packages/intranet-cust-lippokwolf/www/convert-task-to-subproject.tcl

# Copyright (c) 2004-2011 ]project-open[
# All rights including reserved. To inquire license terms please
# refer to http://www.project-open.com/

# @author      klaus.hofeditz@project-open.com

# -------------------------------------------------------------

ad_page_contract {
    Convert task into a sub-project and create first task
    @param task_id task id to convert 
    @author klaus.hofeditz@project-open.com
} {
    { source_task_id:integer }
    { task_name_st:array }
    { task_nr_st:array }
    { assignee_id:array }
    { start_date:array }
    { end_date:array }
    { uom_id:array }
    { planned_units:array }
}

# ---------------------------------------------------------------------
# To Do: 
# ---------------------------------------------------------------------

# - Copy "task-relationships" of task to be splitted to new tasks

# ---------------------------------------------------------------------
# Defaults, Security & Globals
# ---------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set return_url [im_url_with_query]
set current_url [ns_conn url]
set task_status_id [im_project_status_open]
set task_type_id [im_project_type_task]
set log_hours_on_parents_p [parameter::get -package_id [apm_package_id_from_key intranet-timesheet2] -parameter "LogHoursOnParentWithChildrenP" -default 0]
set default_material_id [im_material_default_material_id]
set project_names [list]

# get start/end date of source task 
db_1row get_dates_of_source_task "
	select
		to_char(start_date, 'YYYY-MM-DD') as start_date_source_task,
		to_char(end_date, 'YYYY-MM-DD') as end_date_source_task
	from 
		im_projects 
	where 
		project_id = :source_task_id		 
"

if { ![info exists start_date_source_task] } { set start_date_source_task ""}
if { ![info exists end_date_source_task] } { set end_date_source_task ""}

set debug_var ""

# ------------------------------------------------------------------
# Sanity checks 
# ------------------------------------------------------------------

# Redirect if this not a task
if { [exists_and_not_null source_task_id] } {
    set task_p [db_string task_id "select count(*) from im_timesheet_tasks where task_id = :source_task_id" -default 0]
    if { !$task_p } {
	ad_return_complaint 1 [lang::message::lookup "" intranet-cust-lippokwolf.NotATask "Action can't be performed, this is not a Task."] 
    } 
} else {
    ad_return_complaint 1 [lang::message::lookup "" intranet-cust-lippokwolf.PleaseProvideTaskId "Action can't be performed, please provide a Task Id."] 
}

if { !$log_hours_on_parents_p } {
    set number_hours [db_string get_data "select count(*) from im_hours where project_id = :source_task_id" -default 0]
    if {  0 != $number_hours } {
	ad_return_complaint 1  [lang::message::lookup "" intranet-cust-lippokwolf.SplitNotAllowed "Splitting this task is not allowed because of Parameter 'LogHoursOnParentWithChildrenP' "]	
    }
}


# Form validation   
for {set i 1} {$i <6 } {incr i} {

    # Planned Hours negative? 
    if {[info exists planned_units($i)] && "" != $planned_units($i)} {
	if { $planned_units($i) < 0 } {
	    ad_return_complaint 1 "Found negative value for Planned Hours:<br>
                Current value: '$item_planned_units'
            "
            ad_script_abort
	}
    }
	
	# Planned units a number? 
	if {![string is double $planned_units($i)]} {
		ad_return_complaint 1 "
			<b>[lang::message::lookup "" intranet-core.Not_a_number "Value is not a number"]</b>:<br>
			[lang::message::lookup "" intranet-core.Not_a_number_msg "
    	    	The value for you have provided for 'Planned Units' ('$planned_units($i)') is not a number.<br>
	    	    Please enter something like '12.5' or '100'.
	        "]
        "
        ad_script_abort
    }
    
    # If there's a task_nr there must be a task_name, ... and the way around 
    if { ([info exists task_name_st($i)] && "" != $task_name_st($i)) && ([info exists task_nr_st($i)] && "" == $task_nr_st($i)) } {
            ad_return_complaint 1 "Please provide task number for task: $task_name_st($i)"
            ad_script_abort
    }
    if { ([info exists task_nr_st($i)] && "" != $task_nr_st($i)) && ([info exists task_name_st($i)] && "" == $task_name_st($i)) } {
            ad_return_complaint 1 "Please provide task name for task no.: $task_nr_st($i)"
            ad_script_abort
    }

    # Check for duplicate names 
    if { [info exists task_name_st($i)] && "" != $task_name_st($i)} {
    	if { -1 != [lsearch -exact $project_names $task_name_st($i)] } {
            ad_return_complaint 1 "Please choose unique task names: $task_name_st($i)"
            ad_script_abort
    	}
		lappend project_names $task_name_st($i)
    }


    # Check the format of dates
    if { [info exists start_date($i)] } {
        if { [catch { set start_date_ansi [clock format [clock scan $start_date($i) ] -format %Y-%m-%d] } ""] } {
            ad_return_complaint 1 "<br>Start Date doesn't have the right format or is invalid<br>
            Current value: '$start_date($i)'<br>
            Expected format: 'YYYY-MM-DD'<br><br>"
            ad_script_abort
        }
		if { "" != $start_date_source_task && "" != $start_date($i) } {
		    if { [clock scan $start_date($i)] < [clock scan $start_date_source_task] } {
        	    ad_return_complaint 1 "<br>Start Date ($start_date($i)) is earlier than start date of source task ($start_date_source_task).<br><br>"
	            ad_script_abort					
			}
		}
    }

    if { [info exists end_date($i)] } {
		if { [catch { set end_date_ansi [clock format [clock scan $end_date($i) ] -format %Y-%m-%d] } ""] } {
    	        ad_return_complaint 1 "<br>End Date doesn't have the right format or is invalid.<br>
        	    Current value: '$end_date($i)'<br>
            	Expected format: 'YYYY-MM-DD'<br>"
	            ad_script_abort
		}
		if { "" != $end_date_source_task && "" != $end_date($i) } {
		    if { [clock scan $end_date($i)] > [clock scan $end_date_source_task] } {
        		ad_return_complaint 1 "<br>End Date ($end_date($i)) is later than end date of source task ($end_date_source_task).<br>"
	        	ad_script_abort					
			}
		}
    }

    # End date < Start Date of task? 
    if { [info exists start_date($i)] && [info exists end_date($i)] } {
        if { [clock scan $start_date($i)] > [clock scan $end_date($i)] } {
            ad_return_complaint 1 "<br>End Date needs to be later than start date <br><br>"
            ad_script_abort
        }
    }

    # Assignee selected? 
    if { ![info exists assignee_id($i)]  } {
            ad_return_complaint 1 "<br>You need to select an assignee for task: $task_name_st($i)<br>"
            ad_script_abort
    }
}

# Permissions
# - permissions are controlled using portlet permissions
# im_project_permissions $user_id $project_id project_view project_read project_write project_admin

# --------------------------
# Create new sub-project 
# --------------------------

# Get all info about this tasks 

db_1row sender_get_info_1 "
	select
		p.project_name as task_project_name,
		p.project_nr as task_project_nr,
		p.project_path as task_project_path,
        p.company_id as task_company_id,
        p.project_type_id as task_project_type_id,
        p.project_status_id as task_project_status_id,
		p.parent_id as task_parent_id,
		t.billable_units,
		t.cost_center_id
    from
        im_projects p,
		im_timesheet_tasks t
     where
        project_id = :source_task_id and 
		p.project_id = t.task_id
"

if { [info exists task_parent_id] && "" != $task_parent_id } {
	# get info about project this tasks belongs to
	db_1row sender_get_info_1 "
	select
 		p.project_name, 
		p.project_nr,
		p.project_path,
		p.company_id,
		p.project_type_id,
		p.project_status_id                       
	from
		im_projects p
	where
		project_id = $task_parent_id
	"
} else {
    ad_return_complaint 1 [lang::message::lookup "" intranet-cust-lippokwolf.NoProjectFound "Could not find a project for this task"]
}


db_transaction {
	# Create for each task 
	for {set j 1} {$j < 6} {incr j} {
		if { "" == $task_name_st($j)  } { continue }
    	set set_p 0

		ns_log NOTICE "KHD: $j : $task_name_st($j) : $source_task_id"

   		set db_planned_units $planned_units($j)
   		set db_task_nr $task_nr_st($j) 
	   	set db_task_name $task_name_st($j)	
		set db_uom_id $uom_id($j)
	
		set sql "
        	SELECT im_timesheet_task__new (
                null,               -- p_task_id
                'im_timesheet_task',    -- object_type
                now(),                  -- creation_date
                null,                   -- creation_user
                null,                   -- creation_ip
                null,                   -- context_id

                :db_task_nr,
                :db_task_name,
                :source_task_id,
                $default_material_id,
				null,
    	        :db_uom_id,
                :task_type_id,
                :task_status_id,
				''
 			)
		"
        if {[catch { set task_id [db_string create_task $sql -default 0] } errmsg ]} {
               ad_return_complaint 1 $errmsg
        }

		# Copy "Cost Center" from source_task to new task    
		if { [info exists cost_center_id] } {
	        set sql "
			update 
				im_timesheet_tasks 
			set 
				cost_center_id = :cost_center_id
			where 
				task_id = $task_id
			"
			if {[catch { db_dml target_languages $sql } errmsg ]} {
				ad_return_complaint 1 $errmsg
			}
		}

        # Write Planned Units 
        if { [info exists planned_units($j)] && "0" != $planned_units($j) } {
			set sql "
                        update
                                im_timesheet_tasks
                        set
                                planned_units = :db_planned_units
                        where
                                task_id = $task_id
            "
            if {[catch { db_dml target_languages $sql } errmsg ]} {
				ad_return_complaint 1 $errmsg
            }
        }

        set db_start_date $start_date($j)
        set db_end_date $end_date($j)

		# Set task attributes 
		set sql "
	        update im_projects set
        	        project_name    = :db_task_name,
                	project_nr      = :db_task_nr,
	                project_type_id = :task_type_id,
        	        project_status_id = :task_status_id,
                	start_date      = :db_start_date,
	                end_date        = :db_end_date
        	where
                	project_id = :task_id;
		"
		if {[catch { db_dml update_project $sql } errmsg ]} {
			ad_return_complaint 1 $errmsg
		}

    	# Assign users to task 
    	set db_assignee_id $assignee_id($j)
		im_biz_object_add_role $db_assignee_id $task_id 1300

	} ; # end for-while loop 

	# Change Project Type  
	set sql "
                update im_projects set
                        project_type_id = :project_type_id
                where
                        project_id = :source_task_id;
        "
	if {[catch { db_dml update_project $sql } errmsg ]} {
        	ad_return_complaint 1 $errmsg
    }

    set sql "
                update acs_objects set
                        object_type = 'im_project'
                where
                        object_id = :source_task_id;
    "
    if {[catch { db_dml update_project $sql } errmsg ]} {
		ad_return_complaint 1 $errmsg
    }

	# Delete entry from timesheet task table    
	set sql "delete from im_timesheet_tasks where task_id = :source_task_id"
	if {[catch { db_dml update_project $sql } errmsg ]} {
		ad_return_complaint 1 $errmsg
    }

    # Write Audit Trail
    # im_project_audit -project_id $task_id -action after_create

} on_error {
	ad_return_complaint 1 "DB Transaction Error: Could not create Tasks: $errmsg"
}

ad_returnredirect "/intranet/projects/view?project_id=$source_task_id"
