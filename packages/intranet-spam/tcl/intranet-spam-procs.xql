<?xml version="1.0"?>
<queryset>

<fullquery name="spam_package_id.spam_get_package_id">      
      <querytext>
      
	select min(package_id) from apm_packages 
	  where package_key = '[spam_package_key]'
    
      </querytext>
</fullquery>

 
<fullquery name="spam_send_immediate.spam_update_for_immediate_send">      
      <querytext>
      
	spam_put_in_outgoing_queue $msg_id
	acs_mail_process_queue
    
      </querytext>
</fullquery>

 
<fullquery name="spam_put_in_outgoing_queue.spam_get_outgoing_message">      
      <querytext>
      
	select body_id, send_date, sql_query, context_id, 
	    creation_date, creation_user, creation_ip
	from spam_messages, acs_objects, acs_mail_links
	where 
	    object_id = spam_id
	and mail_link_id = spam_id
	and spam_id = :spam_id
	and approved_p = 't'
    
      </querytext>
</fullquery>

 
<fullquery name="spam_put_in_outgoing_queue.spam_get_recipients">      
      <querytext>
      
	select email from parties, ($sql_query) p2
	where p2.party_id = parties.party_id
    
      </querytext>
</fullquery>

 
<fullquery name="spam_put_in_outgoing_queue.spam_set_outgoing_addresses">      
      <querytext>
      
		insert into acs_mail_queue_outgoing 
		  (message_id, envelope_from, envelope_to)
		 values 
		  (:id, :spam_sender, :email)
	    
      </querytext>
</fullquery>

 
<fullquery name="spam_put_in_outgoing_queue.spam_set_sent_p">      
      <querytext>
      
	    update spam_messages 
	    set sent_p = 't'
	    where spam_id = :spam_id
	
      </querytext>
</fullquery>

 
<fullquery name="spam_p.spam_p_count">      
      <querytext>
      select count(spam_id) from spam_messages where spam_id = :spam_id
      </querytext>
</fullquery>

 
</queryset>
