# /packages/intranet-budget/www/new-provider-estimation-2.tcl
#
# Copyright (C) 2003-2008 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.


ad_page_contract {
    @author iuri sampaio (iuri.sampaio@gmail.com)
    @date 2010-12-09
} {
    item_name:array
    item_cost_type:integer,array,optional
    item_units:integer,array
    item_uom_id:integer,array
    item_rate:integer,array  
    item_currency:array
    {cost_name}
    {cost_type_id}
    {cost_status_id}
    {project_id}
    {return_url}
}


ns_log Notice "$cost_name | $cost_type_id $cost_status_id | $project_id  | $return_url"

# Debug form! This chunk must be erased later                                                                                                                
set myform [ns_getform]
if {[string equal "" $myform]} {
    ns_log Notice "No Form was submited"
} else {
    ns_log Notice "FORM"
    ns_set print $myform
}



if {[exists_and_not_null cost_name]} {


# it needs to evrify existent costs???

    set user_id [ad_maybe_redirect_for_registration]
    set creation_ip [ad_conn peeraddr]
    set provider_id [im_company_internal] 
    set customer_id $provider_id
    
    # set a unique cost identifier 
    # set cost_nr [im_next_cost_nr $cost_name]
    set parent_cost_id [db_exec_plsql insert_cost {}]

    
    if {[exists_and_not_null parent_cost_id]} {
	# Audit the creation of the invoice
	im_audit -object_id $parent_cost_id -action create
	
	set item_list [array names item_name]
	foreach nr $item_list {
	    set name $item_name($nr)
	    if {$name eq ""} {continue}
	    set units $item_units($nr)
	    set uom_id $item_uom_id($nr)
	    set rate $item_rate($nr)
	    set currency $item_currency($nr)
	    
	    set amount [expr $rate * $units]
	    
	    set cost_id [db_exec_plsql insert_cost_item {}]
	    
	    im_audit -object_id $cost_id -action create
	    
	}
    }
}

db_release_unused_handles
ad_returnredirect "${return_url}?project_id=$project_id"
