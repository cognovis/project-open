# /packages/intranet-freelance-rfqs/www/panels/rfa-panel.tcl
#
# Copyright (c) 2003-2007 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.
#
# Authors:
#	frank.bergmann@project-open.com


# -----------------------------------------------------------
# Page Head
# 
# There are two different heads, depending whether it's called
# "standalone" (TCL-page) or as a Workflow Panel.
# -----------------------------------------------------------

if {[info exists task]} {

    # Workflow-Panel Head: This code is called when this page is embedded in a WF "Panel"
    set task_id $task(task_id)
    set case_id $task(case_id)

    # Return-URL Logic
    set return_url ""
    if {[info exists task(return_url)]} { set return_url $task(return_url) }

    set answer_id [db_string pid "select object_id from wf_cases where case_id = :case_id" -default ""]
    set transition_key [db_string transition_key "select transition_key from wf_tasks where task_id = :task_id"]
    set task_page_url [export_vars -base [ns_conn url] { answer_id task_id return_url}]

    set enable_master_p 0
    set task_header ""

} else {

    # Stand-Alone Head: This code is called when the page is used as a normal
    # "EditPage" or "NewPage".

    ad_page_contract {
        Purpose: form to add a new project or edit an existing one
    } {
        answer_id:integer
        { return_url "/intranet/" }
        { task_page_url "" }
	{ task_id "" }
	{ default_assignee_fulfill_rfc_id 0 }
    }

    # Get the task_id if we've got the project
    if {"" == $task_id} { 
	set case_id [db_string case_id "select case_id from wf_cases where object_id = :answer_id" -default 0]
	set tasks [db_list tasks "select task_id from wf_tasks where case_id=:case_id and state in ('started', 'enabled')"]
	switch [llength $tasks] {
	    0 { ad_return_complaint 1 "Didn't find task for project \#$answer_id" }
	    1 {
		set task_id [lindex $tasks 0]
	    }
	    default {
		ad_return_complaint 1 "Found more then one task for project \#$answer_id"
	    }
	}
    }

    if {[catch {
	array set task [wf_task_info $task_id]
    } err_msg]} {
                ad_return_complaint 1 "<li><b>Task \#$task_id nicht gefunden</b>:<p>
			Dieser Fehler kann auftreten, wenn ein Administrator einen RFC
			'hart' gel&ouml;scht hat. Im normalen Betrieb sollte das nicht
			passieren.<p>
			Bitte kontaktieren Sie Ihren System Administrator.<p>
		"
		return
    }


    set transition_key [db_string transition_key "select transition_key from wf_tasks where task_id = :task_id" -default ""]
    set case_id [db_string case_id "select case_id from wf_tasks where task_id = :task_id" -default 0]
    set enable_master_p 1
    set page_title [lang::message::lookup "" intranet-freelance-rfqs.Edit_RFC "Edit RFC"]
    set context_bar [im_context_bar [list /intranet-freelance-rfqs/panels/ "[lang::message::lookup "" intranet-freelance-rfqs.RFCs "RFCs"]"] $page_title]
    set task_header "
        <tr bgcolor=\"\#9bbad6\">
        <th colspan=1><big>$task(task_name)</big></th>
        </tr>
    "
}

set current_url [im_url_with_query]
set action_url "/intranet-freelance-rfqs/panels/rfa-freelance-panel"
if {![exists_and_not_null return_url]} { set return_url [im_url_with_query] }

set rfq_id [db_string pid "select answer_rfq_id from im_freelance_rfq_answers where answer_id = :answer_id" -default ""]

# ------------------------------------------------------
# 
# ------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set subsite_id [ad_conn subsite_id]
set reassign_perm_p [permission::permission_p -party_id $current_user_id -object_id $subsite_id -privilege "wf_reassign_tasks"]
set task(add_assignee_url) "/workflow/assignee-add?[export_url_vars task_id]"
set task(assign_yourself_url) "/workflow/assign-yourself?[export_vars -url {task_id return_url}]"

# -----------------------------------------------------------
# Options
# -----------------------------------------------------------

set customer_options "[list [list "[_ intranet-core.--_Please_select_--]" ""]]"
set customer_list_options [concat $customer_options [im_company_options -include_empty 0 -status "Active" -type "CustOrIntl"]]

set project_lead_options "[list [list "[_ intranet-core.--_Please_select_--]" ""]]"
set project_lead_list_options [concat $project_lead_options [im_employee_options 0]]


# -----------------------------------------------------------
# Get everything about the RFQ
# -----------------------------------------------------------

db_1row rfq_info "
	select	*,
		to_char(rfq_end_date, 'HH24:MI') as rfq_end_time
	from	im_freelance_rfqs
	where	rfq_id = :rfq_id
"


# -----------------------------------------------------------
# Create the Form with RFA information
# -----------------------------------------------------------


set form_id "rfa-form"

template::form::create $form_id
template::form::section $form_id ""

template::element::create $form_id rfq_id -widget "hidden"
template::element::create $form_id answer_id -widget "hidden"
template::element::create $form_id return_url -widget "hidden" -optional -datatype text
template::element::create $form_id task_id -widget "hidden" -optional -datatype text

template::element::create $form_id rfq_name \
    -datatype text\
    -label "[lang::message::lookup "" intranet-freelance-rfqs.RFQ_Name "RFQ Name"]" \
    -html {size 60} \
    -mode display
template::element::create $form_id rfq_start_date \
    -label "[lang::message::lookup "" intranet-freelance-rfqs.RFQ_Start_Date {RFQ Start Date}]" \
    -datatype "date" \
    -widget "date" \
    -mode "display"
template::element::create $form_id rfq_end_date \
    -label "[lang::message::lookup "" intranet-freelance-rfqs.RFQ_End_Date {RFQ End Date}]" \
    -datatype "date" \
    -widget "date" \
    -mode "display"


im_dynfield::append_attributes_to_form \
    -object_type "im_freelance_rfq" \
    -form_id $form_id \
    -object_id $rfq_id \
    -form_display_mode "display"

set ttt {    -object_subtype_id $rfq_type_id  }


# ------------------------------------------------------
# Show Input Fields
# ------------------------------------------------------




# This line forces the "column-sections" form-template
# to create a new column for the right-hand action section.

template::form::section $form_id "Action Section"

# ------------------------------------------------------
#  Add a comment field statically on the "right side"
# ------------------------------------------------------

# Show basic comment field before buttons
template::element::create $form_id wf_comment \
    -optional \
    -datatype text \
    -widget textarea \
    -label "[lang::message::lookup "" intranet-freelance-rfqs.Comment {Comment}]" \
    -html {rows 5 cols 35}


# ------------------------------------------------------
# 
# ------------------------------------------------------

template::element::set_value $form_id rfq_id $rfq_id
template::element::set_value $form_id answer_id $answer_id
template::element::set_value $form_id return_url $return_url
template::element::set_value $form_id task_id $task_id
template::element::set_value $form_id rfq_name $rfq_name
set rfq_start_date_list [split $rfq_start_date "-"]
template::element::set_value $form_id rfq_start_date $rfq_start_date_list
set rfq_end_date_list [concat [split $rfq_end_date "-"] [split $rfq_end_time ":"]]
template::element::set_value $form_id rfq_end_date $rfq_end_date_list


# -----------------------------------------------------------------
# Which buttons to display?
# -----------------------------------------------------------------


set button_list [list \
	 [list "Save" ok_finish] \
]


template::form::set_properties $form_id edit_buttons $button_list 
template::form::set_properties $form_id action $action_url


# -----------------------------------------------------------------
# Deal with the "Cancel" button, even if the form isn't valid
# -----------------------------------------------------------------

set button_id [template::form::get_button $form_id]

if {"ok_nuke" == $button_id} {
    if {[info exists task_id] && "" != $task_id} {
	ad_returnredirect [export_vars -base "rfc-nuke" {answer_id task_id return_url}]
	return
    }
}

if {"ok_cancel" == $button_id} {
    if {[info exists task_id] && "" != $task_id} {

	ad_returnredirect [export_vars -base "rfc-delete" {answer_id task_id return_url}]
	return
    }
}

 
# -----------------------------------------------------------------
# 
# -----------------------------------------------------------------

if {0 && [form is_submission $form_id]} {

    set n_error 0
    # check that no variable contains double or single quotes
    if {[var_contains_quotes $rfq_name]} { 
	template::element::set_error $form_id project_name "[_ intranet-core.lt_Quotes_in_Project_Nam]"
	incr n_error
    }

    if {$n_error >0} { return }
 
}

# -----------------------------------------------------------------
# 
# -----------------------------------------------------------------

if {[form is_valid $form_id]} {

    ns_log Notice "rfa-freelance-panel: form is_valid"

    set rfq_start_date_sql [template::util::date get_property sql_date $rfq_start_date]
    set rfq_end_date_sql [template::util::date get_property sql_timestamp $rfq_end_date]

    db_dml update_answer "
	update im_freelance_rfq_answers set
		amount = :amount
	where answer_id = :answer_id
    "
    ad_returnredirect $return_url
}

