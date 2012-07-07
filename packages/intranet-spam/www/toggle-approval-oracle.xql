<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="toggle_approval">      
      <querytext>
      
    update spam_messages
       set approved_p = util.logical_negation(approved_p)
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
