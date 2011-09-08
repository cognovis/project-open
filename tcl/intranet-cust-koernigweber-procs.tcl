# /packages/intranet-cust-koernigweber/tcl/intranet-cust-koernigweber-procs.tcl
#
# Copyright (C) 1998-2011 


ad_library {
    
    Customizations implementation KoernigWeber 
    @author klaus.hofeditz@project-open.com
}

# ---------------------------------------------------------------------
# Show the members of the Admin Group of the current Business Object.
# ---------------------------------------------------------------------

ad_proc -public im_group_member_component_employee_customer_price_list { 
    {-debug 0}
    object_id 
    current_user_id 
    { add_admin_links 0 } 
    { return_url "" } 
    { limit_to_users_in_group_id "" } 
    { dont_allow_users_in_group_id "" } 
    { also_add_to_group_id "" } 
} {
    Returns an portlet to view and manage companies price matrix 
} {
    # Check if there is a percentage column from intranet-ganttproject
    set show_percentage_p [im_column_exists im_biz_object_members percentage]
    set object_type [util_memoize "db_string otype \"select object_type from acs_objects where object_id=$object_id\" -default \"\""]
    if {$object_type != "im_project" & $object_type != "im_timesheet_task"} { set show_percentage_p 0 }

    # ------------------ limit_to_users_in_group_id ---------------------
    if { [empty_string_p $limit_to_users_in_group_id] } {
	set limit_to_group_id_sql ""
    } else {
	set limit_to_group_id_sql "
	and exists (select 1 
		from 
			group_member_map map2,
		        membership_rels mr,
			groups ug
		where 
			map2.group_id = ug.group_id
			and map2.rel_id = mr.rel_id
			and mr.member_state = 'approved'
			and map2.member_id = u.user_id 
			and map2.group_id = :limit_to_users_in_group_id
		)
	"
    } 

    # ------------------ dont_allow_users_in_group_id ---------------------
    if { [empty_string_p $dont_allow_users_in_group_id] } {
	set dont_allow_sql ""
    } else {
	set dont_allow_sql "
	and not exists (
		select 1 
		from 
			group_member_map map2, 
			membership_rels mr,
			groups ug
		where 
			map2.group_id = ug.group_id
			and map2.rel_id = mr.rel_id
			and mr.member_state = 'approved'
			and map2.member_id = u.user_id 
			and map2.group_id = :dont_allow_users_in_group_id
		)
	"
    } 

    set bo_rels_percentage_sql ""
    if {$show_percentage_p} {
	set bo_rels_percentage_sql ",round(bo_rels.percentage) as percentage"
    }

    # ------------------ Main SQL ----------------------------------------
    # fraber: Abolished the "distinct" because the role assignment page 
    # now takes care that a user is assigned only once to a group.
    # We neeed this if we want to show the role of the user.
    #

    set sql_query "
        select
                u.user_id,
                u.user_id as party_id,
                im_email_from_user_id(u.user_id) as email,
                im_name_from_user_id(u.user_id) as name,
                im_category_from_id(c.category_id) as member_role,
                c.category_gif as role_gif,
                c.category_description as role_description,
                (select amount from im_emp_cust_price_list where company_id=object_id_one and user_id = u.user_id) as amount
                $bo_rels_percentage_sql
        from
                users u,
                acs_rels rels
                LEFT OUTER JOIN im_biz_object_members bo_rels ON (rels.rel_id = bo_rels.rel_id)
                LEFT OUTER JOIN im_categories c ON (c.category_id = bo_rels.object_role_id),
                group_member_map m,
                membership_rels mr
        where
                rels.object_id_one = $object_id
                and rels.object_id_two = u.user_id
                and mr.member_state = 'approved'
                and u.user_id = m.member_id
                and mr.member_state = 'approved'
                and m.group_id = acs__magic_object_id('registered_users'::character varying)
                and m.rel_id = mr.rel_id
                and m.container_id = m.group_id
                and m.rel_type = 'membership_rel'
                $limit_to_group_id_sql
                $dont_allow_sql
        order by lower(im_name_from_user_id(u.user_id))
    "


  	  set sql_query "
		select 
			r.object_id_two as user_id,
			im_name_from_user_id(r.object_id_two) as name,
		 	(select amount from im_emp_cust_price_list where company_id=object_id_one and user_id = u.user_id) as amount
		from 
		    acs_rels r 
		where 
		    object_id_one = :object_id
		    and rel_type = 'im_biz_object_member';
	"

  set sql_query "
	select distinct
		r.object_id_two as user_id,
		im_name_from_user_id(r.object_id_two) as name,
                (select amount from im_emp_cust_price_list where company_id=:object_id and user_id = r.object_id_two) as amount
	from 
		acs_rels r 
	where 
		object_id_one in 
	
	(select 
		project_id 
	from 
		im_projects 
	where 
		company_id = :object_id
	)
		and rel_type = 'im_biz_object_member'
	"
    # ------------------ Format the table header ------------------------
    set colspan 2
    set header_html "
      <tr> 
	<td class=rowtitle align=middle>[_ intranet-core.Name]</td>
	<td class=rowtitle align=middle>[lang::message::lookup "" intranet-core.Price "Price"]</td>
    "
    if {$show_percentage_p} {
        incr colspan
        append header_html "<td class=rowtitle align=middle>[_ intranet-core.Perc]</td>"
    }
    if {$add_admin_links} {
        incr colspan
        append header_html "<td class=rowtitle align=middle>[im_gif delete]</td>"
    }
    append header_html "
      </tr>"

    # ------------------ Format the table body ----------------
    set td_class(0) "class=roweven"
    set td_class(1) "class=rowodd"
    set found 0
    set count 0
    set body_html ""

    set currency [ad_parameter -package_id [im_package_cost_id] "DefaultCurrency" "" "EUR"]
  
    db_foreach users_in_group $sql_query {

	set show_user [im_show_user_style $user_id $current_user_id $object_id]
	if {$debug} { ns_log Notice "im_group_member_component: user_id=$user_id, show_user=$show_user" }
	if {$show_user == 0} { continue }

	append body_html "
		<tr $td_class([expr $count % 2])>
		  <input type=hidden name=member_id value=$user_id>
  		<td>"
	if {$show_user > 0} {
		append body_html "<A HREF=/intranet/users/view?user_id=$user_id>$name</A>"
	} else {
		append body_html $name
	}
	
	append body_html "</td>"

        if { [im_permission $current_user_id "admin_company_price_matrix"]} {
            append body_html "
                  <td align=middle>
                    <input type=input size=6 maxlength=6 name=\"amount.$user_id\" value=\"$amount\">[im_currency_select currency.$user_id $currency]
                  </td>
            "
	} else {
	    if { ""==$amount } {set amount "-"}
            append body_html "
                  <td align=middle>
                    $amount $currency
                  </td>
            "
        }

	append body_html "</td>"

	if {$add_admin_links} {
	    append body_html "
		  <td align=middle>
		    <input type=checkbox name=delete_user value=$user_id>
		  </td>
	    "
	}
	append body_html "</tr>"
    }

    if { [empty_string_p $body_html] } {
	set body_html "<tr><td colspan=$colspan><i>[_ intranet-core.none]</i></td></tr>\n"
    }

    # ------------------ Format the table footer with buttons ------------
    set footer_html ""
	append footer_html "
	    <tr>
	      <td align=right colspan=$colspan>
		<input type=submit value='[lang::message::lookup "" intranet-core.Save "Save"]' name=submit_apply></td>
	      </td>
	    </tr>
	    "
    # ------------------ Join table header, body and footer ----------------
    set html "
	<form method=POST action=/intranet-cust-koernigweber/set-emp-cust-price>
	[export_form_vars object_id return_url]
	    <table bgcolor=white cellpadding=1 cellspacing=1 border=0>
	      $header_html
	      $body_html
	      $footer_html
	    </table>
	</form>
    "
    return $html
}



ad_proc -public im_koernigweber_next_project_nr {
    {-customer_id 0 }
    {-nr_digits {}}
    {-date_format {}}
} {
    Returns "" if there was an error calculating the number.
    koernigweber project_nr look like: cccc-xx-xxxx with the first 4 digits being
    the customer, four digits indicating the year the project starts and a 4 digit 
    consecutive number 
} {

   # set customer_id 54735

    set date_format "YY"
    ns_log Notice "im_koernig_weber_next_project_nr: customer_id=$customer_id, nr_digits=$nr_digits, date_format=$date_format"

    if {"none" == $date_format} { set date_format "" }

    set koernigweber_customer_code ""

    catch {
            db_1row koernigweber_cust_code "
                select  company_code,
			company_name
                from    im_companies
                where   company_id = :customer_id
            "
    } errmsg
    ns_log Notice "im_koernigweber_next_project_nr: koernigweber_customer_code=$koernigweber_customer_code"

    if {[string length $company_code] != 4} {
        ad_return_complaint 1 "<b>Unable to find 'Customer Code'</b>:
        <p>
        The customer <a href=/intranet/companies/view?company_id=$customer_id>$company_name</a>
        does not have a valid 4 digit 'Customer Code' field. <br>
        Please follow the link and setup a customer code with four digits.<br>
        Please contact your System Adninistrator in case of doubt.
        </p>
        <pre>$errmsg</pre>
        "
        ad_script_abort
    }

    # ----------------------------------------------------
    # Calculate the next project nr by finding out the last
    # one +1

    set sql "
                select  project_nr as last_project_nr
                from    im_projects
                where   project_nr like '$company_code%' and 
			company_id = :customer_id
		order by project_nr ASC
		limit 1
    "

    if { 0==[db_0or1row max_project_nr $sql] } {
	set last_project_nr 1
    } else {
	set last_project_nr_length [string length $last_project_nr]
	set last_project_nr [string range $last_project_nr [expr $last_project_nr_length-4] $last_project_nr_length]
	set last_project_nr [expr $last_project_nr + 1]
    }

    # fill up with zeros 
    set zeros ""
    for {set i 0} {$i < [expr 4-[string length $last_project_nr]]} {incr i} {
		append zeros "0"
    }
    set last_project_nr [append zeros $last_project_nr]        

    # code + year code
    set year [db_string today "select to_char(now(), :date_format)"]

    # put everything together
    set project_number ""
    return [append project_number $company_code "_" $year "_" $last_project_nr]
}

	    

ad_proc im_timesheet_price_component { user_id company_id return_url} {
    Returns a formatted HTML table representing the 
    prices for the current company
} {

    if {![im_permission $user_id view_costs]} {
        return ""
    }

    set bgcolor(0) " class=roweven "
    set bgcolor(1) " class=rowodd "
#    set price_format "000.00"
    set price_format "%0.2f"

    set colspan 7
    set price_list_html "
<form action=/intranet-timesheet2-invoices/price-lists/price-action method=POST>
[export_form_vars company_id return_url]
<table border=0>
<tr><td colspan=$colspan class=rowtitle align=center>[_ intranet-timesheet2-invoices.Price_List]</td></tr>
<tr class=rowtitle> 
	  <td class=rowtitle>[_ intranet-timesheet2-invoices.UoM]</td>
	  <td class=rowtitle>[_ intranet-timesheet2-invoices.Task_Type]</td>
	  <td class=rowtitle>[_ intranet-timesheet2-invoices.Material]</td>
	  <td class=rowtitle>[_ intranet-timesheet2-invoices.Rate]</td>
	  <td class=rowtitle>[im_gif del "Delete"]</td>
</tr>"

    set price_sql "
select
	p.*,
	c.company_path as company_short_name,
	im_category_from_id(uom_id) as uom,
	im_category_from_id(task_type_id) as task_type,
	im_material_nr_id(material_id) as material
from
	im_timesheet_prices p,
	im_companies c
where 
	p.company_id=:company_id
	and p.company_id=c.company_id
order by
	currency,
	uom_id,
	task_type_id desc
"

    set price_rows_html ""
    set ctr 1
    set old_currency ""
    db_foreach prices $price_sql {

	if {"" != $old_currency && ![string equal $old_currency $currency]} {
	    append price_rows_html "<tr><td colspan=$colspan>&nbsp;</td></tr>\n"
	}

	append price_rows_html "
        <tr $bgcolor([expr $ctr % 2]) nobreak>
	  <td>$uom</td>
	  <td>$task_type</td>
	  <td>$material</td>
          <td>[format $price_format $price] $currency</td>
          <td><input type=checkbox name=price_id.$price_id></td>
	</tr>"
	incr ctr
	set old_currency $currency
    }

    if {$price_rows_html != ""} {
	append price_list_html $price_rows_html
    } else {
	append price_list_html "<tr><td colspan=$colspan align=center><i>[_ intranet-timesheet2-invoices.No_prices_found]</i></td></tr>\n"
    }

    set sample_pracelist_link "<a href=/intranet-timesheet2-invoices/price-lists/pricelist_sample.csv>[_ intranet-timesheet2-invoices.lt_sample_pricelist_CSV_]</A>"

    append price_list_html "
<tr>
  <td colspan=$colspan align=right>
    <input type=submit name=add_new value=\"[_ intranet-timesheet2-invoices.Add_New]\">
    <input type=submit name=del value=\"[_ intranet-timesheet2-invoices.Del]\">
  </td>
</tr>
</table>
</form>
<ul>
  <li>
    <a href=/intranet-timesheet2-invoices/price-lists/upload-prices?[export_url_vars company_id return_url]>
      [_ intranet-timesheet2-invoices.Upload_prices]</A>
    [_ intranet-timesheet2-invoices.lt_for_this_company_via_]
  <li>
    [_ intranet-timesheet2-invoices.lt_Check_this_sample_pra]
    [_ intranet-timesheet2-invoices.lt_It_contains_some_comm]
</ul>\n"
    return $price_list_html
}



# ------------------------------------------------------
# The list of hours per project
# ------------------------------------------------------

ad_proc im_timesheet_invoicing_project_hierarchy_kw { 
    { -include_task "" }
    -select_project:required
    -start_date:required
    -end_date:required
    -invoice_hour_type:required
} {
    Returns a formatted HTML table representing the list of subprojects
    and their logged hours.
} {
    set bgcolor(0) " class=roweven"
    set bgcolor(1) " class=rowodd"

    set default_material_id [im_material_default_material_id]
    set default_material_name [db_string matname "select acs_object__name(:default_material_id)"]

    set task_table_rows "
    <tr> 
	<td class=rowtitle align=middle>[im_gif help "Include in Invoice"]</td>
	<td align=center class=rowtitle>[lang::message::lookup "" intranet-timesheet2-invoices.Task_Name "Task Name"]</td>
	<td align=center class=rowtitle>[lang::message::lookup "" intranet-timesheet2-invoices.All_br_Reported_br_Units "All<br>Reported<br>Units"]</td>
	<td align=center class=rowtitle>[lang::message::lookup "" intranet-timesheet2-invoices.Reported_br_Units_in_br_Interval "Reported<br>Units in<br>Interval"]</td>
	<td align=center class=rowtitle>[lang::message::lookup "" intranet-timesheet2-invoices.All_Unbilled_Units "All<br>Unbilled<br>Units"]</td>
	<td align=center class=rowtitle>[lang::message::lookup ""  intranet-timesheet2-invoices.UoM "UoM"]<br>[im_gif help "Unit of Measure"]</td>
	<td align=center class=rowtitle>[lang::message::lookup "" intranet-timesheet2-invoices.Status Status]</td>
    </tr>
   "

    set reported_checked ""
    set interval_checked ""
    set new_checked ""
    set unbilled_checked ""
    switch $invoice_hour_type {
	reported { set reported_checked " checked" }
	interval { set interval_checked " checked" }
	new { set new_checked " checked" }
	unbilled { set unbilled_checked " checked" }
    }


    set invoice_radio_disabled ""
    if {"" != $invoice_hour_type} {
        set invoice_radio_disabled "disabled"
    } else {
        set planned_checked " checked"
    }

    # Show a line with with the selected invoicing type
    append task_table_rows "
	<tr>
	  <td colspan=3>Please select the type of hours to use:</td>
	  <td align=center><input type=radio name=invoice_hour_type value=reported $invoice_radio_disabled $reported_checked></td>
	  <td align=center><input type=radio name=invoice_hour_type value=interval $invoice_radio_disabled $interval_checked></td>
	  <td align=center><input type=radio name=invoice_hour_type value=unbilled $invoice_radio_disabled $unbilled_checked></td>
	  <td></td>
	  <td></td>
	</tr>
    "

    set sql "
  	select
                parent.project_id as parent_id,
                parent.project_nr as parent_nr,
                parent.project_name as parent_name,
                children.project_id,
                children.project_name,
                children.project_nr,
                im_category_from_id(children.project_status_id) as project_status,
                im_category_from_id(children.project_type_id) as project_type,
                tree_level(children.tree_sortkey) - tree_level(parent.tree_sortkey) as level,
                t.task_id,
                t.planned_units,
                t.billable_units,
                t.uom_id,
                m.material_name,
                m.material_billable_p,
                im_category_from_id(t.uom_id) as uom_name,
                (select sum(h.hours) from im_hours h where h.project_id = children.project_id) as all_reported_hours,
                (select sum(h.days) from im_hours h where h.project_id = children.project_id) as all_reported_days,
                (select sum(h.hours) from im_hours h where
                        h.project_id = children.project_id
                        and h.day >= to_timestamp(:start_date, 'YYYY-MM-DD')
                        and h.day < to_timestamp(:end_date, 'YYYY-MM-DD')
                ) as hours_in_interval,
                (select sum(h.days) from im_hours h where
                        h.project_id = children.project_id
                        and h.day >= to_timestamp(:start_date, 'YYYY-MM-DD')
                        and h.day < to_timestamp(:end_date, 'YYYY-MM-DD')
                ) as days_in_interval,
                (select sum(h.hours) from im_hours h where
                        h.project_id = children.project_id
                        and h.invoice_id is null
                ) as unbilled_hours,
                (select sum(h.days) from im_hours h where
                        h.project_id = children.project_id
                        and h.invoice_id is null
                ) as unbilled_days
	from
		im_projects parent,
		im_projects children
		LEFT OUTER JOIN im_timesheet_tasks t ON (children.project_id = t.task_id)
		LEFT OUTER JOIN im_materials m ON (t.material_id = m.material_id)
	where
		children.tree_sortkey between parent.tree_sortkey and tree_right(parent.tree_sortkey)
		and parent.project_id in ([join $select_project ","])
	order by 
		parent.project_name, 
		children.tree_sortkey
    "

    set ctr 0
    set colspan 11
    set old_parent_id 0
    db_foreach select_tasks $sql {
	
	set material_name $default_material_name 
	
	# insert intermediate headers for every project
	if {$old_parent_id != $parent_id} {
	    append task_table_rows "
		<tr><td colspan=$colspan>&nbsp;</td></tr>
		<tr>
		  <td class=rowtitle colspan=$colspan>
		    $parent_nr: $parent_name
		  </td>
		</tr>\n"
	    set old_parent_id $parent_id
	}
	
	set indent ""
	for {set i 0} {$i < $level} {incr i} { 
	    append indent "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;" 
	}
	
	set task_checked ""
	set task_disabled ""	
	if {0 == [llength $include_task]} {
	    
	    # Called from the Wizard Page - Enabled tasks
	    # according to the task's material.
	    if {"f" != $material_billable_p} {
	        set task_checked "checked"
	    }
		
	} else {

	    # View from the Invoice page
	    # disable the checkbox (because it is not editable anymore).
	    if {[lsearch $include_task $project_id] > -1} {
		set task_checked "checked"
	    }
	    set task_disabled "disabled"
	}

	switch $uom_id {
	    321 {
		set all_reported_units $all_reported_days
		set units_in_interval $days_in_interval
		set unbilled_units $unbilled_days
	    }
	    320 {
		set all_reported_units $all_reported_hours
		set units_in_interval $hours_in_interval
		set unbilled_units $unbilled_hours
	    }
	    default {
		set all_reported_units "-"
		set units_in_interval "-"
		set unbilled_units "-"
	    }
	}

	append task_table_rows "
	<tr $bgcolor([expr $ctr % 2])> 
	  <td align=middle><input type=checkbox name=include_task value=$project_id $task_disabled $task_checked></td>
	  <td align=left><nobr>$indent <A href=/intranet/projects/view?project_id=$project_id>$project_name</a></nobr></td>
	  <td align=right>$all_reported_units</td>
	  <td align=right>$units_in_interval</td>
	  <td align=right>$unbilled_units</td>
	  <td align=right>$uom_name</td>
	  <td>$project_status</td>
	</tr>
	"
	incr ctr
    }

    if {[string equal "" $task_table_rows]} {
	set task_table_rows "<tr><td colspan=$colspan align=center>[lang::message::lookup "" intranet-timesheet2-invoices.No_tasks_found "No tasks found"]</td></tr>"
    }

    return $task_table_rows
}

proc filter_conncontext { conn arg why } {

    set filter_active_p [parameter::get -package_id [apm_package_id_from_key intranet-cust-koernigweber] -parameter "HTTPSFilter" -default 1]
    if { !$filter_active_p } { return filter_ok }
    
    set headers_string ""
    for { set i 0 } { $i < [ns_set size [ns_conn headers]] } { incr i } {
	append headers_string "[ns_set key [ns_conn headers] $i]: [ns_set value [ns_conn headers] $i]"
    }

    set white_listed_base_urls "
        /intranet/js
        /intranet/images
        /intranet/style
        /resources/acs-subsite
        /resources/diagram
        /resources/acs-templating
        /calendar/resources
        /resources/acs-developer-support
        /images
    "
    set white_listed_urls "
        /intranet-timesheet2/hours/index
        /intranet-timesheet2/hours/new
        /intranet-timesheet2/hours/new-2
        /http-block.html
        /register/logout
        /register/recover-password
        /images/logo.kw.gif
        /lock.jpg
    "
    # Is this a HTTP request?
    set http_p [ns_set iget [ns_conn headers] "HTTP"]
    if { [string equal "1" $http_p] } {
        regexp {(/.*)?(/.*)} [ns_conn url] match link
        if { [string first [string tolower [ns_conn url]] $white_listed_urls] != -1 || [string first $link $white_listed_base_urls] != -1 } {
            return filter_ok
        } else {
	    if { "/intranet/"== [ns_conn url]} {
                 ad_returnredirect "/intranet-timesheet2/hours/index"
	    } else {
                    ad_returnredirect "/http-block.html"
	    }
        }
    }
    return filter_ok
}



















