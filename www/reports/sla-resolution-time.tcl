# /packages/intranet-sencha-ticket-tracker/report-tickets.tcl
#
# Copyright (c) 2011 ]project-open[
#
# All rights reserved. 
# Please see http://www.project-open.com/ for licensing.

ad_page_contract {
    Show Resolution time per ticket
} {
    { start_date "" }
    { end_date "" }
    { level_of_detail:integer 3 }
    { customer_id:integer 0 }
    { ticket_type_id:integer 0 }
    { show_dynfields:multiple ""}
    { output_format "html" }
    { locale "es_ES" }
}


# ------------------------------------------------------------
# Security
#
set menu_label "reporting-helpdesk-sla-resolution-time"
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

set form_mode display

# set locale [lang::user::locale -user_id $current_user_id]
switch $locale {
    en_US {
	set number_format "999999999999.00"
    }
    default {
	set number_format "999999999999,00"
    }
}

# ------------------------------------------------------------
# Check Parameters



# ------------------------------------------------------------
# Defaults

set days_in_past 7
db_1row todays_date "
select
	to_char(sysdate::date - :days_in_past::integer, 'YYYY') as todays_year,
	to_char(sysdate::date - :days_in_past::integer, 'MM') as todays_month,
	to_char(sysdate::date - :days_in_past::integer, 'DD') as todays_day
from dual
"

if {"" == $start_date} {
    set start_date "$todays_year-$todays_month-01"
}

db_1row end_date "
select
	to_char(to_date(:start_date, 'YYYY-MM-DD') + '2 month'::interval, 'YYYY') as end_year,
	to_char(to_date(:start_date, 'YYYY-MM-DD') + '2 month'::interval, 'MM') as end_month,
	to_char(to_date(:start_date, 'YYYY-MM-DD') + '2 month'::interval, 'DD') as end_day
from dual
"

if {"" == $end_date} {
    set end_date "$end_year-$end_month-01"
}


if {![regexp {[0-9][0-9][0-9][0-9]\-[0-9][0-9]\-[0-9][0-9]} $start_date]} {
    ad_return_complaint 1 "Start Date doesn't have the right format.<br>
    Current value: '$start_date'<br>
    Expected format: 'YYYY-MM-DD'"
    ad_script_abort
}

if {![regexp {[0-9][0-9][0-9][0-9]\-[0-9][0-9]\-[0-9][0-9]} $end_date]} {
    ad_return_complaint 1 "End Date doesn't have the right format.<br>
    Current value: '$end_date'<br>
    Expected format: 'YYYY-MM-DD'"
    ad_script_abort
}

# Maxlevel is 3. 
if {$level_of_detail > 3} { set level_of_detail 3 }



# ------------------------------------------------------------
# Page Title, Bread Crums and Help
#

set page_title "Ticket Resolution Time"
set context_bar [im_context_bar $page_title]
set help_text "
	<strong>$page_title</strong><br>
	The report shows the 'resolution time' per ticket and ticket queue
	together with median values per SLA and for all selected tickets.<br>
	The start- and end date act on the creation date of the ticket,
	including start date but excluding end date.<br>
	The report excludes tickets in the current status of 'canceled' and
	'deleted'.
"


# ------------------------------------------------------------
# Default Values and Constants

set rowclass(0) "roweven"
set rowclass(1) "rowodd"
set currency_format "999,999,999.09"
set date_format "YYYY-MM-DD"
set date_time_format "YYYY-MM-DD HH24:MI"
set company_url "/intranet/companies/view"
set project_url "/intranet/projects/view"
set ticket_url "/intranet-helpdesk/new"
set invoice_url "/intranet-invoices/view"
set user_url "/intranet/users/view"
set this_url [export_vars -base "/intranet-sla-management/reports/sla-resolution-time" {start_date end_date} ]

# Level of Details
set levels {2 "Customer+SLA" 3 "All Details"} 


# ------------------------------------------------------------
# Report Definition
#
# Reports are defined in a "declarative" style. The definition
# consists of a number of fields for header, lines and footer.

# Global Header Line
set header0 [list \
		 [lang::message::lookup "" intranet-sla-management.Ticket_Customer "Customer"]  \
		 [lang::message::lookup "" intranet-sla-management.Ticket_SLA "SLA"]  \
		 [lang::message::lookup "" intranet-sla-management.Ticket_Customer_Contact "Customer<br>Contact"]  \
		 [lang::message::lookup "" intranet-sla-management.Ticket_Name "Ticket<br>Name"]  \
		 [lang::message::lookup "" intranet-sla-management.Creation_User "Creation<br>User"]  \
		 [lang::message::lookup "" intranet-sla-management.Ticket_Resolution_Time "Resolution<br>Time"]  \
		]

# Global Footer Line
set footer0 {
    "$ticket_resolution_time_total_count"
    ""
    ""
    ""
    ""
    "\#align=right \[lc_numeric \[expr round(100.0 * \$ticket_resolution_time_total_median) / 100.0\] {} \$locale\]"

}


set customer_header {
	"\#colspan=99 <b><a href=[export_vars -base $company_url {{company_id $company_id}}]>$company_name</a></b>"
}

set sla_header {
	""
	"\#colspan=98 <b><a href=[export_vars -base $project_url {{project_id $sla_id}}]>$sla_name</a></b>"
}

set sla_footer {
    "$ticket_resolution_time_sla_count"
    "$sla_nr"
    ""
    ""
    ""
    "\#align=right [lc_numeric [expr round(100.0 * $ticket_resolution_time_sla_sum / $ticket_resolution_time_sla_count) / 100.0] {} $locale]"
}

set ticket_header {
    "$ticket_resolution_time_sla_count"
    "$sla_nr"
    "<a href=[export_vars -base $user_url {{user_id $ticket_customer_contact_id}}]>$ticket_customer_contact_name</a>"
    "<a href=[export_vars -base $ticket_url {{ticket_id $ticket_id} form_mode}]>$project_nr - $project_name_pretty</a>"
    "<a href=[export_vars -base $user_url {{user_id $creation_user}}]>$creation_user_name</a>"
    "\#align=right \[lc_numeric $ticket_resolution_time {} $locale\]"
}

set counters [list]

# Counters for resolution time per SLA and total
lappend counters [list pretty_name "Solution Time SLA Sum" var ticket_resolution_time_sla_sum reset "\$sla_id" expr "\$ticket_resolution_time"]
lappend counters [list pretty_name "Solution Time SLA Count" var ticket_resolution_time_sla_count reset "\$sla_id" expr "1"]

lappend counters [list pretty_name "Solution Time Total Sum" var ticket_resolution_time_total_sum reset 0 expr "\$ticket_resolution_time"]
lappend counters [list pretty_name "Solution Time Total Count" var ticket_resolution_time_total_count reset 0 expr "1"]


set ticket_resolution_time_total_sum 0
set ticket_resolution_time_total_count 0

# ------------------------------------------------------------
# Add all Project and Company DynFields to list

set dynfield_sql "
	select  aa.attribute_name,
		aa.pretty_name,
		w.widget as tcl_widget,
		w.widget_name as dynfield_widget,
		w.deref_plpgsql_function
	from	im_dynfield_attributes a,
		im_dynfield_widgets w,
		acs_attributes aa
	where	a.widget_name = w.widget_name and
		a.acs_attribute_id = aa.attribute_id and
		aa.object_type = 'im_ticket' and
		aa.attribute_name not like 'default%' and
		aa.attribute_name not in (
			-- Fields already hard coded in the report
			'ticket_customer_contact_id'
		)
	order by 
		a.also_hard_coded_p DESC,
		aa.object_type, 
		aa.sort_order
"

ns_log Notice "sla-resolution-time: show_dynfields=$show_dynfields"

set derefs [list "1 as one"]
set dynfield_options {}
db_foreach dynfield_attributes $dynfield_sql {

    # Skip the DynField completely if the columns doesn't exist (Dynfield configuration errors)
    if {![im_column_exists "im_tickets" $attribute_name]} { continue }

    # Add the dynfield to the list of options
    if {[lsearch $show_dynfields $attribute_name] > -1} { set selected "selected" } else { set selected "" }
    append dynfield_options "\t\t<option value=$attribute_name $selected>$pretty_name</option>\n"

    # Has the Dynfield been selected to be shown?
    if {[lsearch $show_dynfields $attribute_name] < 0} { 
	ns_log Notice "sla-resolution-time: skipping $attribute_name"
	continue 
    } else {
	ns_log Notice "sla-resolution-time: showing $attribute_name"
    }

    # Calculate the "dereference" DynField value
    set deref "substring(${deref_plpgsql_function}($attribute_name)::text for 100) as ${attribute_name}_deref"
    if {"" == $deref} { set deref "substring($attribute_name::text for 100) as ${attribute_name}_deref" }
    regsub -all {[^a-zA-Z0-9\ \-\.]} $pretty_name {} pretty_name
    lappend header0 $pretty_name
    lappend footer0 ""
    lappend sla_footer ""
    lappend derefs $deref
    set var_name "\$${attribute_name}_deref"
    lappend ticket_header $var_name

}


# ----------------------------------------------------------------
# Add the ticket resolution time per group
# First we have to find out if there are times logged for the
# specific group, then we can add the group to the list headers.
# ----------------------------------------------------------------

# find out the groups that do have resolution time in the system
set group_sql "
	select	g.*
	from	groups g
	where	g.group_id > 0
	order by g.group_id
"
set cnt 0
set group_selects {}
db_foreach groups $group_sql {
    incr cnt
    lappend group_selects "sum(t.ticket_resolution_time_per_queue\[$cnt\]) as rtime_$cnt"
}

set group_sum_sql "
	select	[join $group_selects ",\n\t\t"]
	from	im_tickets t
	where	t.ticket_creation_date >= :start_date and
		t.ticket_creation_date < :end_date
"
db_1row group_sum $group_sum_sql


# Calculate a list of groups for storing resolution times per group
set cnt 0
db_foreach groups $group_sql {
    incr cnt

    # Check if there has been some resolution time spent for in this group
    if {![info exists rtime_$cnt]} { ad_return_complaint 1 "Error: didn't find 'rtime_$cnt'" }
    set rtime [expr "\$rtime_$cnt"]
    if {"" == $rtime} { set rtime 0.00 }
    ns_log Notice "sla-resolution-time: cnt=$cnt, rtime=$rtime"
    if {$rtime < 0.01} { continue }

    lappend header0 $group_name
    set var_name "group${group_id}_restime"
    lappend ticket_header "\#align=right \[lc_numeric \$$var_name {} $locale \]"
    set deref "t.ticket_resolution_time_per_queue\[$cnt\] as $var_name"
    lappend derefs $deref

    # Total Counters
    lappend counters [list pretty_name "$group_name Total Sum" var "${var_name}_total_sum" reset 0 expr "\$$var_name+0"]
    lappend counters [list pretty_name "$group_name Total Count" var "${var_name}_total_count" reset 0 expr "1"]
    lappend footer0 "\#align=right \[lc_numeric \[expr round(100.0 * \$${var_name}_total_sum / \$${var_name}_total_count\) / 100.0\] {} $locale\]"

    # Por SLA
    lappend counters [list pretty_name "$group_name SLA Sum" var "${var_name}_sla_sum" reset "\$sla_id" expr "\$$var_name+0"]
    lappend counters [list pretty_name "$group_name SLA Count" var "${var_name}_sla_count" reset "\$sla_id" expr "1"]
    lappend sla_footer "\#align=right \[lc_numeric \[expr round(100.0 * \$${var_name}_sla_sum / \$${var_name}_sla_count\) / 100.0\] {} $locale\]"

}

# ----------------------------------------------------------------
# The entries in this list include <a HREF=...> tags
# in order to link the entries to the rest of the system (New!)
# ----------------------------------------------------------------
#
set report_def [list \
		    group_by company_id \
		    header $customer_header \
		    content [list \
				 group_by sla_id \
				 header $sla_header \
				 content [list \
					      group_by ticket_id \
					      header $ticket_header \
					      content {} \
					      footer {} \
					     ] \
				 footer $sla_footer \
				 ]\
		    footer {} \
		    ]




# ------------------------------------------------------------
# Report SQL - This SQL statement defines the raw data 
# that are to be shown.

set criteria [list]

if {0 != $customer_id && "" != $customer_id} {
    lappend criteria "p.company_id = :customer_id"
}

if {0 != $ticket_type_id && "" != $ticket_type_id} {
    lappend criteria "t.ticket_type_id in (select * from im_sub_categories(:ticket_type_id))"
}

set where_clause [join $criteria " and\n\t\t"]
if { ![empty_string_p $where_clause] } { set where_clause " and $where_clause" }


set report_sql "
	select
		o.*,
		im_name_from_user_id(o.creation_user) as creation_user_name,
		to_char(o.creation_date, :date_time_format) as creation_date_pretty,
		t.*,
		im_category_from_id(t.ticket_status_id) as ticket_status,
		im_category_from_id(t.ticket_type_id) as ticket_type,
		im_name_from_user_id(t.ticket_assignee_id) as ticket_assignee,
		to_char(t.ticket_creation_date, :date_time_format) as ticket_creation_date_pretty,
		to_char(t.ticket_reaction_date, :date_time_format) as ticket_reaction_date_pretty,
		to_char(t.ticket_done_date, :date_time_format) as ticket_done_date_pretty,
		to_char(t.ticket_reaction_date, :date_time_format) as ticket_reaction_date_pretty,
		to_char(t.ticket_confirmation_date, :date_time_format) as ticket_confirmation_date_pretty,
		to_char(t.ticket_signoff_date, :date_time_format) as ticket_signoff_date_pretty,
		im_name_from_user_id(t.ticket_customer_contact_id) as ticket_customer_contact_name,
		p.*,
		substring(p.project_name for 30) as project_name_pretty,
		g.*,
		g.group_name as ticket_queue,
		cust.*,
		im_category_from_id(cust.company_type_id) as company_type,
		sla_project.project_id as sla_id,
		sla_project.project_nr as sla_nr,
		sla_project.project_name as sla_name,
		[join $derefs "\t,\n"]
	from
		acs_objects o,
		im_projects p
		LEFT OUTER JOIN im_companies cust ON (p.company_id = cust.company_id)
		LEFT OUTER JOIN im_offices office ON (office.office_id = cust.main_office_id)
		LEFT OUTER JOIN im_projects sla_project ON (p.parent_id = sla_project.project_id),
		im_tickets t
		LEFT OUTER JOIN persons p_contact ON (t.ticket_customer_contact_id = p_contact.person_id)
		LEFT OUTER JOIN parties pa_contact ON (t.ticket_customer_contact_id = pa_contact.party_id)
		LEFT OUTER JOIN groups g ON (t.ticket_queue_id = g.group_id)
	where
		t.ticket_id = o.object_id and
		t.ticket_id = p.project_id and
		t.ticket_creation_date >= :start_date and
		t.ticket_creation_date < :end_date and
		t.ticket_status_id not in (
			[im_ticket_status_deleted],
			[im_ticket_status_canceled]
		)
		$where_clause
	order by
		lower(cust.company_name),
		lower(sla_project.project_name),
		lower(im_name_from_user_id(o.creation_user)),
		lower(p.project_nr)
"

# --------------------------------------------------------
# Write out HTTP header, considering CSV/MS-Excel formatting
im_report_write_http_headers -output_format $output_format

switch $output_format {
    html {
	ns_write "
	[im_header]
	[im_navbar]
	<form>
	<table cellspacing=10 cellpadding=0 border=0>
	<tr valign=top>
	  <td>
		<!-- 'Filters' - Show the Report parameters -->
		<table cellspacing=2>
		<tr class=rowtitle>
		  <td class=rowtitle colspan=2 align=center>Filters</td>
		</tr>
		<tr>
		  <td class=form-label>Level of Details</td>
		  <td class=form-widget>
		    [im_select -translate_p 0 level_of_detail $levels $level_of_detail]
		  </td>
		</tr>
		<tr>
		  <td><nobr>Start Date:</nobr></td>
		  <td><input type=text name=start_date value='$start_date'></td>
		</tr>
		<tr>
		  <td>End Date:</td>
		  <td><input type=text name=end_date value='$end_date'></td>
		</tr>
	        <tr>
	          <td class=form-label>Ticket Type</td>
	          <td class=form-widget>
	            [im_category_select -include_empty_p 1 -include_empty_name [lang::message::lookup "" intranet-core.All "All"] "Intranet Ticket Type" ticket_type_id $ticket_type_id]
	          </td>
	        </tr>
		<tr>
		  <td>[lang::message::lookup "" intranet-sla-management.Customer "Customer"]</td>
		  <td>[im_company_select -include_empty_name [lang::message::lookup "" intranet-core.All "All"] customer_id $customer_id]</td>
		</tr>
		<tr>
		  <td class=form-label>Format</td>
		  <td class=form-widget>
		    [im_report_output_format_select output_format "" $output_format]
		  </td>
		</tr>
		<tr>
		  <td</td>
		  <td><input type=submit value='Submit'></td>
		</tr>
		</table>
	  </td>
	  <td align=center>
		<table cellspacing=2>
		<tr class=rowtitle>
		  <td class=rowtitle align=center>
			[lang::message::lookup "" intranet-sla-management.Ticket_Fields "Ticket Fields"]
		  </td>
		</tr>
		<tr>
		  <td>
			<select name=show_dynfields size=6 multiple>
			$dynfield_options
			</select>
		  </td>
		</tr>
		</table>
	  </td>
	  <td align=center>
		<table cellspacing=2>
		<tr>
		  <td>$help_text</td>
		</tr>
		</table>
	  </td>
	</tr>
	</table>
	</form>
	
	<!-- Here starts the main report table -->
	<table border=0 cellspacing=1 cellpadding=1>
    "
    }
    printer {
	ns_write "
	<link rel=StyleSheet type='text/css' href='/intranet-reporting/printer-friendly.css' media=all>
	<div class=\"fullwidth-list\">
	<table border=0 cellspacing=1 cellpadding=1 rules=all>
	<colgroup>
		<col id=datecol>
		<col id=hourcol>
		<col id=datecol>
		<col id=datecol>
		<col id=hourcol>
		<col id=hourcol>
		<col id=hourcol>
		<col id=datecol>
		<col id=datecol>
		<col id=datecol>
		<col id=datecol>
		<col id=datecol>
		<col id=datecol>
		<col id=datecol>
		<col id=datecol>
		<col id=datecol>
		<col id=datecol>
		<col id=datecol>
		<col id=datecol>
		<col id=datecol>
		<col id=datecol>
		<col id=datecol>
		<col id=datecol>
		<col id=datecol>
		<col id=datecol>
		<col id=datecol>
		<col id=datecol>
		<col id=datecol>
		<col id=datecol>
		<col id=datecol>
		<col id=datecol>
		<col id=datecol>
		<col id=datecol>
		<col id=datecol>
		<col id=datecol>
		<col id=datecol>
		<col id=datecol>
		<col id=datecol>
	</colgroup>
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

	# Select either "roweven" or "rowodd" from
	# a "hash", depending on the value of "counter".
	# You need explicite evaluation ("expre") in TCL
	# to calculate arithmetic expressions. 
	set class $rowclass([expr $counter % 2])

	im_report_display_footer \
	    -output_format $output_format \
	    -group_def $report_def \
	    -footer_array_list $footer_array_list \
	    -last_value_array_list $last_value_list \
	    -level_of_detail $level_of_detail \
	    -row_class $class \
	    -cell_class $class

	im_report_update_counters -counters $counters

	if {"" != $ticket_type} {
	    set category_key "intranet-core.[lang::util::suggest_key $ticket_type]"
	    set ticket_type [lang::message::lookup $locale $category_key $ticket_type]
	}

	if {"" != $company_type} {
	    set category_key "intranet-core.[lang::util::suggest_key $company_type]"
	    set company_type [lang::message::lookup $locale $category_key $company_type]
	}

	if {"Employees" == $ticket_queue} { set ticket_queue "" }

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


# Calculate fields for totoal (footer0)
# which can be undefined.
set ticket_resolution_time_total_median 0.00
catch { set ticket_resolution_time_total_median [expr $ticket_resolution_time_total_sum / $ticket_resolution_time_total_count] }

im_report_render_row \
    -output_format $output_format \
    -row $footer0 \
    -row_class $class \
    -cell_class $class \
    -upvar_level 1

ns_log Notice "report-tickets: $output_format"

# Write out the HTMl to close the main report table
# and write out the page footer.
#
switch $output_format {
    html { ns_write "</table>[im_footer]\n" }
    printer { ns_write "</table>\n</div>\n" }
    cvs { }
}

