# /packages/intranet-cogonovis/www/projects/project-ae.tcl
#
# Copyright (c) 2011, cognovís GmbH, Hamburg, Germany
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see
# <http://www.gnu.org/licenses/>.
#
 
ad_page_contract {
    
    Purpose: form to add a new project or edit an existing one
    @author Malte Sussdorff (malte.sussdorff@cognovis.de)
    @creation-date 2011-08-05
} {
    {project_type_id ""}
    {project_status_id:integer,optional}
    {company_id ""}
    {parent_id ""}
    {project_nr ""}
    {project_name ""}
    {workflow_key ""}
    {return_url ""}
    {project_id:integer,optional}
}

# -----------------------------------------------------------
# Defaults
# -----------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set user_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
set current_url [im_url_with_query]
set org_project_type_id [im_opt_val project_type_id]
set sub_navbar ""
set auto_increment_project_nr_p [parameter::get -parameter ProjectNrAutoIncrementP -package_id [im_package_core_id] -default 0]
set project_name_field_min_len [parameter::get -parameter ProjectNameMinimumLength -package_id [im_package_core_id] -default 5]
set project_nr_field_min_len [parameter::get -parameter ProjectNrMinimumLength -package_id [im_package_core_id] -default 5]

if { ![exists_and_not_null return_url] && [exists_and_not_null project_id]} {
    set return_url "[im_url_stub]/projects/view?[export_url_vars project_id]"
}

# Do we need the customer_id for creating a project?
# This is necessary if the project_nr depends on the customer_id.
set customer_required_p [parameter::get_from_package_key -package_key "intranet-core" -parameter "NewProjectRequiresCustomerP" -default 0]

if { (![info exists project_id] || "" == $project_id) && $company_id == "" && $customer_required_p} {
    ad_returnredirect [export_vars -base "new-custselect" {project_id parent_id project_nr workflow_key return_url}]
    ad_script_abort
}




# -----------------------------------------------------------
# Permissions
# -----------------------------------------------------------
     
set view_finance_p [im_permission $user_id view_finance]
set view_budget_p [im_permission $user_id view_budget]
set view_budget_hours_p [im_permission $user_id view_budget_hours]
set add_budget_p [im_permission $user_id add_budget]
set add_budget_hours_p [im_permission $user_id add_budget_hours]


set project_exists_p 0
if {[info exists project_id]} {
    set project_exists_p [db_string project_exists "
	select count(*) 
	from im_projects 
	where project_id = :project_id
    " -default 0]
}

if {$project_exists_p} {
    
    # Check project permissions for this user
    im_project_permissions $user_id $project_id view read write admin
    if {!$write} {
	ad_return_complaint "Insufficient Privileges" "
            <li>You don't have sufficient privileges to see this page."
	return
    }
    
} else {
    
    set perm_p 0
    # Check if the user has admin rights on the parent_id
    # to allow freelancers to add sub-projects
    if {"" != $parent_id} {
	im_project_permissions $user_id $parent_id view read write admin
        if {$admin} { set perm_p 1 }
    }
    
    # Users with "add_projects" privilege can always create new projects...
    if {[im_permission $user_id add_projects]} { set perm_p 1 } 
    if {!$perm_p} { 
        ad_return_complaint "Insufficient Privileges" "
            <li>You don't have sufficient privileges to see this page."
        return
    }
    
    # Do we need to get the project type first in order to show the right DynFields?
    if {("" == $org_project_type_id || 0 == $org_project_type_id)} {
        set all_same_p [im_dynfield::subtype_have_same_attributes_p -object_type "im_project"]
        if {!$all_same_p} {
            set exclude_category_ids [list \
                                          [im_project_type_ticket] \
                                          [im_project_type_software_release_item] \
                                         ]
            
            if {![exists_and_not_null project_id]} {
                ad_returnredirect [export_vars -base "/intranet/biz-object-type-select" {
                    project_name
                    project_id
                    also_add_users
                    company_id
                    { return_url "/intranet/projects/new" }
                    { object_type "im_project" }
                    { type_id_var "project_type_id" }
                    { pass_through_variables "project_name also_add_users company_id" }
                    { exclude_category_ids $exclude_category_ids }
                }]
            }
        }
    }
}

# --------------------------------------------
# Create Form
# --------------------------------------------

set form_id "project-ae"
ad_form -name $form_id -action /intranet/projects/new -cancel_url $return_url -form {
    project_id:key
}


# ------------------------------------------------------
# Dynamic Fields
# ------------------------------------------------------

set object_type "im_project"
set dynfield_project_type_id [im_opt_val project_type_id]
if {[info exists project_id]} {
    set existing_project_type_id [db_string ptype "select project_type_id from im_projects where project_id = :project_id" -default 0]
    if {0 != $existing_project_type_id && "" != $existing_project_type_id} {
        set dynfield_project_type_id $existing_project_type_id
    }
}

# Returnredirect to translations for translation projects
if {[apm_package_installed_p "intranet-translation"] && [im_category_is_a $dynfield_project_type_id [im_project_type_translation]] && ![info exists project_id]} {
    ad_returnredirect [export_vars -base "/intranet-translation/projects/new" -url {project_type_id project_status_id company_id parent_id project_nr project_name workflow_key return_url project_id}]
}

set dynfield_project_id 0
if {[exists_and_not_null project_id]} {
    set dynfield_project_id $project_id 
    set ::super_project_id $project_id
} else { 
    set ::super_project_id 0
}

im_dynfield::append_attributes_to_form \
    -object_subtype_id $dynfield_project_type_id \
    -object_type $object_type \
    -form_id $form_id \
    -object_id $dynfield_project_id 



set requires_report_p "f"

ad_form -extend -name $form_id -new_request { 
    
    # -------------------------------------------
    # Set Defaut Values
    # -------------------------------------------
    if { ![exists_and_not_null parent_id] } {
        
        
        # A brand new project (not a subproject)
        if { ![exists_and_not_null company_id] } {
            set company_id [im_company_internal]
        }
        set page_title "[_ intranet-core.Add_New_Project]"
        set context_bar [im_context_bar [list ./ "[_ intranet-core.Projects]"] $page_title]
        set parent_id ""
        
    } else {
        
        # This means we are adding a subproject.
        # Let's select out some defaults for this page
        db_1row projects_by_parent_id_query {select 
	    p.company_id, 
	    p.project_type_id as parent_type_id, 
	    p.project_status_id as parent_status_id
	    from
	    im_projects p
	    where 
	    p.project_id=:parent_id}
        
        # Now set the values for status and type
        if {![exists_and_not_null project_status_id]} {
            template::element::set_value $form_id project_status_id $parent_status_id
        }
        if {$project_type_id eq ""} {
            template::element::set_value $form_id project_type_id $parent_type_id
	    set project_type_id $parent_type_id
        }
        set page_title "[_ intranet-core.Add_subproject]"
        set context_bar [im_context_bar [list ./ "[_ intranet-core.Projects]"] [list "view?project_id=$parent_id" "[_ intranet-core.One_project]"] $page_title]
    }
    
    # Calculate the next project number by calculating the maximum of
    # the "reasonably build numbers" currently available
    set project_nr [im_next_project_nr -customer_id $company_id -parent_id $parent_id]

    # Now set the values
    template::element::set_value $form_id project_nr $project_nr

    set company_enabled_p [db_string company "select 1 from im_dynfield_type_attribute_map tam, im_dynfield_attributes da, acs_attributes a where a.attribute_id = da.acs_attribute_id and a.attribute_name = 'company_id' and tam.attribute_id = da.attribute_id and tam.object_type_id = :project_type_id and tam.display_mode in ('edit','display')" -default 0]
    if {$company_enabled_p} {
	template::element::set_value $form_id company_id $company_id
    }
    
} -edit_request { 
    set page_title "[_ intranet-core.Edit_project]"
    set context_bar [im_context_bar [list /intranet/projects/ "[_ intranet-core.Projects]"] [list "/intranet/projects/view?[export_url_vars project_id]" "One project"] $page_title]
        
    set button_text "[_ intranet-core.Save_Changes]"
} -on_submit {
    
    # Permission check. Cases include a user with full add_projects rights,
    # but also a freelancer updating an existing project or a freelancer
    # creating a sub-project of a project he or she can admin.
    set perm_p 0
    
    # Check for the case that this guy is a freelance
    # project manager of the project or similar...
    im_project_permissions $user_id $project_id view read write admin
    if {$write} { set perm_p 1 }

    # Check if the user has admin rights on the parent_id
    # to allow freelancers to add sub-projects
    if {"" != $parent_id} {
        im_project_permissions $user_id $parent_id view read write admin
        if {$write} { set perm_p 1 }
    }
    
    # Users with "add_projects" privilege can always create new projects...
    if {[im_permission $user_id add_projects]} { set perm_p 1 } 
    
    if {!$perm_p} { 
        ad_return_complaint "Insufficient Privileges" "<li>You don't have sufficient privileges to see this page."
        ad_script_abort
    }
    
    if {[info exists project_nr]} {
        set project_nr [string tolower [string trim $project_nr]]
    }
} -new_data {
    
    
    if { ![exists_and_not_null company_id] } {
	set company_id [im_company_internal]
    }
    
    if {![exists_and_not_null project_path]} {
        set project_path [string tolower [string trim $project_name]]
    }
    
    # Check if the project_nr already exists, if yes, create a new one
    set project_nr_p [db_0or1row select_project_nr {
        SELECT project_id FROM im_projects WHERE project_nr = :project_nr
    }]
    if {$project_nr_p} {
        set project_nr [im_next_project_nr]
    }
    
    db_transaction {
        set project_id [project::new \
                            -project_name $project_name \
                            -project_nr $project_nr \
                            -project_path $project_path \
                            -company_id $company_id \
                            -parent_id $parent_id \
                            -project_type_id $project_type_id \
                            -project_status_id $project_status_id \
                           ]
        
        
        
        
        if {0 == $project_id || "" == $project_id} {
            ad_return_complaint 1 "
	    <b>Error creating project</b>:<br>
	    We have got an error creating a new project.<br>
	    There is probably something wrong with the projects's parameters below:<br>&nbsp;<br>
	    <pre>
	    project_name            $project_name
	    project_nr              $project_nr
	    project_path            $project_path
	    company_id              $company_id
	    parent_id               $parent_id
	    project_type_id         $project_type_id
	    project_status_id       $project_status_id
	    </pre><br>&nbsp;<br>
	    For reference, here is the error message:<br>
	    <pre>$err_msg</pre>
	"
            ad_script_abort
        }
        
        # add users to the project as PMs
        # - current_user (creator/owner)
        # - project_leader
        # - supervisor
        
        set role_id [im_biz_object_role_project_manager]
        im_biz_object_add_role $user_id $project_id $role_id 
        if {[exists_and_not_null project_lead_id]} {
            im_biz_object_add_role $project_lead_id $project_id $role_id 
        }
        
        
        # -----------------------------------------------------------------
        # Create a new Workflow for the project either if:
        # - specified explicitely in the parameters or
        # - if there is a WF associated with the project_type
        
        # Check if there is a WF associated with the project type
        if {![exists_and_not_null workflow_key]} {
            set wf_key [db_string wf "select aux_string1 from im_categories where category_id = :project_type_id" -default ""]
            set wf_exists_p [db_string wf_exists "select count(*) from wf_workflows where workflow_key = :wf_key"]
            if {$wf_exists_p} { set workflow_key $wf_key }
        }
        
        if {[exists_and_not_null workflow_key]} {
            # Create a new workflow case (instance)
            set context_key ""
            
            set case_id [wf_case_new \
                             $workflow_key \
                             $context_key \
                             $project_id \
                            ]
            
            # Determine the first task in the case to be executed and start+finisch the task.
            im_workflow_skip_first_transition -case_id $case_id
            
        }
        
        # Set the old project type. Used to detect changes in the project
        # type and therefore the need to display new DynField fields in a
        # second page.
        set previous_project_type_id 0
        
        # -----------------------------------------------------------------
        # Update the Project
        # -----------------------------------------------------------------
        # -----------------------------------------------------------------
        # Store dynamic fields
        
        ns_log Notice "/intranet/projects/new: im_dynfield::attribute_store -object_type $object_type -object_id $project_id -form_id $form_id"
        if {[info exists start_date]} {
            set start_date [template::util::date get_property sql_date $start_date]
        } else {
            set start_date [template::util::date::today]
        }
        if {[info exists end_date]} {set end_date [template::util::date get_property sql_timestamp $end_date]}
        
        im_dynfield::attribute_store \
            -object_type $object_type \
            -object_id $project_id \
            -form_id $form_id
        
        set requires_report_p t
        
        
        # Write Audit Trail
        im_project_audit -project_id $project_id  -type_id $project_type_id -status_id $project_status_id -action after_create
        
        
        # -----------------------------------------------------------------
        # add the creating current_user to the group
        # ERROR inexistent role
        if { [exists_and_not_null project_lead_id] } {
            im_biz_object_add_role $project_lead_id $project_id [im_biz_object_role_project_manager]
        }
        
        
        # -----------------------------------------------------------------
        # Call the "project_create" or "project_update" user_exit
        
        im_user_exit_call project_create $project_id
        
        
        
        # -----------------------------------------------------------------
        # Flush caches related to the project's information
        
        util_memoize_flush_regexp "im_project_has_type_helper.*"
        util_memoize_flush_regexp "db_list_of_lists company_info.*"
        
    }
    
} -edit_data {
    
    set previous_project_type_id [db_string prev_ptype {select project_type_id from im_projects where project_id = :project_id} -default 0]	
    
    set project_path $project_nr
	
    
    # -----------------------------------------------------------------
    # Store dynamic fields
    
    ns_log Notice "/intranet/projects/new: im_dynfield::attribute_store -object_type $object_type -object_id $project_id -form_id $form_id"

    im_dynfield::attribute_store \
        -object_type $object_type \
        -object_id $project_id \
        -form_id $form_id
    

    # -----------------------------------------------------------------                                                                                                                                                # Create a new Workflow for the project either if:                                                                                                                                                                 # - specified explicitely in the parameters or                                                                                                                                                                     # - if there is a WF associated with the project_type                                                                                                                                                              # Check if there is a WF associated with the project type                                                                                                                                                       
    if {"" == $workflow_key} {
        set wf_key [db_string wf "select aux_string1 from im_categories where category_id = :project_type_id" -default ""]
        set wf_exists_p [db_string wf_exists "select count(*) from wf_workflows where workflow_key = :wf_key"]
        if {$wf_exists_p} { set workflow_key $wf_key }
    }

    # Project Approval WF had been executed and finsihed at least one                                                                                                                                               
    set wf_finished_p 0
    
    if {[info exists project_id] } {
	# Check if WF case already exist for project                                                                                                                                                                
        set workflow_case_id [db_string wf_exists "select case_id from wf_cases where workflow_key = :wf_key and object_id = :project_id limit 1" -default 0]
    } else {
	set wf_finished_p [db_string wf_exists "select count(*) from wf_cases where workflow_key = :wf_key and object_id = :project_id and state = 'finished' limit 1"]
    }
    
    if { 0 == $workflow_case_id && $wf_exists_p && !$wf_finished_p } {
	# Create a new workflow case (instance)                                                                                                                                                                 
	set context_key ""
	set case_id [wf_case_new \
			 $workflow_key \
			 $context_key \
			 $project_id \
			]
	# Determine the first task in the case to be executed and start+finisch the task.                                                                                                                       
	im_workflow_skip_first_transition -case_id $case_id
    }
    
    # Write Audit Trail
    im_project_audit -project_id $project_id -type_id $project_type_id -status_id $project_status_id -action after_update

    # -----------------------------------------------------------------
    # add the creating current_user to the group
    
    if { [exists_and_not_null project_lead_id] } {
        im_biz_object_add_role $project_lead_id $project_id [im_biz_object_role_project_manager]
    }
    
    
    # -----------------------------------------------------------------
    # Call the "project_create" or "project_update" user_exit
    im_user_exit_call project_update $project_id
    
    
    
    # -----------------------------------------------------------------
    # Flush caches related to the project's information
    util_memoize_flush_regexp "im_project_has_type_helper.*"
    util_memoize_flush_regexp "db_list_of_lists company_info.*"

    # Send a notification for this task
    set params [list  [list base_url "/intranet/projects/"]  [list project_id $project_id] [list return_url ""] [list no_write_p 1]]
    
    set result [ad_parse_template -params $params "/packages/intranet-core/lib/project-base-data"]
    set project_url [export_vars -base "[im_url]/projects/view" -url {project_id}]
    notification::new \
        -type_id [notification::type::get_type_id -short_name project_notif] \
        -object_id $project_id \
        -response_id "" \
        -notif_subject "Edit Project: $project_name" \
        -notif_html "<h1><a href='$project_url'>$project_name</h1><p /><div align=left>[string trim $result]</div>"
    
    # ---------------------------------------
    # Close subprojects and tasks if needed
    # ---------------------------------------
    
    if {[im_category_is_a $project_status_id [im_project_status_closed]]} {
	
	# Find the list of tasks in all subprojects and close them
	# We might need to think about workflows in the future here!
	set close_task_ids [im_project_subproject_ids -project_id $project_id -type task]
	foreach close_task_id $close_task_ids {
	    db_dml close_task "update im_timesheet_tasks set task_status_id = [im_timesheet_task_status_closed] where task_id = :close_task_id"
	    db_dml close_task "update im_projects set project_status_id = [im_project_status_closed] where project_id = :close_task_id"
	}

	# Find the list of subprojects
	set close_subproject_ids [im_project_subproject_ids -project_id $project_id -exclude_self]
	foreach close_project_id $close_subproject_ids {
	    db_dml close_task "update im_projects set project_status_id = :project_status_id where project_id = :close_project_id"
	}
    }
	
	
} -after_submit {
  
    set return_url [export_vars -base "/intranet/projects/view" {project_id}]
        
    ad_returnredirect $return_url
    ad_script_abort
}



# -----------------------------------------------------------
# NavBars
# ----------------------------------------------------------- 

set sub_navbar ""
set edit_existing_project_p 0

if {$edit_existing_project_p && [exists_and_not_null project_id]} {
    
    # Setup the subnavbar
    set bind_vars [ns_set create]
    ns_set put $bind_vars project_id [im_opt_val project_id]
    set parent_menu_id [db_string parent_menu "select menu_id from im_menus where label='project'" -default 0]
    set menu_label "project_summary"
    set sub_navbar [im_sub_navbar \
                        -base_url [export_vars -base "/intranet/projects/view" {project_id}] \
                        $parent_menu_id \
                        $bind_vars "" "pagedesriptionbar" $menu_label \
                       ]
}
