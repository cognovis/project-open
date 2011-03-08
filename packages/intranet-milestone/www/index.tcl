# /packages/intranet-milestone/www/index.tcl
#
# Copyright (c) 2003-2008 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract { 
    @author frank.bergmann@project-open.com
} {
    { current_interval 30 }
    { customer_id:integer ""}
    { cost_center_id:integer ""}
    { status_id:integer 76}
    { type_id:integer ""}
    { member_id:integer ""}
    { project_lead_id:integer ""}
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

# User id already verified by filters
set current_user_id [ad_maybe_redirect_for_registration]
set page_focus "im_header_form.keywords"
set page_title [lang::message::lookup "" intranet-milestone.Milestones "Milestones"]
set context_bar [im_context_bar $page_title]
set return_url [im_url_with_query]

set date_format "YYYY-MM-DD"

# ---------------------------------------------------------------
# Admin Links
# ---------------------------------------------------------------

set admin_links ""
if {[im_permission $current_user_id "add_projects"]} {
    set milestone_type_id [im_project_type_milestone]
    append admin_links " <li><a href=\"[export_vars -base /intranet/projects/new {return_url {project_type_id $milestone_type_id}}]\">[lang::message::lookup "" intranet-milestone.Add_a_new_Milestone "Add a new Milestone"]</a></li>\n"
}
append admin_links [im_menu_ul_list -no_uls 1 "milestones" {}]
if {"" != $admin_links} { set admin_links "<ul>\n$admin_links\n</ul>\n" }


# ---------------------------------------------------------------
# Filter with Dynamic Fields
# ---------------------------------------------------------------

set member_options [util_memoize "im_employee_options" 3600]
set cost_center_options [im_cost_center_options -include_empty 1]
set view_options {{"Milestone List" milestone_list}}
set current_interval_options {{Today 1} {"Next 7 days" 7} {"Next 30 days" 30} {"Next 365 days" 365}}
set customer_options [im_company_options -type "Customers"]

set form_id "milestone_filter"
set object_type "im_project"
set action_url "/intranet-milestone/index"
set form_mode "edit"

ad_form \
    -name $form_id \
    -action $action_url \
    -mode $form_mode \
    -method GET \
    -export {start_idx order_by how_many view_name} \
    -form {
	{current_interval:text(select),optional {label "[lang::message::lookup {} intranet-milestone.Time_Interval {Time Interval}]"} {options $current_interval_options} }
	{status_id:text(im_category_tree),optional {label "[lang::message::lookup {} intranet-milestone.Milestone_Status {Status}]"} {custom {category_type "Intranet Project Status" translate_p 1 package_key intranet-core}} }
	{type_id:text(im_category_tree),optional {label "[lang::message::lookup {} intranet-milestone.Milestone_Type {Type}]"} {custom {category_type "Intranet Project Type" translate_p 1 package_key intranet-core} } }
    	{customer_id:text(hidden),optional {label "[lang::message::lookup {} intranet-milestone.Customer {Customer}]"} {options $customer_options }}
    	{member_id:text(select),optional {label "[lang::message::lookup {} intranet-milestone.Member {Member}]"} {options $member_options }}
    	{project_lead_id:text(hidden),optional {label "[lang::message::lookup {} intranet-milestone.Project_Manager {Project Manager}]"} {options $member_options }}
    }

im_dynfield::append_attributes_to_form \
    -object_type $object_type \
    -object_subtype_id [im_project_type_milestone] \
    -form_id $form_id \
    -object_id 0 \
    -advanced_filter_p 1

# Set the form values from the HTTP form variable frame
im_dynfield::set_form_values_from_http -form_id $form_id
im_dynfield::set_local_form_vars_from_http -form_id $form_id

array set extra_sql_array [im_dynfield::search_sql_criteria_from_form \
			       -form_id $form_id \
			       -object_type $object_type
]

template::element::set_value $form_id current_interval $current_interval
template::element::set_value $form_id status_id $status_id
template::element::set_value $form_id type_id $type_id
template::element::set_value $form_id member_id $member_id
template::element::set_value $form_id customer_id $customer_id
template::element::set_value $form_id project_lead_id $project_lead_id


set page_html "
[im_box_header [lang::message::lookup {} intranet-milestone.Late_Milestones "Late Milestones"]]
<br>
[im_milestone_list_component \
		-status_id $status_id \
		-end_date_before 0 \
		-type_id $type_id \
		-customer_id $customer_id \
		-member_id $member_id \
]
[im_box_footer]

[im_box_header [lang::message::lookup {} intranet-milestone.Current_Milestones "Milestones due in the next %current_interval% days"]]
<br>
[im_milestone_list_component \
		-status_id $status_id \
		-end_date_after 0 \
		-end_date_before $current_interval \
		-type_id $type_id \
		-customer_id $customer_id \
		-member_id $member_id \
]
[im_box_footer]

[im_box_header [lang::message::lookup {} intranet-milestone.Future_Milestones "Milestones due after %current_interval% days"]]
<br>
[im_milestone_list_component \
		-status_id $status_id \
		-end_date_after $current_interval \
		-type_id $type_id \
		-customer_id $customer_id \
		-member_id $member_id \
]
[im_box_footer]

"



# Compile and execute the formtemplate if advanced filtering is enabled.
eval [template::adp_compile -string {<formtemplate id="milestone_filter"></formtemplate>}]
set filter_html $__adp_output


set left_navbar_html "
      <div class='filter-block'>
         <div class='filter-title'>
	    [lang::message::lookup "" intranet-milestone.Filter_Milestones "Filter Milestones"]
         </div>
         $filter_html
      </div>
      <hr/>

      <div class='filter-block'>
         <div class='filter-title'>
	        #intranet-core.Admin_Links#
         </div>
         $admin_links
      </div>
"


