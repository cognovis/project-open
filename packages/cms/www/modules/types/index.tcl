# query for attributes of this subclass of content_revision and display them

request create
request set_param id -datatype keyword -value content_revision
request set_param parent_id -datatype keyword -optional
request set_param mount_point -datatype keyword -value types
request set_param refresh_tree -datatype keyword -optional -value t

# Tree hack
if { [string equal $id content_revision] } {
  set refresh_id ""
} else {
  set refresh_id $id
}

set content_type $id
set user_id [User::getID]
set root_id [cm::modules::templates::getRootFolderID]

set module_id [db_string get_module_id ""]

content::check_access $module_id cm_examine -user_id $user_id

set can_edit_widgets $user_permissions(cm_write)


# get the content type pretty name
set object_type_pretty [db_string get_object_type ""]

if { [string equal $object_type_pretty ""] } {
    # error - invalid content_type
    template::forward index
}


# get all the content types that this content type inherits from
db_multirow content_type_tree get_content_type ""

# get all the attribute properties for this object_type
db_multirow attribute_types get_attr_types ""

# get template information
db_multirow type_templates get_type_templates ""

set page_title "Content Type - $object_type_pretty"

# for the permissions include
set return_url [ns_conn url]
set passthrough [content::assemble_passthrough return_url mount_point id]

# for templates table
if { [string equal $user_permissions(cm_write) t] } {
    set footer "<a href=\"register-templates?content_type=$content_type\">
    Register marked templates to this content type</a>"
} else {
    set footer ""
}

# Create the tabbed dialog
set url [ns_conn url]
append url "?id=$id&mount_point=$mount_point&parent_id=$parent_id&refresh_tree=f"

template::tabstrip create type_props -base_url $url
template::tabstrip add_tab type_props attributes "Attributes and Uploads" attributes
template::tabstrip add_tab type_props relations "Relation Types" relations
template::tabstrip add_tab type_props templates "Templates" templates
template::tabstrip add_tab type_props permissions "Permissions" permissions

