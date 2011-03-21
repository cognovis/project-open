# /cms/www/modules/items/publish-status.tcl
# Indicates whether or not the item is publishable and displays
#   what needs to be done before this item can be published.
request create
request set_param item_id -datatype integer

# permissions check - requires cm_item_workflow
content::check_access $item_id cm_examine -user_id [User::getID] 

# Query for publish status and release schedule, if any

db_1row get_info "" -column_array info

# Build a sentence describing the publishing status

set actions [list]

switch $info(publish_status) {

  Production { 
    set message "This item is in production."
  }

  Ready { 
    set message "This item is ready for publishing. "
    if { ! [string equal $info(start_when) Immediate] } {
      append message "It has been scheduled for release
                      on <b>$info(start_when)</b>."
    } else {
      append message "It has not been scheduled for release."
    }
  }

  Live { 
    set message "This item has been published. "
    if { ! [string equal $info(end_when) Indefinite] } {
      append message "It has been scheduled to expire
                      on <b>$info(end_when)</b>."
    } else {
      append message "It has no expiration date."
    }
  }

  Expired { 
    set message "This item is expired."
  }
}

# determine whether the item is publishable or not

db_1row get_publish_info "" -column_array publish_info

template::util::array_to_vars publish_info

# if the live revision doesn't exist, the item is unpublishable
if { [template::util::is_nil live_revision] } {
    set is_publishable f
}


# determine if there is an unfinished workflow

set unfinished_workflow_exists [db_string unfinished_exists ""]

# determine if child type constraints have been satisfied

set unpublishable_child_types 0
db_multirow -extend {is_fulfilled difference direction} child_types get_child_types "" {

    # set is_fulfilled to t if the relationship constraints are fulfilled
    #   otherwise set is_fulfilled to f

    # keep track of numbers
    #  difference - the (absolute) number of child items in excess or lack
    #  direction  - whether "more" or "less" child items are needed

    set is_fulfilled t
    set difference 0
    set direction ""

    if { $child_count < $min_n } {
	set is_fulfilled f
	incr unpublishable_child_types
	set difference [expr $min_n - $child_count]
	set direction more
    }
    if { ![string equal {} $max_n] && $child_count > $max_n } {
	set row(is_fulfilled) f
	incr unpublishable_child_types
	set difference [expr $child_count - $max_n]
	set direction less
    }
}



# determine if relation type constraints have been satisfied

set unpublishable_rel_types 0
db_multirow  -extend {is_fulfilled difference direction} rel_types get_rel_types {

    # set is_fulfilled to t if the relationship constraints are fulfilled
    #   otherwise set is_fulfilled to f

    # keep track of numbers
    #  difference - the (absolute) number of related items in excess or lack
    #  direction  - whether "more" or "less" related items are needed

    set is_fulfilled t
    set difference 0
    set direction ""

    if { $rel_count < $min_n } {
	set is_fulfilled f
	incr unpublishable_rel_types
	set difference [expr $min_n - $rel_count]
	set direction more
    }
    if { ![string equal {} $max_n] && $rel_count > $max_n } {
	set is_fulfilled f
	incr unpublishable_rel_types
	set difference [expr $rel_count - $max_n]
	set direction less
    }

}


