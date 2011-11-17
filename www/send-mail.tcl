ad_page_contract {
    @author David Blanco (david.blanco@grupoversia.com)
    @creation-date 21 Sep 2011
    @cvs-id $Id$
} {
    {object_id:integer ""}
    {destinatarios ""}
    {debug:integer 0}
}
	ns_log Notice "send-mail.tcl Inicio: object_id=$object_id"
	set destinatarios_mail ""
	set return_message ""
	set current_user_id [auth::get_user_id]
	if {""!=$destinatarios} {
		set destinatarios [split $destinatarios "_"]
		foreach destinatario $destinatarios {
			lappend destinatarios_mail [db_string search-spri-mail "select spri_email from persons where person_id=:destinatario" -default ""]
			if {0==$destinatario} {
				lappend send_names "SACSPRI"
			} else {
				lappend send_names [im_name_from_user_id $destinatario]
			}
		}
		set send_names [string map {"\{" "" "\}" ","} $send_names]
	}
	
    set found_p [db_0or1row ticket_info "
	select	*, 
	to_char(ticket_creation_date,'YYYY-MM-DD HH24:MI') as creation_date,
	to_char(ticket_escalation_date,'YYYY-MM-DD HH24:MI') as escalation_date,
	acs_object__name(company_id) as company_name
	from	im_tickets,
		im_projects
	where	ticket_id = project_id and
		ticket_id = :object_id
    "]
  
	
	set old_ticket_queue_id ""
	set audit_sql "
	select *,substring(audit_value from 'ticket_queue_id\\t(\[^\\n\]*)') as old_ticket_queue_id from im_audits 
	where audit_object_id = :object_id and audit_action != 'after_update' and audit_action != 'before_update'
	order by audit_id DESC LIMIT 1
	"
	set found_audit_p [db_0or1row audit-last-record $audit_sql]	

	set channel [im_category_from_id -locale "es_ES" $ticket_incoming_channel_id ]
	set program [im_category_from_id -locale "es_ES" $ticket_area_id ]
	set type [im_category_from_id -locale "es_ES" $ticket_type_id ]
	set usr [im_name_from_user_id [db_string search-creation-user "select object_id_two from acs_rels where object_id_one = :ticket_id and rel_type = 'im_biz_object_member'"]]
	set cutomer_p [db_0or1row search-customer "select * from persons,parties where person_id=:ticket_customer_contact_id and party_id=person_id"]             
	set code [db_string search-work-phone "select work_phone from users_contact where user_id =:current_user_id" -default ""]
	set group_name [db_string search-group-name "select group_name from groups where group_id=:ticket_queue_id" -default "Sin nombre"]
	
	set actions_sql "
	select *,
	substring(audit_value from 'ticket_request\\t(\[^\\n\]*)') as audit_ticket_request,
	substring(audit_value from 'ticket_resolution\\t(\[^\\n\]*)') as audit_ticket_resolution,
	substring(audit_value from 'ticket_queue_id\\t(\[^\\n\]*)') as audit_ticket_queue_id,
	substring(audit_value from 'ticket_status_id\\t(\[^\\n\]*)') as audit_ticket_status_id	
	from im_audits where audit_id in (
		select max(audit_id) as audit_id from im_audits where audit_object_id = :object_id and audit_action != 'after_update' and audit_action != 'before_update' group by audit_action
	)
	order by audit_date DESC	
	"                                  
	set subject "$code - $project_name - $program - $company_name - $ticket_file - $type"
	set body "
	Canal: $channel
	Programa: $program 
	Tipo de ticket: $type
	Expediente: $ticket_file
	Contacto: $first_names $last_name $last_name2
	Teléfono: $telephone
	Email: $spri_email
	
	"
	
	if {30011==$ticket_status_id} {
				append body "
				Fecha y hora: [string range [db_string search-now "select now()"] 0 15]
				Detalle: $ticket_request 
				Resultado: $ticket_resolution 		
				"		
	}
	set old_audit_ticket_queue_id ""
	db_foreach search-actions $actions_sql {
		if {30011==$audit_ticket_status_id} {
			if {$audit_ticket_queue_id!=$old_audit_ticket_queue_id} {
				append body "
				Fecha y hora: [string range $audit_date 0 15]
				Detalle: $audit_ticket_request 
				Resultado: $audit_ticket_resolution 		
				"
			}
			set old_audit_ticket_queue_id $old_audit_ticket_queue_id
		}
	}
	
	append body "
	Reciba un saludo,
	
	SACE SPRI
	902 702 142	
	"
	
	set remite ""
	#Si está escalado
	if {30011==$ticket_status_id} {	
		if {($found_audit_p && $old_ticket_queue_id!=$ticket_queue_id) || !$found_audit_p} {
			#Si viene de SACE o Empleados
			if {!$found_audit_p || $old_ticket_queue_id==73369 || 463==$old_ticket_queue_id} {
				set remite [parameter::get_from_package_key -package_key intranet-sencha-ticket-tracker -parameter DefaultFrom -default "SACSPRI@sicsa.es"]
			} else {
				#TODO: buscar el mail spri del usuario conectado
				set remite [db_string search-spri-mail "select spri_email from persons where person_id=:current_user_id" -default [parameter::get_from_package_key -package_key intranet-sencha-ticket-tracker -parameter DefaultFrom -default "SACSPRI@sicsa.es"]]
			}
			
			#Si va a un no SACE,no SAC y no empleados, ano ser que venga de un nivel 3 (grupos no sac,sace y empleados). se envia tipo 2
			if {(463!=$ticket_queue_id && 73363!=$ticket_queue_id && 73369!=$ticket_queue_id) || (463!=$old_ticket_queue_id && 73363!=$old_ticket_queue_id && 73369!=$old_ticket_queue_id )} {
		    	ns_log Notice "send-mail: acs_mail_lite::send -send_immediately -from_addr $remite -to_addr $destinatarios_mail -subject $subject -body $body -bcc_addr $remite"
				acs_mail_lite::send -send_immediately -from_addr $remite -to_addr $destinatarios_mail -subject $subject -body $body -bcc_addr $remite
				set return_message "Se ha enviado un correo tipo 2 de escalado al grupo $group_name: $send_names"
				if {$debug} {
					doc_return 200 "text/html" "acs_mail_lite::send -send_immediately -from_addr $remite -to_addr $destinatarios_mail -subject $subject -body $body -bcc_addr $remite"
				}
			} else {
				#Si viene de SACE,empleados o secretaria tecnica y va a SAC tipo 1.
				if {(!$found_audit_p || 73369==$old_ticket_queue_id || 463==$old_ticket_queue_id || 73375==$old_ticket_queue_id) && 73363==$ticket_queue_id } {
					set subject "SACE: $project_name"
					set body ""
					acs_mail_lite::send -send_immediately -from_addr $remite -to_addr $destinatarios_mail -subject $subject -body $body -bcc_addr $remite
					ns_log Notice "send-mail: acs_mail_lite::send -send_immediately -from_addr $remite -to_addr $destinatarios_mail -subject $subject -body $body -bcc_addr $remite"	
					set return_message "Se ha enviado un correo tipo 1 de escalado al grupo $group_name: $send_names"
					if {$debug} {
						doc_return 200 "text/html" "acs_mail_lite::send -send_immediately -from_addr $remite -to_addr $destinatarios_mail -subject $subject -body $body -bcc_addr $remite"			
					}
				}
				#Si viene de SAC y va a SACE,empleados o secretaria tecnica. Tipo 1
				if {73363==$old_ticket_queue_id && (73369==$ticket_queue_id || 463==$ticket_queue_id || 73375==$ticket_queue_id)} {
					set subject "SACE: $project_name"
					set body ""
					acs_mail_lite::send -send_immediately -from_addr $remite -to_addr $destinatarios_mail -subject $subject -body $body -bcc_addr $remite
					ns_log Notice "send-mail: acs_mail_lite::send -send_immediately -from_addr $remite -to_addr $destinatarios_mail -subject $subject -body $body -bcc_addr $remite"	
					set return_message "Se ha enviado un correo tipo 1 de escalado al grupo $group_name: $send_names"
					if {$debug} {
						doc_return 200 "text/html" "acs_mail_lite::send -send_immediately -from_addr $remite -to_addr $destinatarios_mail -subject $subject -body $body -bcc_addr $remite"			
					}
				}
				
			}
	    } 
	}
    
    ns_log Notice "send-mail.tcl Fin"
    doc_return 200 "text/html" "$return_message"