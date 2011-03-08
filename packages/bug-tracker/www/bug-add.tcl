ad_page_contract {
    Bug add page.
    
    @author Lars Pind (lars@pinds.com)
    @creation-date 2002-03-25
    @cvs-id $Id: bug-add.tcl,v 1.5 2008/03/12 07:57:57 podesign Exp $
} {
    { return_url "" }
    { bug_container_project_id "" }
}

if { [empty_string_p $return_url] } {
    set return_url "."
}

ad_require_permission [ad_conn package_id] create

# User needs to be logged in here
ad_maybe_redirect_for_registration

# Set some common bug-tracker variables
set project_name [bug_tracker::conn project_name]
set package_id [ad_conn package_id]
set package_key [ad_conn package_key]
set workflow_id [bug_tracker::bug::get_instance_workflow_id]

set page_title "New [bug_tracker::conn Bug]"

set context [list $page_title]

set user_id [ad_conn user_id]

if { $bug_container_project_id != "" } {

  db_1row fetch_bug_container_defaults "
    select
	bt_found_in_version_id,
	bt_fix_for_version_id
    from
	im_projects
    where
	project_id = :bug_container_project_id
  "
} else {
    set bt_found_in_version_id [bug_tracker::conn user_version_id]
    set bt_fix_for_version_id $bt_found_in_version_id
}

# Is this project using multiple versions?
set versions_p [bug_tracker::versions_p]

# Create the form
ad_form -name bug -cancel_url $return_url -form {
    bug_id:key(acs_object_id_seq) 

    {component_id:text(select) 
        {label "[bug_tracker::conn Component]"} 
	{options {[bug_tracker::components_get_options]}} 
	{value {[bug_tracker::conn component_id]}}
    }
    {summary:text 
	{label "Summary"} 
	{html {size 50}}
    }
}


set tmp [im_bt_project_options]

if {$tmp == ""} {
    ad_form -extend -name bug -form {
	{dummy:text(inform)
	    {label "Project"}
	    {value "bug without container project"}
	}
    }
} else {
    ad_form -extend -name bug -form {
	{bug_container_project_id:integer(select)
	    {label "Project"}
	    {options {[im_bt_project_options]}}
	    {values $bug_container_project_id}
	}
    }
} 

ad_form -extend -name bug -form {
    {found_in_version:text(select),optional 
        {label "Found in Version"}  
        {options {[bug_tracker::version_get_options -include_unknown]}} 
        {value {$bt_found_in_version_id}}
    }
    {fix_for_version:text(select),optional 
        {label "Fix For Version"}  
        {options {[bug_tracker::version_get_options -include_unknown]}} 
        {value {$bt_fix_for_version_id}}
    }

    {assign_to:text(select),optional 
        {label "Assign to"}  
        {options {[bug_tracker::assignee_get_options -workflow_id $workflow_id -include_unknown]}} 
    }

    {return_url:text(hidden) {value $return_url}}
}



foreach {category_id category_name} [bug_tracker::category_types] {
    ad_form -extend -name bug -form [list \
        [list "${category_id}:integer(select)" \
            [list label $category_name] \
            [list options [bug_tracker::category_get_options -parent_id $category_id]] \
            [list value   [bug_tracker::get_default_keyword -parent_id $category_id]] \
        ] \
    ]
}


ad_form -extend -name bug -form {
    {description:richtext(richtext),optional
        {label "Description"}
        {html {cols 60 rows 13}}
    }

}

ad_form -extend -name bug -new_data {

    set keyword_ids [list]
    foreach {category_id category_name} [bug_tracker::category_types] {
        # -singular not required here since it's a new bug
        lappend keyword_ids [element get_value bug $category_id]
    }

    bug_tracker::bug::new \
	-bug_id $bug_id \
	-package_id $package_id \
	-component_id $component_id \
	-found_in_version $found_in_version \
	-summary $summary \
	-description [template::util::richtext::get_property contents $description] \
	-desc_format [template::util::richtext::get_property format $description] \
        -keyword_ids $keyword_ids \
	-fix_for_version $fix_for_version \
	-assign_to $assign_to \
	-bug_container_project_id $bug_container_project_id
       


} -after_submit {
    bug_tracker::bugs_exist_p_set_true

    ad_returnredirect $return_url
    ad_script_abort
}


if { !$versions_p } {
    element set_properties bug found_in_version -widget hidden
}

ad_return_template
