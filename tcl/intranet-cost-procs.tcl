# /packages/intranet-invoicing/tcl/intranet-cost-procs.tcl
#
# Copyright (C) 2003-2004 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    Bring together all "components" (=HTML + SQL code)
    related to Cost Items

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
ad_proc -public im_cost_type_cost {} { return 700 }
ad_proc -public im_cost_type_quote {} { return 702 }
ad_proc -public im_cost_type_bill {} { return 704 }
ad_proc -public im_cost_type_po {} { return 706 }
ad_proc -public im_cost_type_customer_doc {} { return 708 }
ad_proc -public im_cost_type_provider_doc {} { return 710 }


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




# ---------------------------------------------------------------
# Options for Form elements
# ---------------------------------------------------------------

ad_proc -public im_project_options { {include_empty 1} } { 
    Cost project options
} {
    set options [db_list_of_lists project_options "
	select project_name, project_id
	from im_projects
    "]
    if {$include_empty} { set options [linsert $options 0 { "" "" }] }
    return $options
}

ad_proc -public im_customer_options { {include_empty 1} } { 
    Cost customer options
} {
    set options [db_list_of_lists customer_options "
	select customer_name, customer_id
	from im_customers
    "]
    if {$include_empty} { set options [linsert $options 0 { "" "" }] }
    return $options
}

ad_proc -public im_provider_options { {include_empty 1} } { 
    Cost provider options
} {
    set options [db_list_of_lists provider_options "
	select customer_name, customer_id
	from im_customers
    "]
    if {$include_empty} { set options [linsert $options 0 { "" "" }] }
    return $options
}

ad_proc -public im_cost_type_options { {include_empty 1} } { 
    Cost type options
} {
   set options [db_list_of_lists cost_type_options "
	select cost_type, cost_type_id
	from im_cost_type
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
	where category_type = 'Intranet Invoice Template'
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
    "]
    if {$include_empty} { set options [linsert $options 0 { "" "" }] }
    return $options
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

ad_proc im_costs_customer_component { user_id customer_id } {
    Returns a HTML table containing a list of costs for a particular
    customer.
} {
    return [im_costs_base_component $user_id $customer_id ""]
}

ad_proc im_costs_project_component { user_id project_id } {
    Returns a HTML table containing a list of costs for a particular
    particular project.
} {
    return [im_costs_base_component $user_id "" $project_id]
}


ad_proc im_costs_base_component { user_id {customer_id ""} {project_id ""} } {
    Returns a HTML table containing a list of costs for a particular
    customer or a particular project.
} {
    if {![im_permission $user_id view_costs]} {
	return ""
    }

    set bgcolor(0) " class=roweven "
    set bgcolor(1) " class=rowodd "
    set max_costs 5
    set colspan 5

    # ----------------- Compose SQL Query --------------------------------
  
    set where_conds [list]
    if {"" != $customer_id} { lappend where_conds "i.customer_id=:customer_id" }
    if {"" != $project_id} { 
	# Select the cost_id's of cost_items and
	# costs explicitely associated with a project.
	lappend where_conds "
	i.cost_id in (
		select distinct cost_id 
		from im_cost_items 
		where project_id=:project_id
	    UNION
		select distinct object_id_two as cost_id
		from acs_rels
		where object_id_one = :project_id
	)" 
    }
    set where_clause [join $where_conds "\n	and "]
    if {"" == $where_clause} { set where_clause "1=1" }

    set costs_sql "
select
	i.*,
	ii.cost_amount,
	ii.cost_currency,
	pa.payment_amount,
	pa.payment_currency,
        im_category_from_id(i.cost_status_id) as cost_status,
        im_category_from_id(i.cost_type_id) as cost_type,
	i.cost_date + payment_days as calculated_due_date
from
	im_costs i,
        (select
                cost_id,
                sum(item_units * price_per_unit) as cost_amount,
		max(currency) as cost_currency
         from im_cost_items
         group by cost_id
        ) ii,
	(select
		sum(amount) as payment_amount, 
		max(currency) as payment_currency,
		cost_id 
	 from im_payments
	 group by cost_id
	) pa
where
	$where_clause
	and i.cost_status_id not in ([im_cost_status_in_process])
        and i.cost_id=ii.cost_id(+)
	and i.cost_id=pa.cost_id(+)
order by
	cost_nr desc
"

    set cost_html "
<table border=0>
  <tr>
    <td colspan=$colspan class=rowtitle align=center>
      Financial Documents
    </td>
  </tr>
  <tr class=rowtitle>
    <td align=center class=rowtitle>Document</td>
    <td align=center class=rowtitle>Type</td>
    <td align=center class=rowtitle>Due</td>
    <td align=center class=rowtitle>Amount</td>
    <td align=center class=rowtitle>Paid</td>
  </tr>
"
    set ctr 1
    db_foreach recent_costs $costs_sql {
	append cost_html "
<tr$bgcolor([expr $ctr % 2])>
  <td><A href=/intranet-costs/view?cost_id=$cost_id>$cost_nr</A></td>
  <td>$cost_type</td>
  <td>$calculated_due_date</td>
  <td>$cost_amount $cost_currency</td>
  <td>$payment_amount $payment_currency</td>
</tr>\n"
	incr ctr
	if {$ctr > $max_costs} { break }
    }


    if {$ctr > $max_costs} {
	append cost_html "
<tr$bgcolor([expr $ctr % 2])>
  <td colspan=$colspan>
    <A HREF=/intranet-costs/index?status_id=0&[export_url_vars status_id customer_id project_id]>
      more costs...
    </A>
  </td>
</tr>\n"
    }

    if {$ctr == 1} {
	append cost_html "
<tr$bgcolor([expr $ctr % 2])>
  <td colspan=$colspan align=center>
    <I>No financial documents yet for this project</I>
  </td>
</tr>\n"
	incr ctr
    }

    if {"" != $customer_id && "" == $project_id} {
	append cost_html "
<tr>
  <td colspan=$colspan align=left>
<!--    <A href=/intranet-costs/new?customer_id=$customer_id>
      Create a new cost for this customer
    </A>
-->
  </td>
</tr>\n"
    }

    if {"" != $project_id} {
	append cost_html "
<tr>
  <td colspan=$colspan align=left>
    <A href=/intranet-costs/index?project_id=$project_id>
      Create a new document for this project
    </A>
  </td>
</tr>\n"
    }

    if {"" != $customer_id} {
    append cost_html "
<tr>
  <td colspan=$colspan align=right>
    <A href=/intranet-costs/index?customer_id=$customer_id>
      Create a new document for this customer
    </A>
  </td>
</tr>\n"
    }

    append cost_html "</table>\n"
    return $cost_html
}


ad_proc -public im_cost_type_select { select_name { default "" } } {
    Returns an html select box named $select_name and defaulted to
    $default with a list of all the cost_types in the system
} {
    return [im_category_select "Intranet Cost Type" $select_name $default]
}


ad_proc -public im_cost_status_select { select_name { default "" } } {
    Returns an html select box named $select_name and defaulted to
    $default with a list of all the cost status_types in the system
} {
    return [im_category_select "Intranet Cost Status" $select_name $default]
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
    return [im_category_select "Intranet Cost Template" $select_name $default]
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
	i.cost_nr
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
    append sql " order by lower(cost_nr)"
    return [im_selection_to_select_box $bind_vars "cost_status_select" $sql $select_name $default]
}



