# /packages/intranet-timesheet2-invoices/tcl/intranet-timesheet2-invoices-procs.tcl

ad_library {
    Bring together all "components" (=HTML + SQL code)
    related to Timesheet Invoices

    @author frank.bergmann@project-open.com
    @author koen.vanwinckel@dotprojects.be
    @creation-date  May 2005
}


# ------------------------------------------------------
# Price List
# ------------------------------------------------------

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
	and p.company_id=c.company_id(+)
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

ad_proc im_timesheet_invoicing_project_hierarchy { 
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
	<td align=center class=rowtitle>[lang::message::lookup "" intranet-timesheet2-invoices.Material "Material"]</td>
	<td align=center class=rowtitle>[lang::message::lookup "" intranet-timesheet2-invoices.Planned_br_Units "Planned<br>Units"]</td>
	<td align=center class=rowtitle>[lang::message::lookup "" intranet-timesheet2-invoices.Billable_br_Units "Billable<br>Units"]</td>
	<td align=center class=rowtitle>[lang::message::lookup "" intranet-timesheet2-invoices.All_br_Reported_br_Units "All<br>Reported<br>Units"]</td>
	<td align=center class=rowtitle>[lang::message::lookup "" intranet-timesheet2-invoices.Reported_br_Units_in_br_Interval "Reported<br>Units in<br>Interval"]</td>
	<td align=center class=rowtitle>[lang::message::lookup "" intranet-timesheet2-invoices.All_Unbilled_Units "All<br>Unbilled<br>Units"]</td>
	<td align=center class=rowtitle>[lang::message::lookup ""  intranet-timesheet2-invoices.UoM "UoM"]<br>[im_gif help "Unit of Measure"]</td>
<!--	<td align=center class=rowtitle>[lang::message::lookup "" intranet-timesheet2-invoices.Type Type]</td> -->
	<td align=center class=rowtitle>[lang::message::lookup "" intranet-timesheet2-invoices.Status Status]</td>
    </tr>
    "


    set planned_checked ""
    set billable_checked ""
    set reported_checked ""
    set interval_checked ""
    set new_checked ""
    set unbilled_checked ""
    switch $invoice_hour_type {
	planned { set planned_checked " checked" }
	billable { set billable_checked " checked" }
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
	  <td align=center><input type=radio name=invoice_hour_type value=planned $invoice_radio_disabled $planned_checked></td>
	  <td align=center><input type=radio name=invoice_hour_type value=billable $invoice_radio_disabled $billable_checked></td>
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


#    ad_return_complaint 1 "<pre>$sql</pre>"

    set ctr 0
    set colspan 11
    set old_parent_id 0
    db_foreach select_tasks $sql {
	
	if {"" == $material_name} { set material_name $default_material_name }
	
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
	if {"" == $uom_id} { set uom_id [im_uom_hour] }
	switch $uom_id {
	    321 {
		# Day
		set all_reported_units $all_reported_days
		set units_in_interval $days_in_interval
		set unbilled_units $unbilled_days
	    }
	    320 {
		# Hour
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
	  <td align=left>$material_name</td>
	  <td align=right>$planned_units</td>
	  <td align=right>$billable_units</td>
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