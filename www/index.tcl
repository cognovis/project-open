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
	    <a href=@reports.report_url@>@reports.report_name@</a>
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
		indicator_id,
		result_date
	from
		im_reporting_indicator_results
"

db_foreach history $history_sql {
	set results_${indicator_id}($result_date) $result
}


db_multirow -extend {report_url edit_html value_html} reports get_reports "
	select
		r.*,
		ir.result
	from
		im_reports r
		LEFT OUTER JOIN (
			select	avg(result) as result,
				indicator_id
			from	im_reporting_indicator_results
			where	result_date >= now() - '1 second'::interval
			group by indicator_id
		) ir ON (r.report_id = ir.indicator_id)
	where
		
		1=1
	order by report_sort_order
" {
	set report_url [export_vars -base "view" {report_id return_url}]
        set edit_html "<a href='/intranet-reporting/new?report_id=$report_id'>[im_gif "wrench"]</a>"

	if {"" == $result} {

		set result "error"
		set error_occured [catch {
			set result [db_string value $report_sql]

			# Randomize a bit to get nice demo data
			set result [expr $result * (rand()+0.5)]
		} err_msg]
		if {$error_occured} { 
			set report_description "<pre>$err_msg</pre>" 
		} else {
			db_dml insert "
				insert into im_reporting_indicator_results (
					result_id,
					indicator_id,
					result_date,
					result
				) values (
					nextval('im_reporting_indicator_results_seq'),
					:report_id,
					now(),
					:result
				)
			"
		}
	}	

	set value_html $result
}


