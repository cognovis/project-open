# 

ad_page_contract {
    
    WebDAV disable folders
    
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-02-15
    @cvs-id $Id$
} {
    folder_id:integer,multiple
} -properties {
} -validate {
} -errors {
}

permission::require_permission \
    -party_id [ad_conn user_id] \
    -object_id [ad_conn package_id ] \
    -privilege "admin"

foreach id $folder_id {

    db_dml disable_folder ""
    
}
util_user_message -message [_ oacs-dav.Folders_Disabled]
ad_returnredirect "."