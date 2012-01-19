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

# ---------------------------------------------------------------------
# Check permissions
# ---------------------------------------------------------------------

# get the current users permissions for this project
# im_project_permissions $current_user_id $project_id view read write admin

# Compatibility with old components...
# set current_user_id $user_id
# set user_admin_p $write

# if {![db_string ex "select count(*) from im_projects where project_id=:project_id"]} {
#    ad_return_complaint 1 "<li>Project doesn't exist"#
#    return
# }

# if {!$read} {
#    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_have_insufficient_6]"
#    return
# }


# set view_finance_p [im_permission $current_user_id view_finance]
# set view_budget_p [im_permission $current_user_id view_budget]
# set view_budget_hours_p [im_permission $current_user_id view_budget_hours]

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
                            <td>$project_name</td>
                          </tr>"

if { ![empty_string_p $parent_id] } {
    set parent_name [db_string get_data "select project_name from im_projects where project_id = :parent_id" -default 0]
    append project_base_data_html "
                          <tr>
                            <td>[_ intranet-core.Parent_Project]</td>
                            <td>
                              <a href=/intranet/projects/view?project_id=$parent_id>$parent_name</a>
                            </td>
                          </tr>"
}

append project_base_data_html "
                          <tr>
                            <td>[lang::message::lookup "" intranet-core.Project_Nr "Project Nr."]</td>
                            <td>$project_nr</td>
                          </tr>
"

if {$enable_project_path_p} {
    append project_base_data_html "
                          <tr>
                            <td>[lang::message::lookup "" intranet-core.Project_Path "Project Path"]</td>
                            <td>$project_path</td>
                          </tr>
    "
}

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

# VAW Special: Freelancers shouldnt see star and end date
# ToDo: Replace this hard coded condition with DynField
# permissions per field.
if { $user_can_see_start_end_date_p && ![empty_string_p $start_date_formatted] } { append project_base_data_html "
                          <tr>
                            <td>[_ intranet-core.Start_Date]</td>
                            <td>$start_date_formatted</td>
<!--                        <td>[lc_time_fmt $start_date_formatted "%x" locale]</td>    -->
                          </tr>"
}

if { $user_can_see_start_end_date_p && ![empty_string_p $end_date] } { append project_base_data_html "
                          <tr>
                            <td>[_ intranet-core.Delivery_Date]</td>
                            <td>$end_date_formatted $end_date_time</td>
<!--                        <td>[lc_time_fmt $end_date_formatted "%x" locale] $end_date_time</td>       -->
                          </tr>"
}


append project_base_data_html "
                          <tr>
                            <td>[_ intranet-core.On_Track_Status]</td>
                            <td>[im_project_on_track_bb $on_track_status_id]</td>
                          </tr>"
if { ![empty_string_p $percent_completed] } { append project_base_data_html "
                          <tr>
                            <td>[_ intranet-core.Percent_Completed]</td>
                            <td>$percent_completed_formatted</td>
                          </tr>"
}

if {$view_budget_hours_p && ![empty_string_p $project_budget_hours] } {
    append project_base_data_html "
                          <tr>
                            <td>[_ intranet-core.Project_Budget_Hours]</td>
                            <td>$project_budget_hours</td>
                          </tr>
    "
}

if {$view_budget_p && ![empty_string_p $project_budget]} {
    append project_base_data_html "
                          <tr>
                            <td>[_ intranet-core.Project_Budget]</td>
                            <td>$project_budget $project_budget_currency</td>
                          </tr>
    "
}

if { ![empty_string_p $company_project_nr] } {
    append project_base_data_html "
                          <tr>
                            <td>[lang::message::lookup "" intranet-core.Company_Project_Nr "Customer Project Nr"]</td>
                            <td>$company_project_nr</td>
                          </tr>"
}
if { ![empty_string_p $description] } { append project_base_data_html "
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


append project_base_data_html "    </table>
                        <br>
"

set html $project_base_data_html
