# /packages/intranet-core/projects/view.tcl
#
# Copyright (C) 1998-2004 various parties
# The software is based on ArsDigita ACS 3.4
#
# This program is free software. You can redistribute it
# and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option)
# any later version. This program is distributed in the
# hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.

ad_page_contract {
    View all the info about a specific project.

    @param project_id the group id
    @param orderby the display order
    @param show_all_comments whether to show all comments

    @author mbryzek@arsdigita.com
    @author Frank Bergmann (frank.bergmann@project-open.com)
} {
    { project_id:integer 0}
}



if {0 == $project_id} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_need_to_specify_a] "
    return
}

# ---------------------------------------------------------------------
# Get Everything about the project
# ---------------------------------------------------------------------
set project [::im::dynfield::Class get_instance_from_db -id $project_id]

set company_id [$project company_id]
set company_name [db_string company_name "select company_name from im_companies where company_id = :company_id"]
foreach dynfield_id [im_dynfield::dynfields -object_type im_project -privilege "read"] {
    set attribute_name [db_string attribute_name "select attribute_name from acs_attributes aa, im_dynfield_attributes da
                                                  where aa.attribute_id = da.acs_attribute_id 
                                                  and da.attribute_id = :dynfield_id"]
    set $attribute_name [$project set ${attribute_name}_deref]
}

set start_date_formatted $start_date
set end_date_formatted $end_date

# ---------------------------------------------------------------------
# Get Everything about the budget
# ---------------------------------------------------------------------

set budget_id [db_string budget_id "select item_id from cr_items where parent_id = :project_id and content_type = 'im_budget' limit 1" -default ""]
set revision_id [content::item::get_latest_revision -item_id $budget_id]

if {$revision_id eq ""} {
    ad_returnredirect [export_vars -base "/intranet-budget/budget" -url {project_id}]
    ad_script_abort
}

set Budget [::im::dynfield::CrClass::im_budget get_instance_from_db -revision_id $revision_id]

$Budget instvar budget_hours budget investment_costs investment_costs_explanation single_costs single_costs_explanation annual_costs annual_costs_explanation project_budget economic_gain economic_gain_explanation

# Get the parent project's name
if {"" == $parent_id} { set parent_id 0 }
set parent_name [util_memoize [list db_string parent_name "select project_name from im_projects where project_id = $parent_id" -default ""]]


# ---------------------------------------------------------------------
# Redirect to timesheet if this is timesheet
# ---------------------------------------------------------------------

# Redirect if this is a timesheet task (subtype of project)
if {$project_type_id == [im_project_type_task]} {
    ad_returnredirect [export_vars -base "/intranet-timesheet2-tasks/new" {{task_id $project_id}}]

}
if {![db_string ex "select count(*) from im_projects where project_id=:project_id"]} {
    ad_return_complaint 1 "<li>Project doesn't exist"
    return
}

# ---------------------------------------------------------------------
# Create the table for the hour / department planning
# ---------------------------------------------------------------------

set hour_ids [db_list hours {select item_id from cr_items where parent_id = :budget_id and content_type = 'im_budget_hour'}]
set hour_xml ""

foreach item_id $hour_ids {
    set Hour [::im::dynfield::CrClass::im_budget_hour get_instance_from_db -item_id $item_id]            
    append hour_xml "
<table:table-row>
<table:table-cell table:style-name=\"Tabelle2.A1\" office:value-type=\"string\">
<text:p text:style-name=\"P48\">[$Hour title]</text:p>
</table:table-cell>
<table:table-cell table:style-name=\"Tabelle2.A1\" office:value-type=\"string\">
<text:p text:style-name=\"P48\">[::xo::db::sql::im_cost_center name -cost_center_id [$Hour department_id]]</text:p>
</table:table-cell>
<table:table-cell table:style-name=\"Tabelle2.C1\" office:value-type=\"float\" office:value=\"[$Hour hours]\">
<text:p text:style-name=\"P48\">[$Hour hours]</text:p>
</table:table-cell>
</table:table-row>
"
}

intranet_oo::parse_content -template_file_path "[acs_package_root_dir "intranet-cust-berendsen"]/templates/projektantrag.odt" -output_filename ${project_name}.pdf
