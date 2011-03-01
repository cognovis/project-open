ad_page_contract {

    Update sort order

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-07-28
    @cvs-id $Id: list-order-update.tcl,v 1.3 2009/04/17 12:38:27 cognovis Exp $


} {
    sort_key:array
    list_id:integer,notnull
    {page_url "default"}
} -validate {
    ordering_is_valid -requires {sort_key} {
	set no_value_supplied [list]
	set no_integer_supplied [list]
	set used_sort_orders [list]
	set doubled_sort_orders [list]
	foreach {attribute_id sort_order} [array get sort_key] {
	    set sort_order [string trim $sort_order]
	    if { $sort_order == "" } {
		lappend no_value_supplied $attribute_id
	    } elseif { [string is false [string is integer $sort_order]] } {
		lappend no_integer_supplied $attribute_id $sort_order
	    } elseif { [info exists order($sort_order)] } {
		lappend doubled_sort_orders $attribute_id $order($sort_order)
	    } else {
		set order($sort_order) $attribute_id
	    }
	}
	set error_messages [list]
	if { [llength $no_value_supplied] } {
	    foreach attribute_id $no_value_supplied {
		lappend error_messages "[_ ams.No_ordering_integer_was_supplied_for] <strong>[attribute::pretty_name -attribute_id $attribute_id]</strong>"
	    }
	}
	if { [llength $no_integer_supplied] } {
	    foreach { attribute_id sort_order } $no_integer_supplied {
		lappend error_messages "[_ ams.The_ordering_number_is_not_an_integer_for] <strong>[attribute::pretty_name -attribute_id $attribute_id]</strong>"
	    }
	}
	if { [llength $doubled_sort_orders] } {
	    foreach { one_attribute_id two_attribute_id } $doubled_sort_orders {
		lappend error_messages "[_ ams.The_ordering_number_is_the_same_for] <strong>[attribute::pretty_name -attribute_id $one_attribute_id]</strong> [_ ams.and] <strong>[attribute::pretty_name -attribute_id $two_attribute_id]</strong>"
	    }
	}
	if { [llength $error_messages] > 0 } {
	    foreach message $error_messages {
		ad_complain $message
	    }
	}
    }
}

set attribute_order [list]
set sort_key_list [array get sort_key]
foreach {attribute_id sort_order} $sort_key_list {
    #make sure the attribute exists
    if {![db_string attribute "select 1 from im_dynfield_layout where attribute_id = :attribute_id and page_url = :page_url" -default 0]} {
        db_dml insert_layout "insert into im_dynfield_layout (attribute_id,page_url) values (:attribute_id,:page_url)"
    }
    set order($sort_order) $attribute_id
    lappend attribute_order $sort_order
}

set ordered_list [lsort -integer $attribute_order]	

set highest_sort 1000000
incr highest_sort
set sort_number 1
foreach sort_order $ordered_list {
	set attribute_id $order($sort_order)
    
	# Move the current out of the way
	db_dml update_sort_order { update im_dynfield_layout set pos_y = :highest_sort where pos_y = :sort_number and page_url = :page_url}
	
	# Then update to the true sort value
	db_dml update_sort_order { update im_dynfield_layout set pos_y = :sort_number where attribute_id = :attribute_id and page_url = :page_url } 

    ::im::dynfield::Element flush -id $attribute_id -list_id $list_id
	incr highest_sort
	incr sort_number
}

set list [::im::dynfield::List get_instance_from_db -id $list_id]


ad_returnredirect "[$list url]"
ad_script_abort
