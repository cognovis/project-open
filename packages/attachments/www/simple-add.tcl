ad_page_contract {
    page to add a new nonversioned object to the system

    @author Ben Adida (ben@openforce.net)
    @author arjun (arjun@openforce.net)
    @creation-date 01 April 2002
    @cvs-id $Id: simple-add.tcl,v 1.9 2008/11/09 23:29:22 donb Exp $
} {
    folder_id:integer,notnull
    object_id:integer,notnull
    return_url:notnull
    pretty_object_name:notnull
    {type "fs_url"}
    {title ""}
    {lock_title_p 0}
} -validate {
    valid_folder -requires {folder_id:integer} {
        if ![fs_folder_p $folder_id] {
            ad_complain "[_ attachments.lt_The_specified_parent_]"
        }
    }
} -properties {
    folder_id:onevalue
    context:onevalue
}

# check for write permission on the folder

ad_require_permission $folder_id write

# set templating datasources

set pretty_name "URL"
if {[empty_string_p $pretty_name]} {
    return -code error "[_ attachments.No_such_type]"
}

set context [_ attachments.Add_pretty_name [list pretty_name $pretty_name]]
#set context [fs_context_bar_list -final [_ attachments.Add_pretty_name [list pretty_name $pretty_name]] $folder_id]

# Should probably generate the item_id and version_id now for
# double-click protection

# if title isn't passed in ignore lock_title_p
if {[empty_string_p $title]} {
    set lock_title_p 0
}
