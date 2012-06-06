# packages/oacs-dav/www/admin/index.tcl

ad_page_contract {
    
    Administer webdav enabled folders
    
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-02-15
    @cvs-id $Id$
} {
    
} -properties {
    title
    context
} -validate {
} -errors {
}

permission::require_permission \
    -party_id [ad_conn user_id] \
    -object_id [ad_conn package_id ] \
    -privilege "admin"
set bulk_actions [list  "[_ oacs-dav.Enable]" "enable" "[_ oacs-dav.Enable_Folders]" "[_ oacs-dav.Disable]" "disable" "[_ oacs-dav.Disable_Folders]" ]
template::list::create \
    -name folders \
    -multirow folders \
    -key folder_id \
    -bulk_actions $bulk_actions \
    -elements {
	package_key {label {[_ oacs-dav.Package_Type]}}
        package_name { label {[_ oacs-dav.Package_Name]} }
	label { label {[_ oacs-dav.Folder_Name]} }
	folder_url { label {[_ oacs-dav.Folder_URL]} }
	status { label {[_ oacs-dav.Status]} }
    }

db_multirow -extend {folder_url package_key package_name status} folders get_folders {} {
    array set sn [site_node::get -node_id $node_id]
    set folder_url $sn(url)
    set package_key $sn(package_key)
    set package_name $sn(instance_name)
    set status [string map -nocase [list t [_ oacs-dav.Enabled] f [_ oacs-dav.Disabled] ] $enabled_p]
}

set title [_ oacs-dav.WebDAV_Folder_Administration]
set context $title
ad_return_template
