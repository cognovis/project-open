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

ad_proc im_trans_price_component { user_id customer_id return_url} {
    Returns a formatted HTML table representing the 
    prices for the current customer
} {

    set bgcolor(0) " class=roweven "
    set bgcolor(1) " class=rowodd "
    set price_format "000.000"

    set colspan 7
    set price_list_html "
<form action=/intranet-trans-invoices/price-lists/price-action method=POST>
[export_form_vars customer_id return_url]
<table border=0>
<tr><td colspan=$colspan class=rowtitle align=center>Price List</td></tr>
<tr class=rowtitle> 
	  <td class=rowtitle>UoM</td>
	  <td class=rowtitle>Task Type</td>
	  <td class=rowtitle>Source</td>
	  <td class=rowtitle>Target</td>
	  <td class=rowtitle>Subject</td>
	  <td class=rowtitle>Rate</td>
	  <td class=rowtitle>[im_gif del "Delete"]</td>
</tr>"

    set price_sql "
select
	p.*,
	c.customer_path as customer_short_name,
	im_category_from_id(uom_id) as uom,
	im_category_from_id(task_type_id) as task_type,
	im_category_from_id(target_language_id) as target_language,
	im_category_from_id(source_language_id) as source_language,
	im_category_from_id(subject_area_id) as subject_area
from
	im_trans_prices p,
	im_customers c
where 
	p.customer_id=:customer_id
	and p.customer_id=c.customer_id(+)
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

	if {"" != $old_currency && ![string equal $old_currency $currency]} {
	    append price_rows_html "<tr><td colspan=$colspan>&nbsp;</td></tr>\n"
	}

	append price_rows_html "
        <tr $bgcolor([expr $ctr % 2]) nobreak>
	  <td>$uom</td>
	  <td>$task_type</td>
	  <td>$source_language</td>
          <td>$target_language</td>
	  <td>$subject_area</td>
          <td>$price $currency</td>
          <td><input type=checkbox name=price_id.$price_id></td>
	</tr>"
	incr ctr
	set old_currency $currency
    }

    if {$price_rows_html != ""} {
	append price_list_html $price_rows_html
    } else {
	append price_list_html "<tr><td colspan=$colspan align=center><i>No prices found</i></td></tr>\n"
    }

    append price_list_html "
<tr>
  <td colspan=$colspan align=right>
    <input type=submit name=add_new value=\"Add New\">
    <input type=submit name=del value=\"Del\">
  </td>
</tr>
</table>
</form>
<ul>
  <li>
    <a href=/intranet-trans-invoices/upload-prices?[export_url_vars customer_id return_url]>
      Upload prices</A>
    for this customer via a CSV file.
  <li>
    Check this 
    <a href=/intranet-trans-invoices/price-lists/pricelist_sample.csv>
      sample pricelist CSV file</A>.
    It contains some comments inside.
</ul>\n"
    return $price_list_html
}