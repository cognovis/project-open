<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="spam_base.spam_base_query">      
      <querytext>
      
	select
	 site_node.url(node_id) 
 	from 
	 site_nodes, apm_packages 
	where
	 object_id=package_id and package_key='[spam_package_key]'
	
      </querytext>
</fullquery>

<fullquery name="spam_new_message.spam_insert_message">
        <querytext>

    begin
      :1 := spam.new (
         spam_id => :spam_id,
         send_date => to_date(:send_date, 'yyyy-mm-dd hh:mi:ss AM'),
         title => :subject,
         sql_query => :sql,
         html_text => :html,
         plain_text => :plain,
         creation_user => [ad_get_user_id],
         creation_ip => '[ad_conn peeraddr]',
         context_id => :context_id,
         approved_p => :approved_p
     );
     end;

        </querytext>
</fullquery>

 
<fullquery name="spam_put_in_outgoing_queue.spam_insert_into_outgoing">      
      <querytext>
      
	    begin
		  :1 := acs_mail_queue_message.new (
		    body_id => :body_id,
		    context_id => :context_id,
		    creation_date => :creation_date,
		    creation_user => :creation_user,
		    creation_ip => :creation_ip
		);
	    end;
	
      </querytext>
</fullquery>

 
<fullquery name="spam_sweeper.spam_get_list_of_outgoing_messages">      
      <querytext>
      
	select spam_id
	  from spam_messages
	where 
	    sysdate >= send_date
	and approved_p = 't'
	and sent_p = 'f'
    
      </querytext>
</fullquery>

 
</queryset>
