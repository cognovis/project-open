# /packages/intranet-riskmanagement/www/new.tcl
#
# Copyright (c) 2003-2008 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.


# -----------------------------------------------------------
# Page Head
#
# There are two different heads, depending whether it's called
# "standalone" (TCL-page) or as a Workflow Panel.
# -----------------------------------------------------------

# Skip if this page is called as part of a Workflow panel
if {![info exists task]} {

    ad_page_contract {
	@author frank.bergmann@project-open.com
    } {
	risk_id:integer,optional
	{ risk_name "" }
	{ risk_project_id "" }
	{ risk_status_id "" }
	{ risk_type_id "" }
	{ mine_p "all" }
	{ vars_from_url "" }
	{ form_mode "edit" }
	{ plugin_id "" }
	{ view_name "" }
	{ return_url "" }
    }

    set show_components_p 1
    set enable_master_p 1

} else {
    
    set task_id $task(task_id)
    set case_id $task(case_id)

    set vars_from_url ""
    set return_url ""

    set risk_id [db_string pid "select object_id from wf_cases where case_id = :case_id" -default ""]
    set transition_key [db_string transition_key "select transition_key from wf_tasks where task_id = :task_id"]
    set task_page_url [export_vars -base [ns_conn url] { risk_id task_id return_url}]

    set show_components_p 0
    set enable_master_p 0
    set risk_type_id ""

    set plugin_id ""
    set view_name "standard"
    set mine_p "all"

    set render_template_id 0

    # Don't show this page in WF panel.
    # Instead, redirect to this same page, but in TaskViewPage mode.
    # ad_returnredirect "/intranet-riskmanagement/new?risk_id=$task(object_id)"

    # fraber 20100602: redirecting to return_url leads to an infinite
    # loop with workflow. Re-activating redirection to the RiskNewPage
    # ad_returnredirect $return_url

    ad_returnredirect [export_vars -base "/intranet-riskmanagement/new" { {risk_id $task(object_id)} {form_mode display}} ]

}


# ------------------------------------------------------------------
# Default & Security
# ------------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set user_id $current_user_id
set current_url [im_url_with_query]
set action_url "/intranet-riskmanagement/new"
# set focus "riskmanagement_risk.var_name"
set focus "risk.var_name"
if {"" == $return_url} { set return_url [im_url_with_query] }

if {[info exists risk_id] && "" == $risk_id} { unset risk_id }

set view_risks_all_p [im_permission $current_user_id "view_risks_all"]
set copy_from_risk_name ""

# No support for workflow at the moment
set edit_risk_status_p 1


# ----------------------------------------------
# Page Title

set page_title [lang::message::lookup "" intranet-riskmanagement.New_Risk "New Risk"]
if {[exists_and_not_null risk_id]} {
    set page_title [db_string title "select project_name from im_projects where project_id = :risk_id" -default ""]
}
if {"" == $page_title && 0 != $risk_type_id} { 
    set risk_type [im_category_from_id $risk_type_id]
    set page_title [lang::message::lookup "" intranet-riskmanagement.New_RiskType "New %risk_type%"]
} 

set context [list $page_title]



if {![info exists risk_probability_percent] || ![info exists risk_impact]} {
    set admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
    set admin_html ""
    if {$admin_p} { set admin_html "<a href=/intranet-dynfield/attribute-type-map?object_type=im_risk>Click here to enable fields</a><br>&nbsp;<br>" }

    ad_return_complaint 1 "<b>Configuration Error</b>:<br>
	The fields 'risk_probability' or 'risk_impact' are not activated for your risk type.<br>&nbsp;<br>
	Please notify your application administrator and ask him or her to enable these
	fields for all types of risks in:<br>
	Admin -&gt; DynFields -&gt; Object Types -&gt; Risk -&gt; Attribute Type Map and set
	all values to 'E'=Edit (3rd option) for all risk types..<br>&nbsp;<br>
	$admin_html
    "
    ad_script_abort
}


# ----------------------------------------------
# Determine risk type

# We need the risk_type_id for page title, dynfields etc.
# Check if we can deduce the risk_type_id from risk_id
if {0 == $risk_type_id || "" == $risk_type_id} {
    if {[exists_and_not_null risk_id]} { 
	set risk_type_id [db_string ttype_id "select risk_type_id from im_risks where risk_id = :risk_id" -default 0]
    }
}

# ----------------------------------------------
# Calculate form_mode

if {"edit" == [template::form::get_action riskmanagement_action]} { set form_mode "edit" }
if {![info exists risk_id]} { set form_mode "edit" }
if {![info exists form_mode]} { set form_mode "display" }

# Show the ADP component plugins?
if {"edit" == $form_mode} { set show_components_p 0 }

set risk_exists_p 0
if {[exists_and_not_null risk_id]} {
    # Check if the risk exists
    set risk_exists_p [db_string risk_exists_p "select count(*) from im_risks where risk_id = :risk_id"]

    # Write Audit Trail
    im_audit -object_id $risk_id -action before_update

}


# ---------------------------------------------
# The base form. Define this early so we can extract the form status
# ---------------------------------------------

set title_label [lang::message::lookup {} intranet-riskmanagement.Name {Title}]
set title_help [lang::message::lookup {} intranet-riskmanagement.Title_Help {Please enter a descriptive name for the new risk.}]

set edit_p [im_permission $current_user_id add_risks_for_customers]
set delete_p $edit_p
set edit_p 1

set actions {}
if {$edit_p} { lappend actions {"Edit" edit} }
# if {$delete_p} { lappend actions {"Delete" delete} }

ad_form \
    -name riskmanagement_risk \
    -cancel_url $return_url \
    -action $action_url \
    -actions $actions \
    -has_edit 1 \
    -mode $form_mode \
    -export {next_url return_url} \
    -form {
	risk_id:key
	{risk_name:text(text) {label $title_label} {html {size 50}}}
    }

# ------------------------------------------------------------------
# Risk Action
# ------------------------------------------------------------------

set risk_action_html ""
if {[info exists risk_id]} {
    set risk_action_html "
	<form action=/intranet-riskmanagement/action name=riskmanagement_action>
	[export_form_vars return_url]
	<!-- manual pass-through of risk_id as an array -->
	<input type=hidden name=risk_id.$risk_id value='on'>
	<input type=submit value='[lang::message::lookup "" intranet-riskmanagement.Action "Action"]'>
	[im_category_select \
	     -translate_p 1 \
	     -package_key "intranet-riskmanagement" \
	     -plain_p 1 \
	     -include_empty_p 1 \
	     -include_empty_name "" \
	     "Intranet Risk Action" \
	     action_id \
	]
	</form>
    "
}

# ------------------------------------------------------------------
# Delete pressed?
# ------------------------------------------------------------------

set button_pressed [template::form get_action riskmanagement_risk]
if {"delete" == $button_pressed} {
     db_dml mark_risk_deleted "
	update	im_risks
	set	risk_status_id = [im_risk_status_deleted]
	where	risk_id = :risk_id
     "

    # Write Audit Trail
    im_audit -object_id $risk_id -action delete

    ad_returnredirect $return_url
}

# ------------------------------------------------------------------
# 
# ------------------------------------------------------------------

# Fetch variable values from the HTTP session and write to local variables
set url_vars_set [ns_conn form]
foreach var_from_url $vars_from_url {
    ad_set_element_value -element $var_from_url [im_opt_val $var_from_url]
}


set risk_elements [list]
set project_options [im_project_options -include_empty 0]
lappend risk_elements {risk_project_id:text(select) {label "[lang::message::lookup {} intranet-riskmanagement.Project Project]"} {options $project_options}}

lappend risk_elements {risk_type_id:text(im_category_tree) {label "[lang::message::lookup {} intranet-riskmanagement.Type Type]"} {custom {category_type "Intranet Risk Type" translate_p 1 include_empty_p 0 package_key "intranet-riskmanagement"}}}

lappend risk_elements {risk_status_id:text(im_category_tree) {label "[lang::message::lookup {} intranet-riskmanagement.Status Status]"} {custom {category_type "Intranet Risk Status" translate_p 1 include_empty_p 0 package_key "intranet-riskmanagement"}} }

# Extend the form with new fields
ad_form -extend -name riskmanagement_risk -form $risk_elements

# Add DynFields to the form
set field_cnt [im_dynfield::append_attributes_to_form \
		   -object_id [im_opt_val risk_id] \
		   -form_display_mode $form_mode \
		   -object_subtype_id [im_opt_val risk_type_id] \
		   -object_type "im_risk" \
		   -form_id "riskmanagement_risk" \
]

# ------------------------------------------------------------------
# Form Actions
# ------------------------------------------------------------------

# Fix for problem changing to "edit" form_mode
set form_action [template::form::get_action "riskmanagement_risk"]
if {"" != $form_action} { set form_mode "edit" }

ad_form -extend -name riskmanagement_risk -on_request {

    # Populate elements from local variables

} -select_query {

	select	r.*
	from	im_risks r
	where	r.risk_id = :risk_id

} -new_data {

    set risk_id [db_string new_risk "
	select im_risk__new(
		null::integer,			-- risk_id  default null
		'im_risk',			-- object_type default im_risk
		now()::timestamptz,		-- creation_date default now()
		:current_user_id::integer,	-- creation_user default null
		'[ad_conn peeraddr]',		-- creation_ip default null
		null::integer,			-- context_id default null

		:risk_project_id::integer,	-- project container
		:risk_status_id::integer,	-- active or inactive or for WF stages
		:risk_type_id::integer,		-- user defined type of risk. Determines WF.
		:risk_name			-- Unique name of risk per project
	)
    "]

    im_dynfield::attribute_store \
	-object_type "im_risk" \
	-object_id $risk_id \
	-form_id riskmanagement_risk

    # Write Audit Trail
    im_audit -object_id $risk_id -action after_create

    ad_returnredirect $return_url
#    ad_returnredirect [export_vars -base "/intranet-riskmanagement/new" {risk_id {form_mode display}}]
    ad_script_abort

} -edit_data {

    db_dml risk_update "
	update im_risks set
		 risk_project_id = :risk_project_id,
		 risk_status_id = :risk_status_id,
		 risk_type_id = :risk_type_id,
		 risk_name = :risk_name,
		 risk_probability_percent = :risk_probability_percent,
		 risk_impact = :risk_impact
	where risk_id = :risk_id
    "

    im_dynfield::attribute_store \
	-object_type "im_risk" \
	-object_id $risk_id \
	-form_id riskmanagement_risk

    # Write Audit Trail
    im_audit -object_id $risk_id -object_type "im_risk" -status_id $risk_status_id -type_id $risk_type_id -action after_update

} -on_submit {

	ns_log Notice "new: on_submit"

} -after_submit {

	ad_returnredirect $return_url
	ad_script_abort

} -validate {
    {risk_name
	{ [string length $risk_name] < 1000 }
	"[lang::message::lookup {} intranet-riskmanagement.Risk_name_too_long {Risk Name too long (max 1000 characters).}]" 
    }
}

# ---------------------------------------------------------------
# Risk Menu
# ---------------------------------------------------------------

# Setup the subnavbar
set bind_vars [ns_set create]
if {[info exists risk_id]} { ns_set put $bind_vars risk_id $risk_id }


if {![info exists risk_id]} { set risk_id "" }

set risk_parent_menu_id [db_string parent_menu "select menu_id from im_menus where label='riskmanagement'" -default 0]
set sub_navbar [im_sub_navbar \
    -components \
    -current_plugin_id $plugin_id \
    -base_url "/intranet-riskmanagement/new?risk_id=$risk_id" \
    -plugin_url "/intranet-riskmanagement/new" \
    $risk_parent_menu_id \
    $bind_vars "" "pagedesriptionbar" "riskmanagement_summary"] 


