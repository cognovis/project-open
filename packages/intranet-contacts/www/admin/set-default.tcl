#packages/contacts/www/admin/remove-default.tcl
ad_page_contract {
    Set the default extended options to one search_id
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
	set already_p [db_string get_already_p {
	    select
	    1
	    from 
	    contact_search_extend_map
	    where
	    extend_id = :value
	    and search_id = :search_id
	} -default 0]
	if { !$already_p  } {
	    db_dml map_extend_id {
		insert into contact_search_extend_map (search_id,extend_id)
		values (:search_id, :value)
	    }
	}
    }
    ad_returnredirect ext-search-options?search_id=$search_id
}

if { [exists_and_not_null attribute_id] } {
    foreach value $attribute_id {
	set already_p [db_string get_already_p {
	    select
	    1
	    from 
	    contact_search_extend_map
	    where
	    attribute_id = :value
	    and search_id = :search_id
	} -default 0]
	if { !$already_p  } {
	    db_dml map_extend_id {
		insert into contact_search_extend_map (search_id,attribute_id)
		values (:search_id, :value)
	    }
	}
    }
    ad_returnredirect attribute-list?search_id=$search_id
}

