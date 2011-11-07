# -------------------------------------------------------------
# /packages/intranet-risks/www/risk-project-component.tcl
#
# Copyright (c) 2011 ]project-open[
# All rights reserved.
#
# Author: frank.bergmann@project-open.com
#

# -------------------------------------------------------------
# Variables:
#	risk_project_id:integer

ad_page_contract {
    @author frank.bergmann@project-open.com
} {
    { risk_project_id:integer "" }
    { risk_customer_id:integer "" }
    { risk_status_id:integer "" }
    { risk_type_id:integer "" }
    { risk_ids "" }
    { start_date "" }
    { end_date "" }
}


set return_url [im_url_with_query]
set current_user_id [ad_maybe_redirect_for_registration]
set page_title [lang::message::lookup "" intranet-riskmanagement.Risks "Risks"]
set context_bar [im_context_bar $page_title]
set main_navbar_label "projects"
set sub_navbar ""
set master_p 1
set show_context_help_p 0
set new_risk_url [export_vars -base "/intranet-riskmanagement/new" {risk_project_id return_url}]

# Check the project permissions for the current_user
im_project_permissions $current_user_id $risk_project_id object_view object_read object_write object_admin
if {!$object_read} {
    ad_return_complaint 1 "You don't have sufficient permissions to see this page"
    ad_script_abort
}

# ---------------------------------------------------------------
# Create Filter with Dynamic Fields
# ---------------------------------------------------------------

set form_id "risk_filter"
set object_type "im_risk"
set action_url "/intranet-riskmanagement/index"
set form_mode "edit"

ad_form \
    -name $form_id \
    -action $action_url \
    -mode $form_mode \
    -method GET \
    -export {start_idx order_by how_many view_name letter filter_advanced_p}\
    -form {}

if {[im_permission $current_user_id "view_risks_all"]} { 
    set mine_p_options [list \
	[list [lang::message::lookup "" intranet-riskmanagement.All "All"] "f" ] \
	[list [lang::message::lookup "" intranet-riskmanagement.In_my_department "In my department"] "dept"] \
	[list [lang::message::lookup "" intranet-riskmanagement.Mine "Mine"] "t"] \
    ]
    ad_form -extend -name $form_id -form {
        {mine_p:text(select),optional {label "Mine/All"} {options $mine_p_options }}
        {risk_status_id:text(im_category_tree),optional {label \#intranet-riskmanagement.Risk_Status\#} {value $risk_status_id} {custom {category_type "Intranet Risk Status" translate_p 1}} }
    } 
}

if { [empty_string_p $risk_customer_id] } {
    set risk_customer_id 0
}

set company_options [im_company_options -include_empty_p 1 -include_empty_name "All" -status "CustOrIntl"]
set project_options [im_project_options -include_empty 1 -include_empty_name "All" ]

# Get the list of profiles readable for current_user_id
set managable_profiles [im_profile::profile_options_managable_for_user -privilege "read" $current_user_id]
# Extract only the profile_ids from the managable profiles
set user_select_groups {}
foreach g $managable_profiles {
    lappend user_select_groups [lindex $g 1]
}
set user_options [im_profile::user_options -profile_ids $user_select_groups]
set user_options [linsert $user_options 0 [list "All" ""]]

ad_form -extend -name $form_id -form {
    {risk_customer_id:text(select),optional {label \#intranet-riskmanagement.Customer\#} {options $company_options}}
    {risk_project_id:text(select),optional {label \#intranet-riskmanagement.Project\#} {options $project_options}}
    {risk_type_id:text(im_category_tree),optional {label \#intranet-riskmanagement.Risk_Type\#} {value $risk_type_id} {custom {category_type "Intranet Risk Type" translate_p 1} } }
    {risk_status_id:text(im_category_tree),optional {label \#intranet-riskmanagement.Risk_Status\#} {value $risk_status_id} {custom {category_type "Intranet Risk Status" translate_p 1 include_empty_name All} } }
    {user_id_from_search:text(select),optional {label \#intranet-riskmanagement.With_Member\#} {options $user_options}}
    {start_date:text(text) {label "[_ intranet-timesheet2.Start_Date]"} {value "$start_date"} {html {size 10}} {after_html {<input type="button" style="height:20px; width:20px; background: url('/resources/acs-templating/calendar.gif');" onclick ="return showCalendar('start_date', 'y-m-d');" >}}}
    {end_date:text(text) {label "[_ intranet-timesheet2.End_Date]"} {value "$end_date"} {html {size 10}} {after_html {<input type="button" style="height:20px; width:20px; background: url('/resources/acs-templating/calendar.gif');" onclick ="return showCalendar('end_date', 'y-m-d');" >}}}
}

im_dynfield::append_attributes_to_form \
    -object_type $object_type \
    -form_id $form_id \
    -object_id 0 \
    -advanced_filter_p 1
    
# Set the form values from the HTTP form variable frame
im_dynfield::set_form_values_from_http -form_id $form_id
im_dynfield::set_local_form_vars_from_http -form_id $form_id

array set extra_sql_array [im_dynfield::search_sql_criteria_from_form -form_id $form_id -object_type $object_type]


# ------------------------------------------------------------------
# 
# ------------------------------------------------------------------

set action_list [list]
set bulk_action_list [list]

lappend action_list [lang::message::lookup "" intranet-riskmanagement.Add_new_risk "Add a new Risk"]
lappend action_list [export_vars -base "/intranet-riskmanagement/new" {return_url risk_project_id}]
lappend action_list [lang::message::lookup "" intranet-riskmanagement.Add_new_risk "Add a new Risk"]

lappend bulk_action_list "[lang::message::lookup "" intranet-riskmanagement.Delete_Risk "Delete Risk"]" "[export_vars -base "/intranet-riskmanagement/delete" {return_url}]" "[lang::message::lookup "" intranet-riskmanagement.Delete_Risk "Delete Risk"]"

list::create \
    -name risks \
    -multirow risks_multirow \
    -key risk_id \
    -row_pretty_plural "Risks" \
    -checkbox_name checkbox \
    -selected_format "normal" \
    -class "list" \
    -main_class "list" \
    -sub_class "narrow" \
    -actions $action_list \
    -bulk_actions $bulk_action_list \
    -elements {
        risk_name {
            label {Risk Name}
            link_url_eval $risk_url
        }
        risk_type {
            display_col risk_type
            label "Risk Type"
        }        
    } -filters {
    } -groupby {
    }

# ----------------------------------------------------
# Create a "multirow" for risks

set criteria {}
if {"" != $risk_project_id} {
    lappend criteria "r.risk_project_id = :risk_project_id"
}
if {"" != $risk_ids} {
    im_security_alert_check_integer -location "intranet-riskmanagement/index" -value $risk_ids
    lappend criteria "r.risk_id in ([join $risk_ids ","])"
}

set where_clause [join $criteria "\n\t\t"]
if {{} != $criteria} { set where_clause "and \n\t\t$where_clause" }


db_multirow -extend { risk_url } risks_multirow risks_select "
	select	*,
		im_category_from_id(r.risk_type_id) as risk_type,
		im_category_from_id(r.risk_status_id) as risk_status
	from	im_risks r
	where	1=1
		$where_clause
" {
    set risk_url [export_vars -base "/intranet-riskmanagement/new" {risk_id return_url {form_mode display}}]
}


# ---------------------------------------------------------------
# Admin Links
# ---------------------------------------------------------------

set admin_html "<ul>"

if {$object_write} {
    append admin_html "<li><a href=\"/intranet-riskmanagement/new\">[_ intranet-riskmanagement.Add_a_new_risk]</a>\n"
}

# ---------------------------------------------------------------
# Navbars
# ---------------------------------------------------------------

# Compile and execute the formtemplate if advanced filtering is enabled.
eval [template::adp_compile -string {<formtemplate id="risk_filter" style="tiny-plain"></formtemplate>}]
set filter_html $__adp_output

# Left Navbar is the filter/select part of the left bar
set left_navbar_html "
	<div class='filter-block'>
        	<div class='filter-title'>
	           #intranet-riskmanagement.Filter_Risks#
        	</div>
            	$filter_html
      	</div>
      <hr/>
"

append left_navbar_html "
      	<div class='filter-block'>
        <div class='filter-title'>
            #intranet-riskmanagement.Admin_Risks#
        </div>
	$admin_html
      	</div>
"
