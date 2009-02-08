ad_page_contract {

    Update sort order

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2005-05-24
    @cvs-id $Id$

} {
    item_id:multiple,notnull
    party_id
}
contact::require_visiblity -party_id $party_id

db_transaction {
    foreach item_id $item_id {
	db_dml expire_item { update cr_items set publish_status = 'expired', live_revision = NULL where item_id = :item_id }
    }
}
ad_returnredirect "${party_id}/files"
