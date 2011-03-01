ad_page_contract {
    Delete the item entirely

    @author Frank Bergmann (frank.bergmann@project-open.com)
    @creation-date February 2007
} {
    item_id:integer
    revision_id:integer
    return_url
}

set user_id [auth::require_login]
permission::require_permission -party_id $user_id \
	    -object_id $item_id -privilege admin
    

db_string delete_item "
	select content_item__delete(:item_id)
"

ad_returnredirect $return_url

