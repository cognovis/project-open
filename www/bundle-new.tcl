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
	{return_url "/intranet-expenses/index"}
	form_mode:optional
	enable_master_p:integer,optional
    }
}

set current_user_id [ad_maybe_redirect_for_registration]
set page_title [lang::message::lookup "" intranet-expenses.Expense_Bundle "Expense Bundle"]
set context_bar [im_context_bar $page_title]

if {![info exists enable_master_p]} { set enable_master_p 1}
if {![info exists form_mode]} { set form_mode "edit" }

set cost_id $bundle_id

set delete_bundle_p [im_permission $current_user_id "add_expense_bundle"]

# ---------------------------------------------------------------
# Options
# ---------------------------------------------------------------

set project_options [im_project_options]
set customer_options [im_company_options]
set provider_options [im_provider_options]
set cost_type_options [im_cost_type_options]
set cost_status_options [im_cost_status_options]
set investment_options [im_investment_options]
set template_options [im_cost_template_options]
set currency_options [im_currency_options]
set cost_center_options [im_cost_center_options -include_empty 1 -department_only_p 0]

# ---------------------------------------------------------------
# The Form
# ---------------------------------------------------------------

set form_id form

set cost_name_label "[_ intranet-cost.Name]"
set project_label "[_ intranet-cost.Project]"
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
set amount_label "[_ intranet-cost.Amount]"
set paid_amount_label [lang::message::lookup "" intranet-cost.Paid_Amount "Paid Amount"]
set currency_label "[_ intranet-cost.Currency]"
set paid_currency_label [lang::message::lookup "" intranet-cost.Paid_Currency "Paid Currency"]
set vat_label "[_ intranet-cost.VAT]"
set tax_label "[_ intranet-cost.TAX]"
set desc_label "[_ intranet-cost.Description]"
set note_label "[_ intranet-cost.Note]"

ad_form \
    -name $form_id \
    -mode $form_mode \
    -export "object_id return_url" \
    -actions {} \
    -has_edit 1 \
    -action "/intranet-expenses/new" \
    -form {
	cost_id:key
	{cost_name:text(text) {label $cost_name_label} {html {size 40}}}
	{project_id:text(select),optional {label $project_label} {options $project_options} }
	{cost_type_id:text(select) {label $type_label} {options $cost_type_options} }
	{cost_status_id:text(select) {label $cost_status_label} {options $cost_status_options} }
	{amount:text(text) {label $amount_label} {html {size 20}} }
	{currency:text(select) {label $currency_label} {options $currency_options} }
	{vat:text(text) {label $vat_label} {html {size 20}} }
    }

ad_form -extend -name $form_id \
    -select_query {
	select	c.*
	from	im_costs c
	where	cost_id = :cost_id
    } -new_data {
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
    } -edit_data {
	db_dml edit_conf "
		update im_confs
		set conf = :conf
		where bundle_id = :bundle_id
	"
    } -after_submit {
	ad_returnredirect $return_url
	ad_script_abort
    }



# ---------------------------------------------------------------
# Format the link to modify hours
# ---------------------------------------------------------------


if {[info exists bundle_id]} {

       set modify_bundle_msg [lang::message::lookup "" intranet-expenses.Modify_Included_Expenses "Modify Included Expenses"]
       set modify_bundle_url [export_vars -base "/intranet-expenses/index" {project_id}]
       set modify_bundle_link "<a href='$modify_bundle_url'>$modify_bundle_msg</a>"
       set modify_bundle_link "<ul>\n<li>$modify_bundle_link</li>\n</ul><br>\n"

} else {

  set modify_bundle_link ""

}


# ---------------------------------------------------------------
# Show the included expenses
# ---------------------------------------------------------------

set included_expenses_msg [lang::message::lookup "" intranet-expenses.Included_Expenses "Included Expenses"]

set export_var_list [list]
set bulk_actions_list [list]
set list_id "included_expenses"

template::list::create \
    -name $list_id \
    -multirow multirow \
    -key bundle_id \
    -has_checkboxes \
    -bulk_actions $bulk_actions_list \
    -bulk_action_export_vars  {	object_id } \
    -row_pretty_plural "[_ intranet-expenses.Included_Expenses]" \
    -elements {
	cost_id {
	    label "[_ intranet-expenses.ID]"
	}
	amount {
	    label "[_ intranet-expenses.Amount]"
	}
	vat {
	    label "[_ intranet-expenses.Vat_Included]"
	}
	effective_date {
	    label "[_ intranet-expenses.Expense_Date]"
	}
	project_name {
	    label "[lang::message::lookup {} intranet-expenses.Project Project]"
	    link_url_eval $project_url
	}
	cost_status {
	    label "[lang::message::lookup {} intranet-expenses.Status Status]"
	}
	owner_name {
	    label "[lang::message::lookup {} intranet-expenses.Owner Owner]"
	    link_url_eval $owner_url
	}
    }

db_multirow -extend {bundle_chk project_url owner_url} multirow multirow "
	select	c.*,
		to_char(c.effective_date,'DD/MM/YYYY') as effective_date,
		acs_object__name(c.project_id) as project_name,
		im_category_from_id(c.cost_status_id) as cost_status,
		o.creation_user as owner_id,
		im_name_from_user_id(o.creation_user) as owner_name
	from 
		im_costs c,
		acs_objects o
	where
		c.cost_id = o.object_id
		and c.cost_type_id = [im_cost_type_expense_bundle]
	order by
		cost_id
" {
    set return_url [im_url_with_query]
    set amount "[format %.2f [expr $amount * [expr 1 + [expr $vat / 100]]]] $currency"
    set vat "[format %.1f $vat] %"
    if {$delete_bundle_p || $owner_id == $current_user_id} {
        set bundle_chk "<input type=\"checkbox\" 
				name=\"bundle_id\" 
				value=\"$cost_id\" 
				id=\"bundles_list,$cost_id\">"
    } else {
	set bundle_chk ""
    }

    set project_url [export_vars -base "/intranet/projects/view" {{project_id $project_id} return_url}]
    set owner_url [export_vars -base "/intranet/users/view" {{user_id $owner_id} return_url}]
}



