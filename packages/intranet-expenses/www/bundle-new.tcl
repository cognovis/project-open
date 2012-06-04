# /packages/intranet-expenses/www/bundle-new.tcl
#
# Copyright (C) 2003-2008 ]project-open[
# all@devcon.project-open.com
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

# Use the page contract only if called as a normal page...
# As a panel, the calling script needs to provide the necessary
# variables.
if {![info exists panel_p]} {

    ad_page_contract {
	New page is basic...
	@author all@devcon.project-open.com
    } {
	bundle_id:integer,optional
	cost_id:integer,optional
	{return_url "/intranet-expenses/index"}
	{ form_mode "display" }
	enable_master_p:integer,optional
	{ printer_friendly_p 0 }
	{ render_template_id:integer 0 }
    }
}

set current_user_id [ad_maybe_redirect_for_registration]
set user_id $current_user_id
set page_title [lang::message::lookup "" intranet-expenses.Expense_Bundle "Expense Bundle"]
set context_bar [im_context_bar $page_title]

# Get the default locale for this current user
set user_locale [lang::user::locale]
set locale $user_locale


if {![info exists enable_master_p]} { set enable_master_p 1}
if {![info exists form_mode]} { set form_mode "edit" }
if {![info exists message]} { set message "" }
if {![info exists printer_friendly_p]} { set printer_friendly_p 0 }
if {![info exists render_template_id]} { set render_template_id 0 }

if {[info exists cost_id]} { set bundle_id $cost_id}
if {[info exists bundle_id]} { set cost_id $bundle_id }

set delete_bundle_p [im_permission $current_user_id "add_expense_bundle"]
set edit_bundle_p $delete_bundle_p

set owner_p 0
set owner_id 0
if {[info exists bundle_id]} {
    set owner_id [db_string owner "select creation_user from acs_objects where object_id = :bundle_id" -default 0]
    set owner_p [expr $owner_id == $current_user_id]
}

if {$printer_friendly_p} { set enable_master_p 0 }


# ---------------------------------------------------------------
# Options
# ---------------------------------------------------------------

set bundle_project_id 0
set expense_name ""
if {[info exists bundle_id]} {

    set exists_p [db_string exists "select count(*) from im_costs where cost_id = :bundle_id"]
    if {!$exists_p} {
	ad_return_complaint 1 "<b>[lang::message::lookup "" intranet-expenses.Expense_Bundle_not_found "Expense Bundle not found"]</b>:<br>
	[lang::message::lookup "" intranet-expenses.Expense_Bundle_not_found "
		This bundle has probably been deleted by another user.
	"]"
	ad_script_abort
    }
    set bundle_project_id [db_string bpid "select project_id from im_costs where cost_id = :bundle_id" -default 0]

    db_0or1row bundle_info "
    	select project_id as bundle_project_id,
	       cost_name as bundle_name
	from im_costs
	where cost_id = :bundle_id
    "
}
set project_options [im_project_options -include_project_ids $bundle_project_id]

set customer_options [im_company_options]
set creation_user_options [im_employee_options]
set provider_options [im_provider_options]
set cost_type_options [im_cost_type_options]
set cost_status_options [im_cost_status_options]
set investment_options [im_investment_options]
set currency_options [im_currency_options]
set cost_center_options [im_cost_center_options -include_empty 1 -department_only_p 0]


# ---------------------------------------------------------------
# Determine the locale
# ---------------------------------------------------------------


if {0 != $render_template_id} {

    if {1 == $render_template_id} { 
	# special template - the default template
	set template_from_param [ad_parameter -package_id [im_package_expenses_id] DefaultExpenseTemplate "" ""]
	if {"" == $template_from_param} {
	    # Use the default template that comes as part of the module
	    set template_body "default.adp"
	    set template_path "[acs_root_dir]/packages/intranet-expenses/templates/"
	} else {
	    # Use the user's template in the template path
	    set template_body $template_from_param
	    set template_path [ad_parameter -package_id [im_package_invoices_id] InvoiceTemplatePathUnix "" "/tmp/templates/"]
	}
    } else {
	set template_body [im_category_from_id $render_template_id]
	set template_path [ad_parameter -package_id [im_package_invoices_id] InvoiceTemplatePathUnix "" "/tmp/templates/"]
    }

    append template_path "/$template_body"
    if {[regexp {(.*)\.([_a-zA-Z]*)\.adp} $template_body match body loc]} {
	set locale $loc
    }
}

# Check if the given locale throws an error and reset
if {[catch {
    lang::message::lookup $locale "dummy_text"
} errmsg]} {
    set locale $user_locale
}

# ---------------------------------------------------------------
# Action Links and their permissions
# ---------------------------------------------------------------

set actions [list]

if {[info exists bundle_id]} {

    set edit_perm_func [parameter::get_from_package_key -package_key intranet-timesheet2 -parameter ExpenseBundleNewPageWfEditButtonPerm -default "im_expense_bundle_new_page_wf_perm_edit_button"]
    set delete_perm_func [parameter::get_from_package_key -package_key intranet-timesheet2 -parameter ExpenseBundleNewPageWfDeleteButtonPerm -default "im_expense_bundle_new_page_wf_perm_delete_button"]

#    if {[eval [list $edit_perm_func -bundle_id $bundle_id]]} {
#	lappend actions [list [lang::message::lookup {} intranet-timesheet2.Edit Edit] edit]
#    }

    if {[eval [list $delete_perm_func -bundle_id $bundle_id]]} {
	lappend actions [list [lang::message::lookup {} intranet-timesheet2.Delete Delete] delete]
    }

    if {0 == $render_template_id} {
	lappend actions [list [lang::message::lookup {} intranet-timesheet2.Printer_Friendly {Printer Friendly}] printer_friendly]
    }
}


# ------------------------------------------------------------------
# Special Buttons Pressed?
# ------------------------------------------------------------------

set button_pressed [template::form get_action form]
if {"delete" == $button_pressed} {
    ad_returnredirect [export_vars -base "/intranet-expenses/bundle-del" {bundle_id return_url}]
}

if {"printer_friendly" == $button_pressed} {
   ad_returnredirect [export_vars -base "bundle-new" {bundle_id return_url {render_template_id 1}}]
}


# ---------------------------------------------------------------
# The Form
# ---------------------------------------------------------------

set form_id form

set cost_name_label "[_ intranet-cost.Name]"
set project_label "[_ intranet-cost.Project]"
set creation_user_label "[lang::message::lookup {} intranet-core.Creation_User {Creation User}]"
set customer_label "[_ intranet-cost.Customer]"
set wp_label "[_ intranet-cost.Who_pays]"
set provider_label "[_ intranet-cost.Provider]"
set wg_label "[_ intranet-cost.Who_gets_the_money]"
set type_label "[_ intranet-cost.Type]"
set cost_status_label "[_ intranet-cost.Status]"
set template_label "[_ intranet-cost.Print_Template]"
set investment_label "[_ intranet-cost.Investment]"
set effective_date_label "[_ intranet-cost.Effective_Date]"
set payment_days_label "[_ intranet-cost.Payment_Days]"
set amount_label "[lang::message::lookup "" intranet-cost.Amount_without_VAT "Amount<br>(without VAT)"]"
set paid_amount_label [lang::message::lookup "" intranet-cost.Paid_Amount "Paid Amount"]
set currency_label "[_ intranet-cost.Currency]"
set paid_currency_label [lang::message::lookup "" intranet-cost.Paid_Currency "Paid Currency"]
set vat_label "[_ intranet-cost.VAT]"
set tax_label "[_ intranet-cost.TAX]"
set desc_label "[_ intranet-cost.Description]"
set note_label "[_ intranet-cost.Note]"

# Set of elements to allow the owner to edit his own 
# Expense Bundle after "create-bundle.tcl".
set elements {
	cost_id:key
	{cost_name:text(text) {label $cost_name_label} {html {size 50}}}
	{project_id:text(hidden),optional}
	{cost_type_id:text(hidden)}
	{cost_status_id:text(hidden)}
	{amount:text(hidden)}
	{currency:text(hidden) }
	{vat:text(hidden) }
        {note:text(textarea),optional {label $note_label} {html {cols 50 rows 4}}}
}


if {$edit_bundle_p || "display" == $form_mode} {

    set elements {
	cost_id:key
	{cost_name:text(text) {label $cost_name_label} {html {size 50}}}
	{project_id:text(select),optional {label $project_label} {options $project_options} }
	{creation_user:text(select),optional {label $creation_user_label} {options $creation_user_options} }
        {cost_type_id:text(select) {label $type_label} {options $cost_type_options} }
        {cost_status_id:text(select) {label $cost_status_label} {options $cost_status_options} }
    }
    
    if {"edit" == $button_pressed} {
	set amount_elems {
	    {amount:text(text) {label $amount_label} {html {size 20}} }
	}
    } else {
	set amount_elems {
	    {amount:text(hidden)}
	    {amount_with_vat:text(calculated_sql),optional {label {Amount<br>(inc. VAT)}} {custom {sql {select trim(to_char(amount * (1 + vat / 100), '99999999999.99')) from im_costs where cost_id = $bundle_id}}} }
	}
    }
    
    set elements1 {
        {currency:text(select) {label $currency_label} {options $currency_options} }
        {vat:text(text) {label $vat_label} {html {size 20}} }
        {note:text(textarea),optional {label $note_label} {html {cols 50 rows 4}}}
    }

    set elements [concat $elements $amount_elems $elements1]

}

ad_form \
    -name $form_id \
    -mode $form_mode \
    -export "object_id return_url" \
    -actions $actions \
    -has_edit 1 \
    -action "/intranet-expenses/bundle-new" \
    -form $elements


ad_form -extend -name $form_id \
    -select_query {

	select	c.*,
		o.creation_user
	from	im_costs c,
		acs_objects o
	where	c.cost_id = :cost_id
		and c.cost_id = o.object_id

    } -new_data {

	if {$edit_bundle_p} {	
	    db_exec_plsql create_conf "
		SELECT im_bundle__new(
			:bundle_id,
			'im_conf',
			now(),
			:current_user_id,
			'[ad_conn peeraddr]',
			null,
			:conf,
			:object_id,
			:bundle_type_id,
			[im_bundle_status_active]
		)
            "

	    # Audit the action
	    im_audit -object_type im_expense_bundle -action after_create -object_id $bundle_id

	} else {
	    im_security_alert \
		-location "intranet-expenses/www/bundle-new" \
		-message "Somebody tried to create an Expense Bundle without permissions" \
		-severity "Severe"
	}

    } -edit_data {

	if {$owner_p} {	
	    db_dml update_consts "
		update im_costs set
			cost_name = :cost_name,
			note = :note
		where cost_id = :bundle_id
	    "
	}

	if {$edit_bundle_p} {	
	    db_dml update_consts "
		update im_costs set
			cost_name = :cost_name,
			project_id = :project_id,
			cost_type_id = :cost_type_id,
			cost_status_id = :cost_status_id,
			note = :note
		where cost_id = :bundle_id
	    "
	}
        if {!$edit_bundle_p && !$owner_p} {
	    im_security_alert \
		-location "intranet-expenses/www/bundle-new" \
		-message "Somebody tried to confirm an Expense Bundle without permissions" \
		-severity "Severe"
	}

	# Audit the action
	im_audit -object_type im_expense_bundle -action after_update -object_id $bundle_id


    } -after_submit {
	ad_returnredirect $return_url
	ad_script_abort
    }



# ---------------------------------------------------------------
# Format the link to modify hours
# ---------------------------------------------------------------

set modify_bundle_link ""

if {[info exists bundle_id]} {
    
    set link_perm_func [parameter::get_from_package_key -package_key intranet-expenses -parameter ExpenseBundleNewPageWfModifyIncludedExpensesPerm -default "im_expense_bundle_new_page_wf_perm_modify_included_expenses"]

    if {[eval [list $link_perm_func -bundle_id $bundle_id]]} {

       set modify_bundle_msg [lang::message::lookup "" intranet-expenses.Modify_Included_Expenses "Modify Included Expenses"]
       set modify_bundle_url [export_vars -base "/intranet-expenses/index" {project_id}]
       set modify_bundle_link "<a href='$modify_bundle_url'>$modify_bundle_msg</a>"
       set modify_bundle_link "<ul>\n<li>$modify_bundle_link</li>\n</ul><br>\n"

   }
}


# ---------------------------------------------------------------
# Show the included expenses
# ---------------------------------------------------------------

set included_expenses_msg [lang::message::lookup "" intranet-expenses.Included_Expenses "Included Expenses"]

set date_format "YYYY-MM-DD"
set bulk_action_list [list]
set list_id "expenses_list"
set action_list [list]

template::list::create \
    -name $list_id \
    -multirow expense_lines \
    -key expense_id \
    -has_checkboxes \
    -actions $action_list \
    -bulk_actions $bulk_action_list \
    -bulk_action_export_vars { task_id bundle_id return_url } \
    -row_pretty_plural "[_ intranet-expenses.Expenses_Items]" \
    -elements {
	effective_date {
	    label "[_ intranet-expenses.Expense_Date]"
	    link_url_eval $expense_new_url
	    display_template { <nobr>@expense_lines.effective_date;noquote@</nobr> }
	}
	amount {
	    label "[_ intranet-expenses.Amount]"
	    display_template { <nobr>@expense_lines.amount;noquote@</nobr> }
	    link_url_eval $expense_new_url
	}
	vat {
	    label "[lang::message::lookup {} intranet-expenses.Vat VAT]"
	}
	external_company_name {
	    label "[_ intranet-expenses.External_company_name]"
	}
	expense_type {
	    label "[_ intranet-expenses.Expense_Type]"
	}
	expense_payment_type {
	    label "[_ intranet-expenses.Expense_Payment_Type]"
	}
	billable_p {
	    label "[lang::message::lookup {} intranet-expenses.Billable {Bill-<br>able?}]"
	}
    }

set def_currency [parameter::get -package_id [apm_package_id_from_key intranet-cost] -parameter "DefaultCurrency" -default 'EUR']

set expense_lines_sql "
	select
		c.*,
		e.*,
		acs_object__name(provider_id) as provider_name,
		to_char(effective_date, :date_format) as effective_date,
		to_char(((c.amount * c.vat/100) + c.amount)*e.reimbursable/100,:cur_format) as amount_reimbursable,
		round(((c.amount * c.vat/100) + c.amount) * (e.reimbursable/100) * 
			im_exchange_rate(c.effective_date::date, c.currency, '$def_currency') :: numeric, 2) as amount_reimbursable_converted,
		im_category_from_id(expense_type_id) as expense_type,
		im_category_from_id(expense_payment_type_id) as expense_payment_type,
		p.project_name
	from
		im_expenses e,
		im_costs c
		LEFT OUTER JOIN im_projects p on (c.project_id = p.project_id)
	where
		e.expense_id = c.cost_id and
		e.bundle_id = :bundle_id
	order by
		c.effective_date
"
set first_loop_p 1
set currency list
array set curr_hash {}
set tmp_output ""
set cur_format [im_l10n_sql_currency_format]
set amount_reimbursable_converted_sum 0

db_multirow -extend {project_url expense_new_url provider_url} expense_lines expenses_lines $expense_lines_sql {
    # -- create summaries for each currency
    if { 1 == $first_loop_p } {
            lappend currency_list $currency
            set curr_idx 0
            set first_loop_p 0
    } else {
        set curr_idx [lsearch $currency_list $currency]
        if { -1 == $curr_idx } {
            lappend currency_list $currency
            set curr_idx [lsearch $currency_list $currency]
        }
    }

    if { [info exists curr_hash($provider_id,$curr_idx) ] } {
        set curr_hash($provider_id,$curr_idx) [expr $curr_hash($provider_id,$curr_idx) + $amount_reimbursable]
    } else {
        set curr_hash($provider_id,$curr_idx) $amount_reimbursable
    }
    # -- end summary currencies
    
    set amount "[format %.2f [expr $amount * [expr 1 + [expr $vat / 100]]]] $currency"
    set vat "[format %.1f $vat] %"
    set reimbursable "[format %.1f $reimbursable] %"
    if {![exists_and_not_null bundle_id]} {
	set expense_chk "<input type=\"checkbox\" 
				name=\"expense_id\" 
				value=\"$expense_id\" 
				id=\"expenses_list,$expense_id\">"
    }
    set expense_new_url [export_vars -base "/intranet-expenses/new" {expense_id return_url}]
    set provider_url [export_vars -base "/intranet/companies/view" {{company_id $provider_id} return_url}]
    set project_url [export_vars -base "/intranet/projects/view" {{project_id $project_id} return_url}]

    if { "" == $amount_reimbursable_converted } {set amount_reimbursable_converted 0}
    set amount_reimbursable_converted_sum [expr $amount_reimbursable_converted_sum + $amount_reimbursable_converted]
}

set reimbursement_output_table "<br><hr width='640px'><br><table cellpadding='3px' cellspacing='3px' border='0'><tr><td colspan='2'><h2>Reimbursement Employee/Currency<h2></td></tr>"

set bak_key ""
foreach key [array names curr_hash] {
    #get current value with $curr_hash($key)
    if {$bak_key == $key} {
        set employee_id ""
    } else {
	set employee_id [string range $key 0 [expr [string first "," $key]-1]]
    }
    set employee_name [im_name_from_user_id $employee_id]
    set reimburse_amount $curr_hash($key)
    if { ".00" != $reimburse_amount } {
        append reimbursement_output_table "<tr><td>$employee_name</td><td align='right'>[lindex $currency_list [string range $key [expr [string first "," $key]+1] [string length $key]]]&nbsp;$reimburse_amount</td></tr><br>"
    }
    set bak_key $key
}
append reimbursement_output_table "</table><br><br><br>"

# ---------------------------------------------------------------
# Special Output: Format using a template
# ---------------------------------------------------------------

# Use a specific template ("render_template_id") to render the "preview"
if {0 != $render_template_id} {

    set cost_type "Expense Bundle"

    if {"" == $template_body} {
	ad_return_complaint 1 "<li>You haven't specified a template for your $cost_type."
	ad_script_abort
    }

    if {![file isfile $template_path] || ![file readable $template_path]} {
	ad_return_complaint "Unknown $cost_type Template" "
	<li>$cost_type template '$template_path' doesn't exist or is not readable
	for the web server. Please notify your system administrator."
	ad_script_abort
    }

    # Render the page using the template
    set invoices_as_html [ns_adp_parse -file $template_path]

    # Show invoice using template
    ns_return 200 text/html $invoices_as_html
    ad_script_abort
} 
