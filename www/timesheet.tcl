# /packages/intranet-reporting/www/timesheet.tcl
#
# Copyright (C) 2003-2004 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/ for licensing details.


ad_page_contract {
	testing reports	
} {

}

set user_id [ad_maybe_redirect_for_registration]
set page_title "Timesheet Report"
set context_bar [im_context_bar $page_title]
set context ""
set today [db_string today "select to_char(sysdate, 'YYYYMMDD.HHmm') from dual"]


# ------------------------------------------------------------
# Define the report - SQL, counters, headers and footers 
#

set inner_sql "
select
	to_char(h.day, 'YY-IW') as log_week,
--	to_char(h.day, 'YY-MM-DD') as log_day,
--	to_char(h.day, 'YY-MM') as log_month,
	h.user_id,
	p.project_id,
	p.company_id,
	sum(h.hours) as hours,
	avg(h.billing_rate) as billing_rate
from
	im_hours h,
	im_projects p,
	cc_users u
where
	h.project_id = p.project_id
	and h.user_id = u.user_id
	and to_char(h.day, 'YY-IW') in (
		select w.week
		from (
			select to_char(w.start_block, 'YY-IW') as week
			from im_start_weeks w
			where start_block >= to_date('2005-01-01', 'YYYY-MM-DD')
		) w
		order by w.week
		limit 20
	)
group by
	p.project_id,
	p.company_id,
	h.user_id,
	p.tree_sortkey,
	log_week
order by
	p.company_id,
	p.tree_sortkey,
	log_week
"

set sql "
select
	u.user_id,
	u.first_names || ' ' || u.last_name as user_name,
	p.project_id,
	p.project_nr,
	c.company_id,
	c.company_path as company_nr,
	c.company_name,
	to_char(s.hours, '999,999.9') as hours,
	to_char(s.billing_rate, '999,999.9') as billing_rate
from
	($inner_sql) s,
	im_companies c,
	im_projects p,
	cc_users u
where
	s.user_id = u.user_id
	and s.company_id = c.company_id
	and s.project_id = p.project_id
"

set report_def [list \
    group_by company_nr \
    header {"<b>$company_name</b>" "" "" "" "" "" "" "" ""} \
    content [list  \
        group_by project_nr \
        header {"" "<b>$project_nr</b>" "" "" "" "" "" "" ""} \
        content [list  \
            header {
                "$company_nr"
                "$project_nr"
                "<a href=/intranet/users/view?user_id=$user_id>$user_name</a>"
                $hours
		$billing_rate} \
            content {} \
        ] \
    ] \
    footer {"" "" "" "" "" "" "" "" ""} \
]

# Global header/footer
set header0 {"Customer" "Project" "User" "Email" "First" "Last" "Sector" "Company" "Sector"}
set footer0 {"" "" "" "" "" ""}

set hours_counter [list \
	pretty_name Hours \
	var hours_subtotal \
	reset \$company_id \
	expr \$hours
]

set counters [list \
	$hours_counter \
]

# ------------------------------------------------------------
# Start formatting the page
#

ad_return_top_of_page "
[im_header]
[im_navbar]
<H1>$page_title</H1>
<table border=0 cellspacing=1 cellpadding=1>\n"

im_report_render_row \
    -row $header0 \
    -row_class rowtitle \
    -field_class rowtitle

set footer_array_list [list]
set last_value_list [list]
db_foreach sql $sql {

    im_report_display_footer \
	-group_def $report_def \
        -footer_array_list $footer_array_list \
	-last_value_array_list $last_value_list

    im_report_update_counters -counters $counters

    set last_value_list [im_report_render_header \
	-group_def $report_def \
	-last_value_array_list $last_value_list \
    ]

    set footer_array_list [im_report_render_footer \
	-group_def $report_def \
	-last_value_array_list $last_value_list \
    ]

}

im_report_display_footer \
    -group_def $report_def \
    -footer_array_list $footer_array_list \
    -last_value_array_list $last_value_list \
    -display_all_footers_p 1

im_report_render_row \
    -row $footer0

ns_write "</table>\n[im_footer]\n"
