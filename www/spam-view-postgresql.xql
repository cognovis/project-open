<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>


<fullquery name="spam_get_text">      
      <querytext>
      
	select content, mime_type
	  from cr_revisions
	where revision_id = content_item__get_live_revision(:content_item_id)
    
      </querytext>
</fullquery>


<fullquery name="spam_get_message">      
      <querytext>
      
    select header_subject as title, 
           to_char(send_date, 'Month DD, YYYY HH:MI:SS') as send_date,
           content_item_id 
     from spam_messages_all
     where spam_id = :spam_id

      </querytext>
</fullquery>

 
</queryset>
