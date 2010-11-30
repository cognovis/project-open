# /packages/intranet-reporting/www/indicators.tcl
#
# Copyright (c) 2007 ]project-open[
# All rights reserved
#

ad_page_contract {
    Show all the Reports

    @author frank.bergmann@project-open.com
} {
    { return_url "" }
    { object_id "" }
}

# ------------------------------------------------------
# Defaults & Security
# ------------------------------------------------------

if {![info exists module]} { set module "" } 

set current_user_id [ad_maybe_redirect_for_registration]
set add_reports_p [im_permission $current_user_id "add_reports"]
set view_reports_all_p [im_permission $current_user_id "view_reports_all"]

if {"" == $return_url} { set return_url [ad_conn url] }
set page_title [lang::message::lookup "" intranet-reporting.Indicators "Indicators"]
set context_bar [im_context_bar $page_title]
set context ""

# Evaluate indicators every X hours:
set eval_interval_hours [parameter::get_from_package_key -package_key "intranet-reporting-indicators" -parameter "IndicatorEvaluationIntervalHours" -default 24]

# Did the user specify an object? Then show only indicators designed
# to be shown with that object.
if {![info exists object_type]} { set object_type "" }
if {"" != $object_id} { set object_type [db_string otype "select object_type from acs_objects where object_id = :object_id" -default ""] }


# ------------------------------------------------------
# List creation
# ------------------------------------------------------
set elements_list {}

lappend elements_list \
	value {
	    label "Value"
	    display_template {
		<b><font color=@reports.indicator_color@>@reports.value_html;noquote@</font></b>
	    }
	}

lappend elements_list \
	diagram {
	    label "Diagram"
	    display_template { @reports.diagram_html;noquote@ }
	}

lappend elements_list \
    name {
	label $page_title
	display_template {
	    <a href=@reports.report_view_url@>@reports.report_name@</a>
	    @reports.help_gif;noquote@
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

list::create \
        -name report_list \
        -multirow reports \
        -key menu_id \
        -elements $elements_list \
        -class "table_indicators" \
        -filters {
        	return_url
        }

set permission_sql "and 't' = im_object_permission_p(r.report_id, :current_user_id, 'read')"
#if {$view_reports_all_p} { set permission_sql "" }

set object_type_sql "and (indicator_object_type is null OR indicator_object_type = '')"
if {"" != $object_type} { set object_type_sql "and lower(indicator_object_type) = lower(:object_type)" }

set indicator_cnt 0
db_multirow -extend {report_view_url edit_html value_html diagram_html help_gif indicator_color} reports get_reports "
	select
		r.report_id,
		r.report_name,
		r.report_description,
		r.report_sql,
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
    incr indicator_cnt

    set report_view_url [export_vars -base "/intranet-reporting-indicators/view" {indicator_id return_url}]
    set report_edit_url [export_vars -base "/intranet-reporting-indicators/new" {indicator_id return_url}]
    set perms_url [export_vars -base "/intranet-reporting-indicators/perms" {{object_id $indicator_id} return_url}]
    set edit_html "
	<a href='$report_edit_url'>[im_gif "wrench"]</a>
	<a href='$perms_url'>[im_gif "lock"]</a>
    "
    set help_gif [im_gif help $report_description]
    set indicator_color "black"

    if {"" == $result} {
	set result "error"
	set error_occured [catch {set result [db_string value $report_sql]} err_msg]

	if {$error_occured} {
	    set result "<pre>$err_msg</pre>" 
	} else {
	    if {"" != $result} {
		db_dml insert "
			insert into im_indicator_results (
				result_id,result_indicator_id,result_date,result
			) values (
				nextval('im_indicator_results_seq'),:report_id,now(),:result
			)
	        "
	    }
	}
    }

    if {"" != $result} {
	if {"" != $result} {
	    if {"" != $indicator_low_warn} { if {$result < $indicator_low_warn} { set indicator_color "\#DF8F00" } }
	    if {"" != $indicator_low_critical} { if {$result < $indicator_low_critical} { set indicator_color "red" } }
	    if {"" != $indicator_high_warn} { if {$result > $indicator_high_warn} { set indicator_color "orange" } }
	    if {"" != $indicator_high_critical} { if {$result > $indicator_high_critical} { set indicator_color "red" } }
	}
    }

    set value_html "min=$indicator_widget_min, res=$result, max=$indicator_widget_max"
    set value_html $result

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
}



