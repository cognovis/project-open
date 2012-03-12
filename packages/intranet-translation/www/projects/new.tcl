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
    target_language_ids:multiple,optional
}

# -----------------------------------------------------------
# Defaults
# -----------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set user_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
set current_url [im_url_with_query]
set org_project_type_id [im_opt_val project_type_id]
set sub_navbar ""

if { ![exists_and_not_null return_url] && [exists_and_not_null project_id]} {
    set return_url "[im_url_stub]/projects/view?[export_url_vars project_id]"
}


# Do we need the company_id for creating a project?
# This is necessary if the project_nr depends on the company_id.
set customer_required_p [parameter::get_from_package_key -package_key "intranet-core" -parameter "NewProjectRequiresCustomerP" -default 0]
if {![info exists project_id] && $company_id == "" && $customer_required_p} {
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
    set project_exists_p [db_string project_exists {select 1 from im_projects where project_id = :project_id} -default 0]
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
ad_form -name $form_id -action /intranet-translation/projects/new -cancel_url $return_url -form {
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

set customer_group_id [im_customer_group_id]
set freelance_group_id [im_freelance_group_id]

set company_contacts_sql "
select DISTINCT
    im_name_from_user_id(u.user_id) as user_name,
    u.user_id
from
    cc_users u,
    group_distinct_member_map m,
    acs_rels ur
where
    u.member_state = 'approved'
    and u.user_id = m.member_id
    and m.group_id in (:customer_group_id, :freelance_group_id)
    and u.user_id = ur.object_id_two
    and ur.object_id_one = :company_id
    and ur.object_id_one != 0
"

set company_contact_options [db_list_of_lists contacts $company_contacts_sql]
set target_language_options [db_list_of_lists languages "select category,category_id from im_categories where category_type = 'Intranet Translation Language' and enabled_p = 't' order by category"]
set help_text [_ acs-subsite.lt_Use_the_Browse_button]

set options_list [list [list "Unzip File?"  "t"]]
ad_form -extend -name $form_id -form {
    {company_contact_id:text(select),optional 
	{label "[_ intranet-translation.Client_contact]"}
	{options "$company_contact_options"}
    }
    {source_language_id:text(select)
	{label "[_ intranet-translation.Source_Language]"}
	{options "$target_language_options"}
    }
    {target_language_ids:text(multiselect)
	{label "[_ intranet-translation.Target_Languages]"}
	{options "$target_language_options"}
    }
    {upload_file:file(file),optional
        {label "#acs-subsite.Filename#"}
        {help_text $help_text}
    }
    {zip_p:text(checkbox),optional
	{label ""}
	{options $options_list}
    }
}

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
        db_1row projects_by_parent_id_query {}
        
        # Now set the values for status and type
        if {![exists_and_not_null project_status_id]} {
            template::element::set_value $form_id project_status_id $parent_status_id
        }
        if {$project_type_id eq ""} {
            template::element::set_value $form_id project_type_id $parent_type_id
        }
        set page_title "[_ intranet-core.Add_subproject]"
        set context_bar [im_context_bar [list ./ "[_ intranet-core.Projects]"] [list "view?project_id=$parent_id" "[_ intranet-core.One_project]"] $page_title]
    }
    
    # Calculate the next project number by calculating the maximum of
    # the "reasonably build numbers" currently available
    set project_nr [im_next_project_nr -customer_id $company_id -parent_id $parent_id]

    # Now set the values
    template::element::set_value $form_id project_nr $project_nr
    template::element::set_value $form_id company_id $company_id
    
} -validate { 
    
    {project_nr
        {![var_contains_quotes $project_nr]}
        {[_ intranet-core.lt_Quotes_in_Project_Nr_]}
    }
    {project_nr
        {[regexp {^[a-z0-9_]+$} $project_nr match]}
        {[lang::message::lookup "" intranet-core.Non_alphanum_chars_in_nr "The specified path contains invalid characters.<br> Allowed are only aphanumeric characters including a-z, 0-9 and '_'."]}
    }
    {project_nr
        {![regexp {/} $project_nr]}
        {[_ intranet-core.intranet-core.lt_Slashes__in_Project_P]}
    }
    {project_nr
        {![regexp {\.} $project_nr]}
        {[_ intranet-core.lt_Dots__in_Project_Path]}
    }
    {project_name
        {![var_contains_quotes $project_name]}
        {[_ intranet-core.lt_Quotes_in_Project_Nam]}
    }
    {parent_id
        {![string equal $parent_id $project_id]}
        {"Parent Project = Project"}
    }
    {end_date
        {[expr {[template::util::date get_property sql_date $end_date] >= [template::util::date get_property sql_date $start_date]}]}
        {[_ intranet-core.lt_End_date_must_be_afte]}
    }
    {percent_completed
        {[expr {$percent_completed <= 100}]}
        {"Number must be in range (0 .. 100)"}
    }
    {percent_completed
        {[expr {$percent_completed >= 0}]}
        {"Number must be in range (0 .. 100)"}
    }
    
} -on_submit {

    if { ![exists_and_not_null zip_p] } {
        set zip_p "f"
    }    

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
    set tmp_filename [ns_queryget upload_file.tmpfile]
    ds_comment "$tmp_filename"
content::item::upload_file -upload_file $upload_file \
    -parent_id 308034
    
    set tmp_filename [template::util::file::get_property tmp_filename $upload_file]
    set filename [template::util::file::get_property filename $upload_file]
    
    ds_comment "$tmp_filename ... $filename"
    asdasd
    
    
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

	set target_language_ids [element get_values $form_id target_language_ids]
	
	# Save the information about the project target languages
	# in the im_target_languages table
	#
	db_transaction {
	    db_dml delete_im_target_language "delete from im_target_languages where project_id=:project_id"
	    
	    foreach lang $target_language_ids {
		ns_log Notice "target_language=$lang"
		set sql "insert into im_target_languages values ($project_id, $lang)"
		db_dml insert_im_target_language $sql
		
		if {[im_table_exists im_freelancers]} {
		    im_freelance_add_required_skills -object_id $project_id -skill_type_id [im_freelance_skill_type_target_language] -skill_ids $lang
		}
	    }
	}

	if {[info exists company_contact_id]} {db_dml update_project "update im_projects set company_contact_id = :company_contact_id where project_id = :project_id"}

	# ---------------------------------------------------------------------
	# Create the directory structure necessary for the project
	# ---------------------------------------------------------------------
	
	# If the filestorage module is installed...
	set fs_installed_p [im_table_exists im_fs_folders]
	if {$fs_installed_p && [exists_and_not_null upload_file]} {
	    
	    set create_err ""
	    if { [catch {
		set create_err [im_filestorage_create_directories $project_id]
	    } err_msg] } {
		ad_return_complaint 1 "<li>err_msg: $err_msg<br>create_err: $create_err<br>"
		return
	    }
	    
	    # Save the file in the correct directory
	    set locale "en_US"
	    set source [lang::message::lookup $locale intranet-translation.Workflow_source_directory "source"]
	    set source_language [im_category_from_id $source_language_id]
	    
	    set project_dir [im_filestorage_project_path $project_id]
	    set source_dir "$project_dir/${source}_$source_language"
	    set tmp_filename [template::util::file::get_property tmp_filename $upload_file]

	    # strip off the C:\directories... crud and just get the file name
	    if {![regexp {([^/\\]+)$} $upload_file match client_filename]} {
		# couldn't find a match
		set client_filename $upload_file
	    }
	    
	    file copy $tmp_filename ${source_dir}/$filename	    
	    if {$zip_p eq "t"} {
		exec unzip -d ${source_dir} ${source_dir}/$filename
		file delete -force ${source_dir}/$filename
	    }
	}

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

} -after_submit {
    set return_url [export_vars -base "new-2" {project_id}]
        
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