# /packages/intranet-trans-invoices/tcl/intranet-trans-invoices-procs.tcl

ad_library {
    Bring together all "components" (=HTML + SQL code)
    related to Invoices

    @author frank.bergmann@project-open.com
    @creation-date  27 June 2003
}


# ------------------------------------------------------
# Price List
# ------------------------------------------------------

ad_proc im_trans_price_component { user_id company_id return_url} {
    Returns a formatted HTML table representing the 
    prices for the current company
} {
    if {![im_permission $user_id view_costs]} { return "" }
    
    set enable_file_type_p [parameter::get_from_package_key -package_key intranet-trans-invoices -parameter "EnableFileTypeInTranslationPriceList" -default 0]

    set bgcolor(0) " class=roweven "
    set bgcolor(1) " class=rowodd "
    set price_format "000.000"
    set min_price_format "000.00"
    set price_url_base "/intranet-trans-invoices/price-lists/new"

    set colspan 9
    if {$enable_file_type_p} { incr colspan}

    set file_type_html "<td class=rowtitle>[lang::message::lookup "" intranet-trans-invoices.File_Type "File Type"]</td>"
    if {!$enable_file_type_p} { set file_type_html "" }

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
		  $file_type_html
		  <td class=rowtitle>[_ intranet-trans-invoices.Rate]</td>
		  <td class=rowtitle>[lang::message::lookup "" intranet-trans-invoices.Minimum_Rate "Min Rate"]</td>
		  <td class=rowtitle>[_ intranet-core.Note]</td>
		  <td class=rowtitle>[im_gif del "Delete"]</td>
	</tr>
    "

    set price_rows_html ""
    set ctr 1
    set old_currency ""
    db_foreach prices {} {

        # There can be errors when formatting an empty string...
        set price_formatted ""
        catch { set price_formatted "[format "%0.3f" $price] $currency" } errmsg
	if {"" != $old_currency && ![string equal $old_currency $currency]} {
	    append price_rows_html "<tr><td colspan=$colspan>&nbsp;</td></tr>\n"
	}

        set price_url [export_vars -base $price_url_base { company_id price_id return_url }]

	set file_type_html "<td>$file_type</td>"
	if {!$enable_file_type_p} { set file_type_html "" }

	append price_rows_html "
        <tr $bgcolor([expr $ctr % 2]) nobreak>
	  <td>$uom</td>
	  <td>$task_type</td>
	  <td>$source_language</td>
          <td>$target_language</td>
	  <td>$subject_area</td>
	  $file_type_html
          <td><a href=\"$price_url\">$price_formatted</a></td>
          <td>$min_price_formatted</td>
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
	</tr>
        "
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
	  <li>
	    <a href=\"[export_vars -base "/intranet-reporting/view" {{report_code translation_price_list_export} {format csv} company_id}]\">
	    [lang::message::lookup "" intranet-trans-invoices.Export_as_csv "Export price list as CSV"]
	    </a>
	</ul>
        "
    }

    return $price_list_html
}
