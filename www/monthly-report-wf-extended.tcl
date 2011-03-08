# /packages/intranet-cust-koernigweber/www/monthly-report-wf-extended.tcl
#
# Copyright (C) 1998-2004 various parties
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


# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    Shows a summary of the loged hours by all team members of a project (1 week).
    Only those users are shown that:
    - Have the permission to add hours or
    - Have the permission to add absences AND
	have atleast some absences logged

    @param owner_id	user concerned can be specified
    @param project_id	can be specified
    @param duration	numbers of days shown on report. 
    @param start_at	start the report at this day
    @param display	 if project_id, choose to display all hours or project hours

    @author mbryzek@arsdigita.com
    @author Frank Bergmann (frank.bergmann@project-open.com)
    @author Alwin Egger (alwin.egger@gmx.net)
    @author Klaus Hofeditz (klaus.hofeditz@project-open.com)
} {
    { owner_id:integer "" }
    { project_id:integer }
    { report_year_month:integer "" }
    { report_month:integer "" }
    { report_year:integer "" }
}


# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set subsite_id [ad_conn subsite_id]
set site_url "/intranet-timesheet2"
set return_url "$site_url/weekly_report"
set date_format "YYYY-MM-DD"
set current_user_id [ad_maybe_redirect_for_registration]

set todays_date [db_string todays_date "select to_char(now(), :date_format) from dual" -default ""]

if { [empty_string_p report_month] } {
    set report_month [string range $todays_date 5 6] 
}

if { [empty_string_p report_year] } {
    set report_year [string range $todays_date 0 3] 
}

if { [empty_string_p report_year] } {
	set report_year_month "[string range $todays_date 0 3]-[string range $todays_date 5 6]"
}

set first_day_of_month "$report_year-$report_month-01"
set duration [db_string get_number_days_month "SELECT date_part('day','$first_day_of_month'::date + '1 month'::interval - '1 day'::interval)" -default 0]
   
if { $owner_id != $user_id && ![im_permission $user_id "view_hours_all"] } {
    ad_return_complaint 1 "<li>[_ intranet-timesheet2.lt_You_have_no_rights_to]"
    return

}

set hours_start_date [db_string get_new_start_at "
	select	to_char(max(day), :date_format) 
	from	im_hours 
	where	project_id = :project_id
    " -default ""]

set project_start_date [db_string get_project_start "
	select	to_char(start_date, :date_format) 
	from	im_projects
	where	project_id = :project_id
    " -default ""]

set start_at $hours_start_date
    if {"" == $start_at} { 
	set start_at $project_start_date 
    }
if {"" == $start_at} { 
	set start_at $todays_date 
}


# ---------------------------------------------------------------
# Format the Filter and admin Links
# ---------------------------------------------------------------


set filter_form_html "
	<form method=get action='$return_url' name=filter_form>
	<table border=0 cellpadding=0 cellspacing=0>
                <tr>
                  <td class=form-label>Month</td>
                  <td class=form-widget>
                    <input type=textfield name=start_date value=$start_date>
                  </td>
                </tr>
                <tr>
                  <td class=form-label>User</td>
                  <td class=form-widget>
                    [im_user_select -include_empty_p 1 user_id $user_id]
                  </td>
                </tr>
                <tr>
                  <td class=form-label>Project</td>
                  <td class=form-widget>
                    [im_project_select -include_empty_p 1 -exclude_subprojects_p 0 -include_empty_name [lang::message::lookup "" intranet-core.All "All"] project_id $project_id]
                  </td>
                </tr>
                <tr>
		  <td colspan='2' valign=top>
		    <input type=submit value='[_ intranet-timesheet2.Apply]' name=submit>
  		  </td>
		</tr>
	</table>
	</form>
"
set admin_html ""


# ---------------------------------------------------------------
# Get the Column Headers and prepare some SQL
# ---------------------------------------------------------------

set table_header_html "<tr><td class=rowtitle>[_ intranet-timesheet2.Users]</td>"
set days [list]
set holydays [list]
set sql_from [list]
set sql_from2 [list]

for { set i [expr $duration - 1]  } { $i >= 0 } { incr i -1 } {
	set col_sql "
	    select 
		to_char(sysdate, :date_format) as today_date,
		to_char(to_date('$start_at', :date_format)-$i, :date_format) as i_date, 
		to_char((to_date('$start_at', :date_format)-$i), 'Day') as f_date_day,
		to_char((to_date('$start_at', :date_format)-$i), 'dd') as f_date_dd,
		to_char((to_date('$start_at', :date_format)-$i), 'Mon') as f_date_mon,
		to_char((to_date('$start_at', :date_format)-$i), 'yyyy') as f_date_yyyy,    
		to_char(to_date('$start_at', :date_format)-$i, 'DY') as h_date 
	    from dual"

	    db_1row get_date $col_sql
	    lappend days $i_date
	    if { $h_date == "SAT" || $h_date == "SUN" } {
		lappend holydays $i_date
	    }

    #prepare the data to UNION
    lappend sql_from2 "select to_date($i_date, :date_format) as day from dual\n"
    set f_date "[_ intranet-timesheet2.[string trim $f_date_day]], $f_date_dd. [_ intranet-timesheet2.$f_date_mon] $f_date_yyyy" 

    append table_header_html "<td class=rowtitle>$f_date</td>"
}

append table_header_html "</tr>"


# ---------------------------------------------------------------
# Get Column Header & Data 
# ---------------------------------------------------------------

set table_header_html "<tr><td class=rowtitle>[_ intranet-timesheet2.Users]</td>"
set inner_sql ""

for { set i 0 } { $i < $duration } { incr i } {
    if { 1 == [string length i]} { set day_double_digit 0$i }
    append inner_sql "(select sum(hours) from im_hours h where
            h.user_id= r.object_id_two
            and h.project_id in ([im_project_subproject_ids p.project_id])
            and h.day like '%$report_year-$report_month-$day_double_digit%') as h_$report_year-$report_month-$day_double_digit
    "

    set h_date [db_string get_view_id "select view_id from im_views where view_name=:view_name" -default 0]
    if { $h_date == "SAT" || $h_date == "SUN" } {
            append table_header_html "<td class=rowtitle>$day_double_digit</td>
    } else {
            append table_header_html "<td class=rowtitle>$day_double_digit</td>
    }
}

append table_header_html "<td>Reminder</td><td>Confirm WF</td></tr>"

set sql "
	select 
		p.project_id,
		r.object_id_two as user,
		$inner_sql
	from 
		im_projects p, 
		acs_rels r
	where 
		r.object_id_one = p.project_id
		and tree_level(p.tree_sortkey) <= 1
		and p.project_type_id not in ([im_project_type_task], [im_project_type_ticket])
		and p.project_status_id IN ([im_project_status_open])
		and p.project_lead_id = $current_user_id
	order by 
		project_id
"

ad_return_complaint 1 $sql

# ---------------------------------------------------------------
# Get Column Header & Data
# ---------------------------------------------------------------

set old_owner [list]
set do_user_init 1
set table_body_html ""
set bgcolor(0) " class=roweven "
set bgcolor(1) " class=rowodd "
set ctr 0

ns_log notice $sql

db_foreach get_hours $sql {
    if { $do_user_init == 1 } {
	set old_owner [list $curr_owner_id $owner_name]
	set do_user_init 0
    }
    if { [lindex $old_owner 0] != $curr_owner_id } {
	append table_body_html [im_do_row [array get bgcolor] $ctr [lindex $old_owner 0] [lindex $old_owner 1] $days [array get user_days] [array get user_absences] $holydays $today_date [array get user_ab_descr]]
	set old_owner [list $curr_owner_id $owner_name]
	array unset user_days
	array unset user_absences
    }
    if { $type == "h" } {
	set user_days($curr_day) $val
    }
    if { $type == "a" } {
	set user_absences($curr_day) $val
	set user_ab_descr($val) $descr
    }
    set val ""
    incr ctr
}

set colspan [expr [llength $days]+1]

# Show a reasonable message when there are no result rows:
if { [array size user_days] > 0 } {
    append table_body_html [im_do_row [array get bgcolor] $ctr $curr_owner_id $owner_name $days [array get user_days] [array get user_absences] $holydays $today_date [array get user_ab_descr]]
} elseif { [empty_string_p $table_body_html] } {
    set table_body_html "
	 <tr><td colspan=$colspan><ul><li><b>
	[_ intranet-timesheet2.No_Users_found]
	</b></ul></td></tr>"
}

# ---------------------------------------------------------------
# Provide << and >> to see future and past days
# ---------------------------------------------------------------

set navig_sql "
    select 
    	to_char(to_date('$start_at', :date_format) - 7, :date_format) as past_date,
	to_char(to_date('$start_at', :date_format) + 7, :date_format) as future_date 
    from 
    	dual"
db_1row get_navig_dates $navig_sql

set switch_link_html "<a href=\"weekly_report?[export_url_vars owner_id project_id duration display]"

set switch_past_html "$switch_link_html&start_at=$past_date\">&laquo;</a>"
set switch_future_html "$switch_link_html&start_at=$future_date\">&raquo;</a>"

# ---------------------------------------------------------------
# Format Table Continuation and title
# ---------------------------------------------------------------

set table_continuation_html "
<tr>
  <td align=center>
     $switch_past_html
  </td>
  <td colspan=[expr $colspan - 2]></td>
  <td align=center>
    $switch_future_html
  </td>
</tr>\n"

set page_title "[_ intranet-timesheet2.Timesheet_Summary]"
set context_bar [im_context_bar $page_title]
if { $owner_id != "" && [info exists owner_name] } {
    append page_title " of $owner_name"
}
if { $project_id != 0 && [info exists project_name] } {
    append page_title " by project \"$project_name\""
}


# ---------------------------------------------------------------
# 
# ---------------------------------------------------------------

set left_navbar "
            <div class=\"filter-block\">
                <div class=\"filter-title\">
                [lang::message::lookup "" intranet-timesheet2.Admin "Admin Links"]
                </div>
		$admin_html
            </div>
            <hr/>
"



ad_proc im_do_row {
    { bgcolorl }
    { ctr }
    { curr_owner_id }
    { owner_name }
    { days }
    { user_daysl }
    { absencel }
    { holydays }
    { today_date }
    { descrl }
} {
    Returns a row with the hours loged of one user
} {
    set user_view_page "/intranet/users/view"
    set absence_view_page "/intranet-timesheet2/absences/view"

    set date_format "YYYY-MM-DD"

    array set bgcolor $bgcolorl
    array set user_days $user_daysl
    array set absence $absencel
    array set descr $descrl
    set html ""
    append html "
        <tr$bgcolor([expr $ctr % 2])>
            <td>
                <a href=\"$user_view_page?user_id=$curr_owner_id\">$owner_name</a>
            </td>
    "

    for { set i 0 } { $i < [llength $days] } { incr i } {
        if { [lsearch -exact $holydays [lindex $days $i]] >= 0 } {
            set holy_html " style=\"background-color=\\#DDDDDD;\" "
        } else {
            set holy_html ""
        }
        set cell_text [list]
        set cell_param [list]
        set absent_p "f"
        if { [info exists absence([lindex $days $i])] } {
            set abs_id $absence([lindex $days $i])
            lappend cell_text "<a href=\"$absence_view_page?absence_id=$abs_id\" style=\"color:\\\\#FF0000;\">[_ intranet-timesheet2.Absent]</a> ($descr($abs_id))"
            set absent_p "t"
        }
        if { [info exists user_days([lindex $days $i])] } {
            lappend cell_text "$user_days([lindex $days $i]) [_ intranet-timesheet2.hours]"
        } elseif { [lindex $days $i] < $today_date && $holy_html == "" && [im_permission $curr_owner_id "add_hours"] } {
            if { $absent_p == "f" } {
                lappend cell_text "[_ intranet-timesheet2.No_hours_logged]"
                lappend cell_param "class=rowyellow"
            }
        }
	if { [lsearch -exact $holydays [lindex $days $i]] >= 0 } {
            set cell_param "style=\"background-color=\\\\#DDDDDD;\""
        }
        append html "<td [join $cell_param " "]>[join $cell_text "<br>"]</td>\n"
    }
    append html "</tr>\n"
    return $html
}
