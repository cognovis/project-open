create table spam_messages ( 
	-- extends acs_mail_bodies
	spam_id		integer not null	
			constraint spam_messages_spam_id_fk
			references acs_mail_links(mail_link_id)
                        on delete cascade,
	-- date to send the spam out 
	-- spam will be put in mail queue at that time
	send_date	timestamptz not null,
	-- the sql query for selecting users.
	-- must be of the form "select party_id from ... where ..."
	sql_query	text not null,
	-- has it been approved yet?  spam won't go in queue until 
	-- approved.
	approved_p	boolean,
	-- has it been approved yet?
        sent_p		boolean    default FALSE
);

-- create a new object type
select acs_object_type__create_type (
        'spam_message',                 -- object_type 
        'Spam Message',                 -- pretty_name
        'Spam Messages',                -- pretty_plural
        'acs_mail_body',                -- supertype
        'spam_messages',                -- table_name
        'spam_id',                      -- id_column
        'spam',                         -- package_name
        'f',                            -- abstract_p (default)
        null,                           -- type_extension_table(default)
        'acs_object.default_name'       -- name_method
);

\i intranet-spam-views.sql
\i intranet-spam-packages.sql
