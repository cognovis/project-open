# /packages/intranet-helpdesk/www/quote.tcl
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
	ticket_id:integer,optional
	{ ticket_name "" }
	{ ticket_nr "" }
	{ ticket_sla_id "" }
	{ ticket_customer_contact_id "" }
	{ task_id "" }
	{ return_url "" }
	edit_p:optional
	message:optional
	{ ticket_type_id "" }
	{ return_url "/intranet-helpdesk/" }
	{ vars_from_url ""}
	{ plugin_id:integer "" }
	{ view_name "standard"}
	{ form_mode "display" }
    }

    set show_components_p 1
    set enable_master_p 1

} else {

    set form_mode "display"
    set task_id $task(task_id)
    set case_id $task(case_id)

    set vars_from_url ""
    set return_url [im_url_with_query]

    set ticket_id [db_string pid "select object_id from wf_cases where case_id = :case_id" -default ""]
    set transition_key [db_string transition_key "select transition_key from wf_tasks where task_id = :task_id"]
    set task_page_url [export_vars -base [ns_conn url] { ticket_id task_id return_url}]

    set show_components_p 0
    set enable_master_p 0
    set ticket_type_id ""
    set ticket_sla_id ""
    set ticket_customer_contact_id ""

    set plugin_id ""
    set view_name "standard"

    # Don't show this page in WF panel.
    ad_returnredirect "/intranet-helpdesk/quote?ticket_id=$task(object_id)"

}

# ------------------------------------------------------------------
# Default & Security
# ------------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set current_url [im_url_with_query]
set action_url "/intranet-helpdesk/new"
set focus "ticket.var_name"

if {[info exists ticket_id] && "" == $ticket_id} { unset ticket_id }

# Can the currrent user create new helpdesk customers?
set user_can_create_new_customer_p 1
set user_can_create_new_customer_sla_p 1
set user_can_create_new_customer_contact_p 1

set ticket_name [db_string title "select project_name from im_projects where project_id = :ticket_id" -default ""]
set page_title [lang::message::lookup "" intranet-helpdesk.Ticket_Quote "Quote for ticket %ticket_name%"]
set context [list $page_title]

# ----------------------------------------------
# Get everything about the ticket
# ----------------------------------------------

db_1row ticket_info "
	select	t.*, p.*,
		p.company_id as ticket_customer_id
	from	im_projects p,
		im_tickets t
	where	p.project_id = t.ticket_id
		and p.project_id = :ticket_id
"

# ---------------------------------------------
# The form
# ---------------------------------------------

set title_label [lang::message::lookup {} intranet-helpdesk.Name {Title}]
set title_help [lang::message::lookup {} intranet-helpdesk.Title_Help {Please enter a descriptive name for the new ticket.}]

set actions {}
if {[im_permission $current_user_id add_tickets_for_customer]} { lappend actions {"Edit" edit} }
if {[im_permission $current_user_id add_tickets_for_customer]} { lappend actions {"Delete" delete} }

ad_form \
    -name ticket \
    -cancel_url $return_url \
    -action $action_url \
    -actions $actions \
    -has_edit 1 \
    -mode $form_mode \
    -export {next_url return_url} \
    -form {
	ticket_id:key
	{ticket_name:text(text) {label $title_label} {html {size 50}} {help_text $title_help} }
	{ticket_nr:text(hidden),optional }
	{start_date:date(hidden),optional }
	{end_date:date(hidden),optional }
    }

# ------------------------------------------------------------------
# 
# ------------------------------------------------------------------

ad_form -extend -name ticket -on_request {

    # Populate elements from local variables

} -select_query {

	select	t.*,
		p.*,
		p.parent_id as ticket_sla_id,
		p.project_name as ticket_name,
		p.project_nr as ticket_nr,
		p.company_id as ticket_customer_id
	from	im_projects p,
		im_tickets t
	where	p.project_id = t.ticket_id and
		t.ticket_id = :ticket_id

} -new_data {

    # Create a new forum topic of type "Note"
    set topic_id [db_nextval im_forum_topics_seq]

    db_transaction {
	set ticket_nr [im_ticket::next_ticket_nr]
	set start_date [db_string now "select now()::date from dual"]
	set end_date [db_string now "select (now()::date)+1 from dual"]
	set start_date_sql [template::util::date get_property sql_date $start_date]
	set end_date_sql [template::util::date get_property sql_timestamp $end_date]
	
	set ticket_id [db_string ticket_insert {}]
	db_dml ticket_update {}
	db_dml project_update {}

	# Add the current user to the project
        im_biz_object_add_role $current_user_id $ticket_id [im_biz_object_role_project_manager]
	
	# Start a new workflow case
	im_workflow_start_wf -object_id $ticket_id -object_type_id $ticket_type_id -skip_first_transition_p 1
	
	# Write Audit Trail
	im_project_audit -project_id $ticket_id
	

	# Create a new forum topic of type "Note"
	set topic_type_id [im_topic_type_id_task]
	set topic_status_id [im_topic_status_id_open]
	set message ""

	if {[info exists ticket_note]} { append message $ticket_note }
	if {[info exists ticket_description]} { append message $ticket_description }
	if {"" == $message} { set message [lang::message::lookup "" intranet-helpdesk.Empty_Forum_Message "No message specified"]}

	db_dml topic_insert {
                insert into im_forum_topics (
                        topic_id, object_id, parent_id,
                        topic_type_id, topic_status_id, owner_id,
                        subject, message
                ) values (
                        :topic_id, :ticket_id, null,
                        :topic_type_id, :topic_status_id, :current_user_id,
                        :ticket_name, :message
                )
	}

	
	# Error handling. Doesn't work yet for some unknown reason
    } on_error {
	ad_return_complaint 1 "<b>Error inserting new ticket</b>:<br>&nbsp;<br>
	<pre>$errmsg</pre>"
    }


} -edit_data {

    set ticket_nr [string tolower $ticket_nr]
    if {"" == $ticket_nr} { set ticket_nr [im_ticket::next_ticket_nr] }
    set start_date_sql [template::util::date get_property sql_date $start_date]
    set end_date_sql [template::util::date get_property sql_timestamp $end_date]

    db_dml ticket_update {}
    db_dml project_update {}

    im_dynfield::attribute_store \
	-object_type "im_ticket" \
	-object_id $ticket_id \
	-form_id ticket

    # Write Audit Trail
    im_project_audit -project_id $ticket_id

} -on_submit {

	ns_log Notice "new: on_submit"

} -after_submit {

	ad_returnredirect $return_url
	ad_script_abort

} -validate {
    {ticket_name
	{ [string length $ticket_name] < 1000 }
	"[lang::message::lookup {} intranet-helpdesk.Ticket_name_too_long {Ticket Name too long (max 1000 characters).}]" 
    }
}

# ---------------------------------------------------------------
# Ticket Menu
# ---------------------------------------------------------------

# Setup the subnavbar
set bind_vars [ns_set create]
if {[info exists ticket_id]} { ns_set put $bind_vars ticket_id $ticket_id }


if {![info exists ticket_id]} { set ticket_id "" }

set ticket_menu_id [db_string parent_menu "select menu_id from im_menus where label='helpdesk'" -default 0]
set sub_navbar [im_sub_navbar \
    -components \
    -current_plugin_id $plugin_id \
    -base_url "/intranet-helpdesk/new?ticket_id=$ticket_id" \
    -plugin_url "/intranet-helpdesk/new" \
    $ticket_menu_id \
    $bind_vars "" "pagedesriptionbar" "helpdesk_summary"] 

