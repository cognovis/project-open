create table spam_messages ( 
	-- extends acs_mail_bodies
	spam_id		integer not null	
			constraint spam_messages_spam_id_fk
			references acs_mail_links(mail_link_id)
                        on delete cascade,
	-- date to send the spam out 
	-- spam will be put in mail queue at that time
	send_date	date not null,
	-- the sql query for selecting users.
	-- must be of the form "select party_id from ... where ..."
	sql_query	varchar(4000) not null,
	-- has it been approved yet?  spam won't go in queue until 
	-- approved.
	approved_p	char(1) 
			constraint spam_messages_approved_p_ck
			check (approved_p in ('t', 'f')),
	-- has it been approved yet?
        sent_p		char(1) default 'f'
			constraint spam_messages_sent_p_ck
			check (sent_p in ('t', 'f'))
);

-- create a new object type
begin
    acs_object_type.create_type (
        supertype => 'acs_mail_body',
        object_type => 'spam_message',
        pretty_name => 'Spam Message',
        pretty_plural => 'Spam Messages',
        table_name => 'SPAM_MESSAGES', 
        id_column => 'SPAM_ID',
        package_name => 'SPAM',
        name_method => 'ACS_OBJECT.DEFAULT_NAME'
    );
end;
/
show errors

@@ spam-views
@@ spam-packages
