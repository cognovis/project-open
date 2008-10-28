# /packages/intranet-reporting/www/view.tcl
#
# Copyright (c) 2003-2007 ]project-open[
# frank.bergmann@project-open.com
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    Show the results of a single "dynamic" report or indicator
    @author frank.bergmann@project-open.com
} {
    indicator_id:integer
    {return_url "/intranet-reporting-indicators/index"}
}


# ---------------------------------------------------------------
# Defaults & Security

set current_user_id [ad_maybe_redirect_for_registration]
set read_p [db_string report_perms "
        select  im_object_permission_p(:indicator_id, :current_user_id, 'read')
" -default 'f']
if {![string equal "t" $read_p]} {
    ad_return_complaint 1 "<li>
    [lang::message::lookup "" intranet-reporting.You_dont_have_permissions "You don't have the necessary permissions to view this page"]"
    return
}

# ---------------------------------------------------------------
# Get Report Info

db_1row report_info "
	select	r.*,
		i.*,
		im_category_from_id(report_type_id) as report_type
	from	im_reports r,
		im_indicators i
	where	r.report_id = :indicator_id
		and r.report_id = i.indicator_id
"

set page_title "$report_type: $report_name"
set context [im_context_bar $page_title]


# ---------------------------------------------------------------
# 

set indicator_sql "
                select  result_date, result
                from    im_indicator_results
                where   result_indicator_id = :report_id
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
		      -diagram_width 600 \
		      -diagram_height 300 \
		      -name $report_name \
		      -values $values \
		      -widget_min $min \
		      -widget_max $max \
]



set page_body $history_html

