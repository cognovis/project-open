delete from acs_mail_links where mail_link_id in (
        select spam_id from spam_messages
);

drop table spam_messages;
drop view spam_messages_all;

delete from acs_objects where object_type = 'spam_message';

begin
	acs_object_type.drop_type (
		'spam_message',
		'f'
	);
end;
/
show errors



drop package spam;
