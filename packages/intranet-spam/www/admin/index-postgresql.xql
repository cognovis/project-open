<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="get_recipient_count">      
      <querytext>
      
	   select count(1) from ($__thisrow(sql_query)) as c
    
      </querytext>
</fullquery>


<fullquery name="spam_queue">      
      <querytext>
      
    select sm.spam_id, 
  	   to_char(sm.send_date, 'Mon DD, YYYY HH:MI:SS PM') as wait_until,
           case when sm.approved_p=TRUE then
                'Approved'
           else
                case when sm.approved_p=FALSE then
                        'Not Approved'
                else
                        'Error'
                end
           end
           as pretty_approved,
           approved_p,
           sm.sql_query,
           sm.header_subject as title,
           acs_permission__permission_p(sm.spam_id, :user_id, 'admin') 
             as admin_p
      from spam_messages_all sm
     where sent_p = 'f'
           and acs_permission__permission_p(sm.spam_id, :user_id, 'write') = 't'
 
     order by sm.send_date

      </querytext>
</fullquery>

 
</queryset>
