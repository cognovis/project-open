# /packages/intranet-cognovis/tasks/task-ae.tcl
#
# Copyright (c) 2003-2008 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    @param form_mode edit or display
    @author frank.bergmann@project-open.com
} {
    ticket_id:integer,optional
    {project_name "" }
    {project_nr "" }
    {parent_id "" }
    {ticket_customer_contact_id "" }
    {ticket_status_id ""}
    {ticket_type_id "" }
    {view_name ""}
    {escalate_from_ticket_id 0}
    {return_url ""}
}

# ----------------------------------------------                                                                                                            
# Page Title                                                                                                                                                
set page_title [lang::message::lookup "" intranet-helpdesk.New_Ticket "New Ticket"]
if {[exists_and_not_null ticket_id]} {
    set page_title [db_string title "select project_name from im_projects where project_id = :ticket_id" -default ""]
}
set focus "ticket.project_name"
set context [list $page_title]



# ------------------------------------------------------------------
# Default & Security
# ------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
if {"" == $return_url} { set return_url [im_url_with_query] }
set current_url [ad_conn url]
set current_user_id $user_id


set create_ticket_p [im_permission $current_user_id add_tickets_for_customers]

# Check if we can get the ticket_customer_id.                                                                                                                
# We need this field in order to limit the customer contacts to show.                                                                                        
if {![exists_and_not_null ticket_customer_id] && [exists_and_not_null parent_id] && "new" != $parent_id} {
    set ticket_customer_id [db_string cid "select company_id from im_projects where project_id = :parent_id" -default ""]
}

ad_form \
    -name ticket \
    -cancel_url $return_url \
    -action ticket-ae \
    -export {next_url user_id return_url} \
    -form {
	ticket_id:key
    }


# Add DynFields to the form
set dynfield_ticket_type_id [im_opt_val ticket_type_id]

set dynfield_ticket_id ""
if {[info exists ticket_id]} { 
    set dynfield_ticket_id $ticket_id 
    set existing_ticket_type_id [db_string ptype "select ticket_type_id from im_tickets where ticket_id = :ticket_id" -default 0]
    if {0 != $existing_ticket_type_id && "" != $existing_ticket_type_id} {
	set dynfield_ticket_type_id $existing_ticket_type_id
    }
}

im_dynfield::append_attributes_to_form \
    -object_type "im_ticket" \
    -form_id ticket \
    -object_id $dynfield_ticket_id \
    -object_subtype_id $dynfield_ticket_type_id


ad_form -extend -name ticket -edit_request {
	set page_title "[_ intranet-core.Edit_project]"
	set context_bar [im_context_bar [list /intranet/projects/ "[_ intranet-core.Projects]"] [list "/intranet/projects/view?[export_url_vars project_id]" "One project"] $page_title]
	
	set button_text "[_ intranet-core.Save_Changes]"
	

} -new_request {
    # ------------------------------------------------------------------
    # Redirect if ticket_type_id or parent_id are missing
    # ------------------------------------------------------------------
    
    set redirect_p 0
    # redirect if ticket_type_id is not defined
    if {("" == $ticket_type_id || 0 == $ticket_type_id) && ![exists_and_not_null ticket_id]} {
	set all_same_p [im_dynfield::subtype_have_same_attributes_p -object_type "im_ticket"]
	set all_same_p 0
	if {!$all_same_p} { set redirect_p 1 }
    }
    
    # Redirect if the SLA hasn't been defined yet
    if {("" == $parent_id || 0 == $parent_id) && ![exists_and_not_null ticket_id]} { set redirect_p 1 }
    
    if {$redirect_p} {
	ad_returnredirect [export_vars -base "/intranet-cognovis/tickets/new-typeselect" {{return_url $current_url} ticket_id ticket_type_id project_name project_nr ticket_status_id parent_id}]
    }
    
    
} -new_data {
    
    # Populate elements from local variables
    if {![exists_and_not_null project_nr]} {
	set project_nr [im_ticket::next_ticket_nr] 
    }
    if {![exists_and_not_null project_name]} {
	set project_name [lang::message::lookup "" intranet-helpdesk.Default_Ticket_Name "Ticket \#%project_nr%"]
    }

    if {[info exists start_date]} {set start_date [template::util::date get_property sql_date $start_date]}
    if {[info exists end_date]} {set end_date [template::util::date get_property sql_timestamp $end_date]}
    
    set project_nr [string trim [string tolower $project_nr]]

    # We need to make sure that we check permissions first.
    set message ""
    if {[info exists ticket_note]} { append message $ticket_note }
    if {[info exists ticket_description]} { append message $ticket_description }

    set ticket_id [im_ticket::new \
                       -ticket_sla_id $parent_id \
                       -ticket_name $project_name \
                       -ticket_nr $project_nr \
                       -ticket_customer_contact_id $ticket_customer_contact_id \
                       -ticket_type_id $ticket_type_id \
                       -ticket_status_id $ticket_status_id \
                       -no_audit \
                       -no_notification \
    ]


    im_dynfield::attribute_store \
	-object_type "im_ticket" \
	-object_id $ticket_id \
	-form_id ticket
    

    if {[info exists escalate_from_ticket_id] && 0 != $escalate_from_ticket_id} {
	
	# Add an escalation relationship between the two tickets
	db_string add_ticket_ticket_rel "
                        select im_ticket_ticket_rel__new (
                                null,
                                'im_ticket_ticket_rel',
                                :ticket_id,
                                :escalate_from_ticket_id,
                                null,
                                :current_user_id,
                                '[ad_conn peeraddr]',
                                0
                        )
       "
	
    }   
    
    # Write Audit Trail
    im_project_audit -object_type "im_ticket" -project_id $ticket_id -action create

    notification::new \
        -type_id [notification::type::get_type_id -short_name ticket_notif] \
        -object_id $ticket_id \
        -response_id "" \
        -notif_subject $project_name \
        -notif_text $message

} -edit_data {

    if {[info exists start_date]} {set start_date [template::util::date get_property sql_date $start_date]}
    if {[info exists end_date]} {set end_date [template::util::date get_property sql_timestamp $end_date]}
    

    im_dynfield::attribute_store \
	-object_type "im_ticket" \
	-object_id $ticket_id \
	-form_id ticket

    # Write Audit Trail
    im_project_audit -object_type "im_ticket" -project_id $ticket_id -action update

    notification::new \
        -type_id [notification::type::get_type_id -short_name ticket_notif] \
        -object_id $ticket_id \
        -response_id "" \
        -notif_subject "Edit: Subject" \
        -notif_text "Text"

} -on_submit {

} -after_submit {


    ad_returnredirect [export_vars -base "/intranet-cognovis/tickets/view" {ticket_id}]
    ad_script_abort
    
}

# ---------------------------------------------------------------
# Project Menu
# ---------------------------------------------------------------

# Setup the subnavbar
if {[info exists ticket_id]} {
    set parent_id [db_string select_parent_id { SELECT parent_id FROM im_projects WHERE project_id = :ticket_id } -default ""]
} else {
    set parent_id ""
}

set bind_vars [ns_set create]
ns_set put $bind_vars project_id $parent_id
set project_menu_id [db_string parent_menu "select menu_id from im_menus where label='project'" -default 0]
set sub_navbar [im_sub_navbar \
    -components \
    -base_url "/intranet/projects/view?project_id=$parent_id" \
    $project_menu_id \
    $bind_vars "" "pagedesriptionbar" "project_timesheet_task"] 


