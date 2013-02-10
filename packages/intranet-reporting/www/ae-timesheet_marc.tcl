# Alliance-engineering timesheet
# Xavier Carpent 2009

# ------------------------------------------------------------------------------
# Page contract

ad_page_contract {
    Alliance Engineering - Timesheet Report
    @param month Month (MM/YYYY format)
} {
    { month "01/2011" }
    { user_id:integer 0}
}

# ------------------------------------------------------------------------------
# Security

set menu_label "ae-timesheet"
set current_user_id [ad_maybe_redirect_for_registration]

set read_p [db_string report_perms "
	select	im_object_permission_p(m.menu_id, :current_user_id, 'read')
	from	im_menus m
	where	m.label = :menu_label
" -default 'f']

# TODO: Pour le moment, toujours true, apres il faudra rajouter des perm dans les menus
#set read_p "t"

if {![string equal "t" $read_p]} {
    ad_return_complaint 1 "
    [lang::message::lookup "" intranet-reporting.You_dont_have_permissions "You don't have the necessary permissions to view this page"]"
    return
}

# ------------------------------------------------------------------------------
# Format check

if {0 == $user_id || "" == $user_id} { 
    set user_id $current_user_id 
}

if {![regexp {^[0-9][0-9]/[0-9][0-9][0-9][0-9]$} $month]} {
    ad_return_complaint 1 "Month doesn't have the right format.<br>
    Current value: '$month'<br>
    Expected format: 'MM/YYYY'"
    ad_script_abort
}

set page_title "<center STYLE=\"font-family: 'Helvetica'\">ALLIANCE ENGINEERING</br>TIMESHEET REPORT</center>"
set context_bar [im_context_bar $page_title]
set context ""
set help_text ""

# ------------------------------------------------------------------------------
# Constants

set rowclass(0) "roweven"
set rowclass(1) "rowodd"

set currency_format "999,999,999.09"
set date_format "DD/MM/YYYY"

set company_url "/intranet/companies/view?company_id="
set project_url "/intranet/projects/view?project_id="
set invoice_url "/intranet-invoices/view?invoice_id="
set user_url "/intranet/users/view?user_id="
set this_url [export_vars -base "/intranet-reporting-tutorial/projects-04" {month} ]

set level_of_detail 1

set weekdays [list "Dimanche" "Lundi" "Mardi" "Mercredi" "Jeudi" "Vendredi" "Samedi"]
set monthnames [list "Janvier" "Février" "Mars" "Avril" "Mai" "Juin" "Juillet" "Août" "Septembre" "Octobre" "Novembre" "Décembre"]

# ------------------------------------------------------------------------------
# SQL Queries

set criteria [list]

if {0 != $user_id && "" != $user_id} {
    lappend criteria "h.user_id = :user_id"
}

set where_clause [join $criteria " and\n            "]
if { ![empty_string_p $where_clause] } {
    set where_clause " and $where_clause"
}

set report_sql "
	select
		p.project_id as project_id,
		p.project_name as project_name,
		p.project_nr as project_nr,
		h.hours as hours,
		h.note as note,
		to_char(h.day, :date_format) as day,
		to_char(h.day, 'd') as weekday_nr
	from
		im_projects p,
		im_hours h
	where
		h.project_id = p.project_id
		and h.day >= to_date(:month, 'MM/YYYY')
		and h.day <= to_date(:month, 'MM/YYYY') + 31
		and :month = to_char(h.day, 'MM/YYYY')
		$where_clause
	order by
		h.day
"

set criteria [list]

if {0 != $user_id && "" != $user_id} {
    lappend criteria "a.owner_id = :user_id"
}

set where_clause [join $criteria " and\n            "]
if { ![empty_string_p $where_clause] } {
    set where_clause " and $where_clause"
}

set absences_sql "
	select
        to_char(a.start_date, :date_format) as absence_start_date,
        to_char(a.end_date, :date_format) as absence_end_date,
		im_category_from_id(a.absence_type_id) as absence_type,
		a.absence_id as absence_id
	from
		im_user_absences a
	where
		a.end_date >= to_date(:month, 'MM/YYYY')
		and a.start_date <= to_date(:month, 'MM/YYYY') + 31
		and (:month = to_char(a.start_date, 'MM/YYYY') or :month = to_char(a.end_date, 'MM/YYYY'))
		$where_clause
	order by
		a.start_date
"

# ------------------------------------------------------------------------------
# Report Definition

set header0 {
	"Date"
	"Jour"
	"Code Projet"
	"Projet"
	"Heures"
	"Remarques/Déplacements"
}

set report_def [list \
    group_by project_id \
    header {
	$day
	$weekday
	"<a href='$project_url$project_id'>$project_nr</a>"
	$project_name
	$hours
	$note
    } \
    content {} \
    footer {} \
]

set footer0 {
	"" 
	"" 
	"" 
	""
	""
}

set header1 {
	"Début"
	"Fin"
	"Type d'absence"
}

set absences_def [list \
    group_by absence_start_date \
    header {
	$absence_start_date
	$absence_end_date
	$absence_type
    } \
    content {} \
    footer {} \
]

set footer1 {
	"" 
	"" 
	""
}

# ------------------------------------------------------------------------------
# Counters

set hours_grand_total_counter [list \
        pretty_name "Heures prestées" \
        var hours_total \
        reset 0 \
        expr "\$hours+0" \
]

set counters [list \
	$hours_grand_total_counter
]

set hours_total 0

# ------------------------------------------------------------------------------
# Content

set datesplit [split $month /)]

ad_return_top_of_page "
	<link rel=StyleSheet href='/intranet/style/style.default.css' type=text/css media=screen>
	<meta http-equiv='Content-Type' content='text/html; charset=utf-8'>
	<table cellspacing=10 cellpadding=10 border=0 align=center>
		<tr>
			<td>
				<img src='ae-logo.jpg' alt='ae logo'>
			</td>
			<td>
				<h1>$page_title</h1>
			</td>
		</tr>
	</table>
	<table cellspacing=0 cellpadding=0 border=0>
	<tr valign=top>
	  <td width='50%'>
		<form>
		<table cellspacing=2>
		<!---
		<tr>
		  <td>Consultant:</td>
		  <td>
		    [im_user_select -include_empty_p 1 -include_empty_name "-- Please select --" user_id $user_id]
		  </td>
		</tr>
		--->
		<tr>
		  <td>Mois:</td>
		  <td><input type=text name=month value='$month'></td>
		</tr>
		<tr>
		  <td</td>
		  <td><input type=submit value='Submit'></td>
		</tr>
		</table>
		</form>
	  </td>
	</tr>
	</table>
	
  <table border=1><tr><td>
  &nbsp;<b><font size=4>Timesheet : [lindex $monthnames [expr [scan [lindex $datesplit 0] {%d}] - 1]] [lindex $datesplit 1] &nbsp&nbsp&nbsp&nbsp Nom : [im_name_from_user_id $user_id]</font></b>&nbsp;
  </td></tr></table>
	<table border=0 cellspacing=1 cellpadding=5>
"

set footer_array_list [list]
set last_value_list [list]

im_report_render_row \
    -row $header0 \
    -row_class "rowtitle" \
    -cell_class "rowtitle"

set counter 0
set class 0

db_foreach sql $report_sql {

	set class $rowclass([expr $counter % 2])

	set project_name [string_truncate -len 40 $project_name]

	set weekday [lindex $weekdays [expr $weekday_nr-1]]

	im_report_display_footer \
	    -group_def $report_def \
	    -footer_array_list $footer_array_list \
	    -last_value_array_list $last_value_list \
	    -level_of_detail $level_of_detail \
	    -row_class $class \
	    -cell_class $class

	im_report_update_counters -counters $counters

	set last_value_list [im_report_render_header \
	    -group_def $report_def \
	    -last_value_array_list $last_value_list \
	    -level_of_detail $level_of_detail \
	    -row_class $class \
	    -cell_class $class
	]

	set footer_array_list [im_report_render_footer \
	    -group_def $report_def \
	    -last_value_array_list $last_value_list \
	    -level_of_detail $level_of_detail \
	    -row_class $class \
	    -cell_class $class
	]

	incr counter
}

im_report_display_footer \
    -group_def $report_def \
    -footer_array_list $footer_array_list \
    -last_value_array_list $last_value_list \
    -level_of_detail $level_of_detail \
    -display_all_footers_p 1 \
    -row_class $class \
    -cell_class $class

im_report_render_row \
    -row $footer0 \
    -row_class $class \
    -cell_class $class \
    -upvar_level 1

ns_write "
	</table>

  <table border=1><tr><td>
  &nbsp;<b><font size=4>Absences</font></b>&nbsp;
  </td></tr></table>
	<table border=0 cellspacing=1 cellpadding=5>
	"

set footer_array_list [list]
set last_value_list [list]

im_report_render_row \
    -row $header1 \
    -row_class "rowtitle" \
    -cell_class "rowtitle"

set class 0
set counter 0

db_foreach sql $absences_sql {

	set class $rowclass([expr $counter % 2])

	im_report_display_footer \
	    -group_def $absences_def \
	    -footer_array_list $footer_array_list \
	    -last_value_array_list $last_value_list \
	    -level_of_detail $level_of_detail \
	    -row_class $class \
	    -cell_class $class

	set last_value_list [im_report_render_header \
	    -group_def $absences_def \
	    -last_value_array_list $last_value_list \
	    -level_of_detail $level_of_detail \
	    -row_class $class \
	    -cell_class $class
	]

	set footer_array_list [im_report_render_footer \
	    -group_def $absences_def \
	    -last_value_array_list $last_value_list \
	    -level_of_detail $level_of_detail \
	    -row_class $class \
	    -cell_class $class
	]

	incr counter
}

im_report_display_footer \
    -group_def $absences_def \
    -footer_array_list $footer_array_list \
    -last_value_array_list $last_value_list \
    -level_of_detail $level_of_detail \
    -display_all_footers_p 1 \
    -row_class $class \
    -cell_class $class

im_report_render_row \
    -row $footer1 \
    -row_class $class \
    -cell_class $class \
    -upvar_level 1

ns_write "
	</table>
  <table border=1><tr><td>
  &nbsp;<b><font size=4>Approbations</font></b>&nbsp;
  </td></tr></table>
	<table border=1>
		<tr>
			<td width='70%'>
				<table cellspacing=1 cellpadding=5 border=0>
					<tr valign=top>
	  				<td>
							<tr>
							  <td>Le consultant certifie avoir contrôlé les heures encodées</td>
							</tr>
							<tr>
							  <td>Nom</td>
							  <td>Date</td>
							</tr>
					  </td>
					</tr>
				</table>
				<br/>
				<br/>
				<table cellspacing=1 cellpadding=5 border=0>
					<tr>
					  <td>Le client approuve les heures prestées par le consultant</td>
					</tr>
					<tr>
					  <td>Nombre d'heures prestées</td>
					  <td>$hours_total</td>
					</tr>
					<tr>
		  			<td>Nom</td>
					  <td>Date</td>
					</tr>
				</table>
				&nbsp
				<br/>
				&nbsp
			</td>
		</tr>
	</table>
	<br/>
	<br/>

	[im_footer]
"
