ad_page_contract {

    Manage the calendar item types
    
    @author Ben Adida (ben@openforce.net)
    
    @creation-date Mar 16, 2002
    @cvs-id $Id$
} {
    calendar_id:notnull
}

# Permission check
ad_require_permission $calendar_id calendar_admin

# List the item types and allow addition of a new one
set item_types [calendar::get_item_types -calendar_id $calendar_id]
set context [list "Item Types"]



