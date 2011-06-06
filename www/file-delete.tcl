ad_page_contract {
    Delete a filestorage file
    @author Frank Bergmann
    @creation-date 6 May 2011
    @cvs-id $Id$
} {
    item_id:integer
}

set user_id [ad_conn user_id]
# Get package. ad_conn package_id doesn't seem to work...
set package_id [db_string package "select min(package_id) from apm_packages where package_key = 'file-storage'"]

ns_log Notice "file-delete: item_id=$item_id, package_id=$package_id"

permission::require_permission \
    -object_id $item_id \
    -party_id $user_id \
    -privilege "write"

fs::delete_file -item_id $item_id


db_release_unused_handles
ad_http_cache_control

ns_log Notice "file-delete: success"
ns_return 200 "text/html" "{
	\"result\": {
		\"success\":	true,
		\"errors\":	{\"email\": \"already taken\"}
    	}
}"
ad_script_abort

