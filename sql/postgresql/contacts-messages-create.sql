-- contacts/sql/postgresql/contacts-messages-create.sql
--
-- @author Matthew Geddert openacs@geddert.com
-- @creation-date 2005-06-29
-- @cvs-id $Id$
--
--

create table contact_message_types (
	message_type             varchar(20)
                                 constraint contact_message_types_pk primary key,
        pretty_name              varchar(100)
                                 constraint contact_message_types_pretty_name_nn not null
);
insert into contact_message_types (message_type,pretty_name) values ('email','#contacts.Email#');
insert into contact_message_types (message_type,pretty_name) values ('letter','#contacts.Letter#');
insert into contact_message_types (message_type,pretty_name) values ('header','#contacts.Header#');
insert into contact_message_types (message_type,pretty_name) values ('footer','#contacts.Footer#');
insert into contact_message_types (message_type,pretty_name) values ('oo_mailing','#contacts.oo_mailing#');


create table contact_message_items (
	item_id                 integer
                                constraint contact_message_items_id_fk references cr_items(item_id)
                                constraint contact_message_items_id_pk primary key,
        owner_id                integer
                                constraint contact_message_items_owner_id_fk references acs_objects(object_id) on delete cascade
                                constraint contact_message_items_owner_id_nn not null,
        message_type            varchar(20)
                                constraint contact_message_items_message_type_fk references contact_message_types(message_type)
                                constraint contact_message_items_message_type_nn not null,
	locale			varchar(30)
				constraint contact_message_items_locale_fk references ad_locales(locale),
        -- Banner contains the path to an image which can be inserted into the open office mailing document
        banner                 varchar(500),
	-- Template contains the path to the oo_template directory for the template that is being used
	oo_template	       varchar(500),
        -- PS is the post scriptum, which is commonly used in mailings.
        ps                      varchar(500)
);

create view contact_messages as 
    select cmi.item_id, 
           cmi.owner_id,
           cmi.message_type,
	   cmi.locale,
           cmi.banner,
           cmi.ps,
	   cmi.oo_template,
           cr.title,
           cr.description,
           cr.content,
           cr.mime_type as content_format,
           ao.package_id
      from contact_message_items cmi, cr_items ci, cr_revisions cr, acs_objects ao
     where cmi.item_id = cr.item_id
       and ci.publish_status not in ( 'expired' )
       and ci.live_revision = cr.revision_id
       and ci.item_id = ao.object_id
;


create table contact_message_log (
        message_id              integer
                                constraint contact_message_log_message_id_pk primary key
				constraint contact_message_log_message_id_fk references acs_objects(object_id),
        message_type            varchar(20)
                                constraint contact_message_log_message_type_fk references contact_message_types(message_type)
                                constraint contact_message_log_message_type_nn not null,
        sender_id               integer
                                constraint contact_message_sender_id_fk references users(user_id)
                                constraint contact_message_sender_id_nn not null,
        recipient_id            integer
                                constraint contact_message_recipient_id_fk references parties(party_id)
                                constraint contact_message_recipient_id_nn not null,
        sent_date               timestamptz
                                constraint contact_message_sent_date_nn not null,
        title                   varchar(1000),
	description             text,
        content                 text
                                constraint contact_message_log_content_nn not null,
        content_format          varchar(200)
                                constraint contact_message_log_content_format_fk references cr_mime_types(mime_type)
                                constraint contact_message_log_content_format_nn not null
);



select acs_object_type__create_type (
   'contact_message_log',         -- content_type
   'Contacts Message Log',        -- pretty_name 
   'Contacts Messages Logs',      -- pretty_plural
   'acs_object',                  -- supertype
   'contact_message_log',         -- table_name
   'object_id',                   -- id_column 
   'contact_messages_log',        -- package_name
   'f',                           -- abstract_p
   NULL,                          -- type_extension_table
   NULL                           -- name_method
);
