#packages/contacts/www/admin/remove-default.tcl
ad_page_contract {
    Remove the default extended options map to one search_id
    @author Miguel Marin (miguelmarin@viaro.net)
    @author Viaro Network www.viaro.net
    @creation-date 2005-09-08
} {
    extend_id:multiple,optional
    attribute_id:multiple,optional
    search_id:integer,notnull
}

if { [exists_and_not_null extend_id] } {
    foreach value $extend_id {
	db_dml unmap_extend_id {
	    delete from contact_search_extend_map where search_id = :search_id and extend_id = :value
	}
    }
    ad_returnredirect ext-search-options?search_id=$search_id
}

if { [exists_and_not_null attribute_id] } {
    foreach value $attribute_id {
	db_dml unmap_extend_id {
	    delete from contact_search_extend_map where search_id = :search_id and attribute_id = :value
	}
    }
    ad_returnredirect attribute-list?search_id=$search_id
}

ad_returnredirect search-list