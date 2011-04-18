# /packages/intranet-reporting/www/timesheet-invoice-hours.tcl
#
# Copyright (C) 2003-2008 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/ for licensing details.


ad_page_contract {
	testing reports	
    @param start_year Year to start the report
    @param start_unit Month or week to start within the start_year
    @param truncate_note_length Truncate (ellipsis) the note field
           to the given number of characters. 0 indicates no
           truncation.
} {
    { level_of_detail 2 }
    { truncate_note_length 4000}
    { output_format "html" }
    { project_id:integer 0}
    { task_id:integer 0}
    { user_id:integer 0}
    { printer_friendly_p:integer 1}
    { company_id:integer 0}
    invoice_id:integer
}

# ------------------------------------------------------------
# Security

# Label: Provides the security context for this report
# because it identifies unquely the report's Menu and
# its permissions.
# Uses the same label as the timesheet report.
set menu_label "reporting-timesheet-customer-project"

set current_user_id [ad_maybe_redirect_for_registration]

set read_p [db_string report_perms "
	select	im_object_permission_p(m.menu_id, :current_user_id, 'read')
	from	im_menus m
	where	m.label = :menu_label
" -default 'f']

# Has the current user the right to edit all timesheet information?
set edit_timesheet_p [im_permission $current_user_id "edit_hours_all"]

# ------------------------------------------------------------
# Constants

set date_format "YYYY-MM-DD"
set number_format "999,999.99"
set system_url [ad_parameter -package_id [ad_acs_kernel_id] SystemURL "" ""]

# ------------------------------------------------------------

set undefined_l10n [lang::message::lookup "" intranet-reporting.undefined "&lt;undefined&gt;"]
set grand_total_l10n [lang::message::lookup "" intranet-reporting.Grand_Total "Grand Total"]
set customer_l10n [lang::message::lookup "" intranet-core.Customer "Customer"]
set project_l10n [lang::message::lookup "" intranet-core.Project "Project"]
set project_number_l10n [lang::message::lookup "" intranet-core.Project_Number "Project Number"]
set customer_po_l10n [lang::message::lookup "" intranet-reporting.Customer_PO "Customer PO"]
set date_signature_l10n [lang::message::lookup "" intranet-reporting.Date_Signature "&nbsp;&nbsp;Date, Signature"]


# ------------------------------------------------------------

if {![string equal "t" $read_p]} {
    ad_return_complaint 1 "
    [lang::message::lookup "" intranet-reporting.You_dont_have_permissions "You don't have the necessary permissions to view this page"]"
    return
}

db_1row invoice_details "
	select	c.cost_name as invoice_name,
		c.cost_nr as invoice_nr
	from	im_costs c
	where	c.cost_id = :invoice_id
"

set page_title [lang::message::lookup "" intranet-reporting.Invoice_details "Details for Invoice %invoice_name%"]
set context_bar [im_context_bar $page_title]
set context ""


# ------------------------------------------------------------
# Defaults

set rowclass(0) "roweven"
set rowclass(1) "rowodd"

# Maxlevel is 4. Normalize in order to show the right drop-down element
if {$level_of_detail > 5} { set level_of_detail 5 }


set company_url "$system_url/intranet/companies/view?company_id="
set project_url "$system_url/intranet/projects/view?project_id="
set user_url "$system_url/intranet/users/view?user_id="
set hours_url "$system_url/intranet-timesheet2/hours/one"
set this_url [export_vars -base "$system_url/intranet-reporting/timesheet-customer-project" {level_of_detail project_id task_id company_id user_id} ]

# BaseURL for drill-down. Needs company_id, project_id, user_id, level_of_detail
set base_url [export_vars -base "$system_url/intranet-reporting/timesheet-customer-project" {task_id} ]


# ------------------------------------------------------------
# Conditional SQL Where-Clause
#

set criteria [list]

if {0 != $company_id && "" != $company_id} {
    lappend criteria "p.company_id = :company_id"
}

if {0 != $user_id && "" != $user_id} {
    lappend criteria "h.user_id = :user_id"
}

if {0 != $task_id && "" != $task_id} {
    lappend criteria "h.project_id = :task_id"
}

if {0 != $invoice_id && "" != $invoice_id} {
    lappend criteria "h.invoice_id = :invoice_id"
}

# Select project & subprojects
if {0 != $project_id && "" != $project_id} {
    lappend criteria "p.project_id in (
	select
		p.project_id
	from
		im_projects p,
		im_projects parent_p
	where
		parent_p.project_id = :project_id
		and p.tree_sortkey between parent_p.tree_sortkey and tree_right(parent_p.tree_sortkey)
		and p.project_status_id not in ([im_project_status_deleted])
    )"
}

set where_clause [join $criteria " and\n            "]
if { ![empty_string_p $where_clause] } {
    set where_clause " and $where_clause"
}


# ------------------------------------------------------------
# Define the report - SQL, counters, headers and footers 
#

set sql "
select
	h.note,
	to_char(h.day, :date_format) as date,
	to_char(h.day, 'J') as julian_date,
	h.day,
	to_char(coalesce(h.hours,0), :number_format) as hours,
	u.user_id,
	im_name_from_user_id(u.user_id) as user_name,
	im_initials_from_user_id(u.user_id) as user_initials,
	main_p.project_id,
	main_p.project_nr,
	main_p.project_name,
	c.company_id,
	c.company_path as company_nr,
	c.company_name,
	c.company_id || '-' || main_p.project_id as company_project_id,
	c.company_id || '-' || main_p.project_id || u.user_id as company_project_user_id,
        p.project_name as sub_project_name
from
	im_hours h,
	im_projects p,
	im_projects main_p,
	im_companies c,
	users u
where
	h.project_id = p.project_id
	and main_p.project_status_id not in ([im_project_status_deleted])
	and h.user_id = u.user_id
	and main_p.tree_sortkey = tree_root_key(p.tree_sortkey)
	and main_p.company_id = c.company_id
	$where_clause
order by
	c.company_path,
	main_p.project_nr,
	user_name,
	h.day
"


db_1row start_end_date "
	select	to_char(min(h.day), :date_format) as hours_start_date,
		to_char(max(h.day), :date_format) as hours_end_date
	from
		($sql) h
"


if {"" == $hours_start_date} { set hours_start_date $undefined_l10n }
if {"" == $hours_end_date} { set hours_end_date $undefined_l10n }

# We skip the customer grouping because we asume that there is exactly
# one customer.

set report_def [list \
	group_by company_project_id \
	header {
	    "\#colspan=99 <br>&nbsp;<br><h1>$project_nr - $project_name</h1>"
	} \
	content [list \
	    group_by company_project_user_id \
	    header {
		"\#colspan=99 <br><b>$user_name</b>"
	    } \
	    content [list \
		    header {
			$date
			$hours
			$note
		    } \
		    content {} \
	    ] \
	    footer {
		"Sum"
		"<i>$hours_user_subtotal</i>"
		""
		""
		""
	    } \
	] \
	footer {
	    "<br>$grand_total_l10n"
	    "<br><b>$hours_project_subtotal</b>"
	    ""
	    ""
	    ""
	} \
]

# Global header/footer

set hours_user_counter [list \
	pretty_name Hours \
	var hours_user_subtotal \
	reset \$company_project_user_id \
	expr \$hours
]

set hours_project_counter [list \
	pretty_name Hours \
	var hours_project_subtotal \
	reset \$company_project_id \
	expr \$hours
]

set hours_customer_counter [list \
	pretty_name Hours \
	var hours_customer_subtotal \
	reset \$company_id \
	expr \$hours
]

set counters [list \
	$hours_user_counter \
	$hours_project_counter \
	$hours_customer_counter \
]


# ------------------------------------------------------------
# Constants
#

set levels {1 "Customer Only" 2 "Customer+Project" 3 "Customer+Project+User" 4 "All Details"} 
set truncate_note_options {4000 "Full Length" 80 "Standard (80)" 20 "Short (20)"} 

# ------------------------------------------------------------
# Start formatting the page
#

set report_options_html ""
if {$level_of_detail > 3} {
    append report_options_html "
	<tr>
	  <td class=form-label>Size of Note Field</td>
	  <td class=form-widget>
	    [im_select -translate_p 0 truncate_note_length $truncate_note_options $truncate_note_length]
	  </td>
	</tr>
    "
}


if {[info exists project_id]} {
    append report_options_html "
	<tr>
	  <td class=form-label></td>
	  <td class=form-widget>
            <input type=hidden name=project_id value=\"$project_id\">
	  </td>
	</tr>
    "
}


if {[info exists task_id]} {
    append report_options_html "
	<tr>
	  <td class=form-label></td>
	  <td class=form-widget>
            <input type=hidden name=task_id value=\"$task_id\">
	  </td>
	</tr>
    "
}

# ------------------------------------------------------------
# Get useful information about the invoice


set company_name [db_string company_name "select company_name from im_companies where company_path = 'internal'" -default "Unable to get company_name"]
set customer_name [db_string company_name "select company_name from im_companies where company_id in (select customer_id from im_costs where cost_id = :invoice_id)" -default "Unable to get customer_name"]
set project_names [db_list project_name "select project_name from im_projects where project_id in (select object_id_one from acs_rels where object_id_two = :invoice_id)"]
set project_name [join $project_names ", "]
set project_nrs [db_list project_nr "select project_nr from im_projects where project_id in (select object_id_one from acs_rels where object_id_two = :invoice_id)"]
set project_nr [join $project_nrs ", "]

set timesheet_customer_l10n [lang::message::lookup "" intranet-reporting.Timesheet_Customer "%customer_name% Timesheet"]


# ------------------------------------------------------------
# Start Formatting the HTML Page Contents

# Write out HTTP header, considering CSV/MS-Excel formatting
im_report_write_http_headers -output_format $output_format

set output_template $output_format
if {$printer_friendly_p} { set output_template "template" }

switch $output_template {
    template {
	ns_write "
		<html>
		 <head>
		  <meta http-equiv='content-type' content='text/html;charset=UTF-8'>
		  <title>$timesheet_customer_l10n</title>
		  <link rel='stylesheet' type='text/css' href='$system_url/intranet-reporting/timesheet-invoice-hours.css'>
		 </head>
		 <body>
		  <div id=header>
		   <p style='text-align:right'>[im_logo]</p>
		  </div>
		  <div id=main>
			<div id=title>$timesheet_customer_l10n</div>
			<div id=subtitle>Period: $hours_start_date to $hours_end_date</div>
			
			<table id=headertable cellpadding=0 border=0 rules=all>
			 <tbody>
			  <tr>
			   <td id=head>$customer_l10n:</td>
			   <td id=head>$project_l10n:</td>
			   <td id=head>$project_number_l10n:</td>
			   <td id=head>$customer_po_l10n:</td>
			  </tr>
			  
			  <tr>
			   <td id=content>$customer_name</td>
			  <td id=content>$project_name</td>
			   <td id=content>$project_nr</td>
			   <td id=content></td>
			  </tr>
			  
			 </tbody>
			</table>
	
	
	"
    }
    html {
	ns_write "
	[im_header $page_title]
	[im_navbar reporting]
        <div id=\"slave\">
        <div id=\"slave_content\">
        <div class=\"filter-list\">
        <div class=\"filter\">
        <div class=\"filter-block\">

	<form>
	<table border=0 cellspacing=1 cellpadding=1>
	[export_form_vars company_id invoice_id]
	<tr valign=top><td>
		<table border=0 cellspacing=1 cellpadding=1>
		<tr>
	          <td class=form-label>Level of Details</td>
		  <td class=form-widget>
		    [im_select -translate_p 0 level_of_detail $levels $level_of_detail]
		  </td>
		</tr>

	        $report_options_html

                <tr>
                  <td class=form-label>Format</td>
                  <td class=form-widget>
                    [im_report_output_format_select output_format "" $output_format]
                  </td>
                </tr>
                <tr>
                  <td class=form-label>Printer Friendly</td>
                  <td class=form-widget>
			<input type=checkbox name=printer_friendly_p value=1>
                  </td>
                </tr>
		<tr>
		  <td class=form-label></td>
		  <td class=form-widget><input type=submit value=Submit></td>
		</tr>
		</table>

	</td></tr>
	</table>
	</form>

        </div>
        </div>
        <div class=\"fullwidth-list\">
	<table border=0 cellspacing=1 cellpadding=1>\n"
    }
}



switch $output_template {
    html {

	# Global header/footer
	set header0 {"Date" Hours Note}
	set footer0 {"" "" ""}
	
	set footer_array_list [list]
	set last_value_list [list]
	set class "rowodd"
	db_foreach sql $sql {
	    
	    
	    if {[string length $note] > $truncate_note_length} {
		set note "[string range $note 0 $truncate_note_length] ..."
	    }
	    set hours_link $hours
	    if {$edit_timesheet_p} {
		set hours_link "<a href=\"[export_vars -base $hours_url {julian_date user_id project_id {return_url $this_url}}]\">$hours</a>\n"
	    }
		    
		
	    im_report_display_footer \
		-output_format $output_format \
		-group_def $report_def \
		-footer_array_list $footer_array_list \
		-last_value_array_list $last_value_list \
		-level_of_detail $level_of_detail \
		-row_class $class \
		-cell_class $class
	    
	    im_report_update_counters -counters $counters
	    
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

    }
    template {

	set user_sql "select distinct user_id, user_name from ($sql) s order by user_name"
	set user_list [db_list_of_lists users $user_sql]

	set grand_total 0
	foreach user_tuple $user_list {
	    set user_id [lindex $user_tuple 0]
	    set user_name [lindex $user_tuple 1]


	    ns_write "
                        <table id=timetable cellpadding=0 border=0 rules=all>
                        <colgroup>
                                <col id=datecol>
                                <col id=hourcol>
                                <col id=textcol>
                        </colgroup>
                        <tbody>
                        <tr>
				<td id=timetitle colspan=3>$user_name</td>
                        </tr>
	    "

	    set hours_sql "select * from ($sql) s where s.user_id = :user_id"
	    set sub_total 0
	    db_foreach hours $hours_sql {
		set description $note
		if { "5" == $level_of_detail} {
		    set description "$sub_project_name<br>$description"
		}

		ns_write "
	                <tr id=time>
                           <td id=time>$date</td>
                           <td id=time>$hours</td>
                           <td id=time>$description</td>
                        </tr>
		"
		set sub_total [expr $sub_total + $hours]
		set grand_total [expr $grand_total + $hours]

	    }

	    ns_write "
                        <tr>
                           <td id=timesum>Sum</td>
                           <td id=timesum>$sub_total</td>
                           <td id=timesum></td>
                        </tr>
                        </tbody>
                        </table>
              "


	}


    }

}


# Write out the HTMl to close the main report table
# and write out the page footer.
#
switch $output_template {
    template { 
	ns_write "
        
			<table id=timetable cellpadding=0 border=0 rules=all>
			<colgroup>
				<col id='datecol'>
				<col id='hourcol'>
				<col id='textcol'>
			</colgroup>
			 <tbody>
			 <tr>
					<td id=totalsum>Grand Total</td>
					<td id=totalsum>$grand_total</td>
					<td id=totalsum>X</td>
				</tr>
			<tr>
					<td id=totalsum style='border:0px'></td>
					<td id=totalsum style='border:0px'></td>
					<td id=totalsum style='border:0px;font-weight:normal;'>$date_signature_l10n</td>
				</tr>
			</table>
		  </div>
		 </body>
		</html>
	"
    }
    html { 
	ns_write "
	</table>
	</div>
	</div>
	</div>
	</div>
	</div>
	[im_footer]
	"
    }
}
