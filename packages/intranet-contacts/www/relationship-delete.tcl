ad_page_contract {
    List and manage contacts.

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-07-28
    @cvs-id $Id$
} {
    {party_id:integer,notnull}
    {rel_id:integer,notnull}
    {return_url ""}
} -validate {
    valid_party -requires {party_id} {
	if { ![contact::exists_p -party_id $party_id] } {
	    ad_complain "[_ intranet-contacts.lt_The_contact_specified]"
	}
    }
}

# ams::object_delete -object_id $rel_id
db_1row get_rel_info {}
if { $object_id_one eq $party_id } { 
    set other_party_id $object_id_two
} else {
    set other_party_id $object_id_two
}

# we can only delete relationships where both parties belong to this package
contact::require_visiblity -party_id $party_id
contact::require_visiblity -party_id $other_party_id

# delete the rel (we don't use relation_remove because it
# requires a rel_type__delete proc, which we don't have
# acs_object__delete allows and on delete cascades to work
# along with this rel removal.
db_1row delete_rel {}


# flush cache for relationship data
contact::flush -party_id $party_id
contact::flush -party_id $other_party_id


if { ![exists_and_not_null return_url] } {
    set return_url "$party_id/relationships"
}


set redirect_rel_types [parameter::get -parameter EditDataAfterRel -package_id [ad_conn package_id] -default ""]
if { [regexp {\*} $redirect_rel_types match] || [lsearch $redirect_rel_types $rel_type] >= 0 } {
    # we need to redirect the party to the attribute add/edit page
    set return_url [export_vars -base "[contact::url -party_id $party_id]edit" -url {return_url}]
    ad_returnredirect -message "[_ intranet-contacts.Relationship_Deleted]. [_ intranet-contacts.lt_update_contact_if_needed]" $return_url
} else {
    # we redirect the party to the specified return_url
    ad_returnredirect -message "[_ intranet-contacts.Relationship_Deleted]" $return_url

}

ad_script_abort
