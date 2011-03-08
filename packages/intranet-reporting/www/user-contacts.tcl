# /packages/intranet-reporting/www/user-contacts.tcl
#
# Copyright (c) 2003-2006 ]project-open[
#
# All rights reserved. 
# Please see http://www.project-open.com/ for licensing.

ad_page_contract {
    Shows a list of all users in the system, together with
    their contact information, 
} {
    { level_of_detail:integer 3 }
    { company_id 0 }
    { company_type_id 0 }
    { output_format "html" }
    { redirect_p "1" }
}

# set current_user_id [ad_maybe_redirect_for_registration]
set current_user_id [ad_get_user_id]
set menu_label "reporting-user-contacts"
set read_p [db_string report_perms "
	select	im_object_permission_p(m.menu_id, :current_user_id, 'read')
	from	im_menus m
	where	m.label = :menu_label
" -default 'f']

if {![string equal "t" $read_p]} {
    set message "You don't have the necessary permissions to view this page"
    ad_return_complaint 1 "<li>$message"
    ad_script_abort
}

# Maxlevel is 3. 
if {$level_of_detail > 3} { set level_of_detail 3 }


# ------------------------------------------------------------
# Page Title, Bread Crums and Help
#

set page_title "Users and Contacts"
set context_bar [im_context_bar $page_title]
set help_text "
	<strong>Users and Contacts:</strong><br>
        This report shows all users in the system, together with
        their state and their contact details.
"


# ------------------------------------------------------------
# Default Values and Constants
#

set rowclass(0) "roweven"
set rowclass(1) "rowodd"
set class "roweven"

set currency_format [im_l10n_sql_currency_format]
set date_format [im_l10n_sql_date_format]
set levels {3 "All Details"} 

set company_url "/intranet/companies/view?company_id="
set user_url "/intranet/users/view?user_id="
set this_url "/intranet-reporting/user-contacts?"


# ------------------------------------------------------------
# Report SQL

set company_sql ""
if {"" != $company_id && 0 != $company_id} {
    set company_sql "and c.company_id = :company_id\n"
}

if {"" != $company_type_id && 0 != $company_type_id} {
    append company_sql "and c.company_type_id = :company_type_id\n"
}

set report_sql "
	select	
		emp.member_p as employee_p,
		cust.member_p as customer_p,
		free.member_p as freelancer_p,
		c.*,
		im_category_from_id(c.company_status_id) as company_status,
		im_category_from_id(c.company_type_id) as company_type,
		p.*,
		u.*,
		'unknown' as member_state,
		im_name_from_user_id(u.user_id) as user_name,
		uc.*,
		im_country_from_code(uc.ha_country_code) as ha_country,
		im_country_from_code(uc.wa_country_code) as wa_country
	from
		parties p,
		users u
		LEFT OUTER JOIN users_contact uc ON (u.user_id = uc.user_id)
		LEFT OUTER JOIN (
			select	r.object_id_two as user_id,
				c.*
			from	acs_rels r,
				im_companies c
			where	r.object_id_one = c.company_id
		) c ON (u.user_id = c.user_id)
		LEFT OUTER JOIN (
			select	member_id, 'e' as member_p
			from	group_distinct_member_map
			where	group_id = 463	
		) emp ON (u.user_id = emp.member_id)
		LEFT OUTER JOIN (
			select	member_id, 'c' as member_p
			from	group_distinct_member_map
			where	group_id = 461	
		) cust ON (u.user_id = cust.member_id)
		LEFT OUTER JOIN (
			select	member_id, 'f' as member_p
			from	group_distinct_member_map
			where	group_id = 465
		) free ON (u.user_id = free.member_id)
	where
		u.user_id = p.party_id
		$company_sql
	order by
		c.company_type_id,
		c.company_name,
		user_name
"

# ------------------------------------------------------------
# Report Definition
#


# Global Header Line
set header0 {
	"Type" 
	"Comp" 
	"C"
	"E"
	"F"
	"Email"
	"Name"
	"Home"
	"Work"
	"Cell"
	"Pager"
	"Fax"
	"AIM"
	"MSN"
	"ICQ"
	"Home"
	"Work"
	"Note"
}

# The entries in this list include <a HREF=...> tags
# in order to link the entries to the rest of the system (New!)
#
set report_def [list \
    group_by company_type_id \
    header {
	"\#colspan=18 <a href=$this_url&company_type_id=$company_type_id&level_of_detail=4 
	target=_blank><img src=/intranet/images/plus_9.gif width=9 height=9 border=0></a> 
	<b>$company_type</b>"
    } \
        content [list \
            group_by company_id \
            header { 
		""
		"\#colspan=17 <a href='$company_url$company_id'>$company_name</a>"
	    } \
	    content [list \
		    header {
			""
			"$company_path"
			"$customer_p"
			"$employee_p"
			"$freelancer_p"
			"$email"
			"$user_name"
			"$home_phone"
			"$work_phone"
			"$cell_phone"
			"$pager"
			"$fax"
			"$aim_screen_name"
			"$msn_screen_name"
			"$icq_number"
			"$ha"
			"$wa"
			"$note"
		    } \
		    content {} \
	    ] \
            footer {} \
    ] \
    footer {} \
]

# Global Footer Line
set footer0 {
	"" 
	"" 
	""
	""
	""
	""
	""
	""
	""
	""
	""
	"" 
	"" 
	"" 
	"" 
	"" 
	"" 
	"" 
}


# ------------------------------------------------------------
# Counters
#

set counters [list]

# Set the values to 0 as default (New!)


# ------------------------------------------------------------
# Start Formatting the HTML Page Contents

# Write out HTTP header, considering CSV/MS-Excel formatting
im_report_write_http_headers -output_format $output_format

switch $output_format {
    html {
	ns_write "
	[im_header]
	[im_navbar]
	<table cellspacing=0 cellpadding=0 border=0>
	<tr valign=top>
	  <td width='30%'>
		<form>
		<table cellspacing=2>
		<tr class=rowtitle>
		  <td class=rowtitle colspan=2 align=center>Filters</td>
		</tr>
		<tr>
		  <td class=form-label>Level of<br>Details</td>
		  <td class=form-widget>
		    [im_select -translate_p 0 level_of_detail $levels $level_of_detail]
		  </td>
		</tr>
		<tr>
		  <td class=form-label>Company<br>Type</td>
		  <td class=form-widget>
		    [im_category_select -include_empty_p 1 "Intranet Company Type" company_type_id $company_type_id]
		  </td>
		</tr>
		<tr>
		  <td class=form-label>Format</td>
		  <td class=form-widget>
		    [im_report_output_format_select output_format "" $output_format]
		  </td>
		</tr>
		<tr>
		  <td class=form-label></td>
		  <td class=form-widget><input type=submit value='Submit'></td>
		</tr>
		</table>
		</form>
	  </td>
	  <td align=center>
		<table cellspacing=2 width='90%'>
		<tr>
		  <td>$help_text</td>
		</tr>
		</table>
	  </td>
	</tr>
	</table>
	
	<!-- Here starts the main report table -->
	<table border=0 cellspacing=1 cellpadding=1>
        "
    }
    default { }
}


# ------------------------------------------------------
# The following report loop is "magic"

set footer_array_list [list]
set last_value_list [list]

im_report_render_row \
    -output_format $output_format \
    -row $header0 \
    -row_class "rowtitle" \
    -cell_class "rowtitle"

set counter 0
db_foreach sql $report_sql {

	set ha_list [list]
	if {"" != $ha_line1} { lappend ha_list $ha_line1 }
	if {"" != $ha_line2} { lappend ha_list $ha_line2 }
	if {"" != $ha_postal_code} { lappend ha_list $ha_postal_code }
	if {"" != $ha_city} { lappend ha_list $ha_city }
	if {"" != $ha_state} { lappend ha_list $ha_state }
	if {"" != $ha_country} { lappend ha_list $ha_country }
	set ha [join $ha_list ", "]

	set wa_list [list]
	if {"" != $wa_line1} { lappend wa_list $wa_line1 }
	if {"" != $wa_line2} { lappend wa_list $wa_line2 }
	if {"" != $wa_postal_code} { lappend wa_list $wa_postal_code }
	if {"" != $wa_city} { lappend wa_list $wa_city }
	if {"" != $wa_state} { lappend wa_list $wa_state }
	if {"" != $wa_country} { lappend wa_list $wa_country }
	set wa [join $wa_list ", "]

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

im_report_render_row \
    -output_format $output_format \
    -row $footer0 \
    -row_class $class \
    -cell_class $class \
    -upvar_level 1


# Write out the HTMl to close the main report table
# and write out the page footer.
#
switch $output_format {
    html { ns_write "</table>\n[im_footer]\n"}
}
