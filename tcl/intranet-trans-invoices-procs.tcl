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
    set price_list_html "
<table border=0>
<tr><td colspan=6 class=rowtitle align=center>Price List</td></tr>
<tr class=rowtitle> 
	  <td class=rowtitle>UoM</td>
	  <td class=rowtitle>Task Type</td>
	  <td class=rowtitle>Source</td>
	  <td class=rowtitle>Target</td>
	  <td class=rowtitle>Subject</td>
	  <td class=rowtitle>Rate</td>
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
	target_language_id,
	source_language_id,
	task_type_id,
	uom_id"

    set price_rows_html ""
    set ctr 1
    db_foreach prices $price_sql {
	append price_rows_html "
        <tr $bgcolor([expr $ctr % 2]) nobreak>
	  <td>$uom</td>
	  <td>$task_type</td>
          <td>$target_language</td>
	  <td>$source_language</td>
	  <td>$subject_area</td>
          <td>$price $currency</td>
	</tr>"
	incr ctr
    }

    if {$price_rows_html != ""} {
	append price_list_html $price_rows_html
    } else {
	append price_list_html "<tr><td colspan=4 align=center><i>No prices found</i></td></tr>\n"
    }

    append price_list_html "
</table>
<ul><li>
  <a href=upload-prices?[export_url_vars customer_id return_url]>Upload Prices</A>
</ul>\n"
    return $price_list_html
}