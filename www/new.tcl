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
set today [db_string birthday_today "select to_char(sysdate,'YYYY-MM-DD') from dual"]
set date_format "YYYY-MM-DD"
set end_century "2099-12-31"
set internal_id [im_company_internal]

if {![im_permission $user_id view_users]} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

set action_url "/intranet-hr/new"
set focus "cost.var_name"
set employee_name ""

set form_mode "edit"

if {[info exists employee_id]} {
    set employee_name [db_string employee_name "select im_name_from_user_id(:employee_id) from dual"]
    ns_log Notice "/intranet-hr/new/: employee_id=$employee_id"
} else {
    ns_log Notice "/intranet-hr/new/: employee_id doesn't exist"
}

set page_title "Employee Information of $employee_name"
set context [ad_context_bar $page_title]


# ------------------------------------------------------------------
# Insert default information if the record doesn't exist
# ------------------------------------------------------------------

set availability "100"
set birthdate $today
set currency [ad_parameter -package_id [im_package_cost_id] "DefaultCurrency" "" "EUR"]

set exists_p [db_string exists_employee "select count(*) from im_employees where employee_id=:employee_id"]
if {!$exists_p} {
    db_dml insert_employee_record "
	insert into im_employees (
	employee_id,
	availability,
	currency,
	employee_status_id
    ) values (
	:employee_id,
	100,
	:currency,
	[im_employee_status_active]
    )"
}

# im_repeating_costs (and it's im_costs superclass) superclass
# im_costs contains a "cause_object_id" field pointing to employee_id.
# The join between im_costs and im_repeating_costs is necessary
# in order to elimiate all the non-repeating cost items.
set rep_cost_id [db_string rep_costs_exist "
	select	rc.rep_cost_id
	from	im_repeating_costs rc,
		im_costs ci
	where 	rc.rep_cost_id = ci.cost_id
		and ci.cause_object_id = :employee_id
" -default 0]

if {!$rep_cost_id} {
    if [catch {
	set rep_cost_id [im_cost::new -cost_name $employee_id -cost_type_id [im_cost_type_repeating]]
	
	db_dml update_costs "
		update im_costs set
			cause_object_id = :employee_id
		where
			cost_id = :rep_cost_id
	"

	db_dml insert_repeating_costs "
		insert into im_repeating_costs (
			rep_cost_id,
			start_date,
			end_date
		) values (
			:rep_cost_id,
			to_date(:today,:date_format),
			to_date(:today,:date_format)
		)
	    "
    } err_msg] {
	ad_return_complaint 1 "<li>Error creating a new repeating cost 
	item for employee \#$employee_id:<br>
	<pre>$err_msg</pre>"
    }
}


# ------------------------------------------------------------------
# Build the form
# ------------------------------------------------------------------

set currency_options [im_currency_options]
set department_options [im_department_options]



set supervisor_options [db_list_of_lists supervisor_options "
	select 
		'No Supervisor (CEO)' as user_name, 
		0 as user_id 
	from dual
    UNION
	select 
		im_name_from_user_id(u.user_id) as user_name,
		u.user_id
	from 
		users u,
		group_distinct_member_map m
	where 
		m.member_id = u.user_id
		and m.group_id = [im_employee_group_id]
"]

set salary_interval_options {{Month month} {Day day} {Week week} {Year year}}

set employee_status_options [db_list_of_lists employee_status_options "
select state, state_id
from im_employee_pipeline_states
"]


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
	{social_security:text(text),optional {label "Monthly Social Security"} {html {size 10}} }
	{insurance:text(text),optional {label "Monthly Insurance"} {html {size 10}} }
	{other_costs:text(text),optional {label "Monthly Others"} {html {size 10}} }
	{currency:text(select),optional {label "Currency"} {options $currency_options} }
	{salary_payments_per_year:text(text),optional {label "Salary Payments per Year"} {html {size 10}} }

	{birthdate:text(text),optional {label "Birthdate"} {html {size 10}} }
	{job_title:text(text),optional {label "Job Title"} {html {size 30}} }
	{job_description:text(textarea),nospell,optional {label "Job Description"} {html {rows 5 cols 40}}}

	{start_date:text(text),optional {label "Start date"} {html {size 10}} }
	{end_date:text(text),optional {label "End date"} {html {size 10}} }

	{voluntary_termination_p:text(radio),optional {label "Voluntary Termination"} {options $voluntary_termination_options} }
	{termination_reason:text(textarea),nospell,optional {label "Termination Reason"} {html {rows 5 cols 40}}}
	{signed_nda_p:text(radio),optional {label "NDA Signed?"} {options $voluntary_termination_options} }

	{dependant_p:text(hidden),optional }
	{only_job_p:text(hidden),optional }
	{married_p:text(hidden),optional }
	{dependants:text(hidden),optional }
	{head_of_household_p:text(hidden),optional }
	{skills:text(hidden),optional }
	{first_experience:text(hidden),optional }
	{years_experience:text(hidden),optional }
	{referred_by:text(hidden),optional }
	{experience_id:text(hidden),optional }
	{source_id:text(hidden),optional }
	{original_job_id:text(hidden),optional }
	{current_job_id:text(hidden),optional }
	{qualification_id:text(hidden),optional }
    }


ad_form -extend -name cost -on_request {
    # Populate elements from local variables

} -select_query {

	select	
		e.*,
                CASE	WHEN rc.start_date is null
                        THEN to_date(:today,:date_format)
                        ELSE to_date(to_char(rc.start_date,:date_format),:date_format)
                END as start_date,
                CASE	WHEN rc.end_date is null
                        THEN to_date(:end_century,:date_format)
                        ELSE to_date(to_char(rc.end_date,:date_format),:date_format)
                END as end_date,
		ci.*
	from	parties p,
		im_employees e,
		im_repeating_costs rc,
		im_costs ci
	where	
		p.party_id = :employee_id
		and p.party_id = e.employee_id
		and p.party_id = ci.cause_object_id
		and ci.cost_id = rc.rep_cost_id

} -after_submit {

    set cost_name $employee_name

    if {"" == $salary} { set salary 0 }
    if {"" == $social_security} { set social_security 0 }
    if {"" == $other_costs} { set other_costs 0 }
    if {"" == $salary} { set salary 0 }
    if {"" == $insurance} { set insurance 0 }
    if {0 == $supervisor_id} { set supervisor_id "" }
    if {"" == $salary_payments_per_year} { set salary_payments_per_year 12 }
    if {![exists_and_not_null tax]} { set tax 0 }
    if {![exists_and_not_null vat]} { set vat 0 }

    db_dml employee_update "
	update im_employees set
		employee_id = :employee_id,
		department_id = :department_id,
		job_title = :job_title,
		job_description = :job_description,
		availability = :availability,
		supervisor_id = :supervisor_id,
		ss_number = :ss_number,
		salary = :salary,
		social_security = :social_security,
		insurance = :insurance,
		other_costs = :other_costs,
		currency = :currency,
		salary_payments_per_year = :salary_payments_per_year,
		dependant_p = :dependant_p,
		only_job_p = :only_job_p,
		married_p = :married_p,
		dependants = :dependants,
		head_of_household_p = :head_of_household_p,
		birthdate = :birthdate,
		skills = :skills,
		first_experience = :first_experience,
		years_experience = :years_experience,
		employee_status_id = :employee_status_id,
		termination_reason = :termination_reason,
		voluntary_termination_p = :voluntary_termination_p,
		signed_nda_p = :signed_nda_p,
		referred_by = :referred_by,
		experience_id = :experience_id,
		source_id = :source_id,
		original_job_id = :original_job_id,
		current_job_id = :current_job_id,
		qualification_id = :qualification_id
	where
		employee_id = :employee_id
"

    if [catch { 
	db_dml update_costs "
	update im_costs set
		cost_name = :employee_name,
		cost_center_id = :department_id,
		customer_id = :internal_id,
		provider_id = :internal_id,
		cost_type_id = [im_cost_type_employee],
		cost_status_id = [im_cost_status_created],
		cause_object_id = :employee_id,
		amount = (
			cast(:salary as float) + 
			cast(:social_security as float) + 
			cast(:insurance as float) + 
			cast(:other_costs as float)
			) * :salary_payments_per_year / 12,
		currency = :currency,
		tax = :tax,
		vat = :vat
	where
		cost_id	= :rep_cost_id
	"

	db_dml insert_repeating_costs "
	update im_repeating_costs set
		start_date = :start_date,
		end_date = :end_date
	where
		rep_cost_id = :rep_cost_id
	"
	 } err_msg] {
	    ad_return_complaint 1 "<li>Error inserting employee cost information:<BR>
            <pre>$err_msg</pre>"
	}

	ad_returnredirect $return_url
	ad_script_abort
}

