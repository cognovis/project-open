# /packages/intranet-helpdesk/www/new.tcl
#
# Copyright (c) 2003-2008 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    @author frank.bergmann@project-open.com
} {
    ticket_id:integer,optional
    { return_url "" }
    edit_p:optional
    message:optional
    { form_mode "display" }
    { ticket_status_id "[im_ticket_status_open]" }
    { return_url "[im_url_with_query]" }
}


# ------------------------------------------------------------------
# Default & Security
# ------------------------------------------------------------------

set currrent_user_id [ad_maybe_redirect_for_registration]
set action_url "/intranet-helpdesk/new"
set focus "ticket.var_name"
set page_title [lang::message::lookup "" intranet-helpdesk.New_Ticket "New Ticket"]
set context [list $page_title]
if {![info exists ticket_id]} { set form_mode "edit" }


# ------------------------------------------------------------------
# Delete?
# ------------------------------------------------------------------

set button_pressed [template::form get_action ticket]
if {"delete" == $button_pressed} {
    db_exec_plsql ticket_delete {}
    ad_returnredirect $return_url
}


# ------------------------------------------------------------------
# Action - Who is allowed to do what?
# ------------------------------------------------------------------

set actions [list]
set actions [list {"Edit" edit} ]


if {[im_permission $currrent_user_id add_tickets]} {
    lappend actions {"Delete" delete}
}


# ------------------------------------------------------------------
# Build the form
# ------------------------------------------------------------------

set customer_options [im_company_options -type "Customer"]

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
	{ticket_name:text(text) {label "[lang::message::lookup {} intranet-helpdesk.Name Name]"} {html {size 50}}}
        {ticket_status_id:text(im_category_tree) {label "[lang::message::lookup {} intranet-helpdesk.Status Status]"} {custom {category_type "Intranet Ticket Status"}}}
        {ticket_type_id:text(im_category_tree) {label "[lang::message::lookup {} intranet-helpdesk.Type Type]"} {custom {category_type "Intranet Ticket Type"}}}
        {ticket_customer_id:text(select) {label "[lang::message::lookup {} intranet-helpdesk.Customer Customer]"} {options $customer_options}}
    }


if {![info exists ticket_type_id]} { set ticket_type_id ""}
set dynfield_ticket_id ""
if {[info exists ticket_id]} { set dynfield_ticket_id $ticket_id}
 set field_cnt [im_dynfield::append_attributes_to_form \
                       -form_display_mode $form_mode \
                       -object_subtype_id $ticket_type_id \
                       -object_type "im_ticket" \
                       -form_id "ticket" \
                       -object_id $dynfield_ticket_id \
]



# Fix for problem changing to "edit" form_mode
set form_action [template::form::get_action "ticket"]
if {"" != $form_action} { set form_mode "edit" }

ad_form -extend -name ticket -on_request {
    # Populate elements from local variables

} -select_query {

	select	t.*,
		p.*
	from	im_projects p,
		im_tickets t
	where	p.project_id = t.ticket_id and
		t.ticket_id = :ticket_id

} -new_data {

    set ticket_nr [db_nextval im_ticket_seq]
    set start_date [db_string now "select now()::date from dual"]
    set end_date [db_string now "select (now()::date)+1 from dual"]
    set start_date_sql [template::util::date get_property sql_date $start_date]
    set end_date_sql [template::util::date get_property sql_timestamp $end_date]

    db_transaction {
	db_string ticket_insert {}
	db_dml ticket_update {}
	db_dml project_update {}

	# Write Audit Trail
	im_project_audit $ticket_id
    } on_error {
	ad_return_complaint 1 "<b>Error inserting new ticket</b>:
	<pre>$errmsg</pre>"
    }

} -edit_data {

    set ticket_nr [string tolower $ticket_nr]
    set start_date_sql [template::util::date get_property sql_date $start_date]
    set end_date_sql [template::util::date get_property sql_timestamp $end_date]

    db_dml ticket_update {}
    db_dml project_update {}

    # Write Audit Trail
    im_project_audit $ticket_id

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
# Project Menu
# ---------------------------------------------------------------

# Setup the subnavbar
set bind_vars [ns_set create]

if {[info exists ticket_id]} {
    ns_set put $bind_vars ticket_id $ticket_id
}

set project_menu_id [db_string parent_menu "select menu_id from im_menus where label='project'" -default 0]
set sub_navbar [im_sub_navbar \
    -components \
    -base_url "/intranet-helpdesk/" \
    $project_menu_id \
    $bind_vars "" "pagedesriptionbar" "project_timesheet_ticket"] 


