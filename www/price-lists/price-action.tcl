# /packages/intranet-timesheet2--invoices/www/price-lists/price-action.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Purpose: Takes commands from a price_component and deletes 
    tasks as requested.

    @param return_url the url to return to
    @param group_id group id

    @author frank.bergmann@project-open.com
} {
    { add_new "" }
    { del "" }
    company_id:integer
    price_id:array,optional
    {return_url ""}
}

set user_id [ad_maybe_redirect_for_registration]
set page_body "<PRE>\n"

if {$return_url == ""} {
    set return_url "/intranet/"
}

# -------------------------------------------------------------
# "Add New" button pressed?
# => Redirect to new.tcl page
if {"" != $add_new} {
    ad_returnredirect "new?[export_url_vars company_id return_url]"
    return
}

# -------------------------------------------------------------
# "Del" button pressed?
if {"" != $del} {
    
    if {![info exists price_id]} { 
	# Abort if there is no price item selected.
	ad_returnredirect $return_url 
	return
    }

    set price_list [array names price_id]
    ns_log Notice "price-action: price_list=$price_list"
    if {0 == [llength $price_list]} { ad_returnredirect $return_url }
    
    db_dml delete_prices "
	delete from im_timesheet_prices
	where price_id in ([join $price_list ","])
    "
    ad_returnredirect $return_url
    return
}

ad_return_complaint 1 "<li>[_ intranet-timesheet2-invoices.lt_Unknown_action_for_pr]"
return

