######################################################
#
# Procedures to generate and maintain the browser's tree
#
# Each module resides in its own namespace, and implements 
# the following 3 procs:
#
# getChildFolders { id } - returns the child folders of a given
#    folder
# getSortedPaths { name id_list {root_id 0} {eval_code {}}} - sets the name to be a multirow
#  datasource listing all paths in sorted order
#  The datasource must contain 3 columns: item_id, item_path and item_type
#
# The folder data structure is a list of the form
#
# { mount_point name id {} expandable_p symlink_p }
#
#####################################################
 

namespace eval cm {
    namespace eval modules {     
        namespace eval workspace  { }
        namespace eval templates  { }
        namespace eval workflow   { }
        namespace eval sitemap    { }
        namespace eval types      { }
        namespace eval search     { }
        namespace eval categories { }
        namespace eval users      { }
        namespace eval clipboard  { }
    }
}


ad_proc -public cm::modules::get_module_id { module_name } {

 Get the id of some module, return empty string on failure

} {
    set id [db_string module_get_id ""]

    return $id
}

ad_proc -public cm::modules::getMountPoints {} {

  Get a list of all the mount points

} {
    set mount_point_list [db_list_of_lists get_list ""]
    
    # Append clipboard
    lappend mount_point_list [folderCreate "clipboard" "Clipboard" "" [list] t f 0]

    return $mount_point_list
}

ad_proc -public cm::modules::getChildFolders { mount_point id } {

  Generic getCHildFolders procedure for sitemap and templates

} {

    # query for child site nodes
    set module_name [namespace tail [namespace current]]

    set result [db_list_of_lists module_get_result ""]

    return $result
}

ad_proc -public cm::modules::workspace::getRootFolderID {} { return 0 } 

ad_proc -public cm::modules::workspace::getChildFolders { id } {
    return [list]
}



ad_proc -public cm::modules::templates::getRootFolderID {} {

  Retreive the id of the root folder

} {
    if { ![nsv_exists browser_state template_root] } {
        set root_id [db_string template_get_root_id ""]
        nsv_set browser_state template_root $root_id
        return $root_id
    } else {
        return [nsv_get browser_state template_root]
    }
}

ad_proc -public cm::modules::templates::getChildFolders { id } {


} {
    if { [string equal $id {}] } {
        set id [getRootFolderID]
    }

    # query for child site nodes
    set module_name [namespace tail [namespace current]]

    return [cm::modules::getChildFolders $module_name $id]
}

ad_proc -public cm::modules::templates::getSortedPaths { name id_list {root_id 0} {eval_code {}}} {


} {
    uplevel "
          cm::modules::sitemap::getSortedPaths $name \{$id_list\} $root_id \{$eval_code\}
        "
}

ad_proc -public cm::modules::workflow::getRootFolderID {} { return 0 } 

ad_proc -public cm::modules::workflow::getChildFolders { id } {
    return [list]
}



ad_proc -public cm::modules::sitemap::getRootFolderID {} {

  Retreive the id of the root folder

} {
    if { ![nsv_exists browser_state sitemap_root] } {
        set root_id [db_string sitemap_get_root_id ""]
        nsv_set browser_state sitemap_root $root_id
        return $root_id
    } else {
        return [nsv_get browser_state sitemap_root]
    }
}

ad_proc -public cm::modules::sitemap::getChildFolders { id } {


} {
    if { [string equal $id {}] } {
        set id [getRootFolderID]
    }

    # query for child site nodes
    set module_name [namespace tail [namespace current]]
    
    return [cm::modules::getChildFolders $module_name $id]
}

ad_proc -public cm::modules::sitemap::getSortedPaths { name id_list {root_id 0} {eval_code {}}} {


} {

    set sql_id_list "'"
    append sql_id_list [join $id_list "','"]
    append sql_id_list "'"

    upvar sorted_paths_root_id _root_id
    set _root_id $root_id
    set sql [db_map sitemap_get_name]
    uplevel "db_multirow $name sitemap_get_name \{$sql\} { $eval_code }"
} 




ad_proc -public cm::modules::types::getTypesTree { } {

  Return a multilist representing the types tree,
  for use in a select widget

} {

    set result [db_list_of_lists types_get_result ""]

    set result [concat [list [list "--" ""]] $result]

    return $result
}

ad_proc -public cm::modules::types::getRootFolderID {} { return "content_revision" } 

ad_proc -public cm::modules::types::getChildFolders { id } {


} {

    set children [list]

    if { [string equal $id {}] } {
        set id [getRootFolderID]
    }

    # query for message categories
    set module_name [namespace tail [namespace current]]

    set result [db_list_of_lists get_result ""]

    return $result
}

# end of types namespace

ad_proc -public cm::modules::search::getRootFolderID {} { return 0 } 

ad_proc -public cm::modules::search::getChildFolders { id } {
    return [list]
}


ad_proc -public cm::modules::categories::getRootFolderID {} { return 0 } 

ad_proc -public cm::modules::categories::getChildFolders { id } {


} {

    set children [list]

    if { [string equal $id {}] } {
        set where_clause "k.parent_id is null"
    } else {
        set where_clause "k.parent_id = :id"
    }

    set module_name [namespace tail [namespace current]]

    # query for keyword categories

    set children [db_list_of_lists category_get_children ""]

    return $children
}

ad_proc -public cm::modules::categories::getSortedPaths { name id_list {root_id 0} {eval_code {}}} {


} {

    set sql_id_list "'"
    append sql_id_list [join $id_list "','"]
    append sql_id_list "'"

    set sql  [db_map get_paths]
    uplevel "db_multirow $name get_paths \{$sql\} \{$eval_code\}"
}


# end of categories namespace

ad_proc -public cm::modules::users::getRootFolderID {} { return 0 }  

ad_proc -public cm::modules::users::getChildFolders { id } {


} {
    
    if { [string equal $id {}] } {
        set where_clause "not exists (select 1 from group_component_map m
                                          where m.component_id = g.group_id)"
        set map_table ""
    } else {
        set where_clause "m.group_id = :id and m.component_id = g.group_id"
        set map_table ", group_component_map m"
    }

    set module_name [namespace tail [namespace current]]


    set result [db_list_of_lists users_get_result ""]

    return $result
}

ad_proc -public cm::modules::users::getSortedPaths { name id_list {root_id 0} {eval_code {}}} {


} {

    set sql_id_list "'"
    append sql_id_list [join $id_list "','"]
    append sql_id_list "'"

    set sql [db_map users_get_paths]
    
    uplevel "db_multirow $name users_get_paths \{$sql\} \{$eval_code\}"
}



ad_proc -public cm::modules::clipboard::getRootFolderID {} { return 0 } 

ad_proc -public cm::modules::clipboard::getChildFolders { id } {


} {

    # Only the mount point is expandable
    if { ![template::util::is_nil id] } {
        return [list]
    }

    set children [list]
    
    set module_name [namespace tail [namespace current]] 

    set result [db_list_of_lists clip_get_result ""]

    return $result
}

# end of clipboard namespace


