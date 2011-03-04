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
	foreach user_id [array names amount] {
	    set rate_amount [string trim $amount($user_id)]
	    set rate_currency [string trim $currency($user_id)]

	    if {![string is double $rate_amount]} { 
		ad_return_complaint 1 "
		     <b>[lang::message::lookup "" intranet-core.Percentage_not_a_number "Percentage is not a number"]</b>:<br>
			[lang::message::lookup "" intranet-core.Percentage_not_a_number_msg "
				The percentage you have given ('%perc%') is not a number.<br>
				Please enter something like '12.5' or '100'.
			"]
		"
		ad_script_abort
	    }

	    if {"" != $rate_amount && $rate_amount < 0.0} { 
		ad_return_complaint 1 "
		     <b>[lang::message::lookup "" intranet-core.Percentage_negative "Percentage should not be negative"]</b>:<br>
			[lang::message::lookup "" intranet-core.Percentage_not_a_number_msg "
				The percentage you have given ('%perc%') is a negative number.<br>
				Please enter a positive number such as '12.5' or '100'.
			"]
		"
		ad_script_abort
	    }
	    # update employee/customer price matrix 
	    set ttt [db_string get_view_id "select im_employee_customer_price__update(NULL, 'im_employee_customer_price', now()::date, NULL, '', NULL, $user_id, $object_id, $rate_amount, '$rate_currency')" -default 0]
	}
	ad_returnredirect $return_url

ad_returnredirect $return_url

