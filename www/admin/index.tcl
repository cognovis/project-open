ad_page_contract {
    main spam admin page 
    lists all the spam
    list of all spam in the queue
       link to detailed view of individual spam
        approve button
        send now button
    assume user already verified by request processor
} -properties {
    spam_queue:multirow
    context:onevalue
}

set user_id [auth::require_login]

# a message is considered unsent if sent_p is false

db_multirow spam_queue spam_queue {
    select sm.spam_id, 
  	   to_char(sm.send_date, 'Mon DD, YYYY HH:MI:SS PM') wait_until,
           decode (sm.approved_p, 't', 'Approved', 
                                  'f', 'Not Approved', 'Error') pretty_approved,
           approved_p,
           sm.sql_query,
           sm.header_subject as title,
           acs_permission.permission_p(sm.spam_id, :user_id, 'admin') 
             as admin_p
      from spam_messages_all sm
     where sent_p = 'f'
           and acs_permission.permission_p(sm.spam_id, :user_id, 'write') = 't'
 
     order by sm.send_date
}

# note that we have to get the recipient count manually, because we
# couldn't reference sql_query in the above query!

for {set i 1} {$i <= ${spam_queue:rowcount}} {incr i} { 
    upvar 0 spam_queue:$i __thisrow
    set __thisrow(total_recipients) [db_string get_recipient_count "
	   select count(1) from ($__thisrow(sql_query))
    "]
}

# !!! eventually order by when it was sent
# we want to match sent messages: 
# (no rows in amo OR there is a row in amo but send_attempts > 0) 
# and approved_p = 't'
# --> no rows in AMO with send_attempts = 0

db_multirow spam_sent spam_sent {
    select sm.spam_id,
           sm.header_subject as title,
           sm.send_date
      from spam_messages_all sm
     where 
           sent_p = 't'
    order by sm.send_date
}

set context [list]

ad_return_template
