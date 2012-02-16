# /packages/intranet-reporting/www/translation-planning.tcl
#
# Copyright (c) 2009 Laurent Léonard (Open-minds)
#
# All rights reserved. 
# Please see http://www.project-open.com/ for licensing.

ad_page_contract {
    
} {
    { date [dt_sysdate] }
}

set current_user_id [ad_maybe_redirect_for_registration]

set menu_label "reporting"

set read_p [db_string report_perms "
        select  im_object_permission_p(m.menu_id, :current_user_id, 'read')
        from    im_menus m
        where   m.label = :menu_label
" -default 'f']

if {![string equal "t" $read_p]} {
    ad_return_complaint 1 "<li>[lang::message::lookup "" intranet-reporting.You_dont_have_permissions "You don't have the necessary permissions to view this page"]"
    return
}

set page_title "Translation Planning"
set context_bar [im_context_bar $page_title]

ns_write "[im_header]
[im_navbar]\n"

ns_write [dt_widget_month_centered -date $date -day_number_template {<a href="?date=[dt_julian_to_ansi $julian_date]">$day_number</a>}]
set date_list [dt_ansi_to_list $date]
set day_of_week [dt_format -format "%w" $date]

set num_days_in_month [dt_num_days_in_month [lindex $date_list 0] [lindex $date_list 1]]
for { set i 0 } { $i <= 6 } { incr i } {
	ns_write " "
	set year [lindex $date_list 0]
	set month [lindex $date_list 1]
	set day [expr [lindex $date_list 2] + $i - $day_of_week]
	if { $day < 1 } {
		set new_date [dt_ansi_to_list [dt_prev_month [lindex $date_list 0] [lindex $date_list 1]]]
		set year [lindex $new_date 0]
		set month [lindex $new_date 1]
		set day [expr $day + [dt_num_days_in_month $year $month]]
	} elseif {$day > $num_days_in_month} {
		set day [expr $day - $num_days_in_month]
		set new_date [dt_ansi_to_list [dt_next_month [lindex $date_list 0] [lindex $date_list 1]]]
		set year [lindex $new_date 0]
		set month [lindex $new_date 1]
	}
	set days($i) [format "%d-%02d-%02d" $year $month $day]
}

set day0 $days(0)
set day1 $days(1)
set day2 $days(2)
set day3 $days(3)
set day4 $days(4)
set day5 $days(5)
set day6 $days(6)

set sql "
SELECT
	im_name_from_user_id(u.person_id) AS user_name,
	u.person_id,
	COALESCE((
		SELECT
			SUM(task_units)
		FROM
			im_trans_tasks
		WHERE
			task_status_id <> 372
			AND trans_id = u.person_id
			AND DATE(end_date) = :day0
	), 0) as day0_trans_units,
	COALESCE((
		SELECT
			SUM(t.task_units)
		FROM
			im_trans_tasks t,
			im_projects p
		WHERE
			t.project_id = p.project_id
			AND t.task_status_id <> 372
			AND t.edit_id = u.person_id
			AND DATE(p.end_date) = :day0
	), 0) as day0_edit_units,
	COALESCE((
		SELECT
			SUM(t.task_units)
		FROM
			im_trans_tasks t,
			im_projects p
		WHERE
			t.project_id = p.project_id
			AND t.task_status_id <> 372
			AND t.proof_id = u.person_id
			AND DATE(p.end_date) = :day0
	), 0) as day0_proof_units,
	COALESCE((
		SELECT
			SUM(task_units)
		FROM
			im_trans_tasks
		WHERE
			task_status_id <> 372
			AND trans_id = u.person_id
			AND DATE(end_date) = :day1
	), 0) as day1_trans_units,
	COALESCE((
		SELECT
			SUM(t.task_units)
		FROM
			im_trans_tasks t,
			im_projects p
		WHERE
			t.project_id = p.project_id
			AND t.task_status_id <> 372
			AND t.edit_id = u.person_id
			AND DATE(p.end_date) = :day1
	), 0) as day1_edit_units,
	COALESCE((
		SELECT
			SUM(t.task_units)
		FROM
			im_trans_tasks t,
			im_projects p
		WHERE
			t.project_id = p.project_id
			AND t.task_status_id <> 372
			AND t.proof_id = u.person_id
			AND DATE(p.end_date) = :day1
	), 0) as day1_proof_units,
	COALESCE((
		SELECT
			SUM(task_units)
		FROM
			im_trans_tasks
		WHERE
			task_status_id <> 372
			AND trans_id = u.person_id
			AND DATE(end_date) = :day2
	), 0) as day2_trans_units,
	COALESCE((
		SELECT
			SUM(t.task_units)
		FROM
			im_trans_tasks t,
			im_projects p
		WHERE
			t.project_id = p.project_id
			AND t.task_status_id <> 372
			AND t.edit_id = u.person_id
			AND DATE(p.end_date) = :day2
	), 0) as day2_edit_units,
	COALESCE((
		SELECT
			SUM(t.task_units)
		FROM
			im_trans_tasks t,
			im_projects p
		WHERE
			t.project_id = p.project_id
			AND t.task_status_id <> 372
			AND t.proof_id = u.person_id
			AND DATE(p.end_date) = :day2
	), 0) as day2_proof_units,
	COALESCE((
		SELECT
			SUM(task_units)
		FROM
			im_trans_tasks
		WHERE
			task_status_id <> 372
			AND trans_id = u.person_id
			AND DATE(end_date) = :day3
	), 0) as day3_trans_units,
	COALESCE((
		SELECT
			SUM(t.task_units)
		FROM
			im_trans_tasks t,
			im_projects p
		WHERE
			t.project_id = p.project_id
			AND t.task_status_id <> 372
			AND t.edit_id = u.person_id
			AND DATE(p.end_date) = :day3
	), 0) as day3_edit_units,
	COALESCE((
		SELECT
			SUM(t.task_units)
		FROM
			im_trans_tasks t,
			im_projects p
		WHERE
			t.project_id = p.project_id
			AND t.task_status_id <> 372
			AND t.proof_id = u.person_id
			AND DATE(p.end_date) = :day3
	), 0) as day3_proof_units,
	COALESCE((
		SELECT
			SUM(task_units)
		FROM
			im_trans_tasks
		WHERE
			task_status_id <> 372
			AND trans_id = u.person_id
			AND DATE(end_date) = :day4
	), 0) as day4_trans_units,
	COALESCE((
		SELECT
			SUM(t.task_units)
		FROM
			im_trans_tasks t,
			im_projects p
		WHERE
			t.project_id = p.project_id
			AND t.task_status_id <> 372
			AND t.edit_id = u.person_id
			AND DATE(p.end_date) = :day4
	), 0) as day4_edit_units,
	COALESCE((
		SELECT
			SUM(t.task_units)
		FROM
			im_trans_tasks t,
			im_projects p
		WHERE
			t.project_id = p.project_id
			AND t.task_status_id <> 372
			AND t.proof_id = u.person_id
			AND DATE(p.end_date) = :day4
	), 0) as day4_proof_units,
	COALESCE((
		SELECT
			SUM(task_units)
		FROM
			im_trans_tasks
		WHERE
			task_status_id <> 372
			AND trans_id = u.person_id
			AND DATE(end_date) = :day5
	), 0) as day5_trans_units,
	COALESCE((
		SELECT
			SUM(t.task_units)
		FROM
			im_trans_tasks t,
			im_projects p
		WHERE
			t.project_id = p.project_id
			AND t.task_status_id <> 372
			AND t.edit_id = u.person_id
			AND DATE(p.end_date) = :day5
	), 0) as day5_edit_units,
	COALESCE((
		SELECT
			SUM(t.task_units)
		FROM
			im_trans_tasks t,
			im_projects p
		WHERE
			t.project_id = p.project_id
			AND t.task_status_id <> 372
			AND t.proof_id = u.person_id
			AND DATE(p.end_date) = :day5
	), 0) as day5_proof_units,
	COALESCE((
		SELECT
			SUM(task_units)
		FROM
			im_trans_tasks
		WHERE
			task_status_id <> 372
			AND trans_id = u.person_id
			AND DATE(end_date) = :day6
	), 0) as day6_trans_units,
	COALESCE((
		SELECT
			SUM(t.task_units)
		FROM
			im_trans_tasks t,
			im_projects p
		WHERE
			t.project_id = p.project_id
			AND t.task_status_id <> 372
			AND t.edit_id = u.person_id
			AND DATE(p.end_date) = :day6
	), 0) as day6_edit_units,
	COALESCE((
		SELECT
			SUM(t.task_units)
		FROM
			im_trans_tasks t,
			im_projects p
		WHERE
			t.project_id = p.project_id
			AND t.task_status_id <> 372
			AND t.proof_id = u.person_id
			AND DATE(p.end_date) = :day6
	), 0) as day6_proof_units
FROM
	cc_users u
WHERE
	u.member_state = 'approved'
	AND u.user_id IN (SELECT member_id FROM group_distinct_member_map WHERE group_id = 463 INTERSECT SELECT member_id FROM group_distinct_member_map WHERE group_id = 465)
ORDER BY
	LOWER(u.first_names),
	LOWER(u.last_name)
"

ns_write "<table>
  <thead>
    <tr>
      <th class=\"rowtitle\" rowspan=\"2\" style=\"text-align: center;\">Person</th>
      <th class=\"rowtitle\" colspan=\"7\" style=\"text-align: center;\">Date</th>
    </tr>
    <tr>\n"
for { set i 0 } { $i <= 6 } { incr i } {
	ns_write "      <th class=\"rowtitle\" style=\"text-align: center;\">[lindex [_ acs-datetime.days_of_week] $i] $days($i)</td>\n"
}
ns_write "    </tr>
    </thead>\n"

set bgcolor(0) " class=\"roweven\""
set bgcolor(1) " class=\"rowodd\""
set ctr 1

db_foreach select_planning $sql {
	set trans_units(0) $day0_trans_units
	set trans_units(1) $day1_trans_units
	set trans_units(2) $day2_trans_units
	set trans_units(3) $day3_trans_units
	set trans_units(4) $day4_trans_units
	set trans_units(5) $day5_trans_units
	set trans_units(6) $day6_trans_units
	set edit_units(0) $day0_edit_units
	set edit_units(1) $day1_edit_units
	set edit_units(2) $day2_edit_units
	set edit_units(3) $day3_edit_units
	set edit_units(4) $day4_edit_units
	set edit_units(5) $day5_edit_units
	set edit_units(6) $day6_edit_units
	set proof_units(0) $day0_proof_units
	set proof_units(1) $day1_proof_units
	set proof_units(2) $day2_proof_units
	set proof_units(3) $day3_proof_units
	set proof_units(4) $day4_proof_units
	set proof_units(5) $day5_proof_units
	set proof_units(6) $day6_proof_units
	for { set i 0 } { $i <= 6 } { incr i } {
		set total_units($i) [expr $trans_units($i) + round($edit_units($i) / 6 * 10) / 10.0 + round($proof_units($i) / 6 * 10) / 10.0]
	}
	ns_write "  <tbody>
    <tr$bgcolor([expr $ctr % 2])>
      <td style=\"text-align: center;\">$user_name</td>\n"
	for { set i 0 } { $i <= 6 } { incr i } {
		if { $total_units($i) < 2000 } {
			set color "00ff00"
		} elseif { $total_units($i) >= 2000 && $total_units($i) < 2500 } {
			set color "ff8f00"
		} elseif { $total_units($i) >= 2500 } {
			set color "ff0000"
		}
		ns_write "      <td style=\"background-color: #$color; text-align: center;\"><a href=\"translation-planning-projects?date=$days($i)&person_id=$person_id\" style=\"color: #000000; text-decoration: none;\">Translation: $trans_units($i)<br />Edit: $edit_units($i)<br />Proofreading: $proof_units($i)<br />Total: $total_units($i)</a></td>\n"
	}
	ns_write "    </tr>
  </tbody>\n"
	incr ctr
}

ns_write "</table>
<p>Total = weighted number of words to be delivered on a given day = translation volume + (edit volume / 6) + (proofreading volume / 6)<br />
If the cell is green : total &lt; 2000<br />
If the cell is orange: 2000 &lt;= total &lt; 2500<br />
If the cell is red : total &gt;= 2500</p>
[im_footer]\n"
