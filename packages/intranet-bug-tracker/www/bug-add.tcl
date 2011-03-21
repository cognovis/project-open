ad_page_contract {
    Bug add page.
    
    @author Lars Pind (lars@pinds.com)
    @author Frank Bergmann <frank.bergmann@project-open.com>
    @creation-date 2002-03-25
    @cvs-id $Id: bug-add.tcl,v 1.4 2007/05/15 23:38:50 cvs Exp $
} {
    maintenance_project_id
    {return_url ""}
}

if { [empty_string_p $return_url] } { set return_url "." }

# ToDo: Permissions

# User needs to be logged in here
set user_id [ad_maybe_redirect_for_registration]

db_1row maint_project_info "
    select
	p.bt_project_id as package_id,
	p.bt_project_id as project_id,
	p.project_name as project_name,
	p.bt_component_id as component_id,
	p.bt_found_in_version_id,
	p.bt_fix_for_version_id
    from
	im_projects p
    where
	project_id = :maintenance_project_id
"

# Set some common bug-tracker variables
set package_key [db_string package_key "select package_key from apm_packages where package_id = :package_id"]
set workflow_id [bug_tracker::bug::get_instance_workflow_id -package_id $package_id]
set page_title "New [bug_tracker::conn Bug -package_id $package_id]"
set context [list $page_title]

# Is this project using multiple versions?
set versions_p [bug_tracker::versions_p -package_id $package_id]

set user_version [bug_tracker::conn user_version_id -package_id $package_id]

# ad_return_complaint 1 $user_version

# Create the form
ad_form -name bug -cancel_url $return_url -form {
    bug_id:key(acs_object_id_seq) 

    {component_id:text(select) 
        {label "[bug_tracker::conn Component -package_id $package_id]"} 
	{options {[bug_tracker::components_get_options -package_id $package_id]}} 
	{value {[bug_tracker::conn component_id -package_id $package_id]}}
    }
    {summary:text 
	{label "Summary"} 
	{html {size 50}}
    }
    {found_in_version:text(select),optional 
        {label "Found in Version"}  
        {options {[bug_tracker::version_get_options -include_unknown -package_id $package_id]}} 
        {value {[bug_tracker::conn user_version_id -package_id $package_id]}}
    }
    {fix_for_version:text(select),optional 
        {label "Fix For Version"}  
        {options {[bug_tracker::version_get_options -include_unknown -package_id $package_id]}} 
        {value {[bug_tracker::conn user_version_id -package_id $package_id]}}
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
            [list options [bug_tracker::category_get_options -parent_id $category_id -package_id $package_id]] \
            [list value   [bug_tracker::get_default_keyword -parent_id $category_id -package_id $package_id]] \
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
	-assign_to $assign_to


} -after_submit {
    bug_tracker::bugs_exist_p_set_true

    ad_returnredirect $return_url
    ad_script_abort
}


if { !$versions_p } {
    element set_properties bug found_in_version -widget hidden
}

ad_return_template
