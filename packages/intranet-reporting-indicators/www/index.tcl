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
}

# ------------------------------------------------------
# Defaults & Security
# ------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set user_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
set add_reports_p [im_permission $current_user_id "add_reports"]
set view_reports_all_p [im_permission $current_user_id "view_reports_all"]

set current_url [im_url_with_query]
if {"" == $return_url} { set return_url [ad_conn url] }
set page_title [lang::message::lookup "" intranet-reporting.Indicators "Indicators"]
set context_bar [im_context_bar $page_title]
set context ""

set wiki_url "http://www.project-open.org/documentation"

# Evaluate indicators every X hours:
set eval_interval_hours [parameter::get_from_package_key -package_key "intranet-reporting-indicators" -parameter "IndicatorEvaluationIntervalHours" -default 24]

# Did the user specify an object? Then show only indicators 
# designed to be shown with that object.
set o_object_type ""
if {"" != $object_id} { set o_object_type [db_string otype "select object_type from acs_objects where object_id = :object_id" -default ""] }


# Do we need to get a sample object?
if {("" != $object_type && $object_type != $o_object_type) || ("" != $object_type && "" == $object_id)} {
    # User needs to specify a sample object
    ad_returnredirect [export_vars -base "index-object-select" {{return_url $current_url} object_type return_url}]
}


# ------------------------------------------------------
# List creation
# ------------------------------------------------------

set elements_list {
    section {
	label "Section"
	display_template {
	    @reports.section@
	}
    }
    name {
	label $page_title
	display_template {
	    <a href=@reports.report_view_url@>@reports.report_name@</a>
	}
    }
}

if {$add_reports_p} {
    lappend elements_list \
	edit {
	    label "[im_gif wrench]"
	    display_template {
		@reports.edit_html;noquote@
	    }
	}
}

lappend elements_list \
	value {
	    label "Value"
	    display_template {
		@reports.value_html;noquote@
	    }
	}

lappend elements_list \
	history {
	    label "History"
	    display_template {
		@reports.history_html;noquote@
	    }
	}

lappend elements_list \
	report_description {
	    label "Description"
	    display_template {
		@reports.report_description;noquote@
	    }
	}


list::create \
        -name report_list \
        -multirow reports \
        -key menu_id \
        -elements $elements_list \
        -filters {
        	return_url
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


set object_type_sql "and (indicator_object_type is null OR indicator_object_type = '')"
if {"" != $object_type} { set object_type_sql "and lower(indicator_object_type) = lower(:object_type)" }



set permission_sql "and 't' = im_object_permission_p(r.report_id, :current_user_id, 'read')"
if {$view_reports_all_p} { set permission_sql "" }

db_multirow -extend {report_view_url edit_html value_html history_html} reports get_reports "
	select
		r.*,
		i.*,
		im_category_from_id(i.indicator_section_id) as section,
		ir.result
	from
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
		r.report_id = i.indicator_id and
		r.report_type_id = [im_report_type_indicator]
		$object_type_sql
		$permission_sql
	order by 
		section
" {
    set report_view_url [export_vars -base "view" {indicator_id return_url}]
    set report_edit_url [export_vars -base "new" {indicator_id}]
    set perms_url [export_vars -base "perms" {{object_id $indicator_id}}]
    set delete_url [export_vars -base "delete" {indicator_id return_url}]
    set edit_html "
	<a href='$report_edit_url'>[im_gif "wrench"]</a><br>
	<a href='$perms_url'>[im_gif "lock"]</a><br>
	<a href='$delete_url'>[im_gif "cancel"]</a>
    "

    regsub -all " " $report_name "_" indicator_name_mangled
    set help_url "$wiki_url/indicator_[string tolower $indicator_name_mangled]"
    set report_description "
	$report_description
	<a href=\"$help_url\">[lang::message::lookup "" intranet-reporting-indicators.More_dots "more..."]</a><br>
    "

    if {"" == $result} {
	set substitution_list [list user_id $current_user_id object_id $object_id]
	set result [im_indicator_evaluate \
			-report_id $report_id \
			-object_id $object_id \
			-report_sql $report_sql \
			-substitution_list $substitution_list \
		       ]
    }	
    
    set value_html $result
    set history_html ""

    if {"error" != $result && "" != $result} {

	set indicator_sql "
	        select	result_date, result
	        from	im_indicator_results
	        where	result_indicator_id = :report_id
	        order by result_date
        "
	set values [db_list_of_lists results $indicator_sql]
	
	set min $indicator_widget_min
	if {"" == $min} { set min 1000000 }
	set max $indicator_widget_max
	if {"" == $max} { set max -1000000 }
	
	foreach vv $values { 
	    set v [lindex $vv 1]
	    if {$v < $min} { set min $v }
	    if {$v > $max} { set max $v }
	}
	
	set history_html ""
	set history_html [im_indicator_timeline_widget \
			  -name $report_name \
			  -values $values \
			  -widget_min $min \
			  -widget_max $max \
        ]
    }

}




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
if {$add_reports_p} { append admin_html "<li><a href='[export_vars -base "new" {{indicator_object_type $object_type} return_url}]'>Add a new Indicator</a></li>\n" }

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
