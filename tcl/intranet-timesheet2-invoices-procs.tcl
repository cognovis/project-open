# /packages/intranet-timesheet2-invoices/tcl/intranet-timesheet2-invoices-procs.tcl

ad_library {
    Bring together all "components" (=HTML + SQL code)
    related to Timesheet Invoices

    @author frank.bergmann@project-open.com
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
    <a href=/intranet-timesheet2-invoices/upload-prices?[export_url_vars company_id return_url]>
      [_ intranet-timesheet2-invoices.Upload_prices]</A>
    [_ intranet-timesheet2-invoices.lt_for_this_company_via_]
  <li>
    [_ intranet-timesheet2-invoices.lt_Check_this_sample_pra]
    [_ intranet-timesheet2-invoices.lt_It_contains_some_comm]
</ul>\n"
    return $price_list_html
}

