# /packages/intranet-trans-invoices/tcl/intranet-trans-invoices-procs.tcl

ad_library {
    Bring together all "components" (=HTML + SQL code)
    related to Invoices

    @author fraber@fraber.de
    @creation-date  27 June 2003
}


# ------------------------------------------------------
# Price List
# ------------------------------------------------------

ad_proc im_trans_price_component { user_id company_id return_url} {
    Returns a formatted HTML table representing the 
    prices for the current company
} {

    if {![im_permission $user_id view_costs]} {
        return ""
    }

    set bgcolor(0) " class=roweven "
    set bgcolor(1) " class=rowodd "
    set price_format "000.000"
    set price_url_base "/intranet-trans-invoices/price-lists/new"

    set colspan 8
    set price_list_html "
<form action=/intranet-trans-invoices/price-lists/price-action method=POST>
[export_form_vars company_id return_url]
<table border=0>
<tr><td colspan=$colspan class=rowtitle align=center>[_ intranet-trans-invoices.Price_List]</td></tr>
<tr class=rowtitle> 
	  <td class=rowtitle>[_ intranet-trans-invoices.UoM]</td>
	  <td class=rowtitle>[_ intranet-trans-invoices.Task_Type]</td>
	  <td class=rowtitle>[_ intranet-trans-invoices.Source]</td>
	  <td class=rowtitle>[_ intranet-trans-invoices.Target]</td>
	  <td class=rowtitle>[_ intranet-trans-invoices.Subject]</td>
	  <td class=rowtitle>[_ intranet-trans-invoices.Rate]</td>
	  <td class=rowtitle>[_ intranet-core.Note]</td>
	  <td class=rowtitle>[im_gif del "Delete"]</td>
</tr>"

    set price_sql "
select
	p.*,
	c.company_path as company_short_name,
	im_category_from_id(uom_id) as uom,
	im_category_from_id(task_type_id) as task_type,
	im_category_from_id(target_language_id) as target_language,
	im_category_from_id(source_language_id) as source_language,
	im_category_from_id(subject_area_id) as subject_area
from
	im_trans_prices p,
	im_companies c
where 
	p.company_id=:company_id
	and p.company_id=c.company_id(+)
order by
	currency,
	uom_id,
	target_language_id desc,
	task_type_id desc,
	source_language_id desc
"

    set price_rows_html ""
    set ctr 1
    set old_currency ""
    db_foreach prices $price_sql {

        # There can be errors when formatting an empty string...
        set price_formatted ""
        catch { set price_formatted [format "%0.3f" $price] } errmsg

	if {"" != $old_currency && ![string equal $old_currency $currency]} {
	    append price_rows_html "<tr><td colspan=$colspan>&nbsp;</td></tr>\n"
	}

        set price_url [export_vars -base $price_url_base { company_id price_id return_url }]

	append price_rows_html "
        <tr $bgcolor([expr $ctr % 2]) nobreak>
	  <td>$uom</td>
	  <td>$task_type</td>
	  <td>$source_language</td>
          <td>$target_language</td>
	  <td>$subject_area</td>
          <td><a href=\"$price_url\">$price_formatted $currency</a></td>
          <td>[string_truncate -len 15 $note]</td>
          <td><input type=checkbox name=price_id.$price_id></td>
	</tr>"
	incr ctr
	set old_currency $currency
    }

    if {$price_rows_html != ""} {
	append price_list_html $price_rows_html
    } else {
	append price_list_html "<tr><td colspan=$colspan align=center><i>[_ intranet-trans-invoices.No_prices_found]</i></td></tr>\n"
    }

    set sample_pracelist_link "<a href=/intranet-trans-invoices/price-lists/pricelist_sample.csv>[_ intranet-trans-invoices.lt_sample_pricelist_CSV_]</A>"

    if {[im_permission $user_id add_costs]} {

        append price_list_html "
<tr>
  <td colspan=$colspan align=right>
    <input type=submit name=add_new value=\"[_ intranet-trans-invoices.Add_New]\">
    <input type=submit name=del value=\"[_ intranet-trans-invoices.Del]\">
  </td>
</tr>\n"

    }

append price_list_html "
</table>
</form>
"


    if {[im_permission $user_id add_costs]} {

        append price_list_html "
<ul>
  <li>
    <a href=/intranet-trans-invoices/price-lists/upload-prices?[export_url_vars company_id return_url]>
      [_ intranet-trans-invoices.Upload_prices]</A>
    [_ intranet-trans-invoices.lt_for_this_company_via_]
  <li>
    [_ intranet-trans-invoices.lt_Check_this_sample_pra]
    [_ intranet-trans-invoices.lt_It_contains_some_comm]
</ul>\n"

    }

    return $price_list_html
}
