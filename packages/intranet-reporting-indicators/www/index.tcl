# /packages/intranet-reporting/www/indicators.tcl
#
# Copyright (c) 2007 ]project-open[
# All rights reserved
#

ad_page_contract {
    Show all the Reports

    @param object_type 
	Selects only indicators made for a specific
        object type (i.e. im_project). If empty, this
	page will only show indicators with an empty
	indicator_object_type.
	This way it is possible to create indicators
	that take an object_id as a parameter.
    @author frank.bergmann@project-open.com
} {
    { return_url "" }
    { object_type "" }
    { object_id "" }
    { start_date "2000-01-01" }
    { end_date "2099-12-31" }
}

# ------------------------------------------------------
# Defaults & Security
# ------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set user_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
set add_reports_p [im_permission $current_user_id "add_reports"]

set current_url [im_url_with_query]
if {"" == $return_url} { set return_url [ad_conn url] }
set page_title [lang::message::lookup "" intranet-reporting.Indicators "Indicators"]
set context_bar [im_context_bar $page_title]
set context ""

# Did the user specify an object? Then show only indicators 
# designed to be shown with that object.
set o_object_type ""
if {"" != $object_id} { set o_object_type [db_string otype "select object_type from acs_objects where object_id = :object_id" -default ""] }


# Do we need to get a sample object?
if {("" != $object_type && $object_type != $o_object_type) || ("" != $object_type && "" == $object_id)} {
    # User needs to specify a sample object
    ad_returnredirect [export_vars -base "index-object-select" {{return_url $current_url} object_type return_url}]
}


set history_sql "
	select	result,
		result_indicator_id,
		result_date
	from
		im_indicator_results
"

db_foreach history $history_sql {
	set results_${result_indicator_id}($result_date) $result
}


set indicator_html [im_indicator_timeline_component \
			-start_date $start_date \
			-end_date $end_date \
			-object_id $object_id \
			-object_type $object_type \
			-indicator_section_id "" \
]


# ---------------------------------------------------------------
# Format the Filter
# ---------------------------------------------------------------

set object_type_options [list "" "" "im_project" "Project" "im_sla_parameter" "SLA Parameter"]

set object_options_sql "
	select	*
	from	(select	acs_object__name(object_id) as object_name,
			object_id
		from	acs_objects o
		where	o.object_type = :object_type) o
	where
		object_name is not null and
		object_name != ''
	order by object_name
"
if {"" != $object_type} {
    set object_options [db_list_of_lists ooptions $object_options_sql]
}



set filter_html "
	<form method=get action='$return_url' name=filter_form>
	[export_form_vars return_url]
	<table border=0 cellpadding=0 cellspacing=0>
	<tr>
	  <td valign=top>[lang::message::lookup "" intranet-reporting-indicators.Start_Date "Start Date"] </td>
	  <td valign=top><input type=text name=start_date value=\"$start_date\"></td>
	</tr>
	<tr>
	  <td valign=top>[lang::message::lookup "" intranet-reporting-indicators.End_Date "End Date"] </td>
	  <td valign=top><input type=text name=end_date value=\"$end_date\"></td>
	</tr>
	<tr>
	  <td valign=top>[lang::message::lookup "" intranet-reporting-indicators.Object_Type "Object Type"] </td>
	  <td valign=top>[im_select object_type $object_type_options {}]</td>
	</tr>
"

if {"" != $object_type} {
    append filter_html "
	<tr>
	  <td valign=top>[lang::message::lookup "" intranet-reporting-indicators.Object "Object"] </td>
	  <td valign=top>[im_select -ad_form_option_list_style_p 1 object_id $object_options $object_id]</td>
	</tr>
    "	
}

append filter_html "
	<tr>
	  <td valign=top>&nbsp;</td>
	  <td valign=top><input type=submit value='[_ intranet-timesheet2.Go]' name=submit></td>
	</tr>
	</table>
	</form>
"


# ---------------------------------------------------------------
# Left Navbar
# ---------------------------------------------------------------

set admin_html ""
if {$add_reports_p} { append admin_html "<li><a href='[export_vars -base "new" {{indicator_object_type $object_type} {form_mode edit} return_url}]'>Add a new Indicator</a></li>\n" }

set left_navbar_html "
            <div class=\"filter-block\">
                <div class=\"filter-title\">
                [lang::message::lookup "" intranet-reporting-indicators.Filter_Indicators "Filter Indicators"]
                </div>
                $filter_html
            </div>
            <hr/>
"

if {$user_admin_p} {
	append left_navbar_html "
            <div class=\"filter-block\">
                <div class=\"filter-title\">
                [lang::message::lookup "" intranet-reporting-indicators.Admin_Indicators "Admin Indicators"]
                </div>
                $admin_html
            </div>
	"
}
