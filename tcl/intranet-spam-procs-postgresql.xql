<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="spam_base.spam_base_query">      
      <querytext>
      
	select
	 site_node__url(node_id) 
 	from 
	 site_nodes, apm_packages 
	where
	 object_id=package_id and package_key='[spam_package_key]'
	
      </querytext>
</fullquery>

<fullquery name="spam_new_message.spam_insert_message">
        <querytext>

         select spam__new (
                :spam_id,       -- spam_id
                null,           -- reply_to
                null,           -- sent_date
                null,           -- sender
                null,           -- rfc822_id
                :subject,       -- title
                :html,          -- html_text
                :plain,         -- plain_text
                :context_id,    -- context_id
                now(),          -- creation_date
                :user_id,       -- creation_user
                :peeraddr,      -- creation_ip
                'spam_message', -- object_type
                :approved_p,    -- approved_p
                :sql,           -- sql_query
                to_timestamp(:send_date, 'yyyy-mm-dd hh:mi:ss AM') -- send_date
         );

        </querytext>
</fullquery>

<fullquery name="spam_update_message.spam_update_message">
        <querytext>

        select spam__edit (
                :spam_id,       -- spam_id
                :subject,       -- title
                :html,          -- html_text
                :plain,         -- plain_text
                :sql,           -- sql_query
                to_timestamp(:send_date, 'yyyy-mm-dd hh:mi:ss AM') -- send_date
        );                

        </querytext>
</fullquery>


<fullquery name="spam_put_in_outgoing_queue.spam_insert_into_outgoing">      
      <querytext>
            select acs_mail_queue_message__new (
                    null,               -- p_mail_link_id
                    :body_id,           -- p_body_id       
                    :context_id,        -- p_context_id
                    :creation_date,     -- p_creation_date
                    :creation_user,     -- p_creation_user
                    :creation_ip,       -- p_creation_ip
                    'acs_mail_link'     -- p_object_type (default)
            );
      </querytext>
</fullquery>

 
<fullquery name="spam_sweeper.spam_get_list_of_outgoing_messages">      
      <querytext>
      
	select spam_id
	  from spam_messages
	where 
	    current_timestamp >= send_date
	and approved_p = 't'
	and sent_p = 'f'
    
      </querytext>
</fullquery>

 
</queryset>
