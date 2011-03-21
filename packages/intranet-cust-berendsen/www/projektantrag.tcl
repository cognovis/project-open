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
if {0} {
    set project [::im::dynfield::Class get_instance_from_db -id $project_id]
    set company_name [db_string company_name "select im_company__name([$project company_id])"]
    ns_log Notice "[$project serialize]"
    foreach dynfield_id [::im::dynfield::Attribute dynfield_attributes -list_ids [$project list_ids] -privilege "read"] {
	
	# Initialize the Attribute
	set element [im::dynfield::Element get_instance_from_db -id [lindex $dynfield_id 0] -list_id [lindex $dynfield_id 1]]
	set [$element attribute_name] [$project value $element]
    }

}
if {1} {
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
    lappend extra_selects "${deref_plpgsql_function}(p.$attribute_name) as ${attribute_name}_deref"
}

set extra_select [join $extra_selects ",\n\t"]

set query "
select
	p.*,
        (select aux_int1 from im_categories where category_id = p.project_priority_st_id) as strategic_value,
        (select aux_int1 from im_categories where category_id = p.project_priority_op_id) as operative_value,
	c.*,
	to_char(p.end_date, 'HH24:MI') as end_date_time,
	to_char(p.start_date, 'DD.MM.YYYY') as start_date_formatted,
	to_char(p.end_date, 'DD.MM.YYYY') as end_date_formatted,
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
"


if { ![db_0or1row projects_info_query $query] } {
    ad_return_complaint 1 "[_ intranet-core.lt_Cant_find_the_project]"
    return
}

set project_type [im_category_from_id $project_type_id]
set project_status [im_category_from_id $project_status_id]

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
    set company_name [db_string company_name "select im_company__name($company_id)"]
}
if {![db_string ex "select count(*) from im_projects where project_id=:project_id"]} {
    ad_return_complaint 1 "<li>Project doesn't exist"
    return
}

intranet_oo::parse_content -template_file_path "[acs_package_root_dir "intranet-cust-berendsen"]/templates/projektantrag.odt" -output_filename ${project_name}.pdf
