<?xml version="1.0"?>
<queryset>

 
<fullquery name="spam_sent">      
      <querytext>
      
    select sm.spam_id,
           sm.header_subject as title,
           sm.send_date
      from spam_messages_all sm
     where 
           sent_p = 't'
    order by sm.send_date

      </querytext>
</fullquery>

 
</queryset>
