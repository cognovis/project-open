ad_page_contract {
    Update the cr_revision of a content item

    @author Frank Bergmann (frank.bergmann@project-open.com)
    @creation-date April 2005
} {
    item_id:integer
    revision_id:integer
    return_url
}

set user_id [auth::require_login]
permission::require_permission -party_id $user_id \
	    -object_id $item_id -privilege admin
    

db_dml update_revision "
	update cr_items
	set latest_revision = :revision_id
	where item_id = :item_id
"

ad_returnredirect $return_url

