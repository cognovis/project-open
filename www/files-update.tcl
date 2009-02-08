ad_page_contract {

    Update sort order

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2005-05-24
    @cvs-id $Id$

} {
    rename:array
    party_id:integer,notnull
}
contact::require_visiblity -party_id $party_id

set item_ids [db_list get_item_ids { select item_id from cr_items where parent_id = :party_id and publish_status = 'ready' } ]
db_transaction {
    foreach item_id $item_ids {
        set new_title [string trim $rename(${item_id})]
        if { [exists_and_not_null new_title] } {
	    db_0or1row get_item_date {
select ci.name,
       cr.title,
       cr.mime_type,
       cr.content,
       cr.content_length
  from cr_items ci, cr_revisions cr, acs_objects ao
 where ci.parent_id = :party_id
   and ci.live_revision = cr.revision_id
   and cr.revision_id = ao.object_id
		and ci.item_id = :item_id }

	    if { $new_title != $title } {
		set filename [contact::util::generate_filename -title $new_title -extension [contact::util::get_file_extension -filename $name] -party_id $party_id]
		set revision_id [content::revision::new -item_id $item_id -is_live "t" -title $new_title -mime_type $mime_type]
		db_dml update_revision { update cr_revisions set content = :content, content_length = :content_length where revision_id = :revision_id }
                db_dml update_item { update cr_items set name = :filename where item_id = :item_id } 
	    }
	}

    }
}
ad_returnredirect "${party_id}/files"
