ad_page_contract {

    Attach something to an object

    @author arjun@openforce.net
    @author ben@openforce
    @cvs-id $Id$

} -query {
    {object_id:notnull}
    {folder_id ""}
    {pretty_object_name ""}
    {return_url:notnull}
}

set user_id [ad_conn user_id]

# Since object_id varname is also used for fs objects in the multirow
# let's keep the object_id to attach to in another var, otherwise
# choosing an existing file wouldn't work...

set to_object_id $object_id

# We require the write permission on an object
permission::require_permission -object_id $to_object_id -privilege write

# Give the object a nasty name if it doesn't have a pretty name
if {[empty_string_p $pretty_object_name]} {
    set pretty_object_name "[_ attachments.Object] #$to_object_id"
}

# Load up file storage information
if {[empty_string_p $folder_id]} {
    set folder_id [attachments::get_root_folder]
} 

# sanity check
if {[empty_string_p $folder_id]} {
    ad_return_complaint 1 "[_ attachments.lt_Error_empty_folder_id]"
    ad_script_abort
}

set write_permission_p \
        [permission::permission_p -object_id $folder_id -privilege write]

# Check permission
permission::require_permission -object_id $folder_id -privilege read

# Size of contents
set n_contents [fs::get_folder_contents_count -folder_id $folder_id -user_id $user_id]

# Folder name
set folder_name [lang::util::localize [fs::get_object_name -object_id $folder_id]]

# Folder contents
db_multirow -unclobber -extend {name_url action_url} contents select_folder_contents {} {
    set name [lang::util::localize $name]
    if { $type eq "folder" } {
        set name_url [export_vars -base "attach" { {folder_id $object_id} {object_id $to_object_id} return_url pretty_object_name}]
    } else {
        set action_url [export_vars -base "attach-2" {{item_id $object_id} {object_id $to_object_id} return_url pretty_object_name}]
    }

}

set passthrough_vars "object_id=$to_object_id&return_url=[ns_urlencode $return_url]&pretty_object_name=[ns_urlencode $pretty_object_name]"

# Context bar
set separator [parameter::get -package_id [ad_conn subsite_id] -parameter ContextBarSeparator -default ">"]
attachments::context_bar -extra_vars $passthrough_vars -folder_id $folder_id -multirow fs_context

set doc(title) [_ attachments.lt_Attach_a_File_to_pret]
set context "[_ attachments.Attach]"

template::head::add_style -style "
.attach-fs-bar {
    border-top: thin solid #555;
    margin: 0.8em 0;
    padding-left: 0.5em;
}"

# Build URLs
set file_add_url [export_vars -base "file-add" { {object_id $to_object_id} folder_id return_url pretty_object_name}]

set simple_add_url [export_vars -base "simple-add" { {object_id $to_object_id} folder_id return_url pretty_object_name}]
