ad_library {

    Bug Tracker Library

    @creation-date 2002-05-03
    @author Lars Pind <lars@collaboraid.biz>
    @cvs-id bug-tracker-procs.tcl,v 1.13.2.7 2003/03/05 18:13:39 lars Exp

}

namespace eval bug_tracker {}

ad_proc bug_tracker::package_key {} {
    return "bug-tracker"
}

ad_proc bug_tracker::conn { args } {

    global bt_conn

    set flag [lindex $args 0]
    if { [string index $flag 0] != "-" } {
        set var $flag
        set flag "-get"
    } else {
        set var [lindex $args 1]
    }

    switch -- $flag {
        -set {
            set bt_conn($var) [lindex $args 2]
        }

        -get {
            if { [info exists bt_conn($var)] } {
                return $bt_conn($var)
            } else {
                switch -- $var {
                    bug - bugs - Bug - Bugs - 
                    component - components - Component - Components {
                        get_pretty_names -array bt_conn
                        return $bt_conn($var)
                    }
                    project_name - project_description - 
                    project_root_keyword_id - project_folder_id - 
                    current_version_id - current_version_name {
                        array set info [get_project_info]
                        foreach name [array names info] {
                            set bt_conn($name) $info($name)
                        }
                        return $bt_conn($var)
                    }
                    user_first_names - user_last_name - user_email - user_version_id - user_version_name {
                        if { [ad_conn user_id] == 0 } {
                            return ""
                        } else {
                            array set info [get_user_prefs]
                            foreach name [array names info] {
                                set bt_conn($name) $info($name)
                            }
                            return $bt_conn($var)
                        }
                    }
                    component_id - 
                    filter - filter_human_readable - 
                    filter_where_clauses - 
                    filter_order_by_clause - filter_from_bug_clause {
                        return {}
                    }
                    default {
                        error "Unknown variable $var"
                    }
                }
            }
        }

        default {
            error "bt_conn: unknown flag $flag"
        }
    }
}

ad_proc bug_tracker::get_pretty_names { 
    -array:required
} {
    upvar $array row

    set row(bug) [parameter::get -parameter "TicketPrettyName" -default "bug"]
    set row(bugs) [parameter::get -parameter "TicketPrettyPlural" -default "bugs"]
    set row(Bug) [string totitle $row(bug)]
    set row(Bugs) [string totitle $row(bugs)]

    set row(component) [parameter::get -parameter "ComponentPrettyName" -default "component"]
    set row(components) [parameter::get -parameter "ComponentPrettyPlural" -default "components"]
    set row(Component) [string totitle $row(component)]
    set row(Components) [string totitle $row(components)]
}

ad_proc bug_tracker::get_bug_id {
    {-bug_number:required}
    {-project_id:required}
} {
    return [db_string bug_id {}]
}


ad_proc bug_tracker::get_page_variables { 
    {extra_spec ""}
} {
    Adds the bug listing filter variables for use in the page contract.
    
    ad_page_contract { doc } [bug_tracker::get_page_variables { foo:integer { bar "" } }]
} {
    set filter_vars {
        page:optional
        f_state:optional
        f_fix_for_version:optional
        f_component:optional
        orderby:optional
        {format "table"}
    }
    foreach { parent_id parent_heading } [bug_tracker::category_types] {
        lappend filter_vars "f_category_$parent_id:optional"
    }
    foreach action_id [workflow::get_actions -workflow_id [bug_tracker::bug::get_instance_workflow_id]] {
        lappend filter_vars "f_action_$action_id:optional"
    }

    return [concat $filter_vars $extra_spec]
}

ad_proc bug_tracker::get_export_variables { 
    {extra_vars ""}
} {
    Gets a list of variables to export for the bug list
} {
    set export_vars {
        f_state
        f_fix_for_version
        f_component
        orderby
        format
    }
    foreach { parent_id parent_heading } [bug_tracker::category_types] {
        lappend export_vars "f_category_$parent_id"
    }
    foreach action_id [workflow::get_actions -workflow_id [bug_tracker::bug::get_instance_workflow_id]] {
        lappend export_vars "f_action_$action_id"
    }

    return [concat $export_vars $extra_vars]
}

#####
#
# Cached project info procs
# 
#####

ad_proc bug_tracker::get_project_info_internal {
    package_id
} {
    db_1row project_info {} -column_array result
    
    return [array get result]
}

ad_proc bug_tracker::get_project_info {
    -package_id
} {
    if { ![info exists package_id] } {
        set package_id [ad_conn package_id]
    }

    return [util_memoize [list bug_tracker::get_project_info_internal $package_id]]
}

ad_proc bug_tracker::get_project_info_flush {
    -package_id
} {
    if { ![info exists package_id] } {
        set package_id [ad_conn package_id]
    }

    util_memoize_flush [list bug_tracker::get_project_info_internal $package_id]
}

ad_proc bug_tracker::set_project_name {
    -package_id
    project_name
} {
    if { ![info exists package_id] } {
        set package_id [ad_conn package_id]
    }
    
    db_dml project_name_update {}
    
    # Flush cache
    util_memoize_flush [list bug_tracker::get_project_info_internal $package_id]]
}
   


#####
#
# Stats procs
#
#####
 

ad_proc -public bug_tracker::bugs_exist_p {
    {-package_id {}}
} {
    Returns whether any bugs exist in a project
} {
    if { ![exists_and_not_null package_id] } {
        set package_id [ad_conn package_id]
    }

    return [util_memoize [list bug_tracker::bugs_exist_p_not_cached -package_id $package_id]]
}
    
ad_proc -public bug_tracker::bugs_exist_p_set_true {
    {-package_id {}}
} {
    Sets bug_exists_p true. Useful for when you add a new bug, so you know that a bug will exist.
} {
    if { ![exists_and_not_null package_id] } {
        set package_id [ad_conn package_id]
    }

    return [util_memoize_seed [list bug_tracker::bugs_exist_p_not_cached -package_id $package_id] 1]
}
    
ad_proc -public bug_tracker::bugs_exist_p_not_cached {
    -package_id:required
} {
    Returns whether any bugs exist in a project. Not cached.
} {
    return [db_string select_bugs_exist_p {} -default 0]
}
    
    
    
#####
#
# Cached user prefs procs
#
#####

ad_proc bug_tracker::get_user_prefs_internal {
    package_id
    user_id
} {
    set found_p [db_0or1row user_info { } -column_array result]

    if { !$found_p } {
        set count [db_string count_user_prefs {}]
        if { $count == 0 } {
            db_dml create_user_prefs {}
            # we call ourselves again, so we'll get the info this time
            return [get_user_prefs_internal $package_id $user_id]
        } else {
            error "Couldn't find user in database"
        }
    } else {
        return [array get result]
    }
}

ad_proc bug_tracker::get_user_prefs {
    -package_id
    -user_id
} {
    if { ![info exists package_id] } {
        set package_id [ad_conn package_id]
    }

    if { ![info exists user_id] } {
        set user_id [ad_conn user_id]
    }

    return [util_memoize [list bug_tracker::get_user_prefs_internal $package_id $user_id]]
}

ad_proc bug_tracker::get_user_prefs_flush {
    -package_id
    -user_id
} {
    if { ![info exists package_id] } {
        set package_id [ad_conn package_id]
    }

    if { ![info exists user_id] } {
        set user_id [ad_conn user_id]
    }

    util_memoize_flush [list bug_tracker::get_user_prefs_internal $package_id $user_id]
}
    
    
#####
#
# Status
#
#####

ad_proc bug_tracker::status_get_options {
    {-package_id ""}
} {
    if { [empty_string_p $package_id] } {
        set package_id [ad_conn package_id]
    }

    set workflow_id [bug_tracker::bug::get_instance_workflow_id -package_id $package_id]
    set state_ids [workflow::fsm::get_states -workflow_id $workflow_id]

    set option_list [list]
    foreach state_id $state_ids {
        workflow::state::fsm::get -state_id $state_id -array state
        lappend option_list [list "$state(pretty_name)" $state(short_name)]
    }

    return $option_list
}

ad_proc bug_tracker::status_pretty {
    status
} {
    set workflow_id [bug_tracker::bug::get_instance_workflow_id]
    if { [catch {set state_id [workflow::state::fsm::get_id -workflow_id $workflow_id -short_name $status]} error] } {
        return ""
    }

    workflow::state::fsm::get -state_id $state_id -array state
    
    return $state(pretty_name)
}

ad_proc bug_tracker::patch_status_get_options {} {
    return { { "Open" open } { "Accepted" accepted } { "Refused" refused }  { "Deleted" deleted }}
}

ad_proc bug_tracker::patch_status_pretty {
    status
} {
    array set status_codes {
        open      "Open"
        accepted  "Accepted"
        refused   "Refused"
        deleted   "Deleted"
    }
    if { [info exists status_codes($status)] } {
        return $status_codes($status)
    } else {
        return ""
    }
}    
    
#####
#
# Resolution
#
#####

ad_proc bug_tracker::resolution_get_options {} {
    return { 
        { "Fixed" fixed } { "By Design" bydesign } { "Won't Fix" wontfix } { "Postponed" postponed } 
        { "Duplicate" duplicate } { "Not Reproducable" norepro } { "Need Info" needinfo } 
    }
}

ad_proc bug_tracker::resolution_pretty {
    resolution
} {
    array set resolution_codes {
        fixed "Fixed"
        bydesign "By Design" 
        wontfix "Won't Fix" 
        postponed "Postponed"
        duplicate "Duplicate"
        norepro "Not Reproducable"
        needinfo "Need Info"
    }
    if { [info exists resolution_codes($resolution)] } {
        return $resolution_codes($resolution)
    } else {
        return ""
    }
}
    
    
    


#####
#
# Categories/Keywords
#
#####

ad_proc bug_tracker::category_parent_heading {
    {-package_id ""}
    -keyword_id:required
} {
    return [bug_tracker::category_parent_element -package_id $pcakage_id -keyword_id $keyword_id -element heading]
}

# TODO: This could be made faster if we do a reverse mapping array from child to parent

ad_proc bug_tracker::category_parent_element {
    {-package_id ""}
    -keyword_id:required
    {-element "heading"}
} {
    foreach elm [get_keywords -package_id $package_id] {
        set child_id [lindex $elm 0]

        if { $child_id == $keyword_id } {
            set parent(id) [lindex $elm 2]
            set parent(heading) [lindex $elm 3]
            return $parent($element)
        }
    }
}

ad_proc bug_tracker::category_heading {
    {-package_id ""}
    -keyword_id:required
} {
    foreach elm [get_keywords -package_id $package_id] {
        set child_id [lindex $elm 0]
        set child_heading [lindex $elm 1]
        set parent_id [lindex $elm 2]
        set parent_heading [lindex $elm 3]
 
        if { $child_id == $keyword_id } {
            return $child_heading
        } elseif { $parent_id == $keyword_id } {
            return $parent_heading
        }
    }
}

ad_proc bug_tracker::category_types {
    {-package_id ""}
} {
    @return Returns the category types for this instance as an
    array-list of { parent_id1 heading1 parent_id2 heading2 ... }
} {
    array set heading [list]
    set parent_ids [list]
    
    set last_parent_id {}
    foreach elm [get_keywords -package_id $package_id] {
        set child_id [lindex $elm 0]
        set child_heading [lindex $elm 1]
        set parent_id [lindex $elm 2]
        set parent_heading [lindex $elm 3]
 
        if { $parent_id != $last_parent_id } {
            set heading($parent_id) $parent_heading
            lappend parent_ids $parent_id
            set last_parent_id $parent_id
        }
    }
    
    set result [list]
    foreach parent_id $parent_ids {
        lappend result $parent_id $heading($parent_id)
    }
    return $result
}

ad_proc bug_tracker::category_get_filter_data_not_cached {
    {-package_id:required}
    {-parent_id:required}
} {
    @param package_id The package (project) to select from
    @param parent_id The category type's keyword_id
    @return list-of-lists with category data for filter
} {
    return [db_list_of_lists select {}]
}

ad_proc bug_tracker::category_get_filter_data {
    {-package_id:required}
    {-parent_id:required}
} {
    @param package_id The package (project) to select from
    @param parent_id The category type's keyword_id
    @return list-of-lists with category data for filter
} {
    return [util_memoize [list bug_tracker::category_get_filter_data_not_cached \
                             -package_id $package_id \
                             -parent_id $parent_id]]
}


ad_proc bug_tracker::category_get_options {
    {-package_id ""}
    {-parent_id:required}
} {
    @param parent_id The category type's keyword_id
    @return options-list for a select widget for the given category type
} {
    set options [list]
    foreach elm [get_keywords -package_id $package_id] {
        set elm_child_id [lindex $elm 0]
        set elm_child_heading [lindex $elm 1]
        set elm_parent_id [lindex $elm 2]
 
        if { $elm_parent_id == $parent_id } {
            lappend options [list $elm_child_heading $elm_child_id]
        }
    }
    return $options
}


## Cache maintenance

ad_proc -private bug_tracker::get_keywords {
    {-package_id ""}
} {
    if { ![exists_and_not_null package_id] } {
        set package_id [ad_conn package_id]
    }
    return [util_memoize [list bug_tracker::get_keywords_not_cached -package_id $package_id]]
}

ad_proc -private bug_tracker::get_keywords_flush {
    {-package_id ""}
} {
    if { ![exists_and_not_null package_id] } {
        set package_id [ad_conn package_id]
    }
    util_memoize_flush [list bug_tracker::get_keywords_not_cached -package_id $package_id]
}

ad_proc -private bug_tracker::get_keywords_not_cached {
    -package_id:required
} {
    return [db_list_of_lists select_package_keywords {}]
}





ad_proc -public bug_tracker::set_default_keyword {
    {-package_id ""}
    {-parent_id:required}
    {-keyword_id:required}
} {
    Set the default keyword for a given type (parent)
} {
    if { ![exists_and_not_null package_id] } {
        set package_id [ad_conn package_id]
    }

    db_dml delete_existing { 
        delete
        from   bt_default_keywords 
        where  project_id = :package_id 
        and    parent_id = :parent_id
    }
    
    db_dml insert_new { 
        insert into bt_default_keywords (project_id, parent_id, keyword_id)
        values (:package_id, :parent_id, :keyword_id)
    }
    get_default_keyword_flush -package_id $package_id -parent_id $parent_id
}

ad_proc -public bug_tracker::get_default_keyword {
    {-package_id ""}
    {-parent_id:required}
} {
    Get the default keyword for a given type (parent)
} {
    if { ![exists_and_not_null package_id] } {
        set package_id [ad_conn package_id]
    }

    return [util_memoize [list bug_tracker::get_default_keyword_not_cached -package_id $package_id -parent_id $parent_id]]
}

ad_proc -public bug_tracker::get_default_keyword_flush {
    {-package_id ""}
    {-parent_id:required}
} {
    Flush the cache for 
} {
    if { ![exists_and_not_null package_id] } {
        set package_id [ad_conn package_id]
    }

    util_memoize_flush [list bug_tracker::get_default_keyword_not_cached -package_id $package_id -parent_id $parent_id]
}


ad_proc -private bug_tracker::get_default_keyword_not_cached {
    {-package_id:required}
    {-parent_id:required}
} {
    Get the default keyword for a given type (parent), not cached.
} {
    return [db_string default { 
        select keyword_id
        from   bt_default_keywords
        where  project_id = :package_id
        and    parent_id = :parent_id
    } -default {}]
}





ad_proc -public bug_tracker::get_default_configurations {} {
    Get the package's default configurations for categories and parameters.
} {
    return {
        "Bug-Tracker" {
            categories {
               "Bug Type" {
                    "*Bug"
                    "Task"
                }
                "Priority" {
                    "1 - Fix Immediately"
                    "2 - Fix Before Release"
                    "*3 - Normal"
                }
                "Severity" {
                    "1 - Crash, Data Loss, or Security"
                    "2 - Broken Function"
                    "*3 - Inconvenience"
                    "4 - Cosmetic"
                }
            }
            parameters {
                TicketPrettyName "bug"
                TicketPrettyPlural "bugs"
                ComponentPrettyName "component"
                ComponentPrettyPlural "components"
                PatchesP "1"
                VersionsP "1"
            }
        }
        "Ticket-Tracker" {
            categories {
                "Ticket Type" {
                    "*Todo"
                    "Suggestion"
                }
                "Priority" {
                    "1 - High"
                    "*2 - Normal"
                    "3 - Low"
                }
            }
            parameters {
                TicketPrettyName "ticket"
                TicketPrettyPlural "tickets"
                ComponentPrettyName "area"
                ComponentPrettyPlural "areas"
                PatchesP "0"
                VersionsP "0"
            }
        }
    }
}

ad_proc -public bug_tracker::delete_all_project_keywords {
    {-package_id ""}
} {
    Deletes all the keywords in a project
} {
    if { ![exists_and_not_null package_id] } {
        set package_id [ad_conn package_id]
    }
    db_exec_plsql keywords_delete {}
    bug_tracker::get_keywords_flush -package_id $package_id
}

ad_proc -public bug_tracker::install_keywords_setup {
    {-package_id ""}
    -spec:required
} {
    @param spec is an array-list of { Type1 { cat1 cat2 cat3 } Type2 { cat1 cat2 cat3 } }
    Default category within type is denoted by letting the name start with a *, 
    which is removed before creating the keyword.
} {
    set root_keyword_id [bug_tracker::conn project_root_keyword_id -package_id $package_id]

    foreach { category_type categories } $spec {
        set category_type_id [cr::keyword::get_keyword_id \
                                  -parent_id $root_keyword_id \
                                  -heading $category_type]
        
        if { [empty_string_p $category_type_id] } {
            set category_type_id [cr::keyword::new \
                                      -parent_id $root_keyword_id \
                                      -heading $category_type]
        }
        
        foreach category $categories {
            if { [string equal [string index $category 0] "*"] } {
                set default_p 1
                set category [string range $category 1 end]
            } else {
                set default_p 0
            }                  
            
            set category_id [cr::keyword::get_keyword_id \
                                 -parent_id $category_type_id \
                                 -heading $category]
            
            if { [empty_string_p $category_id] } {
                set category_id [cr::keyword::new \
                                     -parent_id $category_type_id \
                                     -heading $category]
            }

            if { $default_p } {
                bug_tracker::set_default_keyword \
                    -package_id $package_id \
                    -parent_id $category_type_id \
                    -keyword_id $category_id
            }
        }
    }
    bug_tracker::get_keywords_flush -package_id $package_id
}

ad_proc -public bug_tracker::install_parameters_setup {
    {-package_id ""}
    -spec:required
} {
    @param parameters as an array-list of { name value name value ... }
} {
    foreach { name value } $spec {
        parameter::set_value -package_id $package_id -parameter $name -value $value
    }
}



#####
#
# Versions
#
#####

ad_proc bug_tracker::version_get_options {
    -package_id
    -include_unknown:boolean
    -include_undecided:boolean
} {
    if { ![exists_and_not_null package_id] } {
        set package_id [ad_conn package_id]
    }
    
    set versions_list [util_memoize [list bug_tracker::version_get_options_not_cached $package_id]]

    if { $include_unknown_p } {
        set versions_list [concat { { "Unknown" "" } } $versions_list]
    } 
    
    if { $include_undecided_p } {
        set versions_list [concat { { "Undecided" "" } } $versions_list]
    } 
    
    return $versions_list
}


ad_proc bug_tracker::assignee_get_options {
    -workflow_id
    -include_unknown:boolean
    -include_undecided:boolean
} {
    Returns an option list containing all users that have submitted or assigned to a bug.
    Used for the add bug form. Added because the workflow api requires a case_id.  
    (an item to evaluate is refactoring workflow to provide an assignee widget without a case_id)
} {
   
    set assignee_list [db_list_of_lists assignees {}]

    if { $include_unknown_p } {
        set assignee_list [concat { { "Unknown" "" } } $assignee_list]
    } 
    
    if { $include_undecided_p } {
        set assignee_list [concat { { "Undecided" "" } } $assignee_list]
    } 
    
    return $assignee_list
}


ad_proc bug_tracker::versions_p {
    {-package_id ""}
} { 
    Is the versions feature turned on?
} {
    if { ![exists_and_not_null package_id] } {
        set package_id [ad_conn package_id]
    }
    
    return [parameter::get -package_id [ad_conn package_id] -parameter "VersionsP" -default 1]
}


ad_proc bug_tracker::versions_flush {} {
    set package_id [ad_conn package_id]
    util_memoize_flush [list bug_tracker::version_get_options_not_cached $package_id]
}

ad_proc bug_tracker::version_get_options_not_cached {
    package_id
} {
    set versions_list [db_list_of_lists versions {}]
    
    return $versions_list
}



ad_proc bug_tracker::version_get_name {
    {-package_id ""}
    {-version_id:required}
} {
    if { [empty_string_p $version_id] } {
        return {}
    }
    foreach elm [version_get_options -package_id $package_id] {
        set name [lindex $elm 0]
        set id [lindex $elm 1]
        if { [string equal $id $version_id] } {
            return $name
        }
    }
    error "Version_id $version_id not found"
}


#####
#
# Components
#
#####

ad_proc bug_tracker::component_get_filter_data_not_cached {
    {-package_id:required}
} {
    @param package_id The project we're interested in
    @return list-of-lists with component data for filter
} {
    return [db_list_of_lists select {}]
}

ad_proc bug_tracker::component_get_filter_data {
    {-package_id:required}
} {
    @param package_id The project we're interested in
    @return list-of-lists with component data for filter
} {
    return [util_memoize [list bug_tracker::component_get_filter_data_not_cached \
                             -package_id $package_id]]
}
ad_proc bug_tracker::components_get_options {
    {-package_id ""}
    -include_unknown:boolean
} {
    if { ![exists_and_not_null package_id] } {
        set package_id [ad_conn package_id]
    }

    set components_list [util_memoize [list bug_tracker::components_get_options_not_cached $package_id]]

    if { $include_unknown_p } {
        set components_list [concat { { "Unknown" "" } } $components_list]
    } 
    
    return $components_list
}

ad_proc bug_tracker::components_flush {} {
    set package_id [ad_conn package_id]
    util_memoize_flush [list bug_tracker::components_get_options_not_cached $package_id]
    util_memoize_flush [list bug_tracker::components_get_url_names_not_cached -package_id $package_id]
}

ad_proc bug_tracker::components_get_options_not_cached {
    package_id
} {
    set components_list [db_list_of_lists components {}]

    return $components_list
}

ad_proc bug_tracker::component_get_name {
    {-package_id ""}
    {-component_id:required}
} {
    if { [empty_string_p $component_id] } {
        return {}
    }
    foreach elm [components_get_options -package_id $package_id] {
        set id [lindex $elm 1]
        if { [string equal $id $component_id] } {
            return [lindex $elm 0]
        }
    }
    error "Component_id $component_id not found"
}

ad_proc bug_tracker::component_get_url_name {
    {-package_id ""}
    {-component_id:required}
} {
    if { [empty_string_p $component_id] } {
        return {}
    }
    foreach { id url_name } [components_get_url_names -package_id $package_id] {
        if { [string equal $id $component_id] } {
            return $url_name
        }
    }
    return {}
}

ad_proc bug_tracker::components_get_url_names {
    {-package_id ""}
} {
    if { ![exists_and_not_null package_id] } {
        set package_id [ad_conn package_id]
    }
    return [util_memoize [list bug_tracker::components_get_url_names_not_cached -package_id $package_id]]
}

ad_proc bug_tracker::components_get_url_names_not_cached {
    {-package_id:required}
} {
    db_foreach select_component_url_names {} {
        lappend result $component_id $url_name
    }
    return $result
}


#####
#
# Description (still used by the patch code, to be removed when they've moved to workflow)
#
#####

ad_proc bug_tracker::bug_convert_comment_to_html {
    {-comment:required}
    {-format:required}
} {
    return [ad_html_text_convert -from $format -to text/html -- $comment]
}

ad_proc bug_tracker::bug_convert_comment_to_text {
    {-comment:required}
    {-format:required}
} {
    return [ad_html_text_convert -from $format -to text/plain -- $comment]
}

#####
#
# Actions
#
#####

ad_proc bug_tracker::patch_action_pretty {
    action
} {

    array set action_codes {
        open "Opened"
        edit "Edited"
        comment "Comment"
        accept "Accepted"
        reopen "Reopened"
        refuse "Refused"
        delete "Deleted"
    }

    if { [info exists action_codes($action)] } {
        return $action_codes($action)
    } else {
        return ""
    }        
}

#####
#
# Maintainers
#
#####

ad_proc ::bug_tracker::users_get_options {
    -package_id
} {
    if { ![info exists package_id] } {
        set package_id [ad_conn package_id]
    }
    
    set user_id [ad_conn user_id]
    
    # This picks out users who are already assigned to some bug in this
    set sql {
        select first_names || ' ' || last_name || ' (' || email || ')'  as name, 
               user_id
        from   cc_users
        where  user_id in (
                      select maintainer
                      from   bt_projects
                      where  project_id = :package_id
                      
                      union
                      
                      select maintainer
                      from   bt_versions
                      where  project_id = :package_id
                      
                      union
                      
                      select maintainer
                      from   bt_components
                      where  project_id = :package_id
                )
        or     user_id = :user_id
        order  by name
    }
    
    set users_list [db_list_of_lists users $sql]
    
    set users_list [concat { { "Unassigned" "" } } $users_list]
    lappend users_list { "Search..." ":search:"}
    
    return $users_list
}

   

#####
#
# Patches
#
#####

ad_proc bug_tracker::patches_p {} { 
    Is the patch submission feature turned on?
} {
    return [parameter::get -package_id [ad_conn package_id] -parameter "PatchesP" -default 1]
}

ad_proc bug_tracker::map_patch_to_bug {
    {-patch_id:required}
    {-bug_id:required}
} {                
    db_dml map_patch_to_bug {}
}

ad_proc bug_tracker::unmap_patch_from_bug {
    {-patch_number:required}
    {-bug_number:required}
} {
    set package_id [ad_conn package_id]
    db_dml unmap_patch_from_bug {}
}

ad_proc bug_tracker::get_mapped_bugs {
    {-patch_number:required}
    {-only_open_p "0"}
} {
    Return a list of lists with the bug number in the first element and the bug
    summary in the second.
} {
    set bug_list [list]
    set package_id [ad_conn package_id]

    if { $only_open_p } {
        set workflow_id [bug_tracker::bug::get_instance_workflow_id]
        set initial_state [workflow::fsm::get_initial_state -workflow_id $workflow_id]

        set open_clause "\n        and exists (select 1 
                                               from workflow_cases cas, 
                                                    workflow_case_fsm cfsm 
                                               where cas.case_id = cfsm.case_id 
                                                 and cas.object_id = b.bug_id 
                                                 and cfsm.current_state = :initial_state)"
    } else {
        set open_clause ""
    }

    db_foreach get_bugs_for_patch {} {
        lappend bug_list [list "[bug_tracker::conn Bug] #$bug_number: $summary" "$bug_number"]
    }

    return $bug_list
}

ad_proc bug_tracker::get_bug_links {
    {-patch_id:required}
    {-patch_number:required}
    {-write_or_submitter_p:required}
} {
    set bug_list [get_mapped_bugs -patch_number $patch_number]
    set bug_link_list [list]

    if { [llength $bug_list] == "0"} {
        return ""
    } else {
        
        foreach bug_item $bug_list {

            set bug_number [lindex $bug_item 1]
            set bug_summary [lindex $bug_item 0]

            set unmap_url "unmap-patch-from-bug?[export_vars -url { patch_number bug_number } ]"
            if { $write_or_submitter_p } {
                set unmap_link "(<a href=\"$unmap_url\">unmap</a>)"
            } else {
                set unmap_link ""
            }
            lappend bug_link_list "<a href=\"bug?bug_number=$bug_number \">$bug_summary</a> $unmap_link"
        } 

        if { [llength $bug_link_list] != 0 } {
            set bugs_string [join $bug_link_list "<br>"]
        } else {
            set bugs_string "No bugs." 
        }

        return $bugs_string
    }
}

ad_proc bug_tracker::get_patch_links {
    {-bug_id:required}
    {-show_patch_status "open"}
} {
    set patch_list [list]

    switch -- $show_patch_status {
        open {
            set status_where_clause "and bt_patches.status = :show_patch_status"
        }
        all {
            set status_where_clause ""
        }
    }

    db_foreach get_patches_for_bug "" {
        
        set status_indicator [ad_decode $show_patch_status "all" "($status)" ""]
        lappend patch_list "<a href=\"patch?patch_number=$patch_number\" title=\"patch $patch_number\">[ad_quotehtml $summary]</a> $status_indicator"
    } if_no_rows { 
        set patches_string "No patches." 
    }

    if { [llength $patch_list] != 0 } {
        set patches_string [join $patch_list ",&nbsp;"]
    }

    return $patches_string
}

ad_proc bug_tracker::get_patch_submitter {
    {-patch_number:required}
} {
    set package_id [ad_conn package_id]
    return [db_string patch_submitter_id {}] 
}

ad_proc bug_tracker::update_patch_status {
    {-patch_number:required}
    {-new_status:required}
} {
    set package_id [ad_conn package_id]
    db_dml update_patch_status ""
}

ad_proc bug_tracker::get_uploaded_patch_file_content {
    
} {
    set patch_file [ns_queryget patch_file]
   
    if { [empty_string_p $patch_file] } {
        # No patch file was uploaded
        return ""
    }

    set tmp_file [ns_queryget patch_file.tmpfile]
    set tmp_file_channel [open $tmp_file r]
    set content [read $tmp_file_channel]

    return $content
}

ad_proc bug_tracker::security_violation {
    -user_id:required
    -bug_id:required
    -action_id:required
} {
    workflow::action::get -action_id $enabled_action(action_id) -array action
    bug_tracker::bug::get -bug_id $bug_id -array bug

    ns_log notice "bug_tracker::security_violation: $user_id doesn't have permission to '$action(pretty_name)' on bug $bug(summary)"
    ad_return_forbidden \
            "Permission Denied" \
            "<blockquote>
    You don't have permission to '$action(pretty_name)' on bug #$bug_id (\"$bug(summary)\").
    </blockquote>"
    ad_script_abort
}


#####
#
# Projects
#
#####


ad_proc bug_tracker::project_delete { project_id } {
    Delete a Bug Tracker project and all its data.

    @author Peter Marklund
} {
    #manually delete all bugs to avoid wierd integrity constraints
    while { [set bug_id [db_string min_bug_id {}]] > 0 } {
        bug_tracker::bug::delete $bug_id
    }
    db_exec_plsql delete_project {}
}

ad_proc bug_tracker::project_new { project_id } {
    Create a new Bug Tracker project for a package instance.

    @author Peter Marklund
} {

    if {![db_0or1row already_there {select 1 from bt_projects where  project_id = :project_id} ] } {
	if [db_0or1row instance_info {select p.instance_name, o.creation_user, o.creation_ip from apm_packages p join acs_objects o on (p.package_id = o.object_id) where  p.package_id = :project_id }] {
	    set folder_id [content::folder::new -name "bug_tracker_$project_id" -package_id $project_id]
	    content::folder::register_content_type -folder_id $folder_id -content_type {bt_bug_revision} -include_subtypes t
	    
	    set keyword_id [content::keyword::new -heading "$instance_name"]
	    
	    # Inserts into bt_projects
	    set component_id [db_nextval acs_object_id_seq]
	    db_dml bt_projects_insert {}
	    db_dml bt_components_insert {}
	}
    }
}

ad_proc bug_tracker::version_get_filter_data_not_cached {
    {-package_id:required}
} {
    @param package_id The package (project) to select from
    @return list-of-lists with fix-for-version data for filter
} {
    return [db_list_of_lists select {}]
}

ad_proc bug_tracker::version_get_filter_data {
    {-package_id:required}
} {
    @param package_id The package (project) to select from
    @return list-of-lists with fix-for-version data for filter
} {
    return [util_memoize [list bug_tracker::version_get_filter_data_not_cached \
                             -package_id $package_id]] 
}

ad_proc bug_tracker::assignee_get_filter_data_not_cached {
    {-package_id:required}
    {-workflow_id:required}
    {-action_id:required}
} {
    @param package_id The package (project) to select from
    @param workflow_id The workflow we're interested in
    @param action_id The action we're interested in
    @return list-of-lists with assignee data for filter
} {
    return [db_list_of_lists select {}]
}

ad_proc bug_tracker::assignee_get_filter_data {
    {-package_id:required}
    {-workflow_id:required}
    {-action_id:required}
} {
    @param package_id The package (project) to select from
    @param workflow_id The workflow we're interested in
    @param action_id The action we're interested in
    @return list-of-lists with assignee data for filter
} {
    return [util_memoize [list bug_tracker::assignee_get_filter_data_not_cached \
                             -package_id $package_id \
                             -workflow_id $workflow_id \
                             -action_id $action_id]] 
}

ad_proc bug_tracker::state_get_filter_data_not_cached {
    {-package_id:required}
    {-workflow_id:required}
} {
    @param package_id The package (project) to select from
    @param workflow_id The workflow we're interested in
    @return list-of-lists with state data for filter
} {
    return [db_list_of_lists select {}]
}

ad_proc bug_tracker::state_get_filter_data {
    {-package_id:required}
    {-workflow_id:required}
} {
    @param package_id The package (project) to select from
    @param workflow_id The workflow we're interested in
    @return list-of-lists with state data for filter
} {
    return [util_memoize [list bug_tracker::state_get_filter_data_not_cached \
                             -package_id $package_id \
                             -workflow_id $workflow_id]]
}
