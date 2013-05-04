# /packages/intranet-riskmanagement/www/project-risks-report.tcl
#
# Copyright (c) 2003-2013 ]project-open[
#
# All rights reserved. 
# Please see http://www.project-open.com/ for licensing.

ad_page_contract {
    Lists risks per project, taking into account DynFields.
} {
    { project_id "" }
    { level_of_detail:integer 3 }
    { output_format "html" }
    { number_locale "" }
}

# ------------------------------------------------------------
# Security
#
set menu_label "reporting-project-risks"
set current_user_id [ad_maybe_redirect_for_registration]
set read_p [db_string report_perms "
	select	im_object_permission_p(m.menu_id, :current_user_id, 'read')
	from	im_menus m
	where	m.label = :menu_label
" -default 'f']

# For testing - set manually
set read_p "t"

if {![string equal "t" $read_p]} {
    set message "You don't have the necessary permissions to view this page"
    ad_return_complaint 1 "<li>$message"
    ad_script_abort
}


# ------------------------------------------------------------
# Check Parameters
#

# Maxlevel is 3. 
if {$level_of_detail > 3} { set level_of_detail 3 }

# Default is user locale
if {"" == $number_locale} { set number_locale [lang::user::locale] }



# ------------------------------------------------------------
# Page Title, Bread Crums and Help
#
set page_title [lang::message::lookup "" intranet-riskmanagement.Project_Risks "Project Risks"]
set context_bar [im_context_bar $page_title]
set help_text "
	<strong>$page_title:</strong><br>
	[lang::message::lookup "" intranet-riskmanagement.Project_Risks_help "
	This report returns a list of risks per project<br>
	or the list of all risks in the system if called without<br>
	a specific project.
"]"


# ------------------------------------------------------------
# Default Values and Constants
#
set rowclass(0) "roweven"
set rowclass(1) "rowodd"

# Variable formatting - Default formatting is quite ugly
# normally. In the future we will include locale specific
# formatting. 
#
set currency_format "999,999,999.09"
set percentage_format "90.9"
set date_format "YYYY-MM-DD"

# Set URLs on how to get to other parts of the system for convenience.
set company_url "/intranet/companies/view?company_id="
set project_url "/intranet/projects/view?project_id="
set risk_url "/intranet-riskmanagement/new?form_mode=display&risk_id="
set user_url "/intranet/users/view?user_id="
set this_url "[export_vars -base "/intranet-riskmanagement/project-risks-report" {} ]?"

# Level of Details
# Determines the LoD of the grouping to be displayed
#
set levels [list \
    2 [lang::message::lookup "" intranet-riskmanagement.Risks_per_Project "Risks per Project"] \
    3 [lang::message::lookup "" intranet-riskmanagement.All_Details "All Details"] \
]


# ------------------------------------------------------------
# Report SQL
#

# Get dynamic risk fields
#
set deref_list [im_dynfield::object_attributes_derefs -object_type "im_risk" -prefix "r."]
set deref_extra_select [join $deref_list ",\n\t"]
if {"" != $deref_extra_select} { set deref_extra_select ",\n\t$deref_extra_select" }


set project_sql ""
if {"" != $project_id && 0 != $project_id} {
    set project_sql "and p.project_id = :project_id\n"
} else {
    # No specific project set - show all open projects
    set project_sql "and p.project_status_id in (select * from im_sub_categories([im_project_status_open]))"
}

set report_sql "
	select
		r.*,
		risk_impact * risk_probability_percent as risk_value,
		im_category_from_id(r.risk_type_id) as risk_type,
		im_category_from_id(r.risk_status_id) as risk_status,
		p.project_id,
		p.project_nr,
		p.project_name
		$deref_extra_select
	from
		im_risks r,
		im_projects p
	where
		r.risk_project_id = p.project_id and
		p.parent_id is null
		$project_sql
	order by
		lower(p.project_nr),
		risk_value DESC
"


# ------------------------------------------------------------
# Report Definition
#

# Global Header
set header0 {
	"Project"
	"Risk Name"
	"Risk Value"
	"Probability"
	"Impact"
	"Type"
	"Status"
	"Description"
}

# Main content line
set risk_header_vars {
	"$project_nr"
	"<a href='$risk_url$risk_id'>$risk_name_pretty</a>"
	$risk_value_pretty
	$risk_probability_percent_pretty
	$risk_impact_pretty
	$risk_type
	$risk_status
	$risk_description
}


# ------------------------------------------------------------
# Add risk DynFields

set dynfield_sql "
	select  aa.attribute_name,
		aa.pretty_name,
		w.widget as tcl_widget,
		w.widget_name as dynfield_widget
	from	im_dynfield_attributes a,
		im_dynfield_widgets w,
		acs_attributes aa
	where	a.widget_name = w.widget_name and 
		a.acs_attribute_id = aa.attribute_id and
		aa.object_type in ('im_risk') and
		-- Exclude the default hard-coded fields
		aa.attribute_name not in ('risk_impact', 'risk_probability_percent')
	order by
		aa.object_type,
		aa.sort_order
"

set derefs [list]
db_foreach dynfield_attributes $dynfield_sql {
    lappend header0 $pretty_name
    lappend risk_header_vars "\$${attribute_name}_deref"
}


set project_header {
	"\#colspan=10 <a href=$this_url&project_id=$project_id&level_of_detail=3
	target=_blank><img src=/intranet/images/plus_9.gif width=9 height=9 border=0></a> 
	<b><a href=$project_url$project_id>$project_name</a></b>"
}

# Disable project headers for CSV output
# in order to create one homogenous exportable  lst
if {"csv" == $output_format} { set project_header "" }

# The entries in this list include <a HREF=...> tags
# in order to link the entries to the rest of the system (New!)
#
set report_def [list \
    group_by project_id \
    header $project_header \
    content [list \
	group_by risk_id \
	header $risk_header_vars \
	content {} \
    ] \
    footer {} \
]


# Global Footer Line
set footer0 {}


# ------------------------------------------------------------
# Counters
#

#
# Subtotal Counters (per project)
#
set project_risk_value_counter [list \
	pretty_name "Risk Value" \
	var risk_value \
	reset \$project_id \
	expr "\$risk_value+0" \
]

set project_risk_value_total_counter [list \
	pretty_name "Risk Value Total" \
	var risk_value_total \
	reset 0 \
	expr "\$risk_value+0" \
]


set counters [list \
	$project_risk_value_counter \
	$project_risk_value_total_counter \
]

# Set the values to 0 as default (New!)
set risk_value 0
set risk_value_total 0

# ------------------------------------------------------------
# Start Formatting the HTML Page Contents
#

im_report_write_http_headers -report_name $menu_label -output_format $output_format

switch $output_format {
    html {
	ns_write "
	[im_header]
	[im_navbar]
	<table cellspacing=0 cellpadding=0 border=0>
	<tr valign=top>
	  <td width='30%'>
		<!-- 'Filters' - Show the Report parameters -->
		<form>
		<table cellspacing=2>
		<tr class=rowtitle>
		  <td class=rowtitle colspan=2 align=center>Filters</td>
		</tr>
		<tr>
		  <td>Level of<br>Details</td>
		  <td>
		    [im_select -translate_p 0 level_of_detail $levels $level_of_detail]
		  </td>
		</tr>
		<tr>
		  <td>[lang::message::lookup "" intranet-core.Project Project]:</td>
		  <td>[im_project_select -include_empty_p 1 project_id $project_id]</td>
		</tr>
		<tr>
		  <td class=form-label>[lang::message::lookup "" intranet-reporting.Output_Format Format]</td>
		  <td class=form-widget>
		    [im_report_output_format_select output_format "" $output_format]
		  </td>
		</tr>
		<tr>
		  <td class=form-label><nobr>[lang::message::lookup "" intranet-reporting.Number_Format "Number Format"]</nobr></td>
		  <td class=form-widget>
		    [im_report_number_locale_select number_locale $number_locale]
		  </td>
		</tr>
		<tr>
		  <td</td>
		  <td><input type=submit value='Submit'></td>
		</tr>
		</table>
		</form>
	  </td>
	  <td align=center>
		<table cellspacing=2 width='90%'>
		<tr>
		  <td>$help_text</td>
		</tr>
		</table>
	  </td>
	</tr>
	</table>
	
	<!-- Here starts the main report table -->
	<table border=0 cellspacing=1 cellpadding=1>
    "
    }
}

set footer_array_list [list]
set last_value_list [list]

im_report_render_row \
    -output_format $output_format \
    -row $header0 \
    -row_class "rowtitle" \
    -cell_class "rowtitle"

set counter 0
set class ""
db_foreach sql $report_sql {
	set class $rowclass([expr $counter % 2])

	set risk_value_pretty [im_report_format_number $risk_value $output_format $number_locale]
	set risk_impact_pretty [im_report_format_number $risk_impact $output_format $number_locale]
	set risk_probability_percent_pretty [im_report_format_number $risk_probability_percent $output_format $number_locale]

	# Restrict the length of the project_name to max.
	# 40 characters. (New!)
	set risk_name_pretty [string_truncate -len 40 $risk_name]

	im_report_display_footer \
	    -output_format $output_format \
	    -group_def $report_def \
	    -footer_array_list $footer_array_list \
	    -last_value_array_list $last_value_list \
	    -level_of_detail $level_of_detail \
	    -row_class $class \
	    -cell_class $class

	im_report_update_counters -counters $counters

	set last_value_list [im_report_render_header \
	    -output_format $output_format \
	    -group_def $report_def \
	    -last_value_array_list $last_value_list \
	    -level_of_detail $level_of_detail \
	    -row_class $class \
	    -cell_class $class
	]

	set footer_array_list [im_report_render_footer \
	    -output_format $output_format \
	    -group_def $report_def \
	    -last_value_array_list $last_value_list \
	    -level_of_detail $level_of_detail \
	    -row_class $class \
	    -cell_class $class
	]

	incr counter
}

im_report_display_footer \
    -output_format $output_format \
    -group_def $report_def \
    -footer_array_list $footer_array_list \
    -last_value_array_list $last_value_list \
    -level_of_detail $level_of_detail \
    -display_all_footers_p 1 \
    -row_class $class \
    -cell_class $class

im_report_render_row \
    -output_format $output_format \
    -row $footer0 \
    -row_class $class \
    -cell_class $class \
    -upvar_level 1


# Write out the HTMl to close the main report table
#
switch $output_format {
    html {
	ns_write "</table>\n"
	ns_write "<br>&nbsp;<br>"
	ns_write [im_footer]
    }
}

