# /packages/intranet-sencha-ticket-tracker/report-actions.tcl
#
# Copyright (c) 2011 ]project-open[
#
# All rights reserved. 
# Please see http://www.project-open.com/ for licensing.

ad_page_contract {
    Export of all actions for SPRI
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
set menu_label "reporting-spri-report-actions"
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

set locale [lang::user::locale -user_id $current_user_id]

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

set page_title "SPRI Actions"
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

	select 	audit_date as fechamod,
			substring(audit_value from 'project_name\\t(\[^\\n\]*)') as nombreticket,
			substring(audit_value from 'ticket_request\\t(\[^\\n\]*)') as descripcion,
			substring(audit_value from 'ticket_resolution\\t(\[^\\n\]*)') as resultado,
			substring(audit_value from 'ticket_status_id\\t(\[^\\n\]*)') as estado,
			substring(audit_value from 'ticket_type_id\\t(\[^\\n\]*)') as tipo,
			substring(audit_value from 'ticket_type_id\\t(\[^\\n\]*)') as tipo_id,
			substring(audit_value from 'ticket_queue_id\\t(\[^\\n\]*)') as escalado,
			substring(audit_value from 'ticket_area_id\\t(\[^\\n\]*)') as area,
			substring(audit_value from 'ticket_area_id\\t(\[^\\n\]*)') as programa,
			substring(audit_value from 'ticket_area_id\\t(\[^\\n\]*)') as area_id,
			substring(audit_value from 'ticket_area_id\\t(\[^\\n\]*)') as programa_id,			
			substring(audit_value from 'company_id\\t(\[^\\n\]*)') as cliente_id,
			CASE WHEN substring(audit_value from 'ticket_queue_id\\t(\[^\\n\]*)') = 463 THEN 'SI' ELSE 'NO' END as ticket_resuelto,
			CASE WHEN substring(audit_value from 'ticket_requires_addition_info_p\\t(\[^\\n\]*)') = 't' THEN 'SI' ELSE 'NO' END as ticket_requires_addition_info,
			CASE WHEN substring(audit_value from 'ticket_closed_in_1st_contact_p\\t(\[^\\n\]*)') = 't' THEN 'SI' ELSE 'NO' END as ticket_closed_in_1st_contact,
			substring(audit_value from 'company_id\\t(\[^\\n\]*)') as cliente_id,
			acs_object__name(substring(audit_value from 'company_id\\t(\[^\\n\]*)')::integer) as cliente,
			substring(audit_value from 'ticket_customer_contact_id\\t(\[^\\n\]*)') as contacto_id,
			acs_object__name(substring(audit_value from 'ticket_customer_contact_id\\t(\[^\\n\]*)')::integer) as contacto,
			substring(audit_value from 'ticket_file\\t(\[^\\n\]*)') as exp,
			to_char(to_timestamp(substring(audit_value from 'ticket_creation_date\\t(\[^\\n\]*)'), 'YYYY-MM-DD HH:MI'), 'YYYY-MM-DD')  as fechacre,
			to_char(to_timestamp(substring(audit_value from 'ticket_creation_date\\t(\[^\\n\]*)'), 'YYYY-MM-DD HH:MI'), 'HH24:MI')  as timecre,
			to_char(to_timestamp(substring(audit_value from 'ticket_reaction_date\\t(\[^\\n\]*)'), 'YYYY-MM-DD HH:MI'), 'YYYY-MM-DD')  as fecharec,
			to_char(to_timestamp(substring(audit_value from 'ticket_reaction_date\\t(\[^\\n\]*)'), 'YYYY-MM-DD HH:MI'), 'HH24:MI')  as timerec,
			to_char(to_timestamp(substring(audit_value from 'ticket_escalation_date\\t(\[^\\n\]*)'), 'YYYY-MM-DD HH:MI'), 'YYYY-MM-DD')  as fechaescalado,
			to_char(to_timestamp(substring(audit_value from 'ticket_escalation_date\\t(\[^\\n\]*)'), 'YYYY-MM-DD HH:MI'), 'HH24:MI')  as timeescalado,						
			to_char(to_timestamp(substring(audit_value from 'ticket_done_date\\t(\[^\\n\]*)'), 'YYYY-MM-DD HH:MI'), 'YYYY-MM-DD')  as fechacierre,
			to_char(to_timestamp(substring(audit_value from 'ticket_done_date\\t(\[^\\n\]*)'), 'YYYY-MM-DD HH:MI'), 'HH24:MI')  as timecierre,						
			substring(audit_value from 'ticket_incoming_channel_id\\t(\[^\\n\]*)') as canal,
			substring(audit_value from 'ticket_incoming_channel_id\\t(\[^\\n\]*)') as detalle,
			substring(audit_value from 'ticket_outcoming_channel_id\\t(\[^\\n\]*)') as canalsalida,
			substring(audit_value from 'ticket_outcoming_channel_id\\t(\[^\\n\]*)') as detallecanalsalida,			
			project_nr as numero,
			audit_user_id,
			acs_object__name(audit_user_id) as audit_user_name,
			(select asterisk_user_id from persons where person_id=audit_user_id) as audit_user_asterik_id,
			c.vat_number as cliente_nif,
			c.company_type_id as cliente_tipo_id,
			c.company_type_id as cliente_tipo,
			c.company_province as cliente_provincia,
			pe.spri_email as contacto_email,
			pe.telephone as contacto_telefono,
			CASE WHEN pe.language = 'es_ES' THEN 'Espa�ol' WHEN pe.language = 'eu_ES' THEN 'Euskera' ELSE '' END	as contacto_idioma,
			CASE WHEN pe.gender = 'male' THEN 'Hombre' WHEN pe.gender = 'female' THEN 'Mujer' ELSE '' END as contacto_genero,
			CASE WHEN pe.spri_consultant = 1 THEN 'SI' ELSE 'NO' END as contacto_consultor
	from 	im_audits,
			im_projects,
			im_tickets,
			im_companies c,
			persons pe
	where 	ticket_id	  = audit_object_id	and
			project_id	  = audit_object_id and 
			audit_action != 'after_update' 	and 
			audit_action != 'before_update' and 
			audit_id in (
				select max(audit_id) as audit_id from im_audits where audit_action != 'after_update' and audit_action != 'before_update' group by audit_action
			) and 
			ticket_creation_date >= :start_date and
			ticket_creation_date <= :end_date	
			and c.company_id = substring(audit_value from 'company_id\\t(\[^\\n\]*)')
			and pe.person_id = substring(audit_value from 'ticket_customer_contact_id\\t(\[^\\n\]*)')

	order by 	project_nr asc,
				audit_date asc	
			
"


# ------------------------------------------------------------
# Report Definition
#
# Reports are defined in a "declarative" style. The definition
# consists of a number of fields for header, lines and footer.

# Global Header Line
set header0 {
	"Nombre"                                           					       
	"Numero"                                           	                        
	"Fecha Modificacion"                               	                        
	"Usuario accion ID"                          	                        
	"Usuario accion nombre"                      	                        
	"Usuario accion Asterix ID"	                           	                        
	"Descripcion"                                      	                        
	"Resultado"                                        	                        
	"Estado"                                           	                        
	"Tipo"        
	"Tipo ID"                                     	                        
	"Expediente"                                       	                        
	"Escalado"   
	"Escalado ID"                                        	                        
	"Area"
	"Area ID"                                                   	                        
	"Programa"	                                       	                        
	"Programa ID"	                                       	                        
	"Entidad"   
	"Entidad ID"                                       	                        
	"Tipo entidad"  
	"Tipo entidad ID"                                   	                        
	"NIF"                                              	                        
	"Provincia"                                        	                        
	"Contacto"                                         	                        
	"Contacto Mail"                                    	                        
	"Contacto Tel�fono"                                	                        
	"Contacto idioma"                                  	                        
	"Contacto genero"                                  	                        
	"Contacto consultor"                               	                        
	"Fecha Creacion"                                   	                        
	"Hora Creacion"                                    	                        
	"Fecha Recepcion"                                  	                        
	"Hora Recepcion"                                   	                        
	"Fecha Escalado"                                   	                        
	"Hora Escalado"                                    	                        
	"Fecha Cierre"                                     	                        
	"Hora Cierre"                                      	                        
	"Canal Entrada Lv 1"                               	                        
	"Canal Entrada"                                    	                        
	"Canal Salida Lv 1"                                	                        
	"Canal Salida"	                                   	                        
	"Cerrado en primer contacto"                       	                        
	"Resuelto"
	"Requiere informaci�n adicional"
}

# The entries in this list include <a HREF=...> tags
# in order to link the entries to the rest of the system (New!)
#
set report_def [list \
    group_by nombreticket  \
    header {
	$nombreticket											
	$numero                                                 
	$fechamod            
	$audit_user_id
	$audit_user_name
	$audit_user_asterik_id  
	$descripcion                                          
	$resultado                                              
	$estado                                                 
	$tipo    
	$tipo_id
	$exp                                               
	$escalado    
	$escalado_id                                           
	$area  
	$area_id     
	$programa                                            
	$programa_id
	$cliente   
	$cliente_id  
	$cliente_tipo 
	$cliente_tipo_id
	$cliente_nif
	$cliente_provincia                                        
	$contacto    
	$contacto_email
	$contacto_telefono
	$contacto_idioma
	$contacto_genero
	$contacto_consultor	                                                                                              
	$fechacre                                               
	$timecre                                                
	$fecharec                                               
	$timerec                                                
	$fechaescalado                                          
	$timeescalado                                           
	$fechacierre                                            
	$timecierre                                             
	$canal                                                  
	$detalle       
	$canalsalida                                         
	$detallecanalsalida   
	$ticket_closed_in_1st_contact
	$ticket_resuelto
	$ticket_requires_addition_info
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
	<table border=0 cellspacing=2 cellpadding=1>
    "
    }
    printer {
	ns_write "
	<link rel=StyleSheet type='text/css' href='/intranet-reporting/printer-friendly.css' media=all>
        <div class=\"fullwidth-list\">
	<table border=0 cellspacing=1 cellpadding=1 rules=all>
	<colgroup>
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
	#doc_return 200 "text/html" "$footer_array_list"
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


        # Data Customization
		set estado [im_category_from_id $estado]
		
		set tipo [im_category_from_id $tipo]
		
		set lista_parents [im_category_parents $cliente_tipo_id]
		set parent [lindex $lista_parents 0]
		set cliente_tipo [im_category_from_id -locale "es_ES" $parent]
		
		#set escalado [im_category_from_id $escalado]
		
		set escalado [db_0or1row serach-group-name "select group_name,group_id from groups where group_id=:escalado and group_id!=463"]
		if {!$escalado} {
			set escalado ""
			set escalado_id "463"
		} else {
			set escalado $group_name
			set escalado_id $group_id
		}
		
		if {"" != $area} {
			set lista_parents [im_category_parents $area]
			set parent [lindex $lista_parents 0]
			set area $parent
			set area_id $parent
		}			
		set area [im_category_from_id -locale "es_ES" $area]
		set programa [im_category_from_id -locale "es_ES" $programa]
		
		set lista_parents [im_category_parents $canal]
		set parent [lindex $lista_parents 0]	
		set canal [im_category_from_id $parent]
		if {"" == $canal} {
			set canal [im_category_from_id $detalle]
		}
		
		set detalle [im_category_from_id $detalle]
		
		set lista_parents [im_category_parents $canalsalida]
		set parent [lindex $lista_parents 0]	
		set canalsalida [im_category_from_id $parent]
		if {"" == $canalsalida} {
			set canalsalida [im_category_from_id $detallecanalsalida]
		}
		
		set detallecanalsalida [im_category_from_id $detallecanalsalida]		
		
		#set company_sql "select company_name as comp from im_companies where company_id = $cliente"
		#db_foreach sql $company_sql {
		#	set cliente $comp
		#}
				
		# Control de fechas vacias tras "to_date" cuando un substring del audit viene vacio para la fecha
		
		if {"0001-01-01" == $fechacre} {
            set fechacre ""
            set timecre ""
        }
		
		if {"0001-01-01" == $fecharec} {
            set fecharec ""
            set timerec ""
        }
		
		if {"0001-01-01" == $fechaescalado} {
            set fechaescalado ""
            set timeescalado ""
        }
		
		if {"0001-01-01" == $fechacierre} {
            set fechacierre ""
            set timecierre ""
        }
        
        

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

