<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="toggle_approval">      
      <querytext>
      
    update spam_messages
       set approved_p = util__logical_negation(approved_p)
     where spam_id = :spam_id

      </querytext>
</fullquery>

 
<fullquery name="spam_get_message_for_approval">      
      <querytext>
      
    select to_char(send_date, 'yyyy-mm-dd hh24:mi:ss') as sql_send_time,
      sql_query, approved_p
    from spam_messages
    where spam_id = :spam_id

      </querytext>
</fullquery>

 
</queryset>
