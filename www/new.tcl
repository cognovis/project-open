# /packages/intranet-hr/www/new.tcl
#
# Copyright (C) 2003-2004 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Create a new dynamic value or edit an existing one.

    @param form_mode edit or display

    @author frank.bergmann@project-open.com
} {
    { employee_id:integer,optional }
    { return_url "/intranet-hr/index"}
    edit_p:optional
    message:optional
    { form_mode "display" }
}


# ------------------------------------------------------------------
# Default & Security
# ------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set page_title "Edit Employee Information"
set context [ad_context_bar $page_title]

if {![im_permission $user_id view_users]} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

set action_url "/intranet-hr/new"
set focus "cost.var_name"

# ------------------------------------------------------------------
# Get everything about the employee
# ------------------------------------------------------------------

if {![exists_and_not_null item_id]} {
    # New variable: setup some reasonable defaults

    set form_mode "edit"
}

# ------------------------------------------------------------------
# Build the form
# ------------------------------------------------------------------

set availability "100"
set birthdate [db_string birthday_today "select sysdate from dual"]

set department_options [db_list_of_lists department_options "
	select cost_center_name, cost_center_id
	from im_cost_centers
	where department_p = 't'
"]


set supervisor_options [db_list_of_lists supervisor_options "
	select 
		im_name_from_user_id(u.user_id),
		u.user_id
	from 
		users u,
		group_distinct_member_map m
	where 
		m.member_id = u.user_id
		and m.group_id = [im_employee_group_id]
"]

set salary_interval_options {{Month month} {Day day} {Week week} {Year year}}

set employee_status_options {{Employee 1} {Fired 2}}

set voluntary_termination_options {{Yes t} {No f}}

ad_form \
    -name cost \
    -cancel_url $return_url \
    -action $action_url \
    -mode $form_mode \
    -export {next_url user_id return_url} \
    -form {
	employee_id:key
	{department_id:text(select) {label "Department"} {options $department_options} }
	{supervisor_id:text(select) {label "Supervisor"} {options $supervisor_options} }
        {availability:text(text) {label "Availability %"} {html {size 6}} }
	{employee_status_id:text(select) {label "Employee Status"} {options $employee_status_options} }
	{ss_number:text(text),optional {label "Social Security #"} {html {size 20}} }
	{salary:text(text),optional {label "Monthly Salary"} {html {size 10}} }
	{salary_payments_per_year:text(text),optional {label "Salary Payments per Year"} {html {size 10}} }

	{birthdate:text(text),optional {label "Birthdate"} {html {size 10}} }
	{job_title:text(text),optional {label "Job Title"} {html {size 30}} }
	{job_description:text(textarea),nospell,optional {label "Job Description"} {html {rows 5 cols 40}}}

	{start_date:text(text),optional {label "Start date"} {html {size 10}} }
	{termination_date:text(text),optional {label "End date date"} {html {size 10}} }
	{voluntary_termination_p:text(radio),optional {label "Voluntary Termination"} {options $voluntary_termination_options} }
	{termination_reason:text(textarea),nospell,optional {label "Termination Reason"} {html {rows 5 cols 40}}}
	{signed_nda_p:text(radio),optional {label "NDA Signed?"} {options $voluntary_termination_options} }
    }


ad_form -extend -name cost -on_request {
    # Populate elements from local variables

} -select_query {

	select	
		e.*
	from	parties p,
		im_employees e
	where	
		p.party_id = :employee_id
		and p.party_id = e.employee_id(+)

} -new_data {

    db_dml cost_insert "
declare
	v_item_id	integer;
begin
        v_item_id := im_cost_item.new (
                item_id         => :item_id,
                creation_user   => :user_id,
                creation_ip     => '[ad_conn peeraddr]',
                item_name       => :item_name,
		project_id	=> :project_id,
                customer_id     => :customer_id,
                provider_id     => :provider_id,
                item_status_id  => :item_status_id,
                item_type_id    => :item_type_id,
                template_id     => :template_id,
                effective_date  => :effective_date,
                payment_days    => :payment_days,
		amount		=> :amount,
                currency        => :currency,
                vat             => :vat,
                tax             => :tax,
                description     => :description,
                note            => :note
        );
end;"

} -edit_data {

    db_dml cost_update "
	update  im_cost_items set
                item_name       = :item_name,
		project_id	= :project_id,
                customer_id     = :customer_id,
                provider_id     = :provider_id,
                item_status_id  = :item_status_id,
                item_type_id    = :item_type_id,
                template_id     = :template_id,
                effective_date  = :effective_date,
                payment_days    = :payment_days,
		amount		= :amount,
                currency        = :currency,
                vat             = :vat,
                tax             = :tax,
                description     = :description,
                note            = :note
	where
		item_id = :item_id
"
} -on_submit {

	ns_log Notice "new1: on_submit"


} -after_submit {

	ad_returnredirect $return_url
	ad_script_abort
}

