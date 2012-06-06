# /packages/intranet-sla-management/www/sla-parameter-indicator_component.tcl
#
# Copyright (c) 2010 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# This indicator is executed from within the view page for a project
# of sub-type "Service Level Agreement". It shows a list of indicators,
# one for each SLA parameter.
#
# The component is called with a parameter "project_id" representing
# the SLA project.

# ---------------------------------------------------------------
# Variables
# ---------------------------------------------------------------

#    { project_id:integer "" }
#    return_url 

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set add_reports_p [im_permission $current_user_id "add_reports"]
set view_reports_all_p [im_permission $current_user_id "view_reports_all"]

set bgcolor(0) " class=roweven "
set bgcolor(1) " class=rowodd "

if {"" == $return_url} { set return_url [ad_conn url] }
set page_title [lang::message::lookup "" intranet-sla-parameters.SLA_Parameters "SLA Parameters"]
set context_bar [im_context_bar $page_title]
set context ""

# Evaluate indicators every X hours:
set eval_interval_hours [parameter::get_from_package_key -package_key "intranet-reporting-indicators" -parameter "IndicatorEvaluationIntervalHours" -default 24]

# Perms: Can the user add reports?
set add_reports_p [im_permission $current_user_id "add_reports"]

# Permissions: Check read permissions on the SLA
if {![info exists project_id]} { ad_return_complaint 1 "sla-parameter-indicator-component.tcl: variable project_id not defined" }
im_project_permissions $current_user_id $project_id sla_view sla_read sla_write sla_admin
# $read is queries in the .adp template

set permission_sql "and 't' = im_object_permission_p(i.indicator_id, :current_user_id, 'read')"
#if {$view_reports_all_p} { set permission_sql "" }



# ---------------------------------------------------------------
# Header: We need to show a list of parameter DynFields
# ---------------------------------------------------------------

set header_html ""
append header_html "<tr class=rowtitle>\n"
append header_html "<td class=rowtitle><input type=checkbox name=_dummy onclick=\"acs_ListCheckAll('param',this.checked)\"></td>\n"
append header_html "<td class=rowtitle>[lang::message::lookup "" intranet-sla-management.Parameter_Name "Name"]</td>\n"

# Loop through DynFilds of the im_sla_parameter
set column_sql "
        select  w.deref_plpgsql_function,
                aa.attribute_name,
                aa.pretty_name
        from    im_dynfield_widgets w,
                im_dynfield_attributes a,
                acs_attributes aa
        where   a.widget_name = w.widget_name and
                a.acs_attribute_id = aa.attribute_id and
                aa.object_type = 'im_sla_parameter'
"
set extra_selects [list "0 as zero"]
set dynfield_attributes [list]
db_foreach column_list_sql $column_sql {

    # Select another field
    lappend extra_selects "${deref_plpgsql_function}($attribute_name) as ${attribute_name}_deref"

    # Show this field in the title
    append header_html "<td class=rowtitle>[lang::message::lookup "" intranet-sla-management.$attribute_name $pretty_name]</td>\n"

    # Add the field name to the list of DynFields to be shown
    lappend dynfield_attributes $attribute_name
}
set extra_select [join $extra_selects ",\n\t\t"]

append header_html "</tr>\n"


# ---------------------------------------------------------------
# The SLA-Parameter + Indicator SQL
# ---------------------------------------------------------------

set indicator_sql "
	select
		sp.*,
		i.*,
		$extra_select,
		im_category_from_id(i.indicator_section_id) as section,
		ir.result
	from
		im_sla_parameters sp
		LEFT OUTER JOIN (
			-- Select out all indicators with
			-- their relationship to sla_parameters
			select	
				re.object_id_one as param_id_rel,
				r.*,
				i.*
			from
				im_reports r,
				im_indicators i,
				acs_rels re,
				im_sla_param_indicator_rels spir
			where	
				re.rel_id = spir.rel_id and
				re.object_id_two = r.report_id and
				r.report_id = i.indicator_id and
				r.report_type_id = [im_report_type_indicator] and
				i.indicator_object_type = 'im_sla_parameter'
				$permission_sql
		) i ON (sp.param_id = i.param_id_rel)
		LEFT OUTER JOIN (
			select	avg(result) as result,
				result_indicator_id
			from	im_indicator_results
			where	result_date >= now() - '$eval_interval_hours hours'::interval
			group by result_indicator_id
		) ir ON (i.indicator_id = ir.result_indicator_id)
	where
		sp.param_sla_id = :project_id
	order by 
		lower(sp.param_name),
		lower(i.report_name)
"

# ---------------------------------------------------------------
# Body: We need to show a list of parameter DynFields
# ---------------------------------------------------------------

# We have a double loop here with:
#	1st: parameter: We need to show paramer DynFiends and
#	2nd: indicator: We need to render the indicator

set body_html ""
set old_param_id ""
set param_cnt 0
set indicator_cnt 0
set colspan [expr [llength $dynfield_attributes] + 2]

# Read the results into a multirow because
# the "evaluate" needs to alloc an additional DB connection
db_multirow param_indicators param_indicators $indicator_sql
template::multirow foreach param_indicators {

    set param_view_url [export_vars -base "/intranet-sla-management/new" {param_id {form_mode display} return_url}]

    # Check if the parameter has changed.
    # In this case show the param plus DynFields
    if {$old_param_id != $param_id} {

	set row_html "<tr class=rowtitle>\n"
#	if {$indicator_cnt > 0} { set row_html "<td colspan=$colspan><hr></td></tr>\n<tr>\n" }
	append row_html "<td class=rowtitle><input type=checkbox name=param value=$param_id id=\"param,$param_id\"></td>\n"
	append row_html "<td class=rowtitle><a href='$param_view_url'>$param_name</a></td>\n"
	# Append the values of the dynfield attributes
	foreach da $dynfield_attributes {
	    append row_html "<td class=rowtitle>[eval "set a \$${da}_deref"]</td>\n"
	}
	append row_html "</tr>\n"
	append body_html $row_html
	set old_param_id $param_id
	incr param_cnt
    }

    if {"" != $indicator_id} {
	set result ""
        if {"" == $result} {

	    set result [im_indicator_evaluate \
			    -report_id $indicator_id \
			    -report_sql $report_sql \
			    -object_id $param_id \
			   ]
	    ns_log Notice "sla-parameter-indicator-component: report_id=$indicator_id, object_id=$project_id, result=$result"

	}

#	if {[regexp {^([0-9]*)\.([0-9][0-9])} $result match body fraction]} { set result "$body.$fraction" }
	if {[string is double $result]} { set result [expr round(100.0 * $result) / 100.0] }

	set diagram_html [im_indicator_horizontal_bar \
			      -name $report_name \
			      -value $result \
			      -widget_min $indicator_widget_min \
			      -widget_min_red $indicator_low_critical \
			      -widget_min_yellow $indicator_low_warn \
			      -widget_max_yellow $indicator_high_warn \
			      -widget_max_red $indicator_high_critical \
			      -widget_max $indicator_widget_max \
			     ]
	if {"" == $result} {
	    set diagram_html "No value yet for indicator '$report_name'"
	}

	set base_url "/intranet-reporting-indicators"
	set indicator_view_url [export_vars -base "$base_url/view" {indicator_id return_url}]
	set indicator_edit_url [export_vars -base "$base_url/new" {indicator_id}]
	set indicator_perms_url [export_vars -base "$base_url/perms" {{object_id $indicator_id}}]
	set indicator_delete_url [export_vars -base "$base_url/delete" {indicator_id return_url}]

	set edit_html "
	        <a href='$indicator_edit_url'>[im_gif "wrench"]</a><br>
	        <a href='$indicator_perms_url'>[im_gif "lock"]</a><br>
	        <a href='$indicator_delete_url'>[im_gif "cancel"]</a>
        "
	if {!$add_reports_p} { set edit_html "" }

	set row_html ""
	append row_html "<tr $bgcolor([expr $indicator_cnt % 2])>\n"
	append row_html "<td>&nbsp;</td>\n"
#	append row_html "<td><input type=checkbox name=indicator value=$indicator_id></input></td>\n"
	set indicator_url [export_vars -base "/intranet-reporting-indicators/view" {indicator_id}]
	append row_html "<td colspan=$colspan valign=middle>\n"
	append row_html "<table><tr>\n"
	append row_html "<td><b>$result</b></td>\n"
	append row_html "<td>$diagram_html<br></td>\n"
	append row_html "<td>$edit_html</td>\n"
	append row_html "<td><a href=$indicator_url>$report_name</a></td>\n"
	append row_html "</tr></table>\n"
	append row_html "</td>\n"
	append row_html "</tr>\n"
	append body_html $row_html

	incr indicator_cnt
    }
}

set footer_html ""
set action_html ""
if {$sla_write} {

    set submit_msg [lang::message::lookup "" intranet-core.Submit Submit]
    append action_html "<tr><td colspan=$colspan>\n"
    append action_html "<select name=action>\n"
    append action_html "<option value='associate_indicator'>Associate Parameter with Existing Indicator</option>\n"
#    append action_html "<option value='new_indicator'>New Indicator for Parameter</option>\n"
    append action_html "</select>\n"
    append action_html "<input type=submit name=submit value=$submit_msg>\n"
    append action_html "</td><tr>\n"

    set new_param_url [export_vars -base "/intranet-sla-management/new" {return_url {param_sla_id $project_id}}]
    append footer_html "<ul>\n"
    append footer_html "<li><a href='$new_param_url'>[lang::message::lookup "" intranet-sla-management.Create_a_New_SLA_Parameter "Create a New SLA Parameter"]</a></li>\n"
    set new_indicator_url [export_vars -base "/intranet-reporting-indicators/new" {return_url}]
    append footer_html "<li><a href='$new_indicator_url'>[lang::message::lookup "" intranet-sla-management.Create_a_New_Indicator "Create a New Indicator"]</a></li>\n"
    append footer_html "<li><a href='http://www.project-open.org/documentation/process_sla_management'>[lang::message::lookup "" intranet-sla-management.SLA_Management_Help "SLA Management Help"]</a></li>\n"
    append footer_html "</ul>\n"
}

append body_html $action_html

