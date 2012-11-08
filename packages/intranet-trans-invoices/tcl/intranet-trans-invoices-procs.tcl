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


# ---------------------------------------------------------------
# Permissions
# ---------------------------------------------------------------

ad_proc -public im_trans_invoice_permissions {
    {-debug 0}
    current_user_id
    user_id
    view_var
    read_var
    write_var
    admin_var
} {
    Fill the "by-reference" variables read, write and admin
    with the permissions of $current_user_id on $user_id
} {
    upvar $view_var view
    upvar $read_var read
    upvar $write_var write
    upvar $admin_var admin

    set view 0
    set read 0
    set write 0
    set admin 0

    if {"" == $user_id} { return }
    if {"" == $current_user_id} { return }

    # Admins and creators can do everything
    set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
    set creation_user_id [util_memoize "db_string creator {select creation_user from acs_objects where object_id = $user_id} -default 0"]
    if {$user_is_admin_p || $current_user_id == $creation_user_id} {
        set view 1
        set read 1
        set write 1
        set admin 1
        return
    }

    # Get the list of profiles of user_id (the one to be managed)
    # together with the information if current_user_id can read/write
    # it.
    # m.group_id are all the groups to whom user_id belongs
    set profile_perm_sql "
                select
                        m.group_id,
                        im_object_permission_p(m.group_id, :current_user_id, 'view') as view_p,
                        im_object_permission_p(m.group_id, :current_user_id, 'read') as read_p,
                        im_object_permission_p(m.group_id, :current_user_id, 'write') as write_p,
                        im_object_permission_p(m.group_id, :current_user_id, 'admin') as admin_p
                from
                        acs_objects o,
                        group_distinct_member_map m
                where
                        m.member_id = :user_id
                        and m.group_id = o.object_id
                        and o.object_type = 'im_profile'
    "
    set first_loop 1
    db_foreach profile_perm_check $profile_perm_sql {
        if {$debug} { ns_log Notice "im_user_permissions: $group_id: view=$view_p read=$read_p write=$write_p admin=$admin_p" }
        if {$first_loop} {
            # set the variables to 1 if current_user_id is member of atleast
            # one group. Otherwise, an unpriviliged user could read the data
            # of another unpriv user
            set view 1
            set read 1
            set write 1
            set admin 1
        }

        if {[string equal f $view_p]} { set view 0 }
        if {[string equal f $read_p]} { set read 0 }
        if {[string equal f $write_p]} { set write 0 }
        if {[string equal f $admin_p]} { set admin 0 }
        set first_loop 0
    }

    # Myself - I can read and write its data
    if { $user_id == $current_user_id } {
                set read 1
                set write 1
                set admin 0
    }
    if {$admin} {
                set read 1
                set write 1
    }
    if {$read} { set view 1 }

    if {$debug} { ns_log Notice "im_trans_invoice_permissions: cur=$current_user_id, user=$user_id, view=$view, read=$read, write=$write, admin=$admin" }

}
