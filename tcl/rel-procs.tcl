# @namespace cms_rel
# Procedures for managing relation items and child items

namespace eval cms_rel {}

ad_proc -public cms_rel::sort_related_item_order { item_id } {

 @public sort_related_item_order

 Resort the related items order for a given content item, ensuring that
  order_n is unique for an item_id.  Chooses new order based on the old
  order_n and then rel_id (the order the item was related)

 @author Michael Pih

 @param item_id The item for which to resort related items

} {

    db_transaction {

	# grab all related items ordered by order_n, rel_id
        set related_items [db_list get_related_items ""]

	# assign each related items a new order_n
	set i 0
	foreach rel_id $related_items {
	
	    db_dml reorder {}

	    incr i
	}
    
    }
}


ad_proc -public cms_rel::sort_child_item_order { item_id } {

 @public sort_child_item_order

 Resort the child items order for a given content item, ensuring that
  order_n is unique for an item_id.  Chooses new order based on the old
  order_n and then rel_id (the order the item was related)

 @author Michael Pih

 @param item_id The item for which to resort child items

} {

    db_transaction {

	# grab all related items ordered by order_n, rel_id
        set child_items [db_list get_child_order ""]

	# assign each related items a new order_n
	set i 0
	foreach rel_id $child_items {
	
	    db_dml reorder {}

	    incr i
	}
    
    }
}
