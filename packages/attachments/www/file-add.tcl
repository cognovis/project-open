ad_page_contract {
    page to add a new file to the system

    @author Kevin Scaldeferri (kevin@arsdigita.com)
    @creation-date 6 Nov 2000
    @cvs-id $Id$
} {
    folder_id:integer,notnull
    object_id:integer,notnull
    return_url:notnull
    pretty_object_name:notnull
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
    title:onevalue
    lock_title_p:onevalue
}

# check for write permission on the folder

ad_require_permission $folder_id write

# set templating datasources

set context [_ attachments.Add_File]
#set fs_context [fs_context_bar_list -final "[_ attachments.Add_File]" $folder_id]

# Should probably generate the item_id and version_id now for
# double-click protection

# if title isn't passed in ignore lock_title_p
if {[empty_string_p $title]} {
    set lock_title_p 0
}

