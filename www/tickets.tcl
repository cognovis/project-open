
ad_page_contract {
    @author frank.bergmann@project-open.com
} {
    { node 0}
}

set ticket_sql "
	select	*,
		im_name_from_user_id(o.creation_user) as creation_user_name,
		ticket_description as excerpt
	from	im_projects p,
		im_tickets t,
		acs_objects o
	where	t.ticket_id = p.project_id and
		t.ticket_id = o.object_id
	LIMIT 10
"

set valid_vars {
 ticket_alarm_action              
 ticket_alarm_date                
 ticket_application_id            
 ticket_assignee_id               
 ticket_closed_in_1st_contact_p   
 ticket_component_id              
 ticket_conf_item_id              
 ticket_confirmation_date         
 ticket_creation_date             
 ticket_customer_contact_id       
 ticket_customer_deadline         
 ticket_dept_id                   
 ticket_description               
 ticket_done_date                 
 ticket_hardware_id               
 ticket_id                        
 ticket_note                      
 ticket_prio_id                   
 ticket_queue_id                  
 ticket_quote_comment             
 ticket_quoted_days               
 ticket_reaction_date             
 ticket_resolution_time           
 ticket_resolution_time_dirty     
 ticket_service_id                
 ticket_signoff_date              
 ticket_sla_id                    
 ticket_status_id                 
 ticket_type_id                   
}

set valid_vars {excerpt}

set json_list [list]
set cnt 0
db_foreach tickets $ticket_sql {
	set json_row [list]
	lappend json_row "\"id\": \"$ticket_id\""
	lappend json_row "\"threadid\": \"$ticket_id\""
	lappend json_row "\"text\": \"$project_name\""
	lappend json_row "\"title\": \"$project_name\""
	lappend json_row "\"forumtitle\": \"$project_name\""
	lappend json_row "\"forumid\": \"$parent_id\""
	lappend json_row "\"author\": \"$creation_user_name\""
	lappend json_row "\"replycount\": \"10\""
	lappend json_row "\"lastpost\": \"$ticket_creation_date\""
	lappend json_row "\"lastposter\": \"$creation_user_name\""

	foreach v $valid_vars {
		eval "set a $$v"
		regsub -all {\n} $a {\n} a
		regsub -all {\r} $a {} a
		lappend json_row "\"$v\": \"[ns_quotehtml $a]\""
	}

	lappend json_list "{[join $json_row ", "]}"
	incr cnt
}


doc_return 200 "application/json" "{\"success\": \"true\",\n\"message\": \"Data loaded\",\n\"total\": \"$cnt\",\n\"data\": \[\n[join $json_list ",\n"]\n\t\]\n}"

