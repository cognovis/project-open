# /packages/intranet-core/projects/new.tcl
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
    Purpose: form to add a new project or edit an existing one
    
    @param project_id group id
    @param parent_id the parent project id
    @param return_url the url to return to

    @author mbryzek@arsdigita.com
    @author frank.bergmann@project-open.com
} {
    project_id:optional,integer
    { parent_id:integer "" }
    { company_id:integer "" }
    project_nr:optional
    return_url:optional
}

set user_id [ad_maybe_redirect_for_registration]
set todays_date [lindex [split [ns_localsqltimestamp] " "] 0]
set user_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
set required_field "<font color=red size=+1><B>*</B></font>"

set project_nr_field_size [ad_parameter -package_id [im_package_core_id] ProjectNumberFieldSize "" 20]

# Make sure the user has the privileges, because this
# pages shows the list of companies etc.
if {![im_permission $user_id add_projects]} { 
    ad_return_complaint "Insufficient Privileges" "
    <li>You don't have sufficient privileges to see this page."
}


# Check if we are editing an already existing project
#
if { [exists_and_not_null project_id] } {
    # We are editing an already existing project
    #
    db_1row projects_info_query { 
select 
	p.parent_id, 
	p.company_id, 
	p.project_name,
	p.project_type_id, 
	p.project_status_id, 
	p.description,
	p.project_lead_id, 
	p.supervisor_id, 
	p.project_nr,
	p.project_budget, 
	to_char(p.start_date,'YYYY-MM-DD') as start_date, 
	to_char(p.end_date,'YYYY-MM-DD') as end_date, 
	to_char(p.end_date,'HH24:MI') as end_time,
	p.requires_report_p 
from
	im_projects p
where 
	p.project_id=:project_id
}

    set page_title "[_ intranet-core.Edit_project]"
    set context_bar [ad_context_bar [list /intranet/projects/ "[_ intranet-core.Projects]"] [list "/intranet/projects/view?[export_url_vars project_id]" "One project"] $page_title]

    if { [empty_string_p $start_date] } { set start_date $todays_date }
    if { [empty_string_p $end_date] } { set end_date $todays_date }
    if { [empty_string_p $end_time] } { set end_time "12:00" }
    set button_text "[_ intranet-core.Save_Changes]"

} else {

    # Calculate the next project number by calculating the maximum of
    # the "reasonably build numbers" currently available

    # A completely new project or a subproject
    #
    if {![info exist project_nr]} {
	set project_nr [im_next_project_nr]
    }
    set start_date $todays_date
    set end_date $todays_date
    set end_time "12:00"
    set billable_type_id ""
    set project_lead_id "5"
    set supervisor_id ""
    set description ""
    set project_budget ""
    set "creation_ip_address" [ns_conn peeraddr]
    set "creation_user" $user_id
    set project_id [im_new_object_id]
    set project_name ""
    set button_text "[_ intranet-core.Create_Project]"

    if { ![exists_and_not_null parent_id] } {

	# A brand new project (not a subproject)
	set requires_report_p "f"
	set parent_id ""
	if { ![exists_and_not_null company_id] } {
	    set company_id ""
	}
	set project_type_id 85
	set project_status_id 76
	set page_title "[_ intranet-core.Add_New_Project]"
	set context_bar [ad_context_bar [list ./ "[_ intranet-core.Projects]"] $page_title]

    } else {

	# This means we are adding a subproject.
	# Let's select out some defaults for this page
	db_1row projects_by_parent_id_query {
	    select 
		p.company_id, 
		p.project_type_id, 
		p.project_status_id
	    from
		im_projects p
	    where 
		p.project_id=:parent_id 
	}

	set requires_report_p "f"
	set page_title "[_ intranet-core.Add_subproject]"
	set context_bar [ad_context_bar [list ./ "[_ intranet-core.Projects]"] [list "view?project_id=$parent_id" "[_ intranet-core.One_project]"] $page_title]
    }
}

set page_body "
                <form action=new-2.tcl method=POST>
[export_form_vars return_url project_id creation_ip_address creation_user]
                  <table border=0>
                    <tr> 
                      <td colspan=2 class=rowtitle>[_ intranet-core.Project_Base_Data] [im_gif help "[_ intranet-core.lt_To_avoid_duplicate_pr]"]</td>
                    </tr>
                    <tr> 
                      <td>[_ intranet-core.Project_Name]</td>
                      <td> 
                        <input type=text size=40 name=project_name value=\"$project_name\">
                        [im_gif help "[_ intranet-core.lt_Just_enter_any_suitab]"]
                      </td>
                    </tr>
                    <tr> 
                      <td>[_ intranet-core.Project_] $required_field &nbsp;</td>
                      <td> 
                        <input type=text size=\"$project_nr_field_size\" name=project_nr value=\"$project_nr\" maxlength=\"$project_nr_field_size\" >
                        [im_gif help "[_ intranet-core.lt_A_project_number_is_c]"] &nbsp; 
                      </td>
                    </tr>
"

if {"" != $parent_id && [parameter::get -parameter EnableNestedProjectsP -package_id [ad_acs_kernel_id] -default 1] > 0} {
    append page_body "
                    <tr> 
                      <td>[_ intranet-core.Parent_Project] &nbsp;</td>
                      <td> 
[im_project_select "parent_id" $parent_id "[_ intranet-core.Open]"]
                        [im_gif help "[_ intranet-core.lt_Do_you_want_to_create]"] &nbsp; 
                      </td>
                    </tr>
"
}

append page_body "  
                    <tr>
                      <td>[_ intranet-core.Client] $required_field </td>
                      <td> 
[im_company_select "company_id" $company_id "" "[_ intranet-core.Company]" [list "[_ intranet-core.Deleted]" "[_ intranet-core.Past]" "[_ intranet-core.Declined]" "[_ intranet-core.Inactive]"]]
"
if {$user_admin_p} {
    append page_body "
	<A HREF='/intranet/companies/new'>
	[im_gif new "[_ intranet-core.Add_a_new_client]"]</A>"
}

append page_body "
                        <font size=-1>[im_gif help "[_ intranet-core.lt_There_is_a_difference]"]</font> 
                      </td>
                    </tr>
                    <tr> 
                      <td>[_ intranet-core.Project_Manager]</td>
                      <td> 
[im_employee_select_multiple "project_lead_id" $project_lead_id "" ""]
                      </td>
                    </tr>
                    <tr> 
                      <td>[_ intranet-core.Project_Type]  $required_field </td>
                      <td> <font size=-1> 
[im_project_type_select "project_type_id" $project_type_id]
"
if {$user_admin_p} {
    append page_body "
	<A HREF='/intranet/admin/categories/?select_category_type=Intranet+Project+Type'>
	[im_gif new "[_ intranet-core.lt_Add_a_new_project_typ]"]</A>"
}

append page_body "
                        [im_gif help "[_ intranet-core.lt_General_type_of_proje]"]</font></td>
                    </tr>
                    <tr> 
                      <td>[_ intranet-core.Project_Status] $required_field </td>
                      <td>
[im_project_status_select "project_status_id" $project_status_id]
"
if {$user_admin_p} {
    append page_body "
	<A HREF='/intranet/admin/categories/?select_category_type=Intranet+Project+Status'>
	[im_gif new "[_ intranet-core.lt_Add_a_new_project_sta]"]</A>"
}

append page_body "
                        [im_gif help "[_ intranet-core.lt_In_Process_Work_is_st]"]
                      </td>
                    </tr>\n"


append page_body "
                    <tr> 
                      <td>[_ intranet-core.Start_Date] $required_field </td>
                      <td> 
[philg_dateentrywidget start $start_date]
                      </td>
                    </tr>

                    <tr> 
                      <td>[_ intranet-core.Delivery_Date] $required_field </td>
                      <td> 
[philg_dateentrywidget end $end_date]
                      , &nbsp;
                      <INPUT NAME=end_time.time TYPE=text SIZE=8 MAXLENGTH=8 value='$end_time'>
                      </td>
                    </tr>
                    <tr> 
                      <td>[_ intranet-core.Description]<br>([_ intranet-core.publicly_searchable]) </td>
                      <td> 
                      <textarea NAME=description rows=5 cols=50 wrap=soft>$description</textarea>
                      </td>
                    </tr>

                    <tr> 
                      <td valign=top> 
                        <div align=right>&nbsp; </div>
                      </td>
                      <td> 
                          <p> 
                            <input type=submit value='$button_text' name=submit2>
                            [im_gif help "[_ intranet-core.lt_Create_the_new_folder]"]
                          </p>
                      </td>
                    </tr>
                  </table>
                </form>
"


