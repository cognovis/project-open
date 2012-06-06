ad_page_contract {
    Shows one bug.

    @author Lars Pind (lars@pinds.com)
    @creation-date 2002-03-20
    @cvs-id $Id$
} [bug_tracker::get_page_variables {
    bug_number:integer,notnull
    {user_agent_p:boolean 0}
    {show_patch_status "open"}
}]

#####
#
# Setup
#
#####

ns_log Notice "********************************************************"

set return_url [export_vars -base [ad_conn url] [bug_tracker::get_export_variables { bug_number }]]

set project_name [bug_tracker::conn project_name]
set package_id [ad_conn package_id]
set package_key [ad_conn package_key]
set user_id [ad_conn user_id]

permission::require_permission -object_id $package_id -privilege read

set page_title "[bug_tracker::conn Bug] #$bug_number" 
set fs_title [lang::message::lookup "" bug-tracker.Related_Files "Related Files"]
set context [list [ad_quotehtml $page_title]]


# Is this project using multiple versions?
set versions_p [bug_tracker::versions_p]

# Paches enabled for this project?
set patches_p [bug_tracker::patches_p]


#####
#
# Get basic info
#
#####

# Get the bug_id
if { ![db_0or1row permission_info {} -column_array bug] } {
    ad_return_complaint 1 "Could not find bug \#$bug_number"
    return
}

set case_id [workflow::case::get_id \
        -object_id $bug(bug_id) \
        -workflow_short_name [bug_tracker::bug::workflow_short_name]]

set workflow_id [bug_tracker::bug::get_instance_workflow_id]


#####
#
# Action
#
#####

set enabled_action_id [form get_action bug]


# Registration required for all actions
set action_id ""
if { ![empty_string_p $enabled_action_id] } {
    ns_log Notice "enabled_action if statement"
    ad_maybe_redirect_for_registration
    workflow::case::enabled_action_get -enabled_action_id $enabled_action_id -array enabled_action    
    set action_id $enabled_action(action_id)
}


# Check permissions
if { ![workflow::case::action::available_p -enabled_action_id $enabled_action_id] } {
    bug_tracker::security_violation -user_id $user_id -bug_id $bug(bug_id) -action_id $action_id
}


ns_log Notice "actions: enabled_action_id: -${enabled_action_id}-"


# Buttons
set actions [list]
if { [empty_string_p $enabled_action_id] } {

    ns_log Notice "actions: case_id: $case_id"
    ns_log Notice "actions: case_id: $case_id get_enabled_actions: [workflow::case::get_available_enabled_action_ids -case_id $case_id]"

    foreach available_enabled_action_id [workflow::case::get_available_enabled_action_ids -case_id $case_id] {
        # TODO: avoid the enabled_action_get query by caching it, or caching only the enabled_action_id -> action_id lookup?
        workflow::case::enabled_action_get -enabled_action_id $available_enabled_action_id -array enabled_action
        workflow::action::get -action_id $enabled_action(action_id) -array available_action
        lappend actions [list "     $available_action(pretty_name)     " $available_enabled_action_id]
    }
}

ns_log Notice "actions: $actions"

#####
#
# Create the form
#
#####

# Set the variable that we need for the elements below


# set patch label
# JCD: The string map below is to work around a "feature" in the form generation that 
# lets you use +var+ for a var to eval on the second round.  
# cf http://openacs.org/bugtracker/openacs/bug?bug%5fnumber=1099

if { [empty_string_p $enabled_action_id] } {
    set patch_label [ad_decode $show_patch_status \
                         "open" "Open Patches (<a href=\"[string map {+ %20} [export_vars -base [ad_conn url] -entire_form -override { { show_patch_status all } }]]\">show all</a>)" \
                         "all" "All Patches (<a href=\"[string map {+ %20} [export_vars -base [ad_conn url] -entire_form -override { { show_patch_status open } }]]\">show only open)" \
                         "Patches"]
} else {
    set patch_label [ad_decode $show_patch_status \
                         "open" "Open Patches" \
                         "all" "All Patches" \
                         "Patches"]
}

ad_form -name bug -cancel_url $return_url -mode display -has_edit 1 -actions $actions -form  {
    {bug_number_display:text(inform)
	{label "[bug_tracker::conn Bug] \#"}
        {mode display}
    }
    {component_id:integer(select),optional
	{label "[bug_tracker::conn Component]"}
	{options {[bug_tracker::components_get_options]}}
	{mode display}
    }
    {summary:text(text)
	{label "Summary"}
	{before_html "<b>"}
	{after_html "</b>"}
	{mode display}
	{html {size 50}}
    }
    {bug_container_project_id:integer(select),optional
	{label "Project"}
	{options {[im_bt_project_options -include_empty_p 1]}}
    }
 }


ad_form -extend -name bug -form {
    {pretty_state:text(inform)
	{label "Status"}
	{before_html "<b>"}
	{after_html  "</b>"}
	{mode display}
    }
    {resolution:text(select),optional
	{label "Resolution"}
	{options {[bug_tracker::resolution_get_options]}}
	{mode display}
    }
}

foreach {category_id category_name} [bug_tracker::category_types] {
    ad_form -extend -name bug -form [list \
        [list "${category_id}:integer(select)" \
            [list label $category_name] \
            [list options [bug_tracker::category_get_options -parent_id $category_id]] \
            [list mode display] \
        ] \
    ]
}


ad_form -extend -name bug -form {
    {found_in_version:text(select),optional
	{label "Found in Version"}
	{options {[bug_tracker::version_get_options -include_unknown]}}
	{mode display}
    }
}

workflow::case::role::add_assignee_widgets -case_id $case_id -form_name bug

# More fixed form elements

ad_form -extend -name bug -form {
    {patches:text(inform)
	{label $patch_label}
	{mode display}
    }
    {user_agent:text(inform)
	{label "User Agent"}
	{mode display}
    }
    {fix_for_version:text(select),optional
	{label "Fix for Version"}
	{options {[bug_tracker::version_get_options -include_undecided]}}
	{mode display}
    }
    {fixed_in_version:text(select),optional
	{label "Fixed in Version"}
	{options {[bug_tracker::version_get_options -include_undecided]}}
	{mode display}
    }
    {description:richtext(richtext),optional
	{label "Description"} 
	{html {cols 60 rows 13}} 
    }
    {return_url:text(hidden) 
	{value $return_url}
    }
    {bug_number:key}
    {entry_id:integer(hidden),optional}
}

# TODO: Export filters
set filters [list]
foreach name [bug_tracker::get_export_variables] { 
    if { [info exists $name] } {
        lappend filters [list "${name}:text(hidden),optional" [list value [set $name]]]
    }
}
ad_form -extend -name bug -form $filters

# Set editable fields
if { ![empty_string_p $enabled_action_id] } {   
    foreach field [workflow::action::get_element -action_id $action_id -element edit_fields] { 
	element set_properties bug $field -mode edit 
    }
    
    # LARS: Hack! How do we set editing of dynamic fields?
    if { [string equal [workflow::action::get_element -action_id $action_id -element short_name] "edit"] } {
        foreach { category_id category_name } [bug_tracker::category_types] {
            element set_properties bug $category_id -mode edit
        }
    }
} 
    

# on_submit block
ad_form -extend -name bug -on_submit {

    array set row [list] 
    
    if { ![empty_string_p $enabled_action_id] } { 
        foreach field [workflow::action::get_element -action_id $action_id -element edit_fields] {
            set row($field) [element get_value bug $field]
        }
        foreach {category_id category_name} [bug_tracker::category_types] {
            set row($category_id) [element get_value bug $category_id]
        }
    }
    
    set description [element get_value bug description]

    set row(bug_container_project_id) $bug_container_project_id
    
    bug_tracker::bug::edit \
            -bug_id $bug(bug_id) \
            -enabled_action_id $enabled_action_id \
            -description [template::util::richtext::get_property contents $description] \
            -desc_format [template::util::richtext::get_property format $description] \
            -array row \
            -entry_id [element get_value bug entry_id]    


    ad_returnredirect $return_url
    ad_script_abort

} -edit_request {
    # Dummy
    # If we don't have this, ad_form complains
}

# Not-valid block (request or submit error)
# Unfortunately, ad_form doesn't let us do what we want, namely have a block that executes
# whenever the form is displayed, whether initially or because of a validation error.
if { ![form is_valid bug] } {

    # Get the bug data
    bug_tracker::bug::get -bug_id $bug(bug_id) -array bug -enabled_action_id $enabled_action_id


    # Make list of form fields
    set element_names {
        bug_number component_id summary pretty_state resolution 
        found_in_version user_agent fix_for_version fixed_in_version 
        bug_number_display entry_id bug_container_project_id
    }

    # update the element_name list and bug array with category stuff
    foreach {category_id category_name} [bug_tracker::category_types] {
        lappend element_names $category_id
        set bug($category_id) [cr::keyword::item_get_assigned -item_id $bug(bug_id) -parent_id $category_id]
        if {[string compare $bug($category_id) ""] == 0} {
            set bug($category_id) [bug_tracker::get_default_keyword -parent_id $category_id]
        }
    }
    
    # Display value for patches
    set bug(patches_display) "[bug_tracker::get_patch_links -bug_id $bug(bug_id) -show_patch_status $show_patch_status] &nbsp; \[ <a href=\"patch-add?[export_vars { { bug_number $bug(bug_number) } { component_id $bug(component_id) } }]\">Upload a patch</a> \]"

    # Hide elements that should be hidden depending on the bug status
    foreach element $bug(hide_fields) {
        element set_properties bug $element -widget hidden
    }

    if { !$versions_p } {
        foreach element { found_in_version fix_for_version fixed_in_version } {
            if { [info exists bug:$element] } {
                element set_properties bug $element -widget hidden
            }
        }
    }

    if { !$patches_p } {
        foreach element { patches } {
            if { [info exists bug:$element] } {
                element set_properties bug $element -widget hidden
            }
        }
    }

    # Optionally hide user agent
    if { !$user_agent_p } {
        element set_properties bug user_agent -widget hidden
    }

    # Set regular element values
    foreach element $element_names { 

        # check that the element exists
        if { [info exists bug:$element] && [info exists bug($element)] } {
            if { [form is_request bug] || [string equal [element get_property bug $element mode] "display"] } {
                element set_value bug $element $bug($element)
            }
        }
    }
    
    # Add empty option to resolution code
    if { ![empty_string_p $enabled_action_id] } {
        if { [lsearch [workflow::action::get_element -action_id $action_id -element edit_fields] "resolution"] == -1 } {
            element set_properties bug resolution -options [concat {{{} {}}} [element get_property bug resolution options]]
        }
    } else {
        element set_properties bug resolution -widget hidden
    }

    # Get values for the role assignment widgets
    workflow::case::role::set_assignee_values -case_id $case_id -form_name bug
    
    # Set values for elements with separate display value
    foreach element { 
        patches
    } {
        # check that the element exists
        if { [info exists bug:$element] } {
            element set_properties bug $element -display_value $bug(${element}_display)
        }
    }

    # Set values for description field
    element set_properties bug description \
            -before_html [workflow::case::get_activity_html -case_id $case_id -action_id $action_id]

    # Set page title
    set page_title "[bug_tracker::conn Bug] #$bug_number: $bug(summary)"

    # Context bar
    # TODO: Make real
    set filtered_p 1
    if { $filtered_p } {
        set context [list \
                         [list \
                              [export_vars -base . [bug_tracker::get_export_variables]] \
                              "Filtered [bug_tracker::conn bug] list"] \
                         [ad_quotehtml $page_title]]
    } else {
        set context [list [ad_quotehtml $page_title]]
    }
    
    # User agent show/hide URLs
    if { [empty_string_p $enabled_action_id] } {
        set show_user_agent_url [export_vars -base bug -entire_form -override { { user_agent_p 1 }}]
        set hide_user_agent_url [export_vars -base bug -entire_form -exclude { user_agent_p }]
    }
    
    # Login
    set login_url [ad_get_login_url]
    
    # Single-bug notifications 
    if { [empty_string_p $enabled_action_id]  } {
        set notification_link [bug_tracker::bug::get_watch_link -bug_id $bug(bug_id)]
    }
}
