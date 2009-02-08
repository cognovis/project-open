# /packages/intranet-contacts/www/save-attribute.tcl
ad_page_contract {
    
    Saves an attribute_id for one search_id

    @author Miguel Marin (miguelmarin@viaro.net)
    @author Viaro Networks www.viaro.net
    @creation-date 2005-11-30
} {
    search_id:integer,notnull
    attr_val_name:multiple,notnull
}


set return_url [get_referrer]
set attr_val_name [lindex $attr_val_name 0]

foreach attr $attr_val_name {
    set attr_id [lindex $attr 0]
    set check_p [db_string check { 
	select 1 
	from contact_search_extend_map 
	where search_id = :search_id 
	and attribute_id = :attr_id 
    } -default 0]
    
    if { !$check_p } {
	db_dml insert_attribute { 
	    insert into contact_search_extend_map (search_id,extend_id,attribute_id)
	    values( :search_id,null,:attr_id)
	}
    }
}

ad_returnredirect $return_url