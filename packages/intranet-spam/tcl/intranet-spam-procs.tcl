ad_library {
    Spam procedure library.

    @author Bill Schneider (bschneid@arsdigita.com)
}

ad_proc spam_package_key {} { 
    returns the package key  in apm_packages for the spam package;
    'spam' by default
} { 
    return "intranet-spam"
}

ad_proc spam_package_id {} { 
    returns the package key  in apm_packages for the spam package;
    'spam' by default
} { 
    return [db_string spam_get_package_id "
	select min(package_id) from apm_packages 
	  where package_key = '[spam_package_key]'
    "]
}


ad_proc -public spam_base {} { 
    returns the base URL of the spam system.
} {
    return [util_memoize {
	db_string spam_base_query "
	select
	 site_node.url(node_id) 
 	from 
	 site_nodes, apm_packages 
	where
	 object_id=package_id and package_key='[spam_package_key]'
	"}]
}


ad_proc spam_new_message {
    {-context_id ""}
    {-send_date ""}
    {-spam_id ""}
    {-subject ""}
    {-plain  ""}
    {-html ""}
    {-sql ""}
    {-approved_p ""}
} {
    insert a new spam message into the acs_messages and spam_messages 
    table, and indirectly into the content repository.
    Requires that send_date be a string in the format
    "YYYY-MM-DD HH:MI:SS AM"; nearly ANSI but 12-hour time with AM/PM
} {

    # TilmannS: add a leading zero to the time, otherwise postgresql's
    # to_timestamp chokes. The default (produced by
    # spam_timeentrywidget, which uses ns_dbformvalueput) brings us a
    # string like this: '2001-08-31 7:45:00 PM' but we need something
    # like that: '2001-08-31 07:45:00 PM'. Not the most elegant
    # solution and not meant to be final - in my opinion the
    # time_widget needs some overall improvement here (is there
    # something general in ACS for this kind of stuff?).
    regsub { (\d):} $send_date { 0\1:} send_date

    set user_id [ad_get_user_id]
    set peeraddr [ad_conn peeraddr]

    set plain "asdf"

    if {"" == $send_date} { set send_date [db_string now "select now() from dual"] }

    return [db_exec_plsql spam_insert_message {}]
}

ad_proc spam_update_message {
    {-send_date [db_null]}
    {-spam_id ""}
    {-subject ""}
    {-plain  ""}
    {-html ""}
    {-sql "[db_null]"}
} {
    update an existing spam message into the acs_messages and spam_messages 
    table, and indirectly into the content repository.
    Requires that send_date be a string in the format
    "YYYY-MM-DD HH:MI:SS AM"; nearly ANSI but 12-hour time with AM/PM
} {
    set sql_proc  "
    begin
      spam.edit (
         spam_id => :spam_id,
         send_date => to_date(:send_date, 'yyyy-mm-dd hh:mi:ss AM'),
         title => :subject,
         sql_query => :sql,
         html_text => :html,
         plain_text => :plain
       );
     end;"

    # TilmannS: add a leading zero to the time, otherwise postgresql's
    # to_timestamp chokes. The default (produced by
    # spam_timeentrywidget, which uses ns_dbformvalueput) brings us a
    # string like this: '2001-08-31 7:45:00 PM' but we need something
    # like that: '2001-08-31 07:45:00 PM'. Not the most elegant
    # solution and not meant to be final - in my opinion the
    # time_widget needs some overall improvement here (is there
    # something general in ACS for this kind of stuff?).
    regsub { (\d):} $send_date { 0\1:} send_date
    
    return [db_exec_plsql spam_update_message $sql_proc]
}

ad_proc spam_send_immediate {msg_id} { 

    Sends the previously-entered spam message with id
    <code>msg_id</code> immediately by immediately queueing it in 
    the outgoing acs_mail_queue_outgoing table.

} {
    db_dml spam_update_for_immediate_send {
	spam_put_in_outgoing_queue $msg_id
	acs_mail_process_queue
    }
}

ad_proc -private spam_put_in_outgoing_queue {spam_id} { 
    puts a single spam messages in the outgoing queue immediately.
    requires approved_p to be true, which should generally be redundant
    (that is, program logic should check for approval before calling
    this routine in the first place).
} {
#    set spam_sender [ad_parameter -package_id [spam_package_id] SpamSender]

    set user_id [ad_get_user_id]
    set spam_sender [db_string spam_sender "select first_names||' '||last_name||' <'||email||'>' from cc_users where user_id=:user_id"]

    db_1row spam_get_outgoing_message {
	select body_id, send_date, sql_query, context_id, 
	    creation_date, creation_user, creation_ip
	from spam_messages, acs_objects, acs_mail_links
	where 
	    object_id = spam_id
	and mail_link_id = spam_id
	and spam_id = :spam_id
	and approved_p = 't'
    } 
    set recipients [db_list spam_get_recipients "
	select email from parties, ($sql_query) p2
	where p2.party_id = parties.party_id
    "]
    db_transaction {

	foreach email $recipients {
            set id [db_exec_plsql spam_insert_into_outgoing {
                begin
                :1 := acs_mail_queue_message.new (
		    body_id => :body_id,
		    context_id => :context_id,
		    creation_date => :creation_date,
		    creation_user => :creation_user,
		    creation_ip => :creation_ip
		);
                end;
            }]

	    db_dml spam_set_outgoing_addresses {
		insert into acs_mail_queue_outgoing 
		  (message_id, envelope_from, envelope_to)
		 values 
		  (:id, :spam_sender, :email)
	    }
	}
	db_dml spam_set_sent_p {
	    update spam_messages 
	    set sent_p = 't'
	    where spam_id = :spam_id
	}
    }
}

ad_proc spam_sweeper {} { 
    sweeps the spam_messages table for spams that have been approved but
    not yet been sent, but are due to be sent.  All of these messages will
    be inserted into the acs_mail_queue_outgoing table (once per recipient)
    and also in acs_mail_queue_messages (once total). 
} {

    set spam_list [db_list spam_get_list_of_outgoing_messages {
	select spam_id
	  from spam_messages
	where 
	    sysdate >= send_date
	and approved_p = 't'
	and sent_p = 'f'
    }]
    foreach spam_id $spam_list {
	spam_put_in_outgoing_queue $spam_id
    }
}

ad_proc spam_p {spam_id} {
    return 1 if spam_id is a valid  spam message, 0 if not
} {
    return [db_string spam_p_count 
	"select count(spam_id) from spam_messages where spam_id = :spam_id"
    ]
}

ad_proc spam_timeentrywidget {column {default ""}} {
    just like _ns_timeentrywidget but we need the ability to use a default
    time
} {
    if {$default != ""}  {
	set timestamp $default
    } else {
	set timestamp [lindex [split [ns_localsqltimestamp] " "] 1]
    }

    set output "<INPUT NAME=$column.time TYPE=text SIZE=9>&nbsp;<SELECT NAME=$column.ampm>
<OPTION> AM
<OPTION> PM
</SELECT>"

    return [ns_dbformvalueput $output $column time $timestamp]
}
    

    

