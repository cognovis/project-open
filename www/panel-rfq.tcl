# /packages/intranet-cust-kw/www/bundle-panel.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# -----------------------------------------------------------
# Page Head
# 
# There are two different heads, depending whether it's called
# "standalone" (TCL-page) or as a Workflow Panel.
# -----------------------------------------------------------

# Workflow-Panel Head:

set task_id $task(task_id)
set case_id $task(case_id)


set project_id [db_string get_view_id "select object_id from wf_cases where case_id=:case_id" -default 0]

# Return-URL Logic
set return_url ""
if {[info exists task(return_url)]} { set return_url $task(return_url) }
set bundle_id [db_string pid "select object_id from wf_cases where case_id = :case_id" -default ""]

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set transition_key [db_string transition_key "select transition_key from wf_tasks where task_id = :task_id" -default ""]
set current_user_id [ad_maybe_redirect_for_registration]
set object_name [db_string name "select acs_object__name(:bundle_id)"]

set user_id $current_user_id

# ---------------------------------------------------------------
# Get the included hours
# ---------------------------------------------------------------

set extra_selects [list "0 as zero"]
set column_sql "
        select  w.deref_plpgsql_function,
                aa.attribute_name
        from    im_dynfield_widgets w,
                im_dynfield_attributes a,
                acs_attributes aa
        where   a.widget_name = w.widget_name and
                a.acs_attribute_id = aa.attribute_id and
                aa.object_type = 'im_project'
"
db_foreach column_list_sql $column_sql {
    lappend extra_selects "${deref_plpgsql_function}($attribute_name) as ${attribute_name}_deref"
}
set extra_select [join $extra_selects ",\n\t"]

set query "
select
        p.*,
        c.*,
        to_char(p.end_date, 'HH24:MI') as end_date_time,
        to_char(p.start_date, 'YYYY-MM-DD') as start_date_formatted,
        to_char(p.end_date, 'YYYY-MM-DD') as end_date_formatted,
        to_char(p.percent_completed, '999990.9%') as percent_completed_formatted,
        c.primary_contact_id as company_contact_id,
        im_name_from_user_id(c.primary_contact_id) as company_contact,
        im_email_from_user_id(c.primary_contact_id) as company_contact_email,
        im_name_from_user_id(p.project_lead_id) as project_lead,
        im_name_from_user_id(p.supervisor_id) as supervisor,
        im_name_from_user_id(c.manager_id) as manager,
        $extra_select
from
        im_projects p,
        im_companies c
where
        p.project_id=:project_id
        and p.company_id = c.company_id
order by
        p.project_id
"


if { ![db_0or1row projects_info_query $query] } {
    ad_return_complaint 1 "[_ intranet-core.lt_Cant_find_the_project]"
    return
}

set project_type [im_category_from_id $project_type_id]
set project_status [im_category_from_id $project_status_id]


set view_finance_p 1
set view_budget_p 1
set view_budget_hours_p 1
set enable_project_path_p 1
set user_can_see_start_end_date_p 1

# ---------------------------------------------------------------------
# Project Base Data
# ---------------------------------------------------------------------

set project_base_data_html "
                        <table border=0>
                          <tr>
                            <td>[_ intranet-core.Project_name]</td>
                            <td><a href='/intranet/projects/view?project_id=$project_id'>$project_name</a></td>
                          </tr>"

append project_base_data_html "
                          [im_company_link_tr $user_id $company_id $company_name "[_ intranet-core.Client]"]
                          <tr>
                            <td>[_ intranet-core.Project_Manager]</td>
                            <td>
                            [im_render_user_id $project_lead_id $project_lead $user_id $project_id]
                            </td>
                          </tr>
                          <tr>
                            <td>[_ intranet-core.Project_Type]</td>
                            <td>$project_type</td>
                          </tr>
                          <tr>
                            <td>[_ intranet-core.Project_Status]</td>
                            <td>$project_status</td>
                          </tr>\n"

if { ![empty_string_p $company_project_nr] } {
    append project_base_data_html "
                          <tr>
                            <td>[lang::message::lookup "" intranet-core.Company_Project_Nr "Customer Project Nr"]</td>
                            <td>$company_project_nr</td>
                          </tr>"
}

if { ![empty_string_p $description] } { 
    	append project_base_data_html "
                          <tr>
                            <td>[_ intranet-core.Description]</td>
                            <td width=250>$description</td>
                          </tr>"
}


# ---------------------------------------------------------------------
# Add DynField Columns to the display
# ---------------------------------------------------------------------

set column_sql "
        select
                aa.pretty_name,
                aa.attribute_name
        from
                im_dynfield_widgets w,
                acs_attributes aa,
                im_dynfield_attributes a
                LEFT OUTER JOIN (
                        select *
                        from im_dynfield_layout
                        where page_url = ''
                ) la ON (a.attribute_id = la.attribute_id)
        where
                a.widget_name = w.widget_name and
                a.acs_attribute_id = aa.attribute_id and
                aa.object_type = 'im_project'
        order by
                coalesce(la.pos_y,0), coalesce(la.pos_x,0)
"
db_foreach column_list_sql $column_sql {
    set var ${attribute_name}_deref
    set value [expr $$var]
    if {"" != [string trim $value]} {
                append project_base_data_html "
                  <tr>
                    <td>[lang::message::lookup "" intranet-core.$attribute_name $pretty_name]</td>
                    <td>$value</td>
                  </tr>
                "
    }
}


set inquiry_id [db_string get_inquiry_id "select inquiry_id from im_inquiries_customer_portal where project_id=$project_id" -default 0]



if {[im_openacs54_p]} {
    # Load ExtJS "Uploaded Files Portlet"
    template::head::add_javascript -src "/intranet-customer-portal/resources/js/portlet-uploaded-files.js?inquiry_id=$inquiry_id" -order "2"
    set js_include ""
} else {
    set params [list inquiry_id $inquiry_id]
    set js_include [ad_parse_template -params $params "/packages/intranet-customer-portal/www/resources/js/portlet-uploaded-files.js"]
}

db_1row get_inquiry_info "select * from im_inquiries_customer_portal where inquiry_id=$inquiry_id" 
	append project_base_data_html "
                <tr>
                        <td>[lang::message::lookup "" intranet-core.InquiryDate "Inquiry Date"]</td>
                        <td>$inquiry_date</td>
                </tr>
	"

append project_base_data_html "    </table>
                        <br>
"

set html $project_base_data_html
