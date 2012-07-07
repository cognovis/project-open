create or replace view spam_messages_all as
	select spam_messages.*, acs_mail_bodies.*
	 from spam_messages, acs_mail_bodies, acs_mail_links
	where spam_id = acs_mail_links.mail_link_id
	  and acs_mail_links.body_id = acs_mail_bodies.body_id;
