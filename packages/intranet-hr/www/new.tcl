# /packages/intranet-hr/www/new.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Create a new dynamic value or edit an existing one.

    @param form_mode edit or display

    @author frank.bergmann@project-open.com
} {
    employee_id:integer
    { return_url "/intranet-hr/index"}
    edit_p:optional
    message:optional
    { form_mode "display" }
    { availability:integer "100" }
    { hourly_cost:float "0" }
    { job_title "" }
    { job_description "" }
    { personnel_number "" }
    { ss_number "" }
    { salary:float "0" }
    { social_security:float "0" }
    { insurance:float "0" }
    { other_costs:float "0" }
    { birthdate "" }
    { salary_payments_per_year:integer "" }
    { years_experience:integer "" }
    { termination_reason "" }
    { referred_by "0" }
    { vacation_balance:float "0" }
    { vacation_days_per_year "" }
    { start_date "" }
    { end_date "" }
    { supervisor_id "" }
    { department_id "" }
    { dependant_p "" }
    { only_job_p "" }
    { married_p "" }
    { dependants ""}
    { head_of_household_p "" }
    { skills "" }
    { first_experience "" }
    { employee_status_id "" }
    { voluntary_termination_p "" }
    { signed_nda_p "" }
    { experience_id "" }
    { source_id "" }
    { original_job_id "" }
    { current_job_id "" }
    { qualification_id "" }
}

# ------------------------------------------------------------------
# Default & Security
# ------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set today [db_string birthday_today "select to_char(sysdate,'YYYY-MM-DD') from dual"]
set date_format "YYYY-MM-DD"
set end_century "2099-12-31"
set internal_id [im_company_internal]
set action_url "/intranet-hr/new"
set focus "cost.var_name"
set employee_name ""
set form_mode "edit"

im_user_permissions $user_id $employee_id view read write admin
if {!$write || ![im_permission $user_id view_hr]} {
    ad_return_complaint 1 "[_ intranet-hr.lt_You_have_insufficient]"
    return
}

set employee_name [db_string employee_name "select im_name_from_user_id(:employee_id) from dual"]
set page_title "[_ intranet-hr.lt_Employee_Information_]"
set context [im_context_bar $page_title]


# ------------------------------------------------------------------
# Insert default information if the record doesn't exist
# ------------------------------------------------------------------

set birthdate $today
set default_currency [ad_parameter -package_id [im_package_cost_id] "DefaultCurrency" "" "EUR"]
set currency $default_currency
set exists_p [db_string exists_employee "select count(*) from im_employees where employee_id=:employee_id"]

if {!$exists_p} {
    set availability "100"
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
set rep_cost_ids [db_list rep_costs_exist "
	select	rc.rep_cost_id
	from	im_repeating_costs rc,
		im_costs ci
	where 	rc.rep_cost_id = ci.cost_id
		and ci.cause_object_id = :employee_id
"]


if {[llength $rep_cost_ids] == 0} {
    if [catch {
		set rep_cost_id [im_cost::new -object_type "im_repeating_cost" -cost_name $employee_id -cost_type_id [im_cost_type_repeating]]
	
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
		ad_return_complaint 1 "<li>[_ intranet-hr.lt_Error_creating_a_new_]<br>
		<pre>$err_msg</pre>"
    }
}


# ------------------------------------------------------------------
# Build the form
# ------------------------------------------------------------------

set currency_options [im_currency_options]
set department_options [im_department_options]
set end_date $end_century

set supervisor_options [im_employee_options 1]
set salary_interval_options {{Month month} {Day day} {Week week} {Year year}}

set employee_status_options [db_list_of_lists employee_status_options "
	select state, state_id from im_employee_pipeline_states
"]


set voluntary_termination_options [list [list [_ intranet-hr.Yes] t] [list [_ intranet-hr.No] f]]

set department_label "[_ intranet-hr.Department]"
set supervisor_label "[_ intranet-hr.Supervisor]"
set availability_label "[_ intranet-hr.Availability_]"
set hourly_cost_label "[_ intranet-hr.Hourly_Cost]"
set employee_status_label "[_ intranet-hr.Employee_Status]"
set personnel_number_label "[_ intranet-hr.Personnel_Number]"
set ss_number_label "[_ intranet-hr.Social_Security_]"
set salary_label "[_ intranet-hr.Monthly_Salary]"
set social_security_label "[_ intranet-hr.lt_Monthly_Social_Securi]"
set insurance_label "[_ intranet-hr.Monthly_Insurance]"
set other_cost_label "[_ intranet-hr.Monthly_Others]"
set currency_label "[_ intranet-hr.Currency]"
set salary_payments_per_year_label "[_ intranet-hr.lt_Salary_Payments_per_Y]"
set birthdate_label "[_ intranet-hr.Birthdate]"
set job_title_label "[_ intranet-hr.Job_Title]"
set job_description_label "[_ intranet-hr.Job_Description]"
set start_date_label "[_ intranet-hr.Start_date]"
set end_date_label "[_ intranet-hr.End_date]"
set voluntary_termination_p_label "[_ intranet-hr.lt_Voluntary_Termination]"
set termination_reason_label "[_ intranet-hr.Termination_Reason]"
set signed_nda_p_label "[_ intranet-hr.NDA_Signed]"
set label_yes [lang::message::lookup "" intranet-core.Yes "Yes"]
set label_no [lang::message::lookup "" intranet-core.No "No"]

set vacation_days_per_year_label [lang::message::lookup "" intranet-hr.Vacation_Days_Per_Year "Vacation Days per Year"]
set vacation_balance_label [lang::message::lookup "" intranet-hr.Vacation_Balance "Vacation Balance"]


# -- ------------------------------------------------
# -- New form 
# -- ------------------------------------------------

set form_id "employee_information"

template::form::create $form_id
template::form::section $form_id ""
template::element::create $form_id department_id -label $department_label -widget "select"  -options $department_options
template::element::create $form_id supervisor_id -label $supervisor_label -widget "select"  -options $supervisor_options

template::element::create $form_id availability -optional -label $availability_label -html {size 6}
template::element::create $form_id hourly_cost -optional -label $hourly_cost_label -html {size 10} -datatype float
template::element::create $form_id employee_status_id -label $employee_status_label -widget "select"  -options $employee_status_options
template::element::create $form_id personnel_number -optional -label $personnel_number_label -html {size 10}
template::element::create $form_id ss_number -optional -label $ss_number_label -html {size 20}
template::element::create $form_id salary -optional -label $salary_label -html {size 10} -datatype float
template::element::create $form_id social_security -optional -label $social_security_label -html {size 10} -datatype float
template::element::create $form_id insurance -optional -label $insurance_label -html {size 10} -datatype float
template::element::create $form_id other_costs -optional -label $other_cost_label -html {size 10} -datatype float
template::element::create $form_id salary_payments_per_year -optional -label $salary_payments_per_year_label -html {size 10}
template::element::create $form_id birthdate -optional -label $birthdate_label -html {size 10} -datatype date
template::element::create $form_id job_title -optional -label $job_title_label -html {size 30} -datatype text
template::element::create $form_id job_description -optional -datatype text -widget textarea -label $job_description_label -html {rows 5 cols 40}
template::element::create $form_id start_date -optional -label $start_date_label -html {size 10} -datatype date
template::element::create $form_id end_date -optional -label $end_date_label -html {size 10} -datatype date
template::element::create $form_id voluntary_termination_p -label $voluntary_termination_p_label -widget "select"  -options $voluntary_termination_options -datatype text
template::element::create $form_id termination_reason -optional -datatype text -widget textarea -label $termination_reason_label -html {rows 5 cols 40}
template::element::create $form_id signed_nda_p -optional -datatype text -widget radio -label $signed_nda_p_label -options {{Yes t} {No f}}
template::element::create $form_id vacation_days_per_year -optional -label $vacation_days_per_year_label -html {size 5} -datatype float
template::element::create $form_id vacation_balance -optional -label $vacation_balance_label -html {size 5} -datatype float

template::element::create $form_id dependant_p -optional -widget "hidden"
template::element::create $form_id only_job_p -optional -widget "hidden"
template::element::create $form_id married_p -optional -widget "hidden"
template::element::create $form_id dependants -optional -widget "hidden"
template::element::create $form_id head_of_household_p -optional -widget "hidden"
template::element::create $form_id skills -optional -widget "hidden"
template::element::create $form_id first_experience -optional -widget "hidden"
template::element::create $form_id years_experience -optional -widget "hidden"
template::element::create $form_id referred_by -optional -widget "hidden"
template::element::create $form_id experience_id -optional -widget "hidden"
template::element::create $form_id employee_id -optional -widget "hidden"
template::element::create $form_id return_url -optional -widget "hidden"
template::element::create $form_id source_id -optional -widget "hidden"
template::element::create $form_id original_job_id -optional -widget "hidden"
template::element::create $form_id current_job_id -optional -widget "hidden"
template::element::create $form_id qualification_id -optional -widget "hidden"

set field_cnt [im_dynfield::append_attributes_to_form \
    -object_subtype_id "" \
    -object_type "person" \
    -form_id $form_id \
    -object_id $employee_id \
]

set n_error 0

if {[form is_submission $form_id]} {

	# Form validation 
# 	if { [catch { set birthdate_date_ansi [clock format [clock scan $birthdate] -format %Y-%m-%d] } ""] } {
# 	    incr n_error
# 		template::element::set_error $form_id birthdate "Bad date. Please use 'YYYY-MM-DD' to format the date."
# 	}

# 	if { [catch { set start_date_ansi [clock format [clock scan $start_date] -format %Y-%m-%d] } ""] } {
# 	    incr n_error
# 		template::element::set_error $form_id start_date "Bad date. Please use 'YYYY-MM-DD' to format the date."
# 	}

# 	if { [catch { set end_date_ansi [clock format [clock scan $end_date] -format %Y-%m-%d] } ""] } {
# 	    incr n_error
# 		template::element::set_error $form_id end_date "Bad date. Please use 'YYYY-MM-DD' to format the date."
# 	}

    if {$n_error > 0} {
	    return
    }

    set cost_name $employee_name
    if {"" == $start_date} { set start_date [db_string now "select now()::date"]}
    if {"" == $end_date} { set end_date "2099-12-31" }
    if {"" == $currency} { set currency $default_currency }

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
		    set rep_cost_id [im_cost::new -cost_name $cost_name -cost_type_id [im_cost_type_repeating]]
	    	db_dml insert_repeating_costs "
			insert into im_repeating_costs (
				rep_cost_id,
				start_date,
				end_date
			) values (
				:rep_cost_id,
				:start_date,
				:end_date
			)
		    "
		} err_msg] {
	    	ad_return_complaint 1 "<li>Error creating a new repeating cost 
		    item for employee \#$employee_id:<br>
		    <pre>$err_msg</pre>"
		}
    }

    # Check if the im_employees entry already exists for the user
    # and create it in case of necessity.
    set emp_count [db_string emp_count "
	select count(*) 
	from im_employees 
	where employee_id=:employee_id
    "]
    if {0 == $emp_count} {
	db_dml insert_emp_record "
		insert into im_employees (
			employee_id
		) values (
			:employee_id
		)
	"
    }

    if {"" == $salary} { set salary 0 }
    if {"" == $social_security} { set social_security 0 }
    if {"" == $other_costs} { set other_costs 0 }
    if {"" == $salary} { set salary 0 }
    if {"" == $insurance} { set insurance 0 }

    if {0 == $supervisor_id} { set supervisor_id "" }
    if {"" == $salary_payments_per_year} { set salary_payments_per_year 12 }
    if {![exists_and_not_null tax]} { set tax 0 }
    if {![exists_and_not_null vat]} { set vat 0 }

    if {[info exists supervisor_id] && $supervisor_id == $employee_id} {
		ad_return_complaint 1 "[_ intranet-hr.Employee_Own_Supervisor]"
		return
    }

    db_dml employee_update "
	update im_employees set
		employee_id = :employee_id,
		department_id = :department_id,
		job_title = :job_title,
		job_description = :job_description,
		availability = :availability,
		hourly_cost = :hourly_cost,
		supervisor_id = :supervisor_id,
		ss_number = :ss_number,
		salary = :salary,
		personnel_number = :personnel_number,
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
		qualification_id = :qualification_id,
		vacation_days_per_year = :vacation_days_per_year,
		vacation_balance = :vacation_balance
	where
		employee_id = :employee_id
"

   ns_log Notice "Dynfield: /intranet-hr/new: im_dynfield::attribute_store -object_type person -object_id $employee_id -form_id $form_id"
		im_dynfield::attribute_store \
			-object_type "person" \
			-object_id $employee_id \
			-form_id $form_id

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
	    ad_return_complaint 1 "<li>[_ intranet-hr.lt_Error_inserting_emplo]<BR>
            <pre>$err_msg</pre>"
	 }

	ad_returnredirect $return_url
	ad_script_abort
} 

if { [form is_request $form_id] } {

	db_1row projects_info_query {
    	select
        	e.*,
            CASE    WHEN rc.start_date is null
                    THEN to_date(:today,:date_format)
                    ELSE to_date(to_char(rc.start_date,:date_format),:date_format)
            END as start_date,
            CASE    WHEN rc.end_date is null
                        THEN to_date(:end_century,:date_format)
                        ELSE to_date(to_char(rc.end_date,:date_format),:date_format)
            END as end_date,
	        ci.*,
    	    to_char(e.birthdate,:date_format) as birthdate
    	from    
			parties p,
        	im_employees e,
	        im_repeating_costs rc,
    	    im_costs ci
	    where
	        p.party_id = :employee_id
    	    and p.party_id = e.employee_id
        	and p.party_id = ci.cause_object_id
	        and ci.cost_id = rc.rep_cost_id
	}

	template::element::set_value $form_id department_id $department_id
	template::element::set_value $form_id supervisor_id $supervisor_id
	template::element::set_value $form_id availability $availability
	template::element::set_value $form_id hourly_cost $hourly_cost
	template::element::set_value $form_id employee_status_id $employee_status_id
	template::element::set_value $form_id personnel_number $personnel_number
	template::element::set_value $form_id ss_number $ss_number
	template::element::set_value $form_id salary $salary
	template::element::set_value $form_id social_security $social_security
	template::element::set_value $form_id insurance $insurance
	template::element::set_value $form_id other_costs $other_costs
	template::element::set_value $form_id salary_payments_per_year $salary_payments_per_year
	template::element::set_value $form_id birthdate $birthdate
	template::element::set_value $form_id job_title $job_title
	template::element::set_value $form_id job_description $job_description
	template::element::set_value $form_id start_date $start_date
	template::element::set_value $form_id end_date $end_date
	template::element::set_value $form_id voluntary_termination_p $voluntary_termination_p
	template::element::set_value $form_id termination_reason $termination_reason
	template::element::set_value $form_id signed_nda_p $signed_nda_p
	template::element::set_value $form_id dependant_p $dependant_p
	template::element::set_value $form_id only_job_p $only_job_p
	template::element::set_value $form_id married_p $married_p
	template::element::set_value $form_id dependants $dependants
	template::element::set_value $form_id head_of_household_p $head_of_household_p
	template::element::set_value $form_id skills $skills
	template::element::set_value $form_id first_experience $first_experience
	template::element::set_value $form_id years_experience $years_experience
	template::element::set_value $form_id referred_by $referred_by
	template::element::set_value $form_id experience_id $experience_id
	template::element::set_value $form_id employee_id $employee_id
        template::element::set_value $form_id vacation_days_per_year $vacation_days_per_year
        template::element::set_value $form_id vacation_balance $vacation_balance
	template::element::set_value $form_id return_url "/intranet/users/view?user_id=$employee_id"
}
	
if {[form is_valid $form_id]} {
}
