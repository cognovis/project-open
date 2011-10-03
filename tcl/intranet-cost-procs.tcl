# /packages/intranet-invoicing/tcl/intranet-cost-procs.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    Bring together all "components" (=HTML + SQL code)
    related to Costs

    @author frank.bergann@project-open.com
}

# ---------------------------------------------------------------
# Stati and Types
# ---------------------------------------------------------------

# Frequently used Costs Stati
ad_proc -public im_cost_status_created {} { return 3802 }
ad_proc -public im_cost_status_outstanding {} { return 3804 }
ad_proc -public im_cost_status_past_due {} { return 3806 }
ad_proc -public im_cost_status_partially_paid {} { return 3808 }
ad_proc -public im_cost_status_paid {} { return 3810 }
ad_proc -public im_cost_status_deleted {} { return 3812 }
ad_proc -public im_cost_status_filed {} { return 3814 }
ad_proc -public im_cost_status_requested {} { return 3816 }
ad_proc -public im_cost_status_rejected {} { return 3818 }



# Frequently used Cost Types
ad_proc -public im_cost_type_invoice {} { return 3700 }
ad_proc -public im_cost_type_quote {} { return 3702 }
ad_proc -public im_cost_type_bill {} { return 3704 }
ad_proc -public im_cost_type_po {} { return 3706 }
ad_proc -public im_cost_type_company_doc {} { return 3708 }
ad_proc -public im_cost_type_customer_doc {} { return 3708 }
ad_proc -public im_cost_type_provider_doc {} { return 3710 }
ad_proc -public im_cost_type_provider_travel {} { return 3712 }
ad_proc -public im_cost_type_employee {} { return 3714 }
ad_proc -public im_cost_type_repeating {} { return 3716 }
ad_proc -public im_cost_type_timesheet {} { return 3718 }
ad_proc -public im_cost_type_expense_item {} { return 3720 }
ad_proc -public im_cost_type_expense_bundle {} { return 3722 }
ad_proc -public im_cost_type_delivery_note {} { return 3724 }
ad_proc -public im_cost_type_timesheet_planned {} { return 3726 }
ad_proc -public im_cost_type_timesheet_budget {} { return 3726 }
ad_proc -public im_cost_type_expense_planned {} { return 3728 }
ad_proc -public im_cost_type_interco_invoice {} { return 3730 }
ad_proc -public im_cost_type_interco_quote {} { return 3732 }
ad_proc -public im_cost_type_provider_receipt {} { return 3734 }

ad_proc -public im_cost_type_short_name { cost_type_id } { 
    switch $cost_type_id {
	3700 { return "invoice" }
	3702 { return "quote" }
	3704 { return "bill" }
	3706 { return "po" }
	3708 { return "customer_doc" }
	3710 { return "provider_doc" }
	3712 { return "provider_travel" }
	3714 { return "employee" }
	3716 { return "repeating" }
	3718 { return "timesheet" }
	3720 { return "expense" }
	3722 { return "expense_bundle" }
	3724 { return "delivery_note" }
	3726 { return "timesheet_budget" }
	3728 { return "expense_planned" }
	3730 { return "interco_invoice" }
	3732 { return "interco_quote" }
	default { return "unknown" }
    }
}


# Payment Methods
ad_proc -public im_payment_method_undefined {} { return 800 }
ad_proc -public im_payment_method_cash {} { return 802 }


ad_proc -public im_package_cost_id { } {
} {
    return [util_memoize "im_package_cost_id_helper"]
}

ad_proc -private im_package_cost_id_helper {} {
    return [db_string im_package_core_id {
        select package_id from apm_packages
        where package_key = 'intranet-cost'
    } -default 0]
}




# -----------------------------------------------------------
# Characteristics & Grouping
# -----------------------------------------------------------

ad_proc -public im_cost_type_is_invoice_or_quote_p { cost_type_id } {
    Invoices and Quotes have a "Company" fields,
    so we need to identify them:
} {
    set invoice_or_quote_p [expr $cost_type_id == [im_cost_type_invoice] || $cost_type_id == [im_cost_type_quote] || $cost_type_id == [im_cost_type_delivery_note] || $cost_type_id == [im_cost_type_interco_invoice] || $cost_type_id == [im_cost_type_interco_quote]]
    return $invoice_or_quote_p
}


ad_proc -public im_cost_type_is_invoice_or_bill_p { cost_type_id } {
    Invoices and Bills have a "Payment Terms" field.
    So we need to identify them:
} {
    set invoice_or_bill_p [expr $cost_type_id == [im_cost_type_invoice] || $cost_type_id == [im_cost_type_bill]]
    return $invoice_or_bill_p
}


# -----------------------------------------------------------
# Permissions
# -----------------------------------------------------------

ad_proc -public im_cost_permissions {user_id cost_id view_var read_var write_var admin_var} {
    Fill the "by-reference" variables read, write and admin
    with the permissions of $user_id on $cost_id.<br>

    Cost permissions depend on the rights of the underlying company
    and on Cost Center permissions.
} {
    upvar $view_var view
    upvar $read_var read
    upvar $write_var write
    upvar $admin_var admin

    set user_is_freelance_p [im_user_is_freelance_p $user_id]
    set user_is_inco_customer_p [im_user_is_inco_customer_p $user_id]
    set user_is_customer_p [im_user_is_customer_p $user_id]

    # -----------------------------------------------------
    # Get Cost information
    set customer_id 0
    set provider_id 0
    set cost_center_id 0
    set cost_type_id 0
    db_0or1row get_companies "
        select
                customer_id,
                provider_id,
		cost_center_id,
		cost_type_id
        from
                im_costs
        where
                cost_id = :cost_id
    "

    # -----------------------------------------------------
    # Cost Center permissions - check if the user has read permissions
    # for this particular cost center
    set cc_read [im_cost_center_read_p $cost_center_id $cost_type_id $user_id]
    set cc_write [im_cost_center_write_p $cost_center_id $cost_type_id $user_id]

    set can_read [expr [im_permission $user_id view_costs] || [im_permission $user_id view_invoices]]
    set can_write [expr [im_permission $user_id add_costs] || [im_permission $user_id add_invoices]]

    # AND-connection with add/view - costs/invoices
    if {!$can_read} { set cc_read 0 }
    if {!$can_write} { set cc_write 0 }

    # Set the other two variables
    set cc_admin $cc_write
    set cc_view $cc_read

    # -----------------------------------------------------
    # Customers get the right to see _their_ invoices
    set cust_view 0
    set cust_read 0
    set cust_write 0
    set cust_admin 0
    set incust_view 0
    set incust_read 0
    set incust_write 0
    set incust_admin 0

    if {$user_is_inco_customer_p && $customer_id && $customer_id != [im_company_internal]} {
	im_company_permissions $user_id $customer_id incust_view incust_read incust_write incust_admin
    }
    if {$user_is_customer_p && $customer_id && $customer_id != [im_company_internal]} {
	im_company_permissions $user_id $customer_id cust_view cust_read cust_write cust_admin
    }

    # -----------------------------------------------------
    # Providers get the right to see _their_ invoices
    # This leads to the fact that FreelanceManagers (the guys
    # who can convert themselves into freelancers) can also
    # see the freelancer's permissions. Is this desired?
    # I guess yes, even if they don't usually have the permission
    # to see finance.
    set prov_view 0
    set prov_read 0
    set prov_write 0
    set prov_admin 0
    if {$user_is_freelance_p && $provider_id && $provider_id != [im_company_internal]} {
        im_company_permissions $user_id $provider_id prov_view prov_read prov_write prov_admin
    }

    # -----------------------------------------------------
    # Set the permission as the OR-conjunction of provider and customer
    set view [expr $incust_view || $cust_view || $prov_view || $cc_view]
    set read [expr $incust_read || $cust_read || $prov_read || $cc_read]
    set write [expr $incust_write || $cust_write || $prov_write || $cc_write]
    set admin [expr $incust_admin || $cust_admin || $prov_admin || $cc_admin]

    # Limit rights of all users to view & read if they dont
    # have the expressive permission to "add_costs or add_invoices".
    if {!$can_write} {
        set write 0
        set admin 0
    }
}





ad_proc -public im_cost_type_write_p {
    user_id
    cost_type_id
} {
    Returns "1" if the user can create costs of type cost_type_id or 0 otherwise
} {
    set create_cost_types [im_cost_type_write_permissions $user_id]
    return [expr [lsearch -exact $create_cost_types $cost_type_id] != -1]
}


ad_proc -public im_cost_type_write_permissions {
    user_id
} {
    Returns a list of all cost_type_ids for which the user has
    write permissions for atleast one Cost Center.
} {
    return [util_memoize "im_cost_type_write_permissions_helper $user_id" 60]
}


ad_proc -public im_cost_type_write_permissions_helper {
    user_id 
} {
    Returns a list of all cost_type_ids for which the user has
    write permissions for atleast one Cost Center.
} {
    # Financial Write permissions are required
    set can_write [expr [im_permission $user_id add_costs] || [im_permission $user_id add_invoices]]
    if {!$can_write} { return [list] }

    set result [db_list writable_cost_centers "
	select distinct
		ct.cost_type_id
	from
		im_cost_centers cc,
		im_cost_types ct,
	        acs_permissions p,
	        party_approved_member_map m,
	        acs_object_context_index c,
	        acs_privilege_descendant_map h
	where
		cc.cost_center_id = c.object_id
		and ct.write_privilege = h.descendant
	        and p.object_id = c.ancestor_id
	        and m.member_id = :user_id
	        and p.privilege = h.privilege
	        and p.grantee_id = m.party_id
    "]
    return $result
}



# -----------------------------------------------------------
# Options & Selects
# -----------------------------------------------------------

ad_proc -public im_cost_uom_options { 
    {include_empty 1} 
} {
    Cost UoM (Unit of Measure) options
} {
    set options [db_list_of_lists cost_type_options "
        select	category, category_id
        from	im_categories
	where	category_type = 'Intranet UoM' and
		(enabled_p is null OR enabled_p = 't')
    "]
    if {$include_empty} { set options [linsert $options 0 { "" "" }] }
    return $options
}



# ---------------------------------------------------------------
# Auxil
# ---------------------------------------------------------------

ad_proc -public n20 { value } { 
    Converts null ("") values to numeric "0". This function
    is used inside view definitions in order to deal with null
    values in TCL 
} {
    if {"" == $value} { set value 0 }
    return $value
}



# ---------------------------------------------------------------
# Cost Item Creation
# ---------------------------------------------------------------

namespace eval im_cost {

    ad_proc -public new { 
	{-cost_id 0}
	{-cost_status_id 0}
	{-customer_id 0}
	{-provider_id 0}
	{-user_id 0}
	{-creation_ip ""}
	{-object_type "im_cost"}
	-cost_name
	-cost_type_id
    } {
	Create a new cost item and return its ID.
	The cost item is created with the minimum number
	of parameters necessary for creation (not null).
	We asume that an UPDATE is executed afterwards
	in order to fill in more details.
    } {
	if {0 == $customer_id} { set customer_id [im_company_internal] }
	if {0 == $provider_id} { set provider_id [im_company_internal] }
	if {0 == $cost_id} { set cost_id [db_nextval acs_object_id_seq]}
	if {0 == $cost_status_id} { set cost_status_id [im_cost_status_created]}
	if {0 == $user_id} { set user_id [ad_get_user_id] }
	if {"" == $creation_ip} { set creation_ip [ad_conn peeraddr] }

	set today [db_string today "select sysdate from dual"]
	if [catch {
	    db_dml insert_costs "
		insert into acs_objects	(
			object_id, object_type, context_id,
			creation_date, creation_user, creation_ip
		) values (
			:cost_id, :object_type, null,
			:today, :user_id, :creation_ip
	    )" 
	} errmsg] {
	    ad_return_complaint 1 "<li>Error creating acs_object in im_cost::new<br>
		cost_id=$cost_id<br>
		cost_status_id=$cost_status_id<br>
		customer_id=$customer_id<br>
		provider_id=$provider_id<br>
		cost_name=$cost_name<br>
		cost_type_id=$cost_type_id<br>
            <pre>$errmsg</pre>"
	    return
	}

	if [catch {
	    db_dml insert_costs "
	insert into im_costs (
		cost_id,
		cost_nr,
		cost_name,
		customer_id,
		provider_id,
		cost_type_id,
		cost_status_id
	) values (
		:cost_id,
		:cost_id,
		:cost_name,
		:customer_id,
		:provider_id,
		:cost_type_id,
		:cost_status_id
	)" } errmsg] {
	    ad_return_complaint 1 "<li>Error inserting into im_costs as part of im_cost::new<br>
               cost_id=$cost_id<br>
                cost_status_id=$cost_status_id<br>
                customer_id=$customer_id<br>
                provider_id=$provider_id<br>
                cost_name=$cost_name<br>
                cost_type_id=$cost_type_id<br>
            <pre>$errmsg</pre>"
	    return
	}

	# Audit the action
	# im_audit -object_id $cost_id -action create

	return $cost_id
    }
    
}

# ---------------------------------------------------------------
# Options for Form elements
# ---------------------------------------------------------------

ad_proc -public im_cost_type_options { {include_empty 1} } { 
    Cost type options
} {
   set options [db_list_of_lists cost_type_options "
	select cost_type, cost_type_id
	from im_cost_types
    "]
    if {$include_empty} { set options [linsert $options 0 { "" "" }] }
    return $options
}

ad_proc -public im_cost_status_options { {include_empty 1} } { 
    Cost status options
} {
    set options [db_list_of_lists cost_status_options "
	select cost_status, cost_status_id from im_cost_status
    "]
    if {$include_empty} { set options [linsert $options 0 { "" "" }] }
    return $options
}

ad_proc -public im_cost_template_options { {include_empty 1} } { 
    Cost Template options
} {
    set options [db_list_of_lists template_options "
	select category, category_id
	from im_categories
	where category_type = 'Intranet Cost Template' and
		(enabled_p is null OR enabled_p = 't')
    "]
    if {$include_empty} { set options [linsert $options 0 { "" "" }] }
    return $options
}

ad_proc -public im_investment_options { {include_empty 1} } { 
    Cost investment options
} {
    set options [db_list_of_lists investment_options "
	select name, investment_id
	from im_investments
    "]
    if {$include_empty} { set options [linsert $options 0 { "" "" }] }
    return $options
}

ad_proc -public im_currency_options { 
    {-currency_list {} }
    {include_empty 1} 
} { 
    Cost currency options
} {
    set currency_where ""
    set currency_list [string trim $currency_list]
    if {[llength $currency_list] > 0} {
        set currency_where "and iso in ('[join $currency_list "', '"]')"
    }
    set options [db_list_of_lists currency_options "
	select	iso, iso
	from	currency_codes
	where	supported_p = 't'
		$currency_where
	order by iso
    "]
    if {$include_empty} { set options [linsert $options 0 { "" "" }] }
    return $options
}

ad_proc im_currency_select {
    {-enabled_only_p 1 }
    {-currency_name "iso" }
    {-translate_p 0}
    {-locale ""}
    {-include_empty_p 1}
    {-include_empty_name ""}
    select_name 
    {default ""}
} {
    Return a HTML widget that selects a currency code from
    the list of global countries.
} {
    set enabled_sql "1=1"
    if {$enabled_only_p} { set enabled_sql "supported_p='t'" }

    set bind_vars [ns_set create]
    set statement_name "currency_code_select"
    set sql "select iso, $currency_name
	     from currency_codes
	     where $enabled_sql
	     order by lower(currency_name)"

    return [im_selection_to_select_box -translate_p 0 -locale $locale -include_empty_p $include_empty_p -include_empty_name $include_empty_name $bind_vars $statement_name $sql $select_name $default]
}

ad_proc im_supported_currencies { } {
    Returns the list of supported currencies
} {
    set include_empty 0
    set currency_options [im_currency_options $include_empty]
    set result [list]
    foreach option $currency_options {
	lappend result [lindex $option 0]
    }
    return $result
}



ad_proc -public template::widget::im_currencies { element_reference tag_attributes } {
    ad_form widget for active currencies
    The widget displays a list of active currencies.
} {
    # Defaults
    set include_empty_p 1
   
    # Get references to parameters (magic...)
    upvar $element_reference element
    array set attributes $tag_attributes
    set field_name $element(name)
    set default_value_list $element(values)

    # Determine parameters
    if { [info exists element(custom)] } {
	set params $element(custom)

	set include_empty_pos [lsearch $params include_empty_p]
	if { $include_empty_pos >= 0 } {
	    set include_empty_p [lindex $params [expr $include_empty_pos + 1]]
	}
    }

    # Determine the default value for the widget
    set default_value ""
    if {[info exists element(value)]} {
	set default_value $element(values)
    }

    # Render the widget, depending on the display_mode (edit/display):
    if { "edit" == $element(mode)} {

	return [im_currency_select $field_name $default_value]

    } else {

	return $default_value
    }
}


ad_proc -public im_costs_navbar { 
    default_letter 
    base_url 
    next_page_url 
    prev_page_url 
    export_var_list 
    {select_label ""} 
} {
    Returns rendered HTML code for a horizontal sub-navigation
    bar for /intranet-cost/.
    The lower part of the navbar also includes an Alpha bar.<br>
    Default_letter==none marks a special behavious, printing no alpha-bar.
} {
    # -------- Defaults -----------------------------
    set user_id [ad_get_user_id]
    set url_stub [ns_urldecode [im_url_with_query]]
    ns_log Notice "im_costs_navbar: url_stub=$url_stub"

    set sel "<td class=tabsel>"
    set nosel "<td class=tabnotsel>"
    set a_white "<a class=whitelink"
    set tdsp "<td>&nbsp;</td>"

    # -------- Calculate Alpha Bar with Pass-Through params -------
    set bind_vars [ns_set create]
    foreach var $export_var_list {
        upvar 1 $var value
        if { [info exists value] } {
            ns_set put $bind_vars $var $value
            ns_log Notice "im_costs_navbar: $var <- $value"
        }
    }
    set alpha_bar [im_alpha_bar -prev_page_url $prev_page_url -next_page_url $next_page_url $base_url $default_letter $bind_vars]

    # Get the Subnavbar
    set parent_menu_sql "select menu_id from im_menus where label='finance'"
    set parent_menu_id [util_memoize [list db_string parent_admin_menu $parent_menu_sql -default 0]]
    set navbar [im_sub_navbar $parent_menu_id "" $alpha_bar "tabnotsel" $select_label]

    return $navbar
}

ad_proc im_next_cost_nr { } {
    Returns the next free cost number

    Cost_nr's look like: 2003_07_123 with the first 4 digits being
    the current year, the next 2 digits the month and the last 3 digits 
    as the current number  within the month.
    Returns "" if there was an error calculating the number.

    The SQL query works by building the maximum of all numeric (the 8 
    substr comparisons of the last 4 digits) cost numbers
    of the current year/month, adding "+1", and contatenating again with 
    the current year/month.

    This procedure has to deal with the case that
    two user are costs projects concurrently. In this case there may
    be a "raise condition", that two costs are created at the same
    moment. This is possible, because we take the cost numbers from
    im_costs_ACTIVE, which excludes costs in the process of
    generation.
    To deal with this situation, the calling procedure has to double check
    before confirming the cost.
} {
    set sql "
select
	to_char(sysdate, 'YYYY_MM')||'_'||
	trim(to_char(1+max(i.nr),'0000')) as cost_nr
from
	(select substr(cost_nr,9,4) as nr from im_costs
	 where substr(cost_nr, 1,7)=to_char(sysdate, 'YYYY_MM')
	 UNION 
	 select '0000' as nr from dual
	) i
where
        ascii(substr(i.nr,1,1)) > 47 and
        ascii(substr(i.nr,1,1)) < 58 and
        ascii(substr(i.nr,2,1)) > 47 and
        ascii(substr(i.nr,2,1)) < 58 and
        ascii(substr(i.nr,3,1)) > 47 and
        ascii(substr(i.nr,3,1)) < 58 and
        ascii(substr(i.nr,4,1)) > 47 and
        ascii(substr(i.nr,4,1)) < 58
"
    set cost_nr [db_string next_cost_nr $sql -default ""]
    ns_log Notice "im_next_cost_nr: cost_nr=$cost_nr"

    return $cost_nr
}



# ---------------------------------------------------------------
# Components
# ---------------------------------------------------------------

ad_proc im_costs_object_list_component { user_id cost_id return_url } {
    Returns a HTML table containing a list of objects
    associated with a particular financial document.
} {
    set bgcolor(0) "class=roweven"
    set bgcolor(1) "class=rowodd"

    set object_list_sql "
	select distinct
	   	o.object_id,
		acs_object.name(o.object_id) as object_name,
		u.url
	from
	        acs_objects o,
	        acs_rels r,
		im_biz_object_urls u
	where
	        r.object_id_one = o.object_id
	        and r.object_id_two = :cost_id
		and u.object_type = o.object_type
		and u.url_type = 'view'
    "

    set ctr 0
    set object_list_html ""
    db_foreach object_list $object_list_sql {
	append object_list_html "
        <tr $bgcolor([expr $ctr % 2])>
          <td>
            <A href=\"$url$object_id\">$object_name</A>
          </td>
          <td>
            <input type=checkbox name=object_ids.$object_id>
          </td>
        </tr>\n"
	incr ctr
    }

    if {0 == $ctr} {
	append object_list_html "
        <tr $bgcolor([expr $ctr % 2])>
          <td><i>No objects found</i></td>
        </tr>\n"
    }

    return "
      <form action=cost-association-action method=post>
      [export_form_vars cost_id return_url]
      <table border=0 cellspacing=1 cellpadding=1>
        <tr>
          <td align=middle class=rowtitle colspan=2>Related Projects</td>
        </tr>
        $object_list_html
        <tr>
          <td align=right>
            <input type=submit name=add_project_action value='Add a Project'>
            </A>
          </td>
          <td>
            <input type=submit name=del_action value='Del'>
          </td>
        </tr>
      </table>
      </form>
    "
}


# -------------------------------------------------------------
# Notes List Component
# -------------------------------------------------------------


ad_proc im_company_payment_balance_component { company_id } {
    Returns a formatted HTML with invoices vs. payments.
} {
    # ------------------------------------------------------------------
    # List of Invoices or Bills

    set company_type_id [db_string type "select company_type_id from im_companies where company_id = :company_id" -default 0]
    if {[im_category_is_a $company_type_id [im_company_type_customer]]} { set company_type_id [im_company_type_customer] }
    if {[im_category_is_a $company_type_id [im_company_type_provider]]} { set company_type_id [im_company_type_provider] }

    set company_sql ""
    switch $company_type_id {
	57 {
	    # customer
	    set company_sql "c.customer_id = :company_id"
	    set cust_prov_type_id [im_cost_type_invoice]
	}
	56 {
	    # provider
	    set company_sql "c.provider_id = :company_id"
	    set cust_prov_type_id [im_cost_type_bill]
	}
	default {
	    # partner, internal or similar: Skip this component
	    return ""
	}

    }	

    template::list::create \
	-name list_costs \
	-multirow list_costs_multirow \
	-class "list-table" \
	-main_class "list-table" \
	-sub_class "right" \
	-elements {
	    date_pretty {
		display_col date_pretty
		label "Date"
		display_template "<nobr>@list_costs_multirow.date_pretty@</nobr>"
	    }
	    cost_name {
		display_col cost_name
		label "Name"
		link_url_eval $invoice_url
	    }
	    subtotal_converted {
		label "Subtotal"
	    }
	    vat_pretty { 
		label "VAT" 
		display_template "<nobr>@list_costs_multirow.vat_pretty@</nobr>"
	    }
	    tax_pretty { 
		label "TAX"
		display_template "<nobr>@list_costs_multirow.tax_pretty@</nobr>"
	    }
	    total_converted {
		label "Total"
	    }
	    paid {
		display_col paid_amount_converted
		label "Paid"
	    }
	}

    set costs_sql "    
	select	c.*,
		round(vat,2) as vat_pretty,
		round(tax,2) as tax_pretty,
		im_category_from_id(c.cost_status_id) as cost_status,
		im_category_from_id(c.cost_type_id) as cost_type,
		to_char(c.effective_date, 'YYYY-MM-DD') as date_pretty,
		round((c.paid_amount * xrate)::numeric, 2) as paid_amount_converted,
		round((c.amount * xrate)::numeric, 2) as subtotal_converted,
		round((c.amount * xrate * (1 + vat/100 + tax/100))::numeric, 2) as total_converted
	from	
		(select
			c.*,
			im_exchange_rate(c.effective_date::date, c.currency, 'EUR') as xrate,
			c.paid_currency
		from
			im_costs c
		where
			c.cost_type_id = $cust_prov_type_id and
			$company_sql
		) c
	order by
		effective_date
    "

    set costs_sum 0
    db_multirow -extend {invoice_url} list_costs_multirow costs_sql $costs_sql {
	set invoice_url [export_vars -base "/intranet-invoices/view" {{invoice_id $cost_id}}]
	if {"" == $total_converted} { set total_converted 0 }
	set costs_sum [expr $costs_sum + $total_converted]
    }
    
    eval [template::adp_compile -string "<listtemplate name=list_costs></listtemplate>"]
    set costs_html $__adp_output



    # ------------------------------------------------------------------
    # List of Payments

    template::list::create \
	-name list_payments \
	-multirow list_payments_multirow \
	-class "list-table" \
	-main_class "list-table" \
	-sub_class "right" \
	-elements {
	    date {
		display_col received_date_pretty
		label "[_ intranet-core.Date]"
		link_url_eval $invoice_url
	    }
	    payment_type {
		label "[_ intranet-core.Payment_Method]"
		link_url_eval $invoice_url
	    }
	    amount {
		label "[_ intranet-cost.Amount]"
		display_template "<div align=right>@list_payments_multirow.amount@</div>"
	    }
	}

    set payments_sql "    
	select
		p.*,
		to_char(p.received_date, 'YYYY-MM-DD') as received_date_pretty,
		round((p.amount * im_exchange_rate(p.received_date::date, p.currency, 'EUR')) :: numeric, 2) as amount_converted,
		im_category_from_id(payment_type_id) as payment_type
	from
		im_payments p,
		im_costs c
	where
		p.cost_id = c.cost_id and
		$company_sql
	order by
		received_date
    "

    set payments_sum 0
    db_multirow -extend {invoice_url} list_payments_multirow payments_sql $payments_sql {
	set payment_url [export_vars -base "/intranet-payments/view" {payment_id}]
	set payments_sum [expr $payments_sum + $amount_converted]
    }
    
    eval [template::adp_compile -string "<listtemplate name=list_payments></listtemplate>"]
    set payments_html $__adp_output

    return "
<!--	[lang::message::lookup "" intranet-cost.Invoices "Invoices"] -->
	$costs_html
	<b>Sum: $costs_sum</b>
	<br>&nbsp;<br>
<!--	[lang::message::lookup "" intranet-cost.Payments "Payments"] -->
	$payments_html<br>
	<b>Sum: $payments_sum</b>
	<br>&nbsp;<br>

    "
}


ad_proc im_costs_company_component { user_id company_id } {
    Returns a HTML table containing a list of costs for a particular
    company.
} {
    set html [im_costs_base_component $user_id $company_id ""]
    return $html
}

ad_proc im_costs_project_component { user_id project_id } {
    Returns a HTML table containing a list of costs for a 
    particular project.
} {
    return [im_costs_base_component $user_id "" $project_id]
}


ad_proc im_costs_base_component { 
    user_id 
    {company_id ""} 
    {project_id ""} 
} {
    Returns a HTML table containing a list of costs for a particular
    company or project.
} {
    if {![im_permission $user_id view_costs]} {
	return ""
    }

    set bgcolor(0) " class=roweven "
    set bgcolor(1) " class=rowodd "
    set max_costs 5
    set colspan 5
    set org_project_id $project_id
    set org_company_id $company_id

    # Where to link when clicking on an object linke? "edit" or "view"?
    set view_mode "view"

    # ----------------- Compose SQL Query --------------------------------
  
    set extra_where [list]
    set extra_from [list]
    set extra_select [list]
    set object_name ""
    set new_doc_args ""
    if {"" != $company_id} { 
	lappend extra_where "(ci.customer_id = :company_id OR ci.provider_id = :company_id)" 
	set object_name [db_string object_name "select company_name from im_companies where company_id = :company_id"]
	set new_doc_args "?company_id=$company_id"
    }

    if {"" != $project_id} { 
	# Select the costs explicitely associated with a project.
	lappend extra_where "
	ci.cost_id in (
		select distinct cost_id 
		from im_costs 
		where project_id=:project_id
	    UNION
		select distinct object_id_two as cost_id
		from acs_rels
		where object_id_one = :project_id
	)" 
	set object_name [db_string object_name "select project_name from im_projects where project_id = :project_id"]
	set new_doc_args "?project_id=$project_id"
    }

    set extra_where_clause [join $extra_where "\n\tand "]
    if {"" != $extra_where_clause} { set extra_where_clause "\n\tand $extra_where_clause" }
    set extra_from_clause [join $extra_from ",\n\t"]
    if {"" != $extra_from_clause} { set extra_from_clause ",\n\t$extra_from_clause" }
    set extra_select_clause [join $extra_select ",\n\t"]
    if {"" != $extra_select_clause} { set extra_select_clause ",\n\t$extra_select_clause" }

    set costs_sql "
	select
		ci.*,
		ci.paid_amount as payment_amount,
		ci.paid_currency as payment_currency,
		url.url,
	        im_category_from_id(ci.cost_status_id) as cost_status,
	        im_category_from_id(ci.cost_type_id) as cost_type,
		to_date(to_char(ci.effective_date,'yyyymmdd'),'yyyymmdd') 
			+ ci.payment_days as calculated_due_date
		$extra_select_clause
	from
		im_costs ci,
		acs_objects o,
	        (select * from im_biz_object_urls where url_type=:view_mode) url,
		(	select distinct
				cc.cost_center_id,
				ct.cost_type_id
			from	im_cost_centers cc,
				im_cost_types ct,
				acs_permissions p,
				party_approved_member_map m,
				acs_object_context_index c, 
				acs_privilege_descendant_map h
			where
				p.object_id = c.ancestor_id
				and h.descendant = ct.read_privilege
				and c.object_id = cc.cost_center_id
				and m.member_id = :user_id
				and p.privilege = h.privilege
				and p.grantee_id = m.party_id
		) readable_ccs
		$extra_from_clause
	where
		ci.cost_id = o.object_id
		and o.object_type = url.object_type
		and ci.cost_center_id = readable_ccs.cost_center_id
		and ci.cost_type_id = readable_ccs.cost_type_id
		$extra_where_clause
	order by
		ci.effective_date desc
    "

    set cost_html "
	<table border=0>
	  <tr>
	    <td colspan=$colspan class=rowtitle align=center>
	      [_ intranet-cost.Financial_Documents]
	    </td>
	  </tr>
	  <tr class=rowtitle>
	    <td align=center class=rowtitle>[_ intranet-cost.Document]</td>
	    <td align=center class=rowtitle>[_ intranet-cost.Type]</td>
	    <td align=center class=rowtitle>[_ intranet-cost.Due]</td>
	    <td align=center class=rowtitle>[_ intranet-cost.Amount]</td>
	    <td align=center class=rowtitle>[_ intranet-cost.Paid]</td>
	  </tr>
    "
    set ctr 1
    set payment_amount ""
    set payment_currency ""

    db_foreach recent_costs $costs_sql {

	append cost_html "
		<tr$bgcolor([expr $ctr % 2])>
		  <td><A href=\"$url$cost_id\">[string range $cost_name 0 20]</A></td>
		  <td>$cost_type</td>
		  <td>$calculated_due_date</td>
		  <td>$amount $currency</td>
		  <td>$payment_amount $payment_currency</td>
		</tr>
	"
	incr ctr
	if {$ctr > $max_costs} { break }
    }

    # Restore the original values after SQL selects
    set project_id $org_project_id
    set company_id $org_company_id

    append cost_html "
		<tr$bgcolor([expr $ctr % 2])>
		  <td colspan=$colspan>
		    <A HREF=/intranet-cost/list?[export_url_vars status_id company_id project_id]>
		      [_ intranet-cost.more_costs]
		    </A>
		  </td>
		</tr>
    "

    # Add a reasonable message if there are no documents
    if {$ctr == 1} {
	append cost_html "
		<tr$bgcolor([expr $ctr % 2])>
		  <td colspan=$colspan align=center>
		    <I>[_ intranet-cost.lt_No_financial_document]</I>
		  </td>
		</tr>
	"
	incr ctr
    }


    # Add some links to create new financial documents
    # if the intranet-invoices module is installed
    if {[im_table_exists im_invoices]} {

	# Project Documents:
	if {"" != $project_id} {

	    append cost_html "
	<tr class=rowplain>
	  <td colspan=$colspan>\n"


	    # Customer invoices: customer = Project Customer, provider = Internal
	    set customer_id [util_memoize [list db_string project_customer "select company_id from im_projects where project_id = $project_id" -default ""]]
	    set provider_id [im_company_internal]
	    set bind_vars [list customer_id $customer_id provider_id $provider_id project_id $project_id]
      	    append cost_html [im_menu_ul_list "invoices_customers" $bind_vars]

	    # Provider invoices: customer = Internal, no provider yet defined
	    set customer_id [im_company_internal]
	    set bind_vars [list customer_id $customer_id project_id $project_id]
	    append cost_html [im_menu_ul_list "invoices_providers" $bind_vars]

	    append cost_html "	
	  </td>
	</tr>
	"
	    incr ctr

	} 
    }

    append cost_html "</table>\n"
    return $cost_html
}


# ---------------------------------------------------------------
# Benefits & Loss Calculation per Project
# ---------------------------------------------------------------

ad_proc im_costs_project_finance_component { 
    {-show_details_p 1}
    {-show_summary_p 1}
    {-show_admin_links_p 0}
    user_id 
    project_id 
} {
    Returns a HTML table containing a detailed summary of all
    financial activities of the project. <p>

    The complexity of this component comes from several sources:
    <ul>
    <li>We need to sum up the invoices and sort them into several
        "buckets" that correspond to the different cost types
        such as "customer invoices", "provider purchase orders",
        internal "timesheet costs" etc.
    <li>We can have costs and financial documents (see doc.) in
        several currencies, so we can't just add these together.
        Instead, we need to maintain separate sums per cost type
        and currency.
        Also, costs may have NULL cost values (timesheet costs
        from persons whithout the "hourly cost" defined).
    </ul>

} {
    # pre-filtering 
    # permissions - beauty of code follows transparency and readability
    
    set view_docs_1_p 0
    set view_docs_2_p 0
    set view_docs_3_p 0
    set can_read_summary_p 0
    
    set limit_to_freelancers ""
    set limit_to_inco_customers ""
    set limit_to_customers ""
    
    # user is freelancer and can see purchase orders
    if { [im_profile::member_p -profile_id [im_freelance_group_id] -user_id $user_id] && [im_permission $user_id fi_read_pos]  } {
	set view_docs_1_p 1
    }
    
    # user is interco client with privileges "Fi read quotes" AND  "Fi read invoices AND Fi read interco quotes" AND  "Fi read interco invoices" 
    if { [im_profile::member_p -profile_id [im_inco_customer_group_id] -user_id $user_id] && ( [im_permission $user_id fi_read_invoices] || [im_permission $user_id fi_read_quotes] || [im_permission $user_id fi_read_interco_quotes] || [im_permission $user_id fi_read_interco_invoices] ) } {
	set view_docs_2_p 1
    }

    # user is client with privileges "Fi read quotes" AND  "Fi read invoices" 
    if { [im_profile::member_p -profile_id [im_customer_group_id] -user_id $user_id] && ( [im_permission $user_id fi_read_invoices] || [im_permission $user_id fi_read_quotes] ) } {
	set view_docs_2_p 1
    }
    
    # user is employee and has has privilege  "view cost" 
    if { [im_user_is_employee_p $user_id] && [im_permission $user_id view_costs] } {
	set view_docs_3_p 1
	set can_read_summary_p 1
    }
    
    if { !( $view_docs_1_p || $view_docs_2_p || $view_docs_3_p ) && ![im_user_is_admin_p $user_id]} {
	return "You have no permission to see this page"
    } 
    
    # show admin links only if at least one write permission
    if {$show_details_p} { set show_admin_links_p 1 }

    set bgcolor(0) " class=roweven "
    set bgcolor(1) " class=rowodd "
    set colspan 7
    set date_format "YYYY-MM-DD"
    set num_format "9999999999.99"
    set return_url [im_url_with_query]

    # Locale for rendering 
    set locale "en"

    # Where to link when clicking on an object link? "edit" or "view"?
    set view_mode "view"

    # Default Currency
    set default_currency [ad_parameter -package_id [im_package_cost_id] "DefaultCurrency" "" "EUR"]

    # project_id may get overwritten by SQL query
    set org_project_id $project_id

    # Get a hash array of subtotals per cost_type
    array set subtotals [im_cost_update_project_cost_cache $project_id]

    # ----------------- Compose Main SQL Query --------------------------------

    set project_cost_ids_sql "
		                select distinct cost_id
		                from im_costs
		                where project_id in (
					select	children.project_id
					from	im_projects parent,
						im_projects children
					where	children.tree_sortkey 
							between parent.tree_sortkey 
							and tree_right(parent.tree_sortkey)
						and parent.project_id = :project_id
				)
			    UNION
				select distinct object_id_two as cost_id
				from acs_rels
				where object_id_one in (
					select	children.project_id
					from	im_projects parent,
						im_projects children
					where	children.tree_sortkey 
							between parent.tree_sortkey 
							and tree_right(parent.tree_sortkey)
						and parent.project_id = :project_id
				)
    "


	# If user = freelancer limit docs to PO
	if { [im_profile::member_p -profile_id [im_freelance_group_id] -user_id $user_id] } {
	    set limit_to_freelancers "and ci.cost_type_id = [im_cost_type_po] "
	}
	# If user = inco customer limit docs to Quotes & Invoices & InterCo Quotes & InterCo Invoices
	if { [im_profile::member_p -profile_id [im_inco_customer_group_id] -user_id $user_id] } {
	    set limit_to_inco_customers "and ci.cost_type_id in ( [im_cost_type_quote],[im_cost_type_invoice],[im_cost_type_interco_invoice],[im_cost_type_interco_quote] ) "
	}
	# If user = customer limit docs to Quotes & Invoices
	if { [im_profile::member_p -profile_id [im_customer_group_id] -user_id $user_id] } {
	set limit_to_customers "and ci.cost_type_id in ( [im_cost_type_quote],[im_cost_type_invoice] ) "
		}

    set costs_sql "
	select
		ci.*,
		to_char(ci.paid_amount, :num_format) as payment_amount,
		ci.paid_currency as payment_currency,
		to_char(ci.amount, :num_format) as amount,
		to_char(ci.amount * im_exchange_rate(ci.effective_date::date, ci.currency, :default_currency), :num_format) as amount_converted,
		p.project_nr,
		p.project_name,
		cust.company_name as customer_name,
		prov.company_name as provider_name,
		url.url,
		im_category_from_id(ci.cost_status_id) as cost_status,
		im_category_from_id(ci.cost_type_id) as cost_type,
		im_cost_center_code_from_id(ci.cost_center_id) as cost_center_code,
		to_date(to_char(ci.effective_date,:date_format),:date_format) + ci.payment_days as calculated_due_date
	from
		im_costs ci
			LEFT OUTER JOIN im_projects p ON (ci.project_id = p.project_id)
			LEFT OUTER JOIN im_companies cust on (ci.customer_id = cust.company_id)
			LEFT OUTER JOIN im_companies prov on (ci.provider_id = prov.company_id),
		acs_objects o,
		(select * from im_biz_object_urls where url_type=:view_mode) url
	where
		ci.cost_id = o.object_id
		and o.object_type = url.object_type
		and ci.cost_id in (
			$project_cost_ids_sql
		)
	      	and ci.cost_type_id not in (
	                [im_cost_type_employee],
	                [im_cost_type_repeating],
	                [im_cost_type_expense_item]
	        )
		$limit_to_freelancers
		$limit_to_inco_customers
		$limit_to_customers
	order by
		ci.cost_type_id,
		ci.effective_date desc
    "


    set cost_html "
	<h1>[_ intranet-cost.Financial_Documents]</h1>
	<table border=0 class='table_list_page'>
	  <!-- <tr class='no_hover'>
	    <td colspan=$colspan class=rowtitle>
	      [_ intranet-cost.Financial_Documents]
	    </td>
	  </tr>-->
	  <thead>
	  <tr>
	    <td>[_ intranet-cost.Document]</td>
	    <td>[lang::message::lookup "" intranet-cost.CostCenter_short "CC"]</td>
	    <td>[_ intranet-cost.Company]</td>
	    <td>[_ intranet-cost.Due]</td>
	    <td align='right'>[_ intranet-cost.Amount]</td>
	    <td align='right'>[lang::message::lookup "" intranet-cost.Org_Amount "Org"]</td>
	    <td align='right'>[_ intranet-cost.Paid]</td>
	  </tr>
	  </thead>
	  <tbody>
	  <tr class='rowwhite'><td colspan='99'>&nbsp;</td></tr>
   "

    set ctr 1
    set atleast_one_unreadable_p 0
    set old_atleast_one_unreadable_p 0
    set payment_amount ""
    set payment_currency ""

    set old_project_nr ""
    set old_cost_type_id 0
    db_foreach recent_costs $costs_sql {

	# Write the subtotal line of the last cost_type_id section
	if {$cost_type_id != $old_cost_type_id} {
	    if {0 != $old_cost_type_id} {
		if {!$atleast_one_unreadable_p} {
		    append cost_html "
			<tr class=rowplain>
			  <td colspan=[expr $colspan-4]>&nbsp;</td>
			  <td align='right' colspan=2>
			    <b><nobr>$subtotals($old_cost_type_id) $default_currency</nobr></b>
			  </td>
			  <td colspan='3'>&nbsp;</td>
			</tr>
		    "
		}
		append cost_html "
		<tr class='rowwhite'>
		  <td colspan=99>&nbsp;</td>
		</tr>\n"
	    }

	    regsub -all " " $cost_type "_" cost_type_subs
	    set cost_type [lang::message::lookup "" intranet-core.$cost_type_subs $cost_type]

	    append cost_html "
		<tr class='rowplain'>
		  <td colspan=99><span class='table_interim_title'>$cost_type</span></td>
		</tr>\n"

	    set old_cost_type_id $cost_type_id
	    set old_atleast_one_unreadable_p $atleast_one_unreadable_p
	    set atleast_one_unreadable_p 0
	}

	# Check permissions - query is cached
	set read_p [im_cost_center_read_p $cost_center_id $cost_type_id $user_id]
	if {!$read_p} { 
	    set atleast_one_unreadable_p 1 
	    set can_read_summary_p 0
	}

	set company_name ""
	if {$cost_type_id == [im_cost_type_invoice] || $cost_type_id == [im_cost_type_quote] || $cost_type_id == [im_cost_type_delivery_note] || $cost_type_id == [im_cost_type_interco_invoice] || $cost_type_id == [im_cost_type_interco_quote]} {
	    set company_name $customer_name
	} else {
	    set company_name $provider_name
	}
	
	set cost_url "<A title=\"$cost_name\" href=\"$url$cost_id&return_url=[ns_urlencode $return_url]\">"
	set cost_url_end "</A>"

	set amount_unconverted "<nobr>([string trim $amount] $currency)</nobr>"
	if {[string equal $currency $default_currency]} { set amount_unconverted "" }

	set amount_paid "$payment_amount $default_currency"
	if {"" == $payment_amount} { set amount_paid "" }

	set default_currency_read_p $default_currency
	if {!$read_p} {
	    set cost_url ""
	    set cost_url_end ""
	    set amount_converted ""
	    set amount_unconverted ""
	    set amount_paid ""
	    set default_currency_read_p ""
	}

	append cost_html "
	<tr $bgcolor([expr $ctr % 2])>
	  <td><nobr>$cost_url[string range $cost_name 0 30]</A></nobr></td>
	  <td>$cost_center_code</td>
	  <td>$company_name</td>
	  <td><nobr>$calculated_due_date</nobr></td>
	  <td align='right'><nobr>$amount_converted $default_currency_read_p</nobr></td>
	  <td align='right'><nobr>$amount_unconverted</td>
	  <td align='right'><nobr>$amount_paid</nobr></td>
	</tr>\n"
	incr ctr
    }

    # Write the subtotal line of the last cost_type_id section
    if {$ctr > 1} {
	if {!$atleast_one_unreadable_p} {
	    append cost_html "
		<tr class=rowplain>
		  <td colspan=[expr $colspan-3]>&nbsp;</td>
		  <td colspan='99'>
		    <b>$subtotals($old_cost_type_id) $default_currency</b>
		  </td>
		</tr>
            "
	}
	append cost_html "
		<tr class='rowwhite'>
		  <td colspan=99>&nbsp;</td>
		</tr>\n"
    }

    # Add a reasonable message if there are no documents
    if {$ctr == 1} {
	append cost_html "
	<tr$bgcolor([expr $ctr % 2])>
	  <td colspan=$colspan align=center>
	    <I>[_ intranet-cost.lt_No_financial_document]</I>
	  </td>
	</tr>\n"
	incr ctr
    }

    # Close the main table
    append cost_html "</tbody></table>\n"

    if {!$show_details_p} { set cost_html "" }


    # ----------------- Hard Costs HTML -------------
    # Hard "real" costs such as invoices, bills and timesheet

    set hard_cost_html "
<table with=\"100%\">
  <tr class=rowtitle>
    <td class=rowtitle colspan=2 align=center>[_ intranet-cost.Real_Costs]</td>
  </tr>
  <tr>
    <td>[_ intranet-cost.Customer_Invoices]</td>\n"
    set subtotal $subtotals([im_cost_type_invoice])
    append hard_cost_html "<td align=right>$subtotal $default_currency</td>\n"
    set grand_total $subtotal

    append hard_cost_html "</tr>\n<tr>\n<td>[_ intranet-cost.Provider_Bills]</td>\n"
    set subtotal $subtotals([im_cost_type_bill])
    append hard_cost_html "<td align=right>- $subtotal $default_currency</td>\n"
    set grand_total [expr $grand_total - $subtotal]

    append hard_cost_html "</tr>\n<tr>\n<td>[_ intranet-cost.Timesheet_Costs]</td>\n"
    set subtotal $subtotals([im_cost_type_timesheet])
    append hard_cost_html "<td align=right>- $subtotal $default_currency</td>\n"
    set grand_total [expr $grand_total - $subtotal]

    append hard_cost_html "</tr>\n<tr>\n<td>[lang::message::lookup "" intranet-cost.Expenses "Expenses"]</td>\n"
    set subtotal $subtotals([im_cost_type_expense_bundle])
    append hard_cost_html "<td align=right>- $subtotal $default_currency</td>\n"
    set grand_total [expr $grand_total - $subtotal]

    append hard_cost_html "</tr>\n<tr>\n<td><b>[_ intranet-cost.Grand_Total]</b></td>\n"
    append hard_cost_html "<td align=right><b>$grand_total $default_currency</b></td>\n"

#    append hard_cost_html "<td align=right><b>[lc_numeric $grand_total "" $locale] $default_currency</b></td>\n"

    append hard_cost_html "</tr>\n</table>\n"


    # ----------------- Prelim Costs HTML -------------
    # Preliminary (planned) Costs such as Quotes and Purchase Orders

    set prelim_cost_html "
<table width=\"100%\">
  <tr class=rowtitle>
    <td class=rowtitle colspan=2 align=center>[_ intranet-cost.Preliminary_Costs]</td>
  </tr>
  <tr>
    <td>[_ intranet-cost.Quotes]</td>\n"

    set subtotal $subtotals([im_cost_type_quote])
    append prelim_cost_html "<td align=right>$subtotal $default_currency</td>\n"
    set grand_total $subtotal

    append prelim_cost_html "</tr>\n<tr>\n<td>[_ intranet-cost.Purchase_Orders]</td>\n"
    set subtotal $subtotals([im_cost_type_po])
    append prelim_cost_html "<td align=right>- $subtotal $default_currency</td>\n"
    set grand_total [expr $grand_total - $subtotal]

    append prelim_cost_html "</tr>\n<tr>\n<td>[lang::message::lookup "" intranet-cost.Timesheet_Budget "Timesheet Budget"]</td>\n"
    set subtotal $subtotals([im_cost_type_timesheet_budget])
    append prelim_cost_html "<td align=right>- $subtotal $default_currency</td>\n"
    set grand_total [expr $grand_total - $subtotal]

    append prelim_cost_html "</tr>\n<tr>\n<td>[lang::message::lookup "" intranet-cost.Expenses "Expenses"]</td>\n"
    append prelim_cost_html "<td align=right>
	  $subtotals([im_cost_type_expense_planned]) $default_currency
	</td>\n"

    append prelim_cost_html "</tr>\n<tr>\n<td><b>[lang::message::lookup "" intranet-cost.Preliminary_Total "Preliminary Total"]</b></td>\n"
    append prelim_cost_html "<td align=right><b>$grand_total $default_currency</b></td>\n"
    append prelim_cost_html "</tr>\n</table>\n"


    # ----------------- Check that the Exchange Rates are still valid  -------------

    # See which currencies are to be added here...
    set used_currencies [db_list currencies_used "
	select distinct
		ci.currency
	from	im_costs ci
	where	ci.currency != :default_currency
		and cost_id in (
		    $project_cost_ids_sql
		)
    "]

    set exchange_rates_outdated [im_exchange_rate_outdated_currencies]
    set currency_outdated_warning ""
    if {[llength $used_currencies] > 0 && [llength $exchange_rates_outdated] > 0} {

	set currency_outdated_warning [lang::message::lookup "" intranet-cost.The_exchange_rates_are_outdated "The exchanges rates for the following currencies are outdated. <br>Please contact your System Administrator to update the following exchange rates:"]

	append currency_outdated_warning "
		<ul>
		<li><a href='/intranet-exchange-rate/'>
			[lang::message::lookup "" intranet-cost.Update_Exchange_Rates "Update Exchange Rates"]
		    </a>
		</ul>
	"

	set first_p 1
	foreach entry $exchange_rates_outdated {
	    set currency [lindex $entry 0]
	    set days [lindex $entry 1]
	    set outdated_msg [lang::message::lookup "" intranet-cost.Outdated_since_x_days "Outdated since %days% days"]
	    if {!$first_p} { append currency_outdated_warning ", " }
	    append currency_outdated_warning "$currency: $outdated_msg\n"
	    set first_p 0
	}

	set currency_outdated_warning "
		<table>
		<tr class=rowtitle><td class=rowtitle>
		[lang::message::lookup "" intranet-cost.Outdated_Message "Outdated Exchange Rates Warning"]
		</td></tr>
		<tr><td>$currency_outdated_warning</td></tr>
		</table>
        "

    }


    # ----------------- Admin Links --------------------------------

    # Restore value overwritten by SQL query
    set project_id $org_project_id
    
    # Add some links to create new financial documents
    # if the intranet-invoices module is installed
    set admin_html ""
    if {$show_admin_links_p && [im_table_exists im_invoices]} {


	# Customer invoices: customer = Project Customer, provider = Internal
	set customer_id [util_memoize [list db_string project_customer "select company_id from im_projects where project_id = $org_project_id" -default ""]]
	set provider_id [im_company_internal]
	set bind_vars [list project_id $project_id customer_id $customer_id provider_id $provider_id]

	# set html_customer_links [im_menu_ul_list -package_key intranet-invoices "invoices_customers" $bind_vars]
	set html_customer_links [im_menu_ul_list "invoices_customers" $bind_vars]

	# Provider invoices: customer = Internal, no provider yet defined
	set customer_id [im_company_internal]
	set bind_vars [list customer_id $customer_id project_id $project_id]	

	# set html_provider_links [im_menu_ul_list -package_key intranet-invoices "invoices_providers" $bind_vars]
	set html_provider_links [im_menu_ul_list "invoices_providers" $bind_vars]

	if { ![empty_string_p $html_customer_links] || ![empty_string_p $html_provider_links] } {
		set admin_html "
		<h1>[_ intranet-core.Admin_Links]</h1>
		<table>
		<tr class=rowplain>
		<td>\n"
		if { ![empty_string_p $html_customer_links] } {
			append admin_html "<h2>"
		    	append admin_html [lang::message::lookup "" intranet-cost.Customer_Links "Customer Actions"]
		    	append admin_html "</h2>"	
	      	    	append admin_html $html_customer_links
		}
                if { ![empty_string_p $html_provider_links] } {
			append admin_html "<br><h2>"			
			append admin_html [lang::message::lookup "" intranet-cost.Provider_Links "Provider Actions"]
			append admin_html "</h2>"	
			append admin_html $html_provider_links
		}
	    append admin_html "	
	  </td>
	</tr>
	</table>
	"
	}
    }

    # ----------------- Assemble the "Summary" component ---------------------------
    # With preliminary and hard costs


    set summary_html ""
    if {$show_details_p} {

	# Summary in broad format
	set summary_html "
	<h1>[_ intranet-cost.Financial_Summary]</h1>
	<table cellspacing=0 cellpadding=0>
	<!--<tr><td class=rowtitle colspan=3>[_ intranet-cost.Financial_Summary]</td></tr>-->
	<tr valign=top>
	  <td>$hard_cost_html</td>
	  <td>&nbsp &nbsp;</td>
	  <td>$prelim_cost_html</td>
	</tr>
	</table>\n"

    } else {

	# Summary in narrow format
	set summary_html "
	<table cellspacing=0 cellpadding=0 width=\"100%\">
	<tr><td class=rowtitle>[_ intranet-cost.Financial_Summary]</td></tr>
	<tr valign=top><td>$hard_cost_html</td></tr>
	<tr><td>$prelim_cost_html</td></tr>
	</table>\n"

	set summary_html "
	$hard_cost_html
        <br>
	$prelim_cost_html
        "

    }

    if {!$show_summary_p} { set summary_html "" }
    if {!$can_read_summary_p} { set summary_html "" }

    # ----------------- Put the component/page together ---------------------------

    set result_html "
        $currency_outdated_warning
	<table>
	<tr valign=top>
	  <td>
	    $cost_html
            <br>
            $summary_html
	  </td>
	  <td>
	    $admin_html
	  </td>
	</tr>
        <tr><td colspan=2>
        </td></tr>
	</table>
    "

    return $result_html

}


ad_proc -public im_cost_type_select { 
    select_name 
    { default "" } 
    { super_type_id 0 } 
    { cost_item_group "" }
} {
    Returns an html select box named $select_name and defaulted to
    $default with a list of all the cost_types in the system.
    If super_type_id is specified then return only those types "below" super_type.

    @param cost_item_group Can be "" (all) or "financial_doc".
           Limits the number of cost types to a certain group of FinDocs
} {
    set category_type "Intranet Cost Type"
    set bind_vars [ns_set create]
    ns_set put $bind_vars category_type $category_type

    set sql "
	select	c.category_id,
		c.category
	from	im_categories c
	where	c.category_type = :category_type and
		(enabled_p is null OR enabled_p = 't')
    "

    # Restrict to specific subtypes of FinDocs
    switch [string tolower $cost_item_group] {
	"financial_doc" {
	    append sql "\n\t\tand c.category_id in (
		[im_cost_type_invoice],
		[im_cost_type_quote],
		[im_cost_type_bill],
		[im_cost_type_po],
		[im_cost_type_delivery_note],
		[im_cost_type_interco_invoice],
		[im_cost_type_interco_quote]
	    )"
	}
    }

    if {$super_type_id} {
	ns_set put $bind_vars super_type_id $super_type_id
	append sql "\n	and c.category_id in ([join [im_sub_categories $super_type_id] ","])"
    }
    return [im_selection_to_select_box $bind_vars category_select $sql $select_name $default]
}



ad_proc -public im_cost_status_select { 
    {-translate_p 1} 
    {-locale ""}
    select_name 
    { default "" } 
} {
    Returns an html select box named $select_name and defaulted to
    $default with a list of all the cost status_types in the system
} {
    set include_empty 0
    set options [util_memoize "im_cost_status_options $include_empty"]

    set result "\n<select name=\"$select_name\">\n"
    if {[string equal $default ""]} {
	append result "<option value=\"\"> -- Please select -- </option>"
    }

    foreach option $options {

	if { $translate_p } {
	    set text [lang::message::lookup $locale intranet-core.[lang::util::suggest_key [lindex $option 0]] [lindex $option 0]]
	} else {
	    set text [lindex $option 0]
	}
	
	set selected ""
	if { [string equal $default [lindex $option 1]]} {
	    set selected " selected"
	}
	append result "\t<option value=\"[util_quote_double_quotes [lindex $option 1]]\" $selected>"
	append result "$text</option>\n"

    }

    append result "\n</select>\n"
    return $result
}


ad_proc im_cost_payment_method_select { select_name { default "" } } {
    Returns an html select box named $select_name and defaulted to $default 
    with a list of all the partner statuses in the system
} {
    return [im_category_select "Intranet Cost Payment Method" $select_name $default]
}

ad_proc im_cost_template_select { 
    select_name 
    { default "" } 
} {
    Returns an html select box named $select_name and defaulted to $default 
    with a list of all the partner statuses in the system
} {
    return [im_category_select -translate_p 0 "Intranet Cost Template" $select_name $default]
}



ad_proc im_costs_select { 
    select_name 
    { default "" } 
    { status "" } 
    { exclude_status "" } 
} {
    Returns an html select box named $select_name and defaulted to
    $default with a list of all the costs in the system. If status is
    specified, we limit the select box to costs that match that
    status. If exclude status is provided, we limit to states that do not
    match exclude_status (list of statuses to exclude).

} {
    set bind_vars [ns_set create]

    set sql "
	select
		i.cost_id,
		i.cost_name
	from
		im_costs i
	where
		1=1
    "

    if { ![empty_string_p $status] } {
	ns_set put $bind_vars status $status
	append sql " and cost_status_id=(select cost_status_id from im_cost_status where cost_status=:status)"
    }

    if { ![empty_string_p $exclude_status] } {
	set exclude_string [im_append_list_to_ns_set $bind_vars cost_status_type $exclude_status]
	append sql " and cost_status_id in (select cost_status_id 
						from im_cost_status 
						where cost_status not in ($exclude_string)) "
    }
    append sql " order by lower(cost_name)"
    return [im_selection_to_select_box $bind_vars "cost_status_select" $sql $select_name $default]
}


ad_proc im_cost_update_payments { cost_id } {
    Update the payment amount for a cost item by
    summing up all payments for this item.
} {
    set default_currency [ad_parameter -package_id [im_package_cost_id] "DefaultCurrency" "" "EUR"]

    db_dml update_cost_payment "
	update im_costs set 
	    paid_amount = (
	        select  sum(amount * im_exchange_rate(received_date::date, currency, :default_currency))
	        from    im_payments
	        where   cost_id = :cost_id
	    ),
	    paid_currency = :default_currency
	where cost_id = :cost_id
    "

    # Audit the action
    # im_audit -object_id $cost_id -action after_update -comment "Logging a payment on the cost."

}





# -----------------------------------------------------------
# Cost Cache Sweeper
#
# This is an offline process that is scheduled every ~60 seconds
# to check for projects with the "cost_cache_dirty" NOT NULL.
# 
# Projects with this mark have suffered from changes in the 
# associated financial documents, possibly from sub-projects,
# or structural changes (new or removed subproject).
#
# So this sweeper updates the cost_cache (various "cache" fields
# of im_projects), keeping the controlling information up to date
# within the given limits.
# -----------------------------------------------------------

ad_proc -public im_cost_cache_sweeper { } {
    Checks for the MaxCount projects with the "oldest" outdated
    cost caches. The "im_cost_project_cache_invalidator" does not
    overwrite existing "cost_cache_dirty" entries, so that this
    fields contains the first modification dates in a correct order,
    allowing us an "oldest first" update. This way we best and
    deterministicly limit the average outdated time per cache.
} {
    set max_projects [parameter::get_from_package_key -package_key intranet-cost -parameter "CostCacheSweeperMaxProjects" -default 50]
    set sql "
	select	project_id
	from	im_projects
	where	cost_cache_dirty is not null
	order by cost_cache_dirty
	LIMIT :max_projects
    "
    db_foreach sweep_cost_cache_projects $sql {
	# Update the sum of financial items across subprojects
	im_cost_update_project_cost_cache $project_id
    }
}


ad_proc -public im_cost_update_project_cost_cache { 
    project_id 
} {
    Calculates the sums of all cost elements per project,
    including subprojects of arbitrary depth.
    Returns the "subtotals" array.
} {
    set default_currency [ad_parameter -package_id [im_package_cost_id] "DefaultCurrency" "" "EUR"]
    set default_hourly_cost [ad_parameter -package_id [im_package_cost_id] "DefaultTimesheetHourlyCost" "" 30]

    # Update the logged hours cache
    im_timesheet_update_timesheet_cache -project_id $project_id

    set project_cost_ids_sql "
		                select distinct cost_id
		                from im_costs
		                where project_id in (
					select	children.project_id
					from	im_projects parent,
						im_projects children
					where	children.tree_sortkey 
							between parent.tree_sortkey 
							and tree_right(parent.tree_sortkey)
						and parent.project_id = :project_id
				)
			    UNION
				select distinct object_id_two as cost_id
				from acs_rels
				where object_id_one in (
					select	children.project_id
					from	im_projects parent,
						im_projects children
					where	children.tree_sortkey 
							between parent.tree_sortkey 
							and tree_right(parent.tree_sortkey)
						and parent.project_id = :project_id
				)
    "

   
    set subtotals_sql "
	select
		sum(ci.amount_converted) as amount_converted,
	        cat.cost_type_id
	from
		im_cost_types cat 
		LEFT OUTER JOIN	(
			select	ci.*,
				round((im_exchange_rate(
					ci.effective_date::date, 
					ci.currency, 
					:default_currency
				) * amount)::numeric, 2) as amount_converted
			from	im_costs ci
			where	ci.cost_id in (
					$project_cost_ids_sql
				)
		) ci on (cat.cost_type_id = ci.cost_type_id)
	where
		cat.cost_type_id not in (
			[im_cost_type_employee],
			[im_cost_type_repeating],
			[im_cost_type_expense_item]
		)
		and ci.currency is not null
	group by
		cat.cost_type_id
    "

    # Get the list of all cost types. Do not check for enabled_p here.
    set cost_type_list [util_memoize [list db_list cost_type_category_list "select category_id from im_categories where category_type='Intranet Cost Type'"]]
    foreach category_id $cost_type_list {
	set subtotals($category_id) 0
    }

    db_foreach subtotals $subtotals_sql {
	if {"" == $amount_converted} { set amount_converted 0 }
        set subtotals($cost_type_id) $amount_converted
    }

    # Special treatment for timesheet hours budget - multiply with default hourly rate
    set budget_hours [db_string budget_hours "select project_budget_hours from im_projects where project_id = :project_id" -default ""]
    if {"" == $budget_hours} { set budget_hours 0 }
    set cost_timesheet_planned [expr $budget_hours * $default_hourly_cost]
    set subtotals([im_cost_type_timesheet_planned]) $cost_timesheet_planned

    # Expense Planned
    if {![info exists subtotals([im_cost_type_expense_planned])]} {
	set subtotals([im_cost_type_expense_planned]) 0
    }
    

    # We can update the profit & loss because all financial documents
    # have been converted to default_currency
    db_dml update_projects "
		update im_projects set
			cost_invoices_cache = $subtotals([im_cost_type_invoice]),
			cost_bills_cache = $subtotals([im_cost_type_bill]),
			cost_timesheet_logged_cache = $subtotals([im_cost_type_timesheet]),
			cost_expense_logged_cache = $subtotals([im_cost_type_expense_bundle]),
			cost_quotes_cache = $subtotals([im_cost_type_quote]),
			cost_purchase_orders_cache = $subtotals([im_cost_type_po]),
			cost_delivery_notes_cache = $subtotals([im_cost_type_delivery_note]),
			cost_timesheet_planned_cache = :cost_timesheet_planned,
			cost_expense_planned_cache = 0,
			cost_cache_dirty = null
		where
			project_id = :project_id
    "

    # Audit the action
    # im_project_audit -project_id $project_id -action after_update

    return [array get subtotals]
}



# -----------------------------------------------------------
# NavBar tree for finance
# -----------------------------------------------------------

ad_proc -public im_navbar_tree_finance { 
    -user_id:required
    -locale:required
} { 
    Finance Navbar 
} {
    set wiki [im_navbar_doc_wiki]
    set current_user_id [ad_get_user_id]

    set html "
	<li><a href=/intranet-cost/>[lang::message::lookup "" intranet-cost.Finance "Finance"]</a>
	<ul>
	<li><a href=$wiki/module_finance>[lang::message::lookup "" intranet-core.Finance_Help "Finance Help"]</a>

		<li><a href=/intranet-invoices/list?cost_type_id=3708>[lang::message::lookup "" intranet-cost.New_Customer_Invoices_Quotes "New Cust. Invoices &amp; Quotes"]</a>
		<ul>
			[im_navbar_write_tree -package_key "intranet-invoices" -label "invoices_customers" -maxlevel 0]
		</ul>
		<li><a href=/intranet-invoices/list?cost_type_id=3710>[lang::message::lookup "" intranet-cost.New_Provider_Bills_POs "New Prov. Bills &amp; POs"]</a>
		<ul>
			[im_navbar_write_tree -package_key "intranet-invoices" -label "invoices_providers" -maxlevel 0]
		</ul>
		<li><a href=/intranet-invoices/list?cost_status_id=3802&cost_type_id=3700>[lang::message::lookup "" intranet-cost.Accounts_Receivable "Accounts Receivable"]</a></li>
		<li><a href=/intranet-invoices/list?cost_status_id=3802&cost_type_id=3704>[lang::message::lookup "" intranet-cost.Accounts_Payable "Accounts Payable"]</a></li>
		<li><a href=/intranet-payments/index>[lang::message::lookup "" intranet-cost.Payments Payments]</a></li>
		<li><a href=/intranet-dw-light/invoices.csv>[lang::message::lookup "" intranet-cost.Export_Finance_to_CSV "Export Finance to CSV/Excel"]</a></li>

		<li><a href=/intranet-reporting/>[lang::message::lookup "" intranet-core.Reporting Reporting]</a>
                <ul>
                [im_navbar_write_tree -package_key "intranet-reporting" -label "reporting-finance" -maxlevel 1]
                [im_navbar_write_tree -package_key "intranet-reporting" -label "reporting-timesheet" -maxlevel 1]
                </ul>

		<li><a href=/intranet/admin/>[lang::message::lookup "" intranet-cost.Admin Admin]</a>
		<ul>
			[im_menu_li admin_cost_centers]
			[im_menu_li finance_exchange_rates]
			<li><a href=/intranet-material/>[lang::message::lookup "" intranet-cost.Materials_Service_Types "Materials (Service Types)"]</a>
		</ul>
	</ul>
    "
    return $html
}



