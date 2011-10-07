ad_page_contract {
    @author David Blanco (david.blanco@grupoversia.com)
    @creation-date 21 Sep 2011
    @cvs-id $Id$
} {
    { object_id:integer ""}
}

	ns_log Notice "send-mail.tcl Inicio: object_id=$object_id"
	set result "true"
	set err_msg ""
	
    set found_p [db_0or1row ticket_info "
	select	*, to_char(ticket_creation_date,'YYYY-MM-DD HH24:MI') as creation_date,to_char(ticket_escalation_date,'YYYY-MM-DD HH24:MI') as escalation_date
	from	im_tickets,
		im_projects
	where	ticket_id = project_id and
		ticket_id = :object_id
    "]
    
#	set audit_sql "
#		select *,substring(audit_value from 'ticket_queue_id\\t(\[^\\n\]*)') as old_ticket_queue_id from im_audits where audit_id in (
#		select max(audit_id) as audit_id from im_audits where audit_object_id = :object_id and audit_action != 'after_update' and audit_action != 'before_update' group by audit_action
#	)
#	order by audit_id DESC 
#	"
	
	set old_ticket_queue_id ""
	set audit_sql "
	select *,substring(audit_value from 'ticket_queue_id\\t(\[^\\n\]*)') as old_ticket_queue_id from im_audits 
	where audit_object_id = :object_id and audit_action != 'after_update' and audit_action != 'before_update'
	order by audit_id DESC LIMIT 1
	"
	set found_audit_p [db_0or1row audit-last-record $audit_sql]	

    # Send out notification mail to all members of the queue
    set member_sql "
	select	member_id,
		im_name_from_user_id(member_id) as member_name,
		im_email_from_user_id(member_id) as member_email
	from	group_distinct_member_map gdmm
	where	group_id = :ticket_queue_id
    "
    set member_list {}
    set member_list_mail {}
    db_foreach members $member_sql {
		lappend member_list $member_name
		lappend member_list_mail $member_email
    }

	set channel [im_category_from_id -locale "es_ES" $ticket_incoming_channel_id ]
	set program [im_category_from_id -locale "es_ES" $ticket_area_id ]
	set type [im_category_from_id -locale "es_ES" $ticket_type_id ]
	set usr [im_name_from_user_id [db_string search-creation-user "select object_id_two from acs_rels where object_id_one = :ticket_id and rel_type = 'im_biz_object_member'"]]
	set cutomer_p [db_0or1row search-customer "select * from persons,parties where person_id=:ticket_customer_contact_id and party_id=person_id"]

	set subject "SPRI: $project_name"
	set body "
	Fecha y hora: $escalation_date
	Canal: $channel
	Programa: $program 
	Tipo de ticket: $type
	Expediente: $ticket_file
	Contacto: $first_names $last_name $last_name2
	Telefono: $telephone
	Email: $email
	Detalle: $ticket_request 
	
	
	Reciba un saludo,
	
	SACE SPRI
	902 702 142	
	"

	if {($found_audit_p && $old_ticket_queue_id!=$ticket_queue_id) || !$found_audit_p} {
		if {463!=$ticket_queue_id && 73363!=$ticket_queue_id && 73369!=$ticket_queue_id} {
				# Only resiste
				#if {73621==$ticket_queue_id } {
				    db_foreach send_email $member_sql {
						acs_mail_lite::send -from_addr "SACSPRI@sicsa.es" -to_addr $member_email -subject $subject -body $body
				#}
			}
		} else {
			#Si ha cambiado de estado SACE a SAC
			if (73369==$old_ticket_queue_id && 73363==$ticket_queue_id ) {
				ns_log Notice "send-mail: Cambio cola SACE a SAC envio a responsable"
				acs_mail_lite::send -from_addr "SACSPRI@sicsa.es" -to_addr "david.blanco@grupoversia.com" -subject "Tiene un ticket escalado de SACE ($project_name)"
				#acs_mail_lite::send -from_addr "SACSPRI@sicsa.es" -to_addr [email_image::get_email -user_id 59673] -subject "Tiene un ticket escalado de SACE ($project_name)"
			}
			
		}
    } 
    
    ns_log Notice "send-mail.tcl Fin"
	#doc_return 200 "text/html" "$subject<br>$body$member_list<br>$member_list_mail"
    doc_return 200 "text/html" "{
	\"result\": {
		\"success\":	$result,
		\"message\":	$body
    	}
}"