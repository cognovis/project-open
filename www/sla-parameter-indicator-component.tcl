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

# Permissions: Check read permissions on the SLA
if {![info exists project_id]} { ad_return_complaint 1 "sla-parameter-indicator-component.tcl: variable project_id not defined" }
im_project_permissions $current_user_id $project_id sla_view sla_read sla_write sla_admin
# $read is queries in the .adp template

set permission_sql "and 't' = im_object_permission_p(r.report_id, :current_user_id, 'read')"
#if {$view_reports_all_p} { set permission_sql "" }



# ---------------------------------------------------------------
# Header: We need to show a list of parameter DynFields
# ---------------------------------------------------------------

set header_html ""
append header_html "<tr class=rowtitle>\n"
append header_html "<td><input type=checkbox name=_dummy onclick=\"acs_ListCheckAll('param',this.checked)\"></td>\n"
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
		r.*,
		i.*,
		$extra_select,
		im_category_from_id(i.indicator_section_id) as section,
		ir.result
	from
		im_sla_parameters sp,
		acs_rels re,
		im_sla_param_indicator_rels spir,
		im_reports r,
		im_indicators i
		LEFT OUTER JOIN (
			select	avg(result) as result,
				result_indicator_id
			from	im_indicator_results
			where	result_date >= now() - '$eval_interval_hours hours'::interval
			group by result_indicator_id
		) ir ON (i.indicator_id = ir.result_indicator_id)
	where
		sp.param_sla_id = :project_id and
		re.object_id_one = sp.param_id and
		re.object_id_two = r.report_id and
		re.rel_id = spir.rel_id and
		r.report_id = i.indicator_id and
		r.report_type_id = [im_report_type_indicator] and
		i.indicator_object_type = 'im_sla_parameter'
		$permission_sql
	order by 
		lower(sp.param_name),
		lower(r.report_name)
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
db_foreach param_indicators $indicator_sql {

    set param_view_url [export_vars -base "/intranet-sla-management/new" {param_id {form_mode display} return_url}]

    # Check if the parameter has changed.
    # In this case show the param plus DynFields
    if {$old_param_id != $param_id} {

	set row_html ""
	append row_html "<td><input type=checkbox name=param value=$param_id id=\"param,$param_id\"></td>\n"
	append row_html "<td><a href='$param_view_url'>$param_name</a></td>\n"
	# Append the values of the dynfield attributes
	foreach da $dynfield_attributes {
	    append row_html "<td>[eval "set a \$${da}_deref"]</td>\n"
	}

	append body_html $row_html
	incr param_cnt
    }

    set diagram_html [im_indicator_horizontal_bar \
			  -name "test" \
			  -value $result \
			  -widget_min $indicator_widget_min \
			  -widget_min_red $indicator_low_critical \
			  -widget_min_yellow $indicator_low_warn \
			  -widget_max_yellow $indicator_high_warn \
			  -widget_max_red $indicator_high_critical \
			  -widget_max $indicator_widget_max \
			 ]

    set row_html ""
    append row_html "<tr $bgcolor([expr $indicator_cnt % 2])>\n"
    append row_html "<td colspan=$colspan>$diagram_html</td>\n"
    append row_html "</tr>\n"
    append body_html $row_html

    incr indicator_cnt
}

set footer_html ""
set action_html ""
if {$sla_write} {

    set submit_msg [lang::message::lookup "" intranet-core.Submit Submit]
    append action_html "<tr><td colspan=$colspan>\n"
    append action_html "<select name=action>\n"
    append action_html "<option name=''></option>\n"
    append action_html "</select>\n"
    append action_html "<input type=submit name=submit value=$submit_msg>\n"
    append action_html "</td><tr>\n"
    set action_html ""

    append footer_html "<ul>\n"
    append footer_html "<li><a href=''>[lang::message::lookup "" intranet-sla-management.Create_a_New_SLA_Parameter "Create a New SLA Parameter"]</a></li>\n"
    append footer_html "<li><a href='http://www.project-open.org/documentation/process_sla_management'>[lang::message::lookup "" intranet-sla-management.SLA_Management_Help "SLA Management Help"]</a></li>\n"
    append footer_html "</ul>\n"
}

append body_html $action_html

