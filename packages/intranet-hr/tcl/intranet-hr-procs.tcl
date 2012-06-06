# /packages/intranet-hr/tcl/intranet-hr-procs.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    Common procedures to implement employee specific functions:

    @author frank.bergmann@project-open.com
}

# ----------------------------------------------------------------------
# Constant Functions
# ----------------------------------------------------------------------


ad_proc -public im_employee_status_potential {} { return 450 }
ad_proc -public im_employee_status_received_test {} { return 451 }
ad_proc -public im_employee_status_failed_test {} { return 452 }
ad_proc -public im_employee_status_approved_test {} { return 453 }
ad_proc -public im_employee_status_active {} { return 454 }
ad_proc -public im_employee_status_past {} { return 455 }


# ----------------------------------------------------------------------
# Employee Info Component
# Some simple extension data for employeers
# ----------------------------------------------------------------------

ad_proc im_employee_info_component { employee_id return_url {view_name ""} } {
    Show some simple information about a employee
} {
    if {"" == $view_name} { set view_name "employees_view" }
    ns_log Notice "im_employee_info_component: employee_id=$employee_id, view_name=$view_name"
    set current_user_id [ad_get_user_id]

    set date_format "YYYY-MM-DD"
    set number_format "9999990D99"

    set department_url "/intranet-cost/cost-centers/new?cost_center_id="
    set user_url "/intranet/users/view?user_id="

    set td_class(0) "class=roweven"
    set td_class(1) "class=rowodd"

    # employee_id gets modified by the SQl ... :-(
    set org_employee_id $employee_id    

    # --------------- Security --------------------------

    set view 0
    set read 0
    set write 0
    set admin 0
    im_user_permissions $current_user_id $employee_id view read write admin
    ns_log Notice "im_employee_info_component: view=$view, read=$read, write=$write, admin=$admin"
    if {!$read} { return "" }

    # Check if the current_user is a HR manager
    if {![im_permission $current_user_id view_hr]} { return "" }

    # Finally: Show this component only for employees
    if {![im_user_is_employee_p $employee_id]} { 
	ns_log Notice "im_employee_info_component: user is not an employee..."
	return "" 
    }

    # --------------- Select all values --------------------------

    if {[catch {db_1row employee_info "
	select	
		im_name_from_user_id(pe.person_id) as user_name,
		p.email,
		e.*,
		ci.*,
		to_char(ci.start_date,:date_format) as start_date_formatted,
		to_char(ci.end_date,:date_format) as end_date_formatted,
		to_char(e.birthdate,:date_format) as birthdate_formatted,
		to_char(salary, :number_format) as salary_formatted,
		to_char(hourly_cost, :number_format) as hourly_cost_formatted,
		to_char(other_costs, :number_format) as other_costs_formatted,
		to_char(insurance, :number_format) as insurance_formatted,
		to_char(social_security, :number_format) as social_security_formatted,
		u.user_id,
		cc.cost_center_name as department_name,
		im_name_from_user_id(e.supervisor_id) as supervisor_name
	from	
		users u
		LEFT OUTER JOIN im_employees e ON (u.user_id = e.employee_id)
		LEFT OUTER JOIN im_cost_centers cc ON (e.department_id = cc.cost_center_id)
		LEFT OUTER JOIN (
			select	* 
			from	im_costs c, im_repeating_costs rc
			where	c.cost_id = rc.rep_cost_id
				and c.cost_type_id = [im_cost_type_employee]
				and c.cause_object_id = :employee_id
		) ci ON (u.user_id = ci.cause_object_id),
		parties p,
		persons pe
	where	
		pe.person_id = u.user_id
		and p.party_id = u.user_id
		and u.user_id = :employee_id

    "} err_msg]} {

	return "<b>Multiple Salary Items per User</b>:<br>
		This error is probably due to an incomplete update to version V3.2.<br>
		Please notify your System Administrator and tell him (or her) to<br>
		execute the script /packages/intranet-hr/sql/postgresql/update/upgrade-3.2.6.0.0-3.2.7.0.0.sql.
		<p><pre>$err_msg</pre>"
    } 

    regsub -all " " $salary_period "_" salary_period_key
    set salary_period [lang::message::lookup "" intranet-hr.Salary_period_${salary_period_key} $salary_period]
	
    set employee_info_exists 1

    set view_id [db_string get_view "select view_id from im_views where view_name=:view_name" -default 0]
    ns_log Notice "im_employee_info_component: view_id=$view_id, emp_info_exists=$employee_info_exists"

    set column_sql "
	select	c.column_name,
		c.column_render_tcl,
		c.visible_for
	from	im_view_columns c
	where	c.view_id=:view_id
	order by sort_order"

   set employee_id $org_employee_id

   set employee_html "
	<form method=GET action=/intranet-hr/new>
	[export_form_vars employee_id return_url]
	<table cellpadding=1 cellspacing=1 border=0>
	<tr> 
	  <td colspan=2 class=rowtitle align=center>[_ intranet-hr.Employee_Information]</td>
	</tr>\n"

    set ctr 1
    if {$employee_info_exists} {
	# if the row makes references to "private Note" and the user isn't
	# adminstrator, this row don't appear in the browser.
	db_foreach column_list_sql $column_sql {
	    ns_log Notice "im_employee_info_component: visible_for=$visible_for"
	    if {"" == $visible_for || [eval $visible_for]} {
		append employee_html "
                <tr $td_class([expr $ctr % 2])>
		<td>[lang::message::lookup "" "intranet-hr.[lang::util::suggest_key $column_name]" $column_name] &nbsp;</td><td>"
		set cmd "append employee_html $column_render_tcl"
		eval $cmd
		append employee_html "</td></tr>\n"
		incr ctr
	    }
	}
    } else {
	append employee_html "<tr><td colspan=2><i>[_ intranet-hr.Nothing_defined_yet]</i></tr></td>\n"
    }

    if {$write} {
        append employee_html "
        <tr $td_class([expr $ctr % 2])>
        <td></td><td><input type=submit value='[_ intranet-hr.Edit]'></td></tr>\n"
    }
    append employee_html "</table></form>\n"

    return $employee_html
}
