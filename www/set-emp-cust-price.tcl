# /packages/intranet-cust-koernigweber/www/set-emp-cust-price.tcl
#
# Copyright (C) 1998-2011 various parties

ad_page_contract {
    Sets or updates Employee/Company Price Matrix   
    @author various@arsdigita.com
    @author frank.bergmann@project-open.com
    @author klaus.hofeditz@project-open.com
} {
    object_id:integer
    amount:array,optional
    currency:array,optional
    project_type_id:integer,array,optional
    new_user_id:integer
    new_cost_object_category_id:integer,optional
    new_amount:optional
    new_currency:optional    
    new_start_date:optional
    filter_records
    delete_price:array,optional
    { return_url "" }
    { submit "" }
}

# -----------------------------------------------------------------
# Security
# -----------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]

# Determine our permissions for the current object_id.
# We can build the permissions command this ways because
# all ]project-open[ object types define procedures
# im_ObjectType_permissions $user_id $object_id view read write admin.
#
set object_type [db_string acs_object_type "select object_type from acs_objects where object_id=:object_id"]
set perm_cmd "${object_type}_permissions \$current_user_id \$object_id view read write admin"
eval $perm_cmd

if {!$write} {
    ad_return_complaint 1 "You have no rights to modify members of this object."
    return
}

ns_log Notice "member-update: object_id=$object_id"
ns_log Notice "member-update: submit=$submit"

# -----------------------------------------------------------------
# Action
# -----------------------------------------------------------------
 	set debug ""
 	foreach user_id_project_type_id [array names amount] {
 	    set rate_amount [string trim $amount($user_id_project_type_id)]
 	    set rate_currency [string trim $currency($user_id_project_type_id)]
	    set user_id [string range $user_id_project_type_id 0 [expr [string first "_" $user_id_project_type_id] -1]]
	    set project_type [string range $user_id_project_type_id [expr [string first "_" $user_id_project_type_id] +1] [string length user_id_project_type_id]]
	    if {![string is double $rate_amount]} { 
		ad_return_complaint 1 "
		     <b>[lang::message::lookup "" intranet-core.Price_not_a_number "Price is not a number"]</b>:<br>
			[lang::message::lookup "" intranet-core.Price_not_a_number_msg "
				The data you have given ('%rate_amount%') is not a number.<br>
				Please enter a value like '12.5' or '100'.
			"]
		"
		ad_script_abort
	    }

	    if {"" != $rate_amount && $rate_amount < 0.0} { 
		ad_return_complaint 1 "
		     <b>[lang::message::lookup "" intranet-core.Price_negative "Percentage should not be negative"]</b>:<br>
			[lang::message::lookup "" intranet-core.Price_not_a_number_msg "
				The value you have entered ('%rate_amount%') is a negative number.<br>
				Please enter a positive number such as '12.5' or '100'.
			"]
		"
		ad_script_abort
	    }

	    if { "" != $rate_amount} { 
		ns_log NOTICE "ERR_ NULL, 'im_employee_customer_price', now()::date, NULL, '', NULL, $user_id, $object_id, $rate_amount, '$rate_currency' [string length $rate_amount]"
		# update employee/customer price matrix 
		if { "" == $project_type } {set project_type_db NULL } else { set project_type_db $project_type }
		    set sql "
			select 
				im_employee_customer_price__update(NULL, 
				'im_employee_customer_price', now()::date, 
				NULL, '', NULL, $user_id, $object_id, 
				$rate_amount, '$rate_currency',$project_type_db,:start_date)
			"

		set foo [db_string get_view_id $sql -default 0]
	    }
	}

	# Ignore when no price is set 
        if { "" != $new_amount } {

	    if { "" == $new_start_date } {
		ad_return_complaint 1 "<strong> [lang::message::lookup "" intranet-cust-koernigweber.Provide_Start_Date "Bitte geben Sie ein Start Datum an"]</strong>"
		return
	    }

	    if { [catch { set end_date_ansi [clock format [clock scan $new_start_date] -format %Y-%m-%d] } ""] } {
		ad_return_complaint 1 "Wrong date"
		return
	    }
	    	# In case there's a new record write it 
		if { "" != $new_user_id } {
		    if { ![info exists new_cost_object_category_id] } { 
	              set sql "
	                select
        	                im_employee_customer_price__update(NULL,
        	                'im_employee_customer_price', now()::date,
                	        NULL, '', NULL, :new_user_id, $object_id,
                        	:new_amount, :new_currency, NULL, :new_start_date)
	                "
		    } else {
	              set sql "
        	        select
                	        im_employee_customer_price__update(NULL,
                        	'im_employee_customer_price', now()::date,
	                        NULL, '', NULL, :new_user_id, $object_id,
        	                :new_amount, :new_currency, :new_cost_object_category_id, :new_start_date)
                	"
		    }
        	    set foo [db_string write_new_price $sql -default 0]
		}
	}

       	# Check for price records to delete 
	foreach price_id [array names delete_price] {
		if {[catch { db_dml delete_price_record "delete from im_customer_prices where id = :price_id" } errmsg ]} {}
	}

	# Portlets are only on user or project pages 
	if { "user" == $object_type } {
	    ad_returnredirect "/intranet/users/view?filter_records=$filter_records&[export_vars -url -exclude { filter_records } [wf_split_query_url_to_arg_spec $return_url] ]"
	} else { 
	    ad_returnredirect "/intranet/projects/view?filter_records=$filter_records&[export_vars -url -exclude { filter_records } [wf_split_query_url_to_arg_spec $return_url] ]"
	}
