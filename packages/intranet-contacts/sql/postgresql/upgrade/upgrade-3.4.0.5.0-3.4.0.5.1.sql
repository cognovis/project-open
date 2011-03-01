-- upgrade-3.4.0.5.0-3.4.0.5.1.sql

SELECT acs_log__debug('/packages/intranet-contacts/sql/postgresql/upgrade/upgrade-3.4.0.5.0-3.4.0.5.1.sql','');

delete from contact_message_types;
insert into contact_message_types (message_type,pretty_name) values ('email','#intranet-contacts.Email#');
insert into contact_message_types (message_type,pretty_name) values ('letter','#intranet-contacts.Letter#');
insert into contact_message_types (message_type,pretty_name) values ('header','#intranet-contacts.Header#');
insert into contact_message_types (message_type,pretty_name) values ('footer','#intranet-contacts.Footer#');
insert into contact_message_types (message_type,pretty_name) values ('oo_mailing','#intranet-contacts.oo_mailing#');
