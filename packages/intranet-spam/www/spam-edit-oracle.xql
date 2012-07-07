<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>


<fullquery name="spam_get_num_recipients">      
      <querytext>
      
     select count(1) from ($sql_query)

      </querytext>
</fullquery>


<fullquery name="spam_get_multipart_plain_text">
        <querytext>

        select cr.content as plain_text
        from acs_mail_multipart_parts mpp, cr_items ci,  cr_revisions cr
        where 
          mpp.content_item_id=ci.item_id and
          ci.live_revision=cr.revision_id and
          multipart_id=:content_item_id and cr.mime_type='text/plain'

        </querytext>
</fullquery>


<fullquery name="spam_get_multipart_html_text">
        <querytext>

        select cr.content as html_text
        from acs_mail_multipart_parts mpp, cr_items ci, cr_revisions cr
        where
          mpp.content_item_id=ci.item_id and
          ci.live_revision=cr.revision_id and
          multipart_id=:content_item_id and cr.mime_type='text/html' 

        </querytext>
</fullquery>


<fullquery name="spam_get_message">      
      <querytext>
      
    select header_subject as title, 
      to_char(send_date, 'yyyy-mm-dd') as send_date, 
      to_char(send_date, 'hh24:mi:ss') as send_time, 
      sql_query, sent_p, content_item_id
    from spam_messages_all
    where spam_id = :spam_id

      </querytext>
</fullquery>


<fullquery name="spam_get_text">      
      <querytext>
      
	select content, mime_type
	  from cr_revisions
	where revision_id = content_item.get_live_revision(:content_item_id)
    
      </querytext>
</fullquery>


 
</queryset>
