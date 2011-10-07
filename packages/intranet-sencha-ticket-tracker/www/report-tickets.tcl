# /packages/intranet-sencha-ticket-tracker/report-tickets.tcl
#
# Copyright (c) 2011 ]project-open[
#
# All rights reserved. 
# Please see http://www.project-open.com/ for licensing.

ad_page_contract {
    Export of all tickets for SPRI
} {
    { start_date "" }
    { end_date "" }
    { level_of_detail:integer 3 }
    { customer_id:integer 0 }
    { output_format "html" }
}


# ------------------------------------------------------------
# Security
#
set menu_label "reporting-spri-report-tickets"
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
        to_char(to_date(:start_date, 'YYYY-MM-DD') + 31::integer, 'YYYY') as end_year,
        to_char(to_date(:start_date, 'YYYY-MM-DD') + 31::integer, 'MM') as end_month,
        to_char(to_date(:start_date, 'YYYY-MM-DD') + 31::integer, 'DD') as end_day
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

set page_title "SPRI Tickets"
set context_bar [im_context_bar $page_title]
set help_text "
	<strong>$page_title</strong><br>
"


# ------------------------------------------------------------
# Default Values and Constants

set rowclass(0) "roweven"
set rowclass(1) "rowodd"
set currency_format "999,999,999.09"
set date_format "YYYY-MM-DD"
set date_time_format "YYYY-MM-DD HH24:MI"
set company_url "/intranet/companies/view?company_id="
set project_url "/intranet/projects/view?project_id="
set invoice_url "/intranet-invoices/view?invoice_id="
set user_url "/intranet/users/view?user_id="
set this_url [export_vars -base "/intranet-reporting-tutorial/projects-05" {start_date end_date} ]

# Level of Details
set levels {2 "Customers" 3 "Customers+Projects"} 


# ------------------------------------------------------------
# Report SQL - This SQL statement defines the raw data 
# that are to be shown.

set report_sql "
	select
		t.*,
		im_category_from_id(t.ticket_incoming_channel_id) as ticket_incoming_channel,
		im_category_from_id(t.ticket_outgoing_channel_id) as ticket_outgoing_channel,
		im_category_from_id(t.ticket_area_id) as ticket_program,
		(select im_category_from_id(min(im_category_parents)) from im_category_parents(t.ticket_area_id)) as ticket_area,

		p.*,
		g.group_name as ticket_queue,
		im_category_from_id(t.ticket_status_id) as ticket_status,
		im_category_from_id(t.ticket_type_id) as ticket_type,
		cust.company_id,
		cust.company_name,
		cust.vat_number,
		cust.company_province,
		im_category_from_id(cust.company_type_id) as company_type,

		CASE WHEN t.ticket_queue_id = 463 THEN 'SI' ELSE 'NO' END as ticket_resuelto,
		CASE WHEN t.ticket_requires_addition_info_p = 'true' THEN 'SI' ELSE 'NO' END as ticket_requires_addition_info,

		p_creator.person_id as creation_user_id,
		p_creator.first_names as creation_user_first_names,
		p_creator.last_name as creation_user_last_name,
		coalesce(p_creator.asterisk_user_id, im_name_from_user_id(p_creator.person_id)) as creation_user_asterisk_id,
		im_name_from_user_id(p_creator.person_id) as creation_user_name,

		coalesce(p_contact.first_names,'') || ' ' || 
			coalesce(p_contact.last_name, '') || ' ' || 
			coalesce(p_contact.last_name2, '') as contact_name,
		pa_contact.email as contact_email,
		p_contact.telephone as contact_telephone,
		p_contact.vip_p as contact_vip_p,
		p_contact.gender as contact_gender,
		p_contact.language as contact_language,

		to_char(o.creation_date, 'YYYY-MM-DD') as creation_date_date,
		to_char(o.creation_date, 'HH24:MI') as creation_date_time,

		to_char(t.ticket_creation_date, :date_time_format) as ticket_creation_date_pretty,
		to_char(t.ticket_creation_date, 'YYYY-MM-DD') as ticket_creation_date_date,
		to_char(t.ticket_creation_date, 'HH24:MI') as ticket_creation_date_time,

		to_char(t.ticket_escalation_date, 'YYYY-MM-DD') as ticket_escalation_date_date,
		to_char(t.ticket_escalation_date, 'HH24:MI') as ticket_escalation_date_time,

		to_char(t.ticket_done_date, 'YYYY-MM-DD') as ticket_done_date_date,
		to_char(t.ticket_done_date, 'HH24:MI') as ticket_done_date_time,

		to_char(t.ticket_reaction_date, :date_time_format) as ticket_reaction_date_pretty,
		to_char(t.ticket_confirmation_date, :date_time_format) as ticket_confirmation_date_pretty,
		to_char(t.ticket_done_date, :date_time_format) as ticket_done_date_pretty,
		to_char(t.ticket_signoff_date, :date_time_format) as ticket_signoff_date_pretty,
		to_char(t.ticket_resolution_date, :date_time_format) as ticket_resolution_date_pretty,
		to_char(t.ticket_escalation_date, :date_time_format) as ticket_escalation_date_pretty,
		to_char(t.ticket_resolution_date, :date_time_format) as ticket_resolution_date_pretty
	from
		acs_objects o
		LEFT OUTER JOIN persons p_creator ON (o.creation_user = p_creator.person_id),
		im_projects p
		LEFT OUTER JOIN im_companies cust ON (p.company_id = cust.company_id)
		LEFT OUTER JOIN im_offices office ON (office.office_id = cust.main_office_id),
		im_tickets t
		LEFT OUTER JOIN persons p_contact ON (t.ticket_customer_contact_id = p_contact.person_id)
		LEFT OUTER JOIN parties pa_contact ON (t.ticket_customer_contact_id = pa_contact.party_id)
		LEFT OUTER JOIN groups g ON (t.ticket_queue_id = g.group_id)
	where
		t.ticket_id = o.object_id and
		t.ticket_id = p.project_id and
		o.creation_date >= :start_date and
		o.creation_date <= :end_date
	order by
		lower(cust.company_path),
		lower(p.project_nr)
"


# ------------------------------------------------------------
# Report Definition
#
# Reports are defined in a "declarative" style. The definition
# consists of a number of fields for header, lines and footer.

# Global Header Line
set header0 {
	"Asterisk ID Informador" 
	"Ticket ID"
	"Fecha Sistema"
	"Hora Sistema"
	"Fecha Recepcion"
	"Hora Recepcion"
	"Fecha Escalacion"
	"Hora Escalacion"
	"Fecha Cierre"
	"Hora Cierre"
	"Canal Entrada"
	"Canal Salida"
	"NIF"
	"Empresa"
	"Tipo Empresa"
	"Provincia"
	"Contacto Nombre"
	"Contacto Mail"
	"Telefono"
	"Area"
	"Programa"
	"Tema"
	"Expediente"
	"Detalle"
	"Respuesta"
	"Resuelto"
	"Apoyo Mail"
	"Escalado"
}

# The entries in this list include <a HREF=...> tags
# in order to link the entries to the rest of the system (New!)
#
set report_def [list \
    group_by ticket_id \
    header {
	$creation_user_first_names
	$project_nr
	$creation_date_date
	$creation_date_time
	$ticket_creation_date_date
	$ticket_creation_date_time
	$ticket_escalation_date_date
	$ticket_escalation_date_time
	$ticket_done_date_date
	$ticket_done_date_time
	$ticket_incoming_channel
	$ticket_outgoing_channel
	$vat_number
	$company_name
	$company_type
	$company_province
	$contact_name
	$contact_email
	$contact_telephone
	$ticket_area
	$ticket_program
	$ticket_type
	$ticket_file
	$ticket_request
	$ticket_resolution
	$ticket_resuelto
	$ticket_requires_addition_info
	$ticket_queue
    } \
    content {} \
    footer {} \
]



# Global Footer Line
set footer0 {}


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
		<!-- 'Filters' - Show the Report parameters -->
		<form>
		<table cellspacing=2>
		<tr class=rowtitle>
		  <td class=rowtitle colspan=2 align=center>Filters</td>
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

ns_log Notice "report-tickets: $output_format"

# Write out the HTMl to close the main report table
# and write out the page footer.
#
switch $output_format {
    html { ns_write "</table>[im_footer]\n" }
    printer { ns_write "</table>\n</div>\n" }
    cvs { }
}

