<?xml version="1.0"?>
<queryset>

<fullquery name="acs_mail_encode_content.get_storage_type">
<querytext>

select storage_type from cr_items 
where item_id = :content_item_id

</querytext>
</fullquery>



<fullquery name="acs_mail_encode_content.acs_mail_body_to_mime_get_content_simple">
<querytext>
      
select content, mime_type as v_content_type
	from cr_revisions
	where revision_id = :revision_id
        
</querytext>
</fullquery>


 

<fullquery name="acs_mail_encode_content.acs_mail_body_to_mime_get_contents">      
<querytext>
      
select mime_filename, mime_disposition, content_item_id as ci_id
  from acs_mail_multipart_parts
  where multipart_id = :content_item_id
  order by sequence_number
        
</querytext>
</fullquery>

 

<fullquery name="acs_mail_body_to_output_format.acs_mail_body_to_mime_get_body">
<querytext>
      
select body_id from acs_mail_links where mail_link_id = :link_id
        
</querytext>
</fullquery>

 


<fullquery name="acs_mail_body_to_output_format.acs_mail_body_to_mime_data">      
<querytext>
      
select header_message_id, header_reply_to, header_subject,
       header_from, header_to, content_item_id
  from acs_mail_bodies
  where body_id = :body_id
    
</querytext>
</fullquery>



 
<fullquery name="acs_mail_body_to_output_format.acs_mail_body_to_mime_headers">
<querytext>
      
select header_name, header_content from acs_mail_body_headers
  where body_id = :body_id
    
</querytext>
</fullquery>



<fullquery name="acs_mail_process_queue.acs_message_delete_sent">      
<querytext>
      
delete from acs_mail_queue_outgoing
  where message_id = :message_id
    and envelope_from = :envelope_from
    and envelope_to = :envelope_to
            
</querytext>
</fullquery>

 


<fullquery name="acs_mail_process_queue.acs_message_cleanup_queue">      
<querytext>
      
delete from acs_mail_queue_messages
  where message_id not in
  (select message_id from acs_mail_queue_outgoing)
  and message_id not in
  (select message_id from acs_mail_queue_incoming)
    
</querytext>
</fullquery>



 
<fullquery name="acs_mail_multipart_type.acs_mail_multipart_type">      
<querytext>
      
select multipart_kind from acs_mail_multiparts
  where multipart_id = :object_id
    
</querytext>
</fullquery>



 
<fullquery name="acs_mail_link_get_body_id.acs_mail_link_get_body_id">      
<querytext>
      
select body_id from acs_mail_links where mail_link_id = :link_id
    
</querytext>
</fullquery>

 
</queryset>
