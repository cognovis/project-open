<?xml version="1.0"?>
<queryset>

<fullquery name="contact::message::log.log_message">
    <querytext>
	insert into contact_message_log
	( message_id, message_type, sender_id, recipient_id, sent_date, title, description, content, content_format)
	values
	( :object_id, :message_type, :sender_id, :recipient_id, :sent_date, :title, :description, :content, :content_format)
    </querytext>
</fullquery>


<fullquery name="contact::message::log.create_acs_object">
    <querytext>
	 select 
		acs_object__new (
		 	          null,
				  'contact_message_log',
				  :sent_date,
				  :sender_id,
				  :creation_ip,
				  :package_id
				)
    </querytext>
</fullquery>


</queryset>
