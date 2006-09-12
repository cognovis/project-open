# /packages/intranet-invoicing/tcl/intranet-cost-procs.tcl
#
# Copyright (C) 2003-2004 Project/Open
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



# Frequently used Cost Types
ad_proc -public im_cost_type_invoice {} { return 3700 }
ad_proc -public im_cost_type_quote {} { return 3702 }
ad_proc -public im_cost_type_bill {} { return 3704 }
ad_proc -public im_cost_type_po {} { return 3706 }
ad_proc -public im_cost_type_company_doc {} { return 3708 }
ad_proc -public im_cost_type_provider_doc {} { return 3710 }
ad_proc -public im_cost_type_provider_travel {} { return 3712 }
ad_proc -public im_cost_type_employee {} { return 3714 }
ad_proc -public im_cost_type_repeating {} { return 3716 }
ad_proc -public im_cost_type_timesheet {} { return 3718 }
ad_proc -public im_cost_type_expense_item {} { return 3720 }
ad_proc -public im_cost_type_expense_report {} { return 3722 }
ad_proc -public im_cost_type_delivery_note {} { return 3724 }


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
	3722 { return "expense_report" }
	3724 { return "delivery_note" }
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
    set invoice_or_quote_p [expr $cost_type_id == [im_cost_type_invoice] || $cost_type_id == [im_cost_type_quote] || $cost_type_id == [im_cost_type_delivery_note]]
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
    set view [expr $cust_view || $prov_view || $cc_view]
    set read [expr $cust_read || $prov_read || $cc_read]
    set write [expr $cust_write || $prov_write || $cc_write]
    set admin [expr $cust_admin || $prov_admin || $cc_admin]

    # Limit rights of all users to view & read if they dont
    # have the expressive permission to "add_costs or add_invoices".
    if {!$can_write} {
        set write 0
        set admin 0
    }

#    ad_return_complaint 1 "$cost_center_id $cc_read $cc_write $view $read $write $admin"
}



# -----------------------------------------------------------
# Options & Selects
# -----------------------------------------------------------

ad_proc -public im_cost_center_status_options { {include_empty 1} } { 
    Cost Center status options
} {
    set options [db_list_of_lists cost_center_status_options "
	select category, category_id 
	from im_categories
	where category_type = 'Intranet Cost Center Status'
    "]
    if {$include_empty} { set options [linsert $options 0 { "" "" }] }
    return $options
}


ad_proc -public im_cost_center_type_options { {include_empty 1} } { 
    Cost Center type options
} {
    set options [db_list_of_lists cost_center_type_options "
	select category, category_id 
	from im_categories
	where category_type = 'Intranet Cost Center Type'
    "]
    if {$include_empty} { set options [linsert $options 0 { "" "" }] }
    return $options
}


ad_proc -public im_cost_uom_options { {include_empty 1} } {
    Cost UoM (Unit of Measure) options
} {
    set options [db_list_of_lists cost_type_options "
        select category, category_id
        from im_categories
	where category_type = 'Intranet UoM'
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

	set user_id [ad_get_user_id]
	set creation_ip [ad_conn peeraddr]
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
	where category_type = 'Intranet Cost Template'
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

ad_proc -public im_currency_options { {include_empty 1} } { 
    Cost currency options
} {
    set options [db_list_of_lists currency_options "
	select iso, iso
	from currency_codes
	where supported_p = 't'
    "]
    if {$include_empty} { set options [linsert $options 0 { "" "" }] }
    return $options
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



ad_proc -public im_department_options { {include_empty 0} } {
    Returns a list of all Departments in the company.
} {
    set department_only_p 1
    return [im_cost_center_options $include_empty $department_only_p]
}


ad_proc -public im_cost_center_select { 
    {-include_empty 0} 
    {-department_only_p 0} 
    select_name 
    {default ""} 
    {cost_type_id ""} 
} {
    Returns a select box with all Cost Centers in the company.
} {
#   ad_return_complaint 1 "include_empty=$include_empty, department_only_p=$department_only_p, select_name=$select_name, default=$default, cost_type_id=$cost_type_id"

    set options [im_cost_center_options $include_empty $department_only_p $cost_type_id]

    # Only one option, so 
    # write out string instead of select component
    if {[llength $options] == 1} {
	set cc_entry [lindex $options 0]
	set cc_id [lindex $cc_entry 1]
	set cc_name [string trim [lindex $cc_entry 0]]
	# Replace &nbsp; by " "
	regsub -all {\&nbsp\;} $cc_name " " cc_name
	return "$cc_name <input type=hidden name=\"$select_name\" value=\"$cc_id\">\n"
    }

    return [im_options_to_select_box $select_name $options $default]
}

ad_proc -public im_cost_center_options { 
    {include_empty 0} 
    {department_only_p 0} 
    {cost_type_id ""} 
} {
    Returns a list of all Cost Centers in the company.
    Takes into account the permission of the user to 
    charge FinDocs to CostCenters
} {
    set user_id [ad_get_user_id]
    set start_center_id [db_string start_center_id "
	select cost_center_id 
	from im_cost_centers 
	where cost_center_label='company'
    " -default 0]

    set cost_type "Invalid"
    if {"" != $cost_type_id} { set cost_type [db_string ct "select im_category_from_id(:cost_type_id)"] }

    set cost_type_sql ""
    set short_name [im_cost_type_short_name $cost_type_id]
    if {"" != $cost_type_id} { 
	set cost_type_sql "and im_object_permission_p(cost_center_id, :user_id, 'fi_write_${short_name}s') = 't'\n"
    }

    set department_only_sql ""
    if {$department_only_p} {
	set department_only_sql "and cc.department_p = 't'"
    }

    set options_sql "
        select
                cc.cost_center_name,
                cc.cost_center_id,
                cc.cost_center_label,
    		(length(cc.cost_center_code) / 2) - 1 as indent_level
        from
                im_cost_centers cc
	where
		1=1
		$department_only_sql
		$cost_type_sql
	order by
		cc.cost_center_code
    "

    set options [list]
    db_foreach cost_center_options $options_sql {
        set spaces ""
        for {set i 0} {$i < $indent_level} { incr i } {
            append spaces "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
        }
        lappend options [list "$spaces$cost_center_name" $cost_center_id]
    }

    if {$include_empty && [llength $options] == 0} {
	set invalid_cc [lang::message::lookup "" intranet-cost.No_CC_permissions_for_cost_type "No CC permissions for \"%cost_type%\""]
	lappend options [list $invalid_cc ""]
    }

    return $options
}




ad_proc -public im_costs_default_cost_center_for_user { 
    user_id
} {
    Returns a reasonable default cost center for a given user.
} {
    # For an employee return the department_id:
    set cost_center_id [db_string employee_cost_center "
	select	department_id
	from	im_employees
	where	employee_id = :user_id
    " -default 0]

    # No further logic yet - maybe assign groups to default
    # cost centers in the future?

    return $cost_center_id
}



ad_proc -public im_cost_center_read_p {
    cost_center_id
    cost_type_id
    user_id
} {
    Returns "1" if the user can read the CC, "0" otherwise.
    This TCL-level query makes sense, because it is cached
    and thus quite cheap to execute, while executing the
    acs_permission__permission_p() query could be quite
    expensive with a considerable number of financial docs.
} {
   return [string equal "t" [util_memoize "db_string cc_perms \"
	select	im_object_permission_p($cost_center_id, $user_id, ct.read_privilege)
	from	im_cost_types ct
	where	ct.cost_type_id = $cost_type_id
   \"" 60]]
}


ad_proc -public im_cost_center_write_p {
    cost_center_id
    cost_type_id
    user_id
} {
    Returns "1" if the user can write to the CC, "0" otherwise.
    This TCL-level query makes sense, because it is cached
    and thus quite cheap to execute, while executing the
    acs_permission__permission_p() query could be quite
    expensive with a considerable number of financial docs.
} {
   return [string equal "t" [util_memoize "db_string cc_perms \"
	select	im_object_permission_p($cost_center_id, $user_id, ct.write_privilege)
	from	im_cost_types ct
	where	ct.cost_type_id = $cost_type_id
   \"" 60]]
}


ad_proc -public im_costs_navbar { default_letter base_url next_page_url prev_page_url export_var_list {select_label ""} } {
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
    set alpha_bar [im_alpha_bar $base_url $default_letter $bind_vars]
    if {[string equal "none" $default_letter]} { set alpha_bar "&nbsp;" }
    if {![string equal "" $prev_page_url]} {
        set alpha_bar "<A HREF=$prev_page_url>&lt;&lt;</A>\n$alpha_bar"
    }

    if {![string equal "" $next_page_url]} {
        set alpha_bar "$alpha_bar\n<A HREF=$next_page_url>&gt;&gt;</A>\n"
    }

    # Get the Subnavbar
    set parent_menu_sql "select menu_id from im_menus where label='finance'"
    set parent_menu_id [db_string parent_admin_menu $parent_menu_sql -default 0]
    set navbar [im_sub_navbar $parent_menu_id "" $alpha_bar "tabnotsel" $select_label]
    return "<!-- navbar1 -->\n$navbar<!-- end navbar1 -->"
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

ad_proc im_costs_company_component { user_id company_id } {
    Returns a HTML table containing a list of costs for a particular
    company.
} {
    return [im_costs_base_component $user_id $company_id ""]
}

ad_proc im_costs_project_component { user_id project_id } {
    Returns a HTML table containing a list of costs for a particular
    particular project.
} {
    return [im_costs_base_component $user_id "" $project_id]
}


ad_proc im_costs_base_component { user_id {company_id ""} {project_id ""} } {
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
        (select * from im_biz_object_urls where url_type=:view_mode) url
	$extra_from_clause
where
	ci.cost_id = o.object_id
	and o.object_type = url.object_type
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
</tr>\n"
	incr ctr
	if {$ctr > $max_costs} { break }
    }

    # Restore the original values after SQL selects
    set project_id $org_project_id
    set company_id $org_company_id

    if {$ctr > $max_costs} {
	append cost_html "
<tr$bgcolor([expr $ctr % 2])>
  <td colspan=$colspan>
    <A HREF=/intranet-cost/list?[export_url_vars status_id company_id project_id]>
      [_ intranet-cost.more_costs]
    </A>
  </td>
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


    # Add some links to create new financial documents
    # if the intranet-invoices module is installed
    if {[db_table_exists im_invoices]} {

	# Project Documents:
	if {"" != $project_id} {

	    append cost_html "
	<tr class=rowplain>
	  <td colspan=$colspan>\n"


	    # Customer invoices: customer = Project Customer, provider = Internal
	    set customer_id [db_string project_customer "select company_id from im_projects where project_id=:project_id" -default ""]
	    set provider_id [im_company_internal]
	    set bind_vars [ad_tcl_vars_to_ns_set customer_id provider_id project_id]
      	    append cost_html [im_menu_ul_list "invoices_customers" $bind_vars]

	    # Provider invoices: customer = Internal, no provider yet defined
	    set customer_id [im_company_internal]
	    set bind_vars [ad_tcl_vars_to_ns_set customer_id project_id]
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
    if {![im_permission $user_id view_costs]} {	return "" }

    set bgcolor(0) " class=roweven "
    set bgcolor(1) " class=rowodd "
    set colspan 6
    set date_format "YYYY-MM-DD"
    set num_format "9999999999.99"

    set return_url [im_url_with_query]

    # Where to link when clicking on an object link? "edit" or "view"?
    set view_mode "view"

    # Default Currency
    set default_currency [ad_parameter -package_id [im_package_cost_id] "DefaultCurrency" "" "EUR"]

    # project_id may get overwritten by SQL query
    set org_project_id $project_id


    # ----------------- Main SQL - select subtotals and their currencies -------------

    # Determines the cost_ids to be included in in this view.
    # There are two options:
    # - Those cost items that contain our project_id in the "project_id" column
    #   (generated from normal invoicing process) and
    # - Those that are N:M related to a project via acs_rels.
    #   These holds for cummulative invoices, for example in translation.
    #

    

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
						and parent.project_id = :org_project_id
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
						and parent.project_id = :org_project_id
				)
    "

   
    set subtotals_sql "
select
	to_char(sum(ci.amount), :num_format) as amount,
	to_char(sum(ci.amount_converted), :num_format) as amount_converted,
	ci.currency,
        cat.category_id as cost_type_id,
        im_category_from_id(cat.category_id) as cost_type,
	case 
		when cat.category_id = [im_cost_type_invoice] then 1
		when cat.category_id = [im_cost_type_quote] then 1
		else -1
	end as sign	
from
	im_categories cat left outer join 
	(
		select	ci.*,
			im_exchange_rate(
				ci.effective_date::date, 
				ci.currency, 
				:default_currency
			) * amount as amount_converted
		from	im_costs ci
		where	
			ci.cost_id in (
				$project_cost_ids_sql
			)
	) ci on (cat.category_id = ci.cost_type_id)
where
	cat.category_id in (
		[im_cost_type_invoice],
		[im_cost_type_quote],
		[im_cost_type_bill],
		[im_cost_type_po],
		[im_cost_type_timesheet],
		[im_cost_type_expense_item],
		[im_cost_type_expense_report],
		[im_cost_type_delivery_note]
	)
	and ci.currency is not null
group by
	ci.currency,
	cat.category_id,
	ci.cost_type_id
order by
	cat.category_id
"

    # ----------------- Initialize variables -------------

    # Initialize the subtotal array
    set cost_type_sql "select category_id from im_categories where category_type='Intranet Cost Type'"
    db_foreach subtotal_init $cost_type_sql {
	set subtotals($category_id) 0
    }

    # ----------------- Calculate Subtotals per cost_type_id -------------

    db_foreach subtotals $subtotals_sql {
	if {"" == $amount_converted} { set amount_converted 0 }
	if {"" == $currency} { set currency $default_currency }
	set subtotals($cost_type_id) $amount_converted
	ns_log Notice "im_costs_project_finance_component: subtotals($cost_type_id) = $amount_converted"
    }


    # ----------------- Compose SQL Query --------------------------------
    # Only get "real" costs (=invoices and bills) and ignore
    # quotes and purchase orders 
 
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
order by
	ci.cost_type_id,
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
<!--    <td align=center class=rowtitle>[_ intranet-cost.Project]</td> -->
    <td align=center class=rowtitle>[_ intranet-cost.Document]</td>
    <td align=center class=rowtitle>[_ intranet-cost.Company]</td>
    <td align=center class=rowtitle>[_ intranet-cost.Due]</td>
    <td align=center class=rowtitle>[_ intranet-cost.Amount]</td>
    <td align=center class=rowtitle>[lang::message::lookup "" intranet-cost.Org_Amount "Org"]</td>
    <td align=center class=rowtitle>[_ intranet-cost.Paid]</td>
  </tr>
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
			  <td colspan=[expr $colspan-3]>&nbsp;</td>
			  <td colspan=2>
			    <b>$subtotals($old_cost_type_id) $default_currency</b>
			  </td>
			</tr>
		    "
		}
		append cost_html "
		<tr>
		  <td colspan=99 class=rowplain>&nbsp;</td>
		</tr>\n"
	    }

	    append cost_html "
		<tr class=rowtitle>
		  <td class=rowplain colspan=99>$cost_type</td>
		</tr>\n"

	    set old_cost_type_id $cost_type_id
	    set old_atleast_one_unreadable_p $atleast_one_unreadable_p
	    set atleast_one_unreadable_p 0
	}

	# Check permissions - query is cached
	set read_p [im_cost_center_read_p $cost_center_id $cost_type_id $user_id]
	if {!$read_p} { set atleast_one_unreadable_p 1 }

	set company_name ""
	if {$cost_type_id == [im_cost_type_invoice] || $cost_type_id == [im_cost_type_quote]} {
	    set company_name $customer_name
	} else {
	    set company_name $provider_name
	}
	
	set cost_url "<A href=\"$url$cost_id&return_url=[ns_urlencode $return_url]\">"
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
	  <td><nobr>$cost_url[string range $cost_name 0 20]</A></nobr></td>
	  <td>$company_name</td>
	  <td>$calculated_due_date</td>
	  <td><nobr>$amount_converted $default_currency_read_p</nobr></td>
	  <td><nobr>$amount_unconverted</td>
	  <td><nobr>$amount_paid</nobr></td>
	</tr>\n"
	incr ctr
    }

    # Write the subtotal line of the last cost_type_id section
    if {$ctr > 1} {
	if {!$atleast_one_unreadable_p} {
	    append cost_html "
		<tr class=rowplain>
		  <td colspan=[expr $colspan-3]>&nbsp;</td>
		  <td colspan=2>
		    <b>$subtotals($old_cost_type_id) $default_currency</b>
		  </td>
		</tr>
            "
	}
	append cost_html "
		<tr>
		  <td colspan=99 class=rowplain>&nbsp;</td>
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
    append cost_html "</table>\n"


    # ----------------- Hard Costs HTML -------------
    # Hard "real" costs such as invoices, bills and timesheet

    # Add numbers to the im_projects table "cache" fields
    if {[db_column_exists im_projects cost_invoices_cache]} {
	
	# We can update the profit&loss because all financial documents
	# for this project are of the same currency.
	db_dml update_projects "
		update im_projects set
			cost_invoices_cache = $subtotals([im_cost_type_invoice]),
			cost_bills_cache = $subtotals([im_cost_type_bill]),
			cost_timesheet_logged_cache = $subtotals([im_cost_type_timesheet]),
			cost_expense_logged_cache = $subtotals([im_cost_type_expense_report]),
			cost_quotes_cache = $subtotals([im_cost_type_quote]),
			cost_purchase_orders_cache = $subtotals([im_cost_type_po]),
			cost_delivery_notes_cache = $subtotals([im_cost_type_delivery_note]),
			cost_timesheet_planned_cache = 0,
			cost_expense_planned_cache = 0
		where
			project_id = :org_project_id
	"
    }

    set hard_cost_html "
<table width=\"100%\">
  <tr class=rowtitle>
    <td class=rowtitle colspan=9 align=center>[_ intranet-cost.Real_Costs]</td>
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
    set subtotal $subtotals([im_cost_type_expense_report])
    append hard_cost_html "<td align=right>- $subtotal $default_currency</td>\n"
    set grand_total [expr $grand_total - $subtotal]

    append hard_cost_html "</tr>\n<tr>\n<td><b>[_ intranet-cost.Grand_Total]</b></td>\n"
    append hard_cost_html "<td align=right><b>$grand_total $default_currency</b></td>\n"
    append hard_cost_html "</tr>\n</table>\n"


    # ----------------- Prelim Costs HTML -------------
    # Preliminary (planned) Costs such as Quotes and Purchase Orders

    set prelim_cost_html "
<table width=\"100%\">
  <tr class=rowtitle>
    <td class=rowtitle colspan=9 align=center>[_ intranet-cost.Preliminary_Costs]</td>
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

    append prelim_cost_html "</tr>\n<tr>\n<td>[_ intranet-cost.Timesheet_Costs]</td>\n"
    
    append prelim_cost_html "<td align=right>
<!--	  $subtotals([im_cost_type_timesheet]) $default_currency -->
	</td>\n"

    append prelim_cost_html "</tr>\n<tr>\n<td>[lang::message::lookup "" intranet-cost.Expenses "Expenses"]</td>\n"
    append prelim_cost_html "<td align=right>
<!--	  $subtotals([im_cost_type_expense_report]) $default_currency -->
	</td>\n"


    append prelim_cost_html "</tr>\n<tr>\n<td><b>[_ intranet-cost.Grand_Total]</b></td>\n"
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

	set currency_outdated_warning [lang::message::lookup "" intranet-costs.The_exchange_rates_are_outdated "The exchanges rates for the following currencies are outdated. <br>Please contact your System Administrator to update the following exchange rates:"]
	append currency_outdated_warning "\n<br>\n"
	append currency_outdated_warning "\n<table>\n"

	foreach entry $exchange_rates_outdated {
	    set currency [lindex $entry 0]
	    set days [lindex $entry 1]
	    set outdated_msg [lang::message::lookup "" intranet-costs.Outdated_since_x_days "Outdated since %days% days"]
	    append currency_outdated_warning "\n<tr><td>$currency:</td><td>$outdated_msg</td></tr>\n"
	}
	append currency_outdated_warning "\n</table>\n"


	set currency_outdated_warning "
		<table>
		<tr class=rowtitle><td class=rowtitle align=center>
		[lang::message::lookup "" intranet-costs.Outdated_Message "Outdated Exhcange Rates Warning"]
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
    if {[db_table_exists im_invoices]} {

	set admin_html "
	<table>
	<tr>
	  <td colspan=$colspan class=rowtitle align=center>
	    [_ intranet-core.Admin_Links]
	  </td>
	</tr>
	<tr class=rowplain>
	  <td colspan=$colspan>\n"

	    # Customer invoices: customer = Project Customer, provider = Internal
	    set customer_id [db_string project_customer "select company_id from im_projects where project_id = :org_project_id" -default ""]
	    set provider_id [im_company_internal]
	    set bind_vars [ad_tcl_vars_to_ns_set customer_id provider_id project_id]
      	    append admin_html [im_menu_ul_list "invoices_customers" $bind_vars]

	    # Provider invoices: customer = Internal, no provider yet defined
	    set customer_id [im_company_internal]
	    set bind_vars [ad_tcl_vars_to_ns_set customer_id project_id]
	    append admin_html [im_menu_ul_list "invoices_providers" $bind_vars]

	    append admin_html "	
	  </td>
	</tr>
	</table>
	"
    }

    set result_html ""

    if {$show_details_p} {
	set result_html "
        $currency_outdated_warning
	<table>
	<tr valign=top>
	  <td>
	    $cost_html
	  </td>
	  <td>
	    $admin_html
	  </td>
	</tr>
	</table>\n"

    }

    if {$show_details_p && $show_summary_p} {
	# Summary in broad format
	append result_html "
	<br>
	<table cellspacing=0 cellpadding=0>
	<tr><td class=rowtitle colspan=3 align=center>[_ intranet-cost.Financial_Summary]</td></tr>
	<tr valign=top>
	  <td>
	    $hard_cost_html
	  </td>
	  <td>&nbsp &nbsp;</td>
	  <td>
	    $prelim_cost_html
	  </td>
	</tr>
	</table>
	"
    }

    if {!$show_details_p && $show_summary_p} {
	# Summary in narrow format
	append result_html "
	<br>
	<table cellspacing=0 cellpadding=0 width=\"70%\" >
	<tr>
	  <td class=rowtitle align=center>[_ intranet-cost.Financial_Summary]</td>
	</tr>
	<tr valign=top>
	  <td>
	    $hard_cost_html
	  </td>
	</tr>
	<tr>
	  <td>
	    $prelim_cost_html
	  </td>
	</tr>
	</table>
	"
    }
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
	where	c.category_type = :category_type"

    # Restrict to specific subtypes of FinDocs
    switch [string tolower $cost_item_group] {
	"financial_doc" {
	    append sql "\n\t\tand c.category_id in (
		[im_cost_type_invoice],
		[im_cost_type_quote],
		[im_cost_type_bill],
		[im_cost_type_po],
		[im_cost_type_delivery_note]
		)"
	}
    }

    if {$super_type_id} {
	ns_set put $bind_vars super_type_id $super_type_id
	append sql "\n	and c.category_id in (
		select distinct
			child_id
		from	im_category_hierarchy
		where	parent_id = :super_type_id
	)"
    }
    return [im_selection_to_select_box $bind_vars category_select $sql $select_name $default]
}



ad_proc -public im_cost_status_select { {-translate_p 1}  select_name { default "" } } {
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
	    set text [_ intranet-core.[lang::util::suggest_key [lindex $option 0]]]
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

ad_proc im_cost_template_select { select_name { default "" } } {
    Returns an html select box named $select_name and defaulted to $default 
    with a list of all the partner statuses in the system
} {
    return [im_category_select_plain -translate_p 0 "Intranet Cost Template" $select_name $default]
}



ad_proc im_costs_select { select_name { default "" } { status "" } { exclude_status "" } } {
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
}






