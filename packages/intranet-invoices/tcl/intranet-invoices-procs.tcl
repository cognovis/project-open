# /packages/intranet-invoicing/tcl/intranet-invoice.tcl
#
# Copyright (C) 2003-2005 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.


ad_library {
    Bring together all "components" (=HTML + SQL code)
    related to Invoices

    @author frank.bergann@project-open.com
    @author malte.sussdorff@cognovis.de
}


# -----------------------------------------------------------
# Package Routines
# -----------------------------------------------------------

ad_proc -public im_package_invoices_id { } {
} {
    return [util_memoize "im_package_invoices_id_helper"]
}

ad_proc -private im_package_invoices_id_helper {} {
    return [db_string im_package_core_id {
        select package_id from apm_packages
        where package_key = 'intranet-invoices'
    } -default 0]
}



# ---------------------------------------------------------------
# Update the invoice value
# ---------------------------------------------------------------

ad_proc -public im_invoice_update_rounded_amount {
    -invoice_id
    { -discount_perc "" }
    { -surcharge_perc "" }
} {
    Updates the invoice amount, based on funny rounding rules for different currencies.
} {
#    ns_log Notice "im_invoice_update_rounded_amount: invoice=$invoice_id, dis=$discount_perc, sur=$surcharge_perc"

    # Get the rounding factor for the invoice
    set currency [db_string currency "select currency from im_costs where cost_id = :invoice_id" -default ""]
    if {"" == $currency} { ad_return_complaint 1 "Internal Error:<p>Invoice \\#$invoice_id not found." }
    set rf [im_invoice_rounding_factor -currency $currency]

    # Check the discount and surcharge
    if {"" == $discount_perc} { set discount_perc 0.0 }
    if {"" == $surcharge_perc} { set surcharge_perc 0.0 }

    # Calculate the subtotal
    set subtotal [db_string subtotal "
        select  sum(round(price_per_unit * item_units * :rf) / :rf)
        from    im_invoice_items
        where   invoice_id = :invoice_id
    "]

    # Update the total amount, including surcharge and discount
    set update_invoice_amount_sql "
        update im_costs set
                amount = :subtotal
                         + round(:subtotal * :surcharge_perc::numeric) / 100.0
                         + round(:subtotal * :discount_perc::numeric) / 100.0
        where cost_id = :invoice_id
    "
    db_dml update_invoice_amount $update_invoice_amount_sql
    return $invoice_id
}


# ---------------------------------------------------------------
# Get the rounding factor (rf) for a currency
# ---------------------------------------------------------------

ad_proc -public im_invoice_rounding_factor {
    -currency
} {
    Gets the right rounding factor per currency.
    A rf (rounding factor) of 100 indicates two digits after the decimal separator precision.
} {
    return [util_memoize "im_invoice_rounding_factor_helper -currency $currency"]
}

ad_proc -public im_invoice_rounding_factor_helper {
    { -currency "" }
} {
    Gets the right rounding factor per currency
    A rf (rounding factor) of 100 indicates two digits after the decimal separator precision.
} {
    if {"" == $currency} { set currency [ad_parameter -package_id [im_package_cost_id] "DefaultCurrency" "" "EUR"] }
    set rf 100
    if {[catch {
        set rf [db_string rf "select rounding_factor from currency_codes where iso = :currency" -default 100]
    } err_msg]} {
        ns_log Error "im_invoice_rounding_factor_helper: Error determining rounding factor: $err_msg"
    }
    return $rf
}


# -----------------------------------------------------------
# 
# -----------------------------------------------------------

ad_proc -public im_next_invoice_nr {
    { -cost_type_id 0}
    { -cost_center_id 0}
} {
    Returns the next free invoice number.

    @param cost_type_id Counter for type of financial document
           to be generated.

    Invoice_nr's look like: 2003_07_0123 with the first 4 digits being
    the current year, the next 2 digits the month and the last 4 digits 
    as the current number within the month.
    Returns "" if there was an error calculating the number.

    The SQL query works by building the maximum of all numeric (the 8 
    substr comparisons of the last 4 digits) invoice numbers
    of the current year/month, adding "+1", and contatenating again with 
    the current year/month.

    This procedure has to deal with the case that
    two user are invoices projects concurrently. In this case there may
    be a "raise condition", that two invoices are created at the same
    moment. This is possible, because we take the invoice numbers from
    im_invoices_ACTIVE, which excludes invoices in the process of
    generation.
    To deal with this situation, the calling procedure has to double check
    before confirming the invoice.
} {
    # ----------------------------------------------------
    # Get some parameters that influence the counters:

    # Prefix the numbers with a "I", "Q", "B" and "P" for Invoices, Quotes, ...?
    set use_invoice_prefix_p [parameter::get -package_id [im_package_invoices_id] -parameter "UseInvoiceNrTypePrefixP" -default 0]

    # Determine the date format that specifies whether to 
    # restart the invoice every year ("YYYY") or every month
    # ("YYYY_MM")
    set date_format [parameter::get -package_id [im_package_invoices_id] -parameter "InvoiceNrDateFormat" -default "YYYY_MM"]
    if {"empty" == $date_format} { set date_format "" }

    # Check for a custom project_nr generator
    set invoice_nr_generator [parameter::get -package_id [im_package_invoices_id] -parameter "CustomInvoiceNrGenerator" -default ""]
    if {"" != $invoice_nr_generator} {
	return [eval $invoice_nr_generator -cost_type_id $cost_type_id -cost_center_id $cost_center_id -date_format $date_format]
    }
    
    # ----------------------------------------------------
    # Set the prefix for financial document type
    set prefix ""
    if {$use_invoice_prefix_p} {
	switch $cost_type_id {
	    3700 { set prefix "I" }
	    3702 { set prefix "Q" }
	    3704 { set prefix "B" }
	    3706 { set prefix "P" }
	    3718 { set prefix "T" }
	    3720 { set prefix "E" }
	    3720 { set prefix "R" }
	    3724 { set prefix "D" }
	    default { set prefix "" }
	}
    }

    # ----------------------------------------------------
    # Calculate the next invoice Nr by finding out the last
    # one +1

    # Adjust the position of the start of date and nr in the invoice_nr
    set prefix_len [string length $prefix]
    set date_start_idx [expr 1+$prefix_len]
    set date_format_len [string length $date_format]
    set nr_start_idx [expr 2+$date_format_len+$prefix_len]

    set prefix_where ""
    if {$prefix_len} {
	set prefix_where "and substr(invoice_nr, 1, 1) = :prefix"
    }

    set sql "
select
	trim(max(i.nr)) as last_invoice_nr
from
	(select	substr(invoice_nr, :nr_start_idx,4) as nr 
	 from	im_invoices, dual
	 where	
		substr(invoice_nr, :date_start_idx, :date_format_len) = to_char(sysdate, :date_format)
		$prefix_where
	UNION
	 select '0000' as nr from dual
	) i
where
        ascii(substr(i.nr,1,1)) > 47 and ascii(substr(i.nr,1,1)) < 58 and
        ascii(substr(i.nr,2,1)) > 47 and ascii(substr(i.nr,2,1)) < 58 and
        ascii(substr(i.nr,3,1)) > 47 and ascii(substr(i.nr,3,1)) < 58 and
        ascii(substr(i.nr,4,1)) > 47 and ascii(substr(i.nr,4,1)) < 58
"

    set last_invoice_nr [db_string max_invoice_nr $sql -default ""]
    set last_invoice_nr [string trimleft $last_invoice_nr "0"] 
    if {[empty_string_p $last_invoice_nr]} {
	set last_invoice_nr 0
    }
    set next_number [expr $last_invoice_nr + 1]


    # ----------------------------------------------------
    # Put together the new invoice_nr
    set sql "
	select
	        to_char(sysdate, :date_format)||'_'||
	        trim(to_char($next_number,'0000')) as invoice_nr
	from
	        dual
    "
    set invoice_nr [db_string next_invoice_nr $sql -default ""]

    return "$prefix$invoice_nr"
}



ad_proc -public im_invoice_nr_variant { invoice_nr } {
    Returns the next available "variant" of an invoice number.
    Example: 
    <ul>
      <li>2004_08_002 -> 2004_08_002a or
      <li>2004_08_002a -> 2004_08_002b etc.
    </ul>
} {
    # ToDo: May become slow with a rising number of invoices (> 10.000)
    set max_extension [db_string max_extension "
	select max(i.invoice_nr_extension)
	from
	        (select
	                substr(i.invoice_nr,13,13) as invoice_nr_extension
	        from
	                im_invoices i
	        where
	                substr(i.invoice_nr,1,12) = :invoice_nr	                
	        ) i
    "]

    # simple case: no extension yet
    if {"" == $max_extension} { 
	ns_log Notice "im_invoice_nr_variant: $invoice_nr: no extension yet"
	return "${invoice_nr}a" 
    }

    # second case: "a" .. "y"
    if {1 == [string length $max_extension] && [string compare $max_extension "z"] < 0} { 
	ns_log Notice "im_invoice_nr_variant: $invoice_nr: 1 digit: '$max_extension': incrementing"
	set chr [string first $max_extension "abcdefghijklmnopqrstuvwxyz"]
	incr chr
	set new_extension [string range "abcdefghijklmnopqrstuvwxyz" $chr $chr]
	return "${invoice_nr}$new_extension" 
    }

    ad_return_complaint 1 "<li>System Error: too many invoice copies<br>
    This error occurs because you have more then 26 variants of a sinlge
    financial document (invoice, quote, purchase order, ...).<br>
    Please change your invoice number and/or notify the 
    &\#93;project-open&\#91;
    team."
    return ""
}




# ---------------------------------------------------------------
# Logic to choose the most appropriate company contact for an invoice
# ---------------------------------------------------------------

ad_proc im_invoices_default_company_contact { 
	company_id 
	{ project_id ""} 
} {
    Return the most appropriate company contact for an 
    invoice.
} {
    # Determine the preferred company contact
    #
    set primary_contact_id ""
    set accounting_contact_id ""
    set company_info_sql "
	select	primary_contact_id,
		accounting_contact_id
	from	im_companies
	where	company_id = :company_id
		and company_id != 0
    "
    catch {[db_1row company_info $company_info_sql]} errmsg
    set company_contact_id $accounting_contact_id
    if {"" == $company_contact_id} { set company_contact_id $primary_contact_id }


    # Determine the projects' contact (if exists)
    #
    set project_contact_id ""
    if {0 != $project_id && "" != $project_id || [im_column_exists im_projects company_contact_id]} {
	set project_contact_id [db_string project_info "
		select	company_contact_id 
		from	im_projects 
		where	project_id = :project_id
			and :company_id != 0
	" -default ""]
    }

    # Use the company's and project's contacts as default for
    # each other.
    if {"" == $company_contact_id || 0 == $company_contact_id} {
	set company_contact_id $project_contact_id
    }
    if {"" == $project_contact_id || 0 == $project_contact_id} {
	set project_contact_id $company_contact_id
    }

    # Check what we prefer (if there are two options..)
    set prefer_accounting_contact_p [parameter::get -package_id [im_package_invoices_id] -parameter "PreferAccountingContactOverProjectContactP" -default 1]

    if {$prefer_accounting_contact_p} {
	return $company_contact_id
    } else {
	return $project_contact_id
    }

}





# ---------------------------------------------------------------
# Components
# ---------------------------------------------------------------

ad_proc im_invoices_default_company_template { 
    cost_type_id
    company_id
} {
    Business logic to determine the default invoice template
    for the given cost type at the given company. 
    The algorithm checks if there are dedicated fields in the 
    im_companies table. Ugly? Maybe...
} {
    # Get the short_name of the cost_type, a string like "invoice"
    # "bill" or "delnote".
    set short_name [db_string cost_type_short_name "
	select	short_name
	from	im_cost_types 
	where	cost_type_id = :cost_type_id
    " -default "unknown"]

    # Check whether there is column "default_<short_name>_template_id"
    # in the table im_companies:
    set column_name "default_${short_name}_template_id"

    set template_id ""
    catch {
	set template_id [db_string cost_type_short_name "
		select  $column_name
		from    im_companies
		where   company_id = :company_id
	" -default "unknown"]
    } err_msg
    # Ignore error message

    return $template_id
}


# ---------------------------------------------------------------
# Components
# ---------------------------------------------------------------

ad_proc im_invoices_object_list_component { user_id invoice_id read write return_url } {
    Returns a HTML table containing a list of objects
    associated with a particular financial document.
} {
    if {!$read} { return "" }

    set bgcolor(0) "class=roweven"
    set bgcolor(1) "class=rowodd"

    db_1row invoice_company_id "
	select	customer_id,
		provider_id
	from	im_costs
	where	cost_id = :invoice_id
    "
    
    # ---------------------- Format the list ------------------
    #
    set ctr 0
    set object_list_html ""
    db_foreach object_list {} {

	# Allow us to add some extra stuff for certain know object
	# types such as projects...
	switch $object_type {
	    im_project { set extra_url "&view_name=finance" }
	    default { set extra_url "" }
	}

	append object_list_html "
        <tr $bgcolor([expr $ctr % 2])>
          <td>
            <A href=\"$url$object_id$extra_url\">$object_name</A>
          </td>\n"
	if {$write} {
	    append object_list_html "
          <td>
            <input type=checkbox name=object_ids.$object_id>
          </td>\n"
	}
	append object_list_html "
        </tr>\n"
	incr ctr
    }

    if {0 == $ctr} {
	append object_list_html "
        <tr $bgcolor([expr $ctr % 2])>
          <td><i>[_ intranet-invoices.No_objects_found]</i></td>
        </tr>\n"
    }

    set return_html "
      <form action=invoice-association-action method=post>
      [export_form_vars invoice_id return_url]
      <table border=0 cellspacing=1 cellpadding=1>
        <tr>
          <td align=middle class=rowtitle colspan=2>[_ intranet-invoices.Related_Projects]</td>
        </tr>
        $object_list_html
    "
    if {$write} {
	append return_html "
        <tr>
          <td align=right>
            <input type=submit name=add_project_action value='[_ intranet-invoices.Add_a_Project]'>
            </A>
          </td>
          <td>
            <input type=submit name=del_action value='[_ intranet-invoices.Del]'>
          </td>
        </tr>\n"
    }
    append return_html "
      </table>
      </form>
    "

    return $return_html
}


ad_proc im_invoice_payment_method_select { select_name { default "" } } {
    Returns an html select box named $select_name and defaulted to $default 
    with a list of all the partner statuses in the system
} {
    return [im_category_select_plain "Intranet Invoice Payment Method" $select_name $default]
}


ad_proc im_invoices_select { select_name { default "" } { status "" } { exclude_status "" } } {
    
    Returns an html select box named $select_name and defaulted to
    $default with a list of all the invoices in the system. If status is
    specified, we limit the select box to invoices that match that
    status. If exclude status is provided, we limit to states that do not
    match exclude_status (list of statuses to exclude).

} {
    set bind_vars [ns_set create]

    set sql "
	select
		i.invoice_id,
		i.invoice_nr
	from
		im_invoices i
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
    append sql " order by lower(invoice_nr)"
    return [im_selection_to_select_box $bind_vars "cost_status_select" $sql $select_name $default]
}



# ---------------------------------------------------------------
# Unify "select_projects" to use the common superproject
# ---------------------------------------------------------------

ad_proc im_invoices_unify_select_projects {
    select_projects
} {
    Input is the list of projects related to a financial document.
    Output is a shortened list of related projects.
    Why? Financial documents related to more then one project
    are counted multiple times in various ]po[ reports and list
    pages. So this procedure deals with the frequent case that
    all projects belong to a single super-project and reduces
    the list of related projects to that super-project.
} {
    # Skip function if there is only a single project or none at all...
    if {[llength $select_projects] <= 1} { return $select_projects }
    
    # Security check because we're going to use non-colon vars below
    foreach p $select_projects {
	if {![string is integer $p]} { im_security_alert -location im_invoices_unify_select_projects -message "select_project not an integer" -value $p }
    }

    # Search for the common superproject
    set sql "
        select distinct
                main_p.project_id
        from
                im_projects main_p,
                im_projects p
        where
                main_p.tree_sortkey = tree_root_key(p.tree_sortkey) and
                p.project_id in ([join $select_projects ","])
    "
    set main_projects [db_list main_ps $sql]
    if {1 == [llength $main_projects]} { return $main_projects }
    
    # Didn't find a common superproject - just return the original
    return $select_projects
}


# ---------------------------------------------------------------
# Check for inconsistent invoices
# ---------------------------------------------------------------

ad_proc im_invoices_check_for_multi_project_invoices {} {
    Check if there are invoices around that are assoicated with
    more then one project.
} {
    set multiples_sql "
        select
                count(*) as cnt,
                cost_id,
                cost_name
        from
                im_projects p,
                acs_rels r,
                im_costs c
        where
                r.object_id_one = p.project_id
                and r.object_id_two = c.cost_id
        group by
                cost_id, cost_name
        having
                count(*) > 1
    "

    set errors ""
    db_foreach multiples $multiples_sql {
        append errors "<li>Financial document <a href=[export_vars -base "/intranet-invoices/view" {{invoice_id $cost_id}}]>$cost_name</a> is associated with more then one project.\n"
    }

    if {"" != $errors} {
        ad_return_complaint 1 "<p>Financial documents related to multiple projects currently cause errors in this report.</p>
        <ul>$errors</ul><p>
        Please assign every financial document to a single project (usually the main project).</p>\n"
        return
    }
}




# ---------------------------------------------------------------
# OpenOffice Integration
# ---------------------------------------------------------------


ad_proc im_invoice_oo_tdom_explore {
    {-level 0}
    -parent:required
} {
    Returns a hierarchical representation of a tDom tree
    representing the content of an OOoo document in this case.
} {
    set name [$parent nodeName]
    set type [$parent nodeType]

    set indent ""
    for {set i 0} {$i < $level} {incr i} { append indent "    " }

    set result "${indent}$name"
    if {$type == "TEXT_NODE"} { return "$result=[$parent nodeValue]\n" }

    if {$type != "ELEMENT_NODE"} { return "$result\n" }

    # Create a key-value list of attributes behind the name of the tag
    append result " ("
    foreach attrib [$parent attributes] {
	# Pull out the attributes identified by name:namespace.
	set attrib_name [lindex $attrib 0]
	set ns [lindex $attrib 1]
#	set value [$parent getAttribute "$ns:$attrib_name"]
	set value ""
	append result "'$ns':'$attrib_name'='$value', "
    }
    append result ")\n"

    # Recursively descend to child nodes
    foreach child [$parent childNodes] { 
	append result [im_invoice_oo_tdom_explore -parent $child -level [expr $level + 1]] 
    }
    return $result
}




ad_proc -public im_invoice_change_oo_content {
    -path:required
    -document_filename:required
    -contents:required
} {
    Takes the provided contents and places them in the content.xml 
    file of the odt file, effectivly changing the content of the file.

    @param path Path to the file containing the content
    @param document_filename The open-office file whose contents will be changed.
    @param contents This is a list of key-values (to be used as an array) of filenames and contents
                    to be replaced in the oo-file.
    @return The path to the new file.
} {
    # Create a temporary directory
    set dir [ns_tmpnam]
    ns_mkdir $dir

    array set content_array $contents
    foreach filename [array names content_array] {
	# Save the content to a file.
	set file [open "${dir}/$filename" w]
	fconfigure $file -encoding "utf-8"

	set content $content_array($filename)
	regsub -all -nocase "<br>" $content "<text:line-break/>" content
        regsub -all -nocase "<p>" $content "<text:line-break/>" content
        regsub -all -nocase "&nbsp;" $content " " content
        regsub -all -nocase "</p>" $content "<text:line-break/>" content
        regsub -all -nocase "a href=" $content "text:a xlink:type=\"simple\" xlink:href=" content
        regsub -all -nocase "/a" $content "/text:a" content
        regsub -all -nocase "<ul>" $content "<text:list text:style-name=\"L1\">" content
        regsub -all -nocase "</ul>" $content "</text:list>" content
	puts $file $content
	flush $file
	close $file
    }

    # copy the document
    ns_cp "${path}/$document_filename" "${dir}/$document_filename"

    # Replace old content in document with new content
    # The zip command should replace the content.xml in the zipfile which
    # happens to be the OpenOffice File. 
    foreach filename [array names content_array] {
	exec zip -j "${dir}/$document_filename" "${dir}/$filename"
    }

    # copy odt file
    set new_file "[ns_tmpnam].odt"
    ns_cp "${dir}/$document_filename" $new_file

    # delete other tmpfiles
    ns_unlink "${dir}/$document_filename"
    foreach filename [array names content_array] {
	ns_unlink "${dir}/$filename"
    }
    ns_rmdir $dir

    return $new_file
}


# Make sure that we only call im_invoice_copy_new for invoices of the
# same type. Otherwise we can't guarantee correct work with Collmex

# ---------------------------------------------------------------
# Driver Function for Various Output formats
# ---------------------------------------------------------------


ad_proc -public im_invoice_copy_new {
    -source_invoice_ids
    -target_cost_type_id
} {
    Generate a new invoice of the target_cost_type_id with the data from the original quotes or purchase orders.

    This procedure makes a couple of assumptions
    - The customer / provider is the same
    - All invoice_items of the original invoice will show up as a single item on the new one
    - target_cost_type_ids must be a bill or an invoice
    
    NOTE: This procedure is supposed to run in the background and therefore has not permission checks.
} {

    set user_id [im_sysadmin_user_default]
    # First make sure all the source_invoice_ids are of the same type
    
    set source_cost_type_id [db_list cost_types "select distinct cost_type_id from im_costs where cost_id in ([template::util::tcl_to_sql_list $source_invoice_ids])"]
    if {[llength $source_cost_type_id] != 1} {
	# We cant't work this
	ns_log Error "Tried to generate for $source_invoice_ids which are not of the same cost_type_id"
	return
    }

    # Find out the current type and, if int1 matches, find the type in the
    # target_cost_type
    
    set new_cost_type_id [db_string linked_cost_type "
         select category_id 
         from im_categories, im_category_hierarchy
         where parent_id = :target_cost_type_id 
         and aux_int1 = (select aux_int1 from im_categories where category_id = :source_cost_type_id)
         and child_id = category_id
         limit 1
    " -default $target_cost_type_id]

    # Sanity Check
    set ctr 0
    db_foreach companies "select distinct provider_id, customer_id from im_costs where cost_id in ([template::util::tcl_to_sql_list $source_invoice_ids])" {
	incr ctr
    }
    if {$ctr >1} {
	# We cant't work this
	ns_log Error "Tried to generate for $source_invoice_ids which are not of the same company or provider"
	return
    }


    # ---------------------------------------------------------------
    # Get everything about the original document
    # ---------------------------------------------------------------

    db_1row invoices_info_query "
select
	i.*,
	ci.*,
        c.aux_int1 as new_template_id
from
	im_invoices i, 
	im_costs ci,
        im_categories c
where 
        i.invoice_id in ([join $source_invoice_ids ", "])
	and i.invoice_id = ci.cost_id
        and ci.template_id = c.category_id
LIMIT 1
"
    
    set invoice_nr [im_next_invoice_nr -cost_type_id $target_cost_type_id]
    set new_invoice_id [im_new_object_id]
    
    # We need to find out if we have a customer or provider document
    if {[lsearch [im_category_all_parents -category_id $source_cost_type_id] 3708] > -1} {
	set customer_p 1
	set provider_p 0
	set payment_days [db_string payments_days "select default_payment_days from im_companies where company_id = :customer_id"]
    } else {
	set customer_p 0
	set provider_p 1
	set payment_days [db_string payments_days "select default_payment_days from im_companies where company_id = :provider_id"]
    }
    if {$payment_days eq ""} { set payment_days [ad_parameter -package_id [im_package_cost_id] "DefaultCompanyInvoicePaymentDays" "" 30] }

    
    # Check the template
    if {![exists_and_not_null new_template_id]} {
	set new_template_id $template_id
    }
    
    # ---------------------------------------------------------------
    # Update invoice base data
    # ---------------------------------------------------------------
    
    set invoice_id [db_exec_plsql create_invoice ""]

    # Give company_contact_id READ permissions - required for Customer Portal 
    permission::grant -object_id $invoice_id -party_id $company_contact_id -privilege "read"

    # Check if the cost item was changed via outside SQL
    im_audit -object_type "im_invoice" -object_id $invoice_id -action before_update

    # Update the invoice itself
    db_dml update_invoice "
update im_invoices 
set 
	invoice_nr	= :invoice_nr,
	payment_method_id = :payment_method_id,
	company_contact_id = :company_contact_id,
	invoice_office_id = :invoice_office_id,
	discount_perc	= :discount_perc,
	discount_text	= :discount_text,
	surcharge_perc	= :surcharge_perc,
	surcharge_text	= :surcharge_text
where
	invoice_id = :invoice_id
"

    db_dml update_costs "
update im_costs
set
	project_id	= :project_id,
	cost_name	= :invoice_nr,
	customer_id	= :customer_id,
	cost_nr		= :invoice_id,
	provider_id	= :provider_id,
	cost_status_id	= :cost_status_id,
	cost_type_id	= :target_cost_type_id,
	cost_center_id	= :cost_center_id,
	template_id	= :new_template_id,
	effective_date	= now(),
        delivery_date   = :delivery_date,
	start_block	= ( select max(start_block) 
			    from im_start_months 
			    where start_block < now()),
	payment_days	= :payment_days,
	variable_cost_p = 't',
	amount		= null,
	currency	= :currency
where
	cost_id = :invoice_id
"

    # ---------------------------------------------------------------
    # Associate the invoice with the project via acs_rels
    # ---------------------------------------------------------------

    set related_project_sql "
        select distinct
		object_id_one as project_id
        from
		acs_rels r
        where
		r.object_id_two in ([join $source_invoice_ids ", "])
     "
    set related_project_ids [db_list related_projects $related_project_sql]
	
    # Look for common super-projects for multi-project documents
    set select_project [im_invoices_unify_select_projects $related_project_ids]
    
    foreach project_id $select_project {
	db_1row "get relations" "
		select	count(*) as v_rel_exists
                from    acs_rels
                where   object_id_one = :project_id
                        and object_id_two = :invoice_id
    "
	if {0 ==  $v_rel_exists} {
	    set rel_id [db_exec_plsql create_rel ""]
	}
    }

    # ---------------------------------------------------------------
    # Associate the invoice with the source invoices via acs_rels
    # ---------------------------------------------------------------
    
    foreach source_id $source_invoice_ids {
	if {$source_id ne ""} {
	    db_1row "get relations" "
		select	count(*) as v_rel_exists
                from    acs_rels
                where   object_id_one = :source_id
                        and object_id_two = :invoice_id
    "
	    if {0 ==  $v_rel_exists} {
		set rel_id [db_exec_plsql create_invoice_rel ""]
	    }
	}
    }

    # ---------------------------------------------------------------
    # Associate the invoice with the source invoices via acs_rels
    # ---------------------------------------------------------------

    set invoice_item_ids [db_list item_ids "select item_id from im_invoice_items where invoice_id in ([template::util::tcl_to_sql_list $source_invoice_ids])"]
    foreach old_item_id $invoice_item_ids {
	set item_id [db_nextval "im_invoice_items_seq"]
	set insert_invoice_items_sql "
        INSERT INTO im_invoice_items (
                item_id, item_name,
                project_id, invoice_id,
                item_units, item_uom_id,
                price_per_unit, currency,
                sort_order, item_type_id,
                item_material_id,
                item_status_id, description, task_id,
		item_source_invoice_id
        ) select :item_id, item_name,
                project_id, :invoice_id,
                item_units, item_uom_id,
                price_per_unit, currency,
                sort_order, item_type_id,
                item_material_id,
                item_status_id,description, task_id,
		invoice_id from im_invoice_items where item_id = :old_item_id
	" 
        db_dml insert_invoice_items $insert_invoice_items_sql
    }

    # ---------------------------------------------------------------
    # Update the invoice value
    # ---------------------------------------------------------------
    if {"" == $discount_perc} { set discount_perc 0.0 }
    if {"" == $surcharge_perc} { set surcharge_perc 0.0 }
    
    im_invoice_update_rounded_amount \
	-invoice_id $invoice_id \
	-discount_perc $discount_perc \
	-surcharge_perc $surcharge_perc
    
    # ---------------------------------------------------------------
    # 
    # ---------------------------------------------------------------
    
    # Audit the creation of the invoice
    im_audit -object_type "im_invoice" -object_id $invoice_id -action after_create -status_id $cost_status_id -type_id $cost_type_id

    return $invoice_id
}


ad_proc -public im_invoice_generate_bills {
    {-current_status_id "3804"}
    {-new_status_id "3814"}
} {
    Generate all bills from purchase orders which are in a certain state (defaults to "Outstanding")

    Checks if we have a finance document attached to it already (so we are not going to generate it)
    Sets the purchase orders, once they are transferred into a provider bill, into the state "filed"
} {
    if {$current_status_id eq $new_status_id} {return}
    set cost_types [im_category_children -super_category_id [im_cost_type_po]]
    lappend cost_types [im_cost_type_po]
    set purchase_order_ids [db_list purchase_orders "select cost_id from im_costs where cost_type_id in ([template::util::tcl_to_sql_list $cost_types]) and cost_status_id = :current_status_id"]
    
    # check if we have a linked bill already.
    # in this case, don't generate (?)
    set existing_bill_ids [list]
    db_foreach provider_bills "select object_id_one, object_id_two from acs_rels where object_id_one in ([template::util::tcl_to_sql_list $purchase_order_ids]) and rel_type = 'im_invoice_invoice_rel'" {
	lappend existing_bill_ids $object_id_one
    }
	
    foreach purchase_order_id $purchase_order_ids {
	if {[lsearch $existing_bill_ids $purchase_order_id]<0} {
	    set new_invoice_id [im_invoice_copy_new -source_invoice_ids $purchase_order_ids -target_cost_type_id 3704]

	    # Update the status of the purchase orders
	    db_dml update_status "update im_costs set cost_status_id = :new_status_id where cost_id in ([template::util::tcl_to_sql_list $purchase_order_ids])"
	}
    }
	
    return 1
}

ad_proc -public im_invoice_send_invoice_mail {
    -invoice_id
    {-recipient_id ""}
    {-from_addr ""}
    {-cc_addr ""}
} {
    Send out an E-Mail to the recipient for with the invoice attached
    
    @param invoice_id cost_id of the invoice to be sent
    @recipient_id Recipient of the invoice mail. Defaults to company_contact_id of the invoice
    @from_addr Sender of the invoice mail. Defaults to current user mail
    @cc_addr Optional cc email address. Useful for receiving copies.
} {
    set invoice_revision_id [intranet_openoffice::invoice_pdf -invoice_id $invoice_id]
    set user_id [ad_conn user_id]
    if {"" == $recipient_id} {
	set recipient_id [db_string company_contact_id "select company_contact_id from im_invoices where invoice_id = :invoice_id" -default $user_id]
    } 

    db_1row get_recipient_info "select first_names, last_name, email as to_addr from cc_users where user_id = :recipient_id"

    if {"" == $from_addr} {
	set from_addr [party::email -party_id $user_id]
    }
    
    # Get the type information so we can get the strings
    set invoice_type_id [db_string type "select cost_type_id from im_costs where cost_id = :invoice_id"]
    
    set recipient_locale [lang::user::locale -user_id $recipient_id]
    set subject [lang::util::localize "#intranet-invoices.invoice_email_subject_${invoice_type_id}#" $recipient_locale]
    set body [lang::util::localize "#intranet-invoices.invoice_email_body_${invoice_type_id}#" $recipient_locale]
    acs_mail_lite::send -send_immediately -to_addr $to_addr -from_addr $from_addr -cc_addr $cc_addr -subject $subject -body $body -file_ids $invoice_revision_id -use_sender
}
