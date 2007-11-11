# /packages/intranet-reporting/www/indicators.tcl
#
# Copyright (c) 2007 ]project-open[
# The code is based on ArsDigita ACS 3.4
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
    Show all the Reports

    @author frank.bergmann@project-open.com
} {
    { return_url "" }
}

# ------------------------------------------------------
# Defaults & Security
# ------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set user_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
if {"" == $return_url} { set return_url [ad_conn url] }
set page_title [lang::message::lookup "" intranet-reporting.Indicators "Indicators"]
set context_bar [im_context_bar $page_title]
set context ""


# ------------------------------------------------------
# List creation
# ------------------------------------------------------

set elements_list {
    name {
	label $page_title
	display_template {
	    <a href=@reports.report_view_url@>@reports.report_name@</a>
	}
    }
}

if {$user_admin_p} {
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


db_multirow -extend {report_view_url edit_html value_html history_html} reports get_reports "
	select
		r.*,
		i.*,
		ir.result
	from
		im_reports r,
		im_indicators i
		LEFT OUTER JOIN (
			select	avg(result) as result,
				result_indicator_id
			from	im_indicator_results
			where	result_date >= now() - '1 second'::interval
			group by result_indicator_id
		) ir ON (i.indicator_id = ir.result_indicator_id)
	where
		r.report_id = i.indicator_id and
		r.report_type_id = [im_report_type_indicator]
	order by 
		report_sort_order
" {
    set report_view_url [export_vars -base "view" {indicator_id return_url}]
    set report_edit_url [export_vars -base "new" {indicator_id}]
    set edit_html "<a href='$report_edit_url'>[im_gif "wrench"]</a>"
    
    if {"" == $result} {
	
	set result "error"
	set error_occured [catch {
	    set result [db_string value $report_sql]
	    
	    # Randomize a bit to get nice demo data
	    set result [expr $result * (1 + (rand()+0.5) / 20)]
	} err_msg]
	if {$error_occured} { 
	    set report_description "<pre>$err_msg</pre>" 
	} else {
	    db_dml insert "
				insert into im_indicator_results (
					result_id,
					result_indicator_id,
					result_date,
					result
				) values (
					nextval('im_indicator_results_seq'),
					:report_id,
					now(),
					:result
				)
	    "
	}
    }	
    
    set value_html $result

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

    set history_html [im_indicator_timeline_widget \
			  -name $report_name \
			  -values $values \
			  -widget_min $min \
			  -widget_max $max \
    ]

}


