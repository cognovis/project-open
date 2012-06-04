--
-- packages/acs-mail/sql/acs-mail-queue-create.sql
--
-- @author John Prevost <jmp@arsdigita.com>
-- @creation-date 2001-01-08
-- @cvs-id $Id$
--

begin
    acs_object_type.create_type (
        supertype => 'acs_mail_link',
        object_type => 'acs_mail_queue_message',
        pretty_name => 'Queued Message',
        pretty_plural => 'Queued Messages',
        table_name => 'ACS_MESSAGES_QUEUE_MESSAGES',
        id_column => 'MESSAGE_ID',
        name_method => 'ACS_OBJECT.DEFAULT_NAME'
    );
end;
/
show errors

create table acs_mail_queue_messages (
    message_id integer
        constraint acs_mail_queue_ml_id_pk primary key
        constraint acs_mail_queue_ml_id_fk references acs_mail_links
		on delete cascade
);

create table acs_mail_queue_incoming (
    message_id integer
        constraint acs_mail_queue_in_mlid_pk primary key
        constraint acs_mail_queue_in_mlid_fk
            references acs_mail_queue_messages on delete cascade,
    envelope_from varchar2(4000),
    envelope_to varchar2(4000)
);

create table acs_mail_queue_outgoing (
    message_id integer
        constraint acs_mail_queue_out_mlid_fk
            references acs_mail_queue_messages on delete cascade,
    envelope_from varchar2(4000),
    envelope_to		varchar2(1500),
	constraint acs_mail_queue_out_pk
	primary key (message_id, envelope_to)
);

-- API -----------------------------------------------------------------

create or replace package acs_mail_queue_message
as

 function new (
  mail_link_id    in acs_mail_links.mail_link_id%TYPE default null,
  body_id         in acs_mail_bodies.body_id%TYPE,

  context_id      in acs_objects.context_id%TYPE    default null,
  creation_date   in acs_objects.creation_date%TYPE default sysdate,
  creation_user   in acs_objects.creation_user%TYPE default null,
  creation_ip     in acs_objects.creation_ip%TYPE   default null,
  object_type     in acs_objects.object_type%TYPE   default 'acs_mail_link'
 ) return acs_objects.object_id%TYPE;

 procedure del (
  message_id in acs_mail_links.mail_link_id%TYPE
 );
end acs_mail_queue_message;
/
show errors

create or replace package body acs_mail_queue_message
as

 function new (
  mail_link_id    in acs_mail_links.mail_link_id%TYPE default null,
  body_id         in acs_mail_bodies.body_id%TYPE,

  context_id      in acs_objects.context_id%TYPE    default null,
  creation_date   in acs_objects.creation_date%TYPE default sysdate,
  creation_user   in acs_objects.creation_user%TYPE default null,
  creation_ip     in acs_objects.creation_ip%TYPE   default null,
  object_type     in acs_objects.object_type%TYPE   default 'acs_mail_link'
 ) return acs_objects.object_id%TYPE
 is
     v_object_id acs_objects.object_id%TYPE;
 begin
     v_object_id := acs_mail_link.new (
         mail_link_id => mail_link_id,
		 body_id => body_id,		      
         context_id => context_id,
         creation_date => creation_date,
         creation_user => creation_user,
         creation_ip => creation_ip,
         object_type => object_type
     );
     insert into acs_mail_queue_messages ( message_id )
         values ( v_object_id );
     return v_object_id;
 end;

 procedure del (
  message_id in acs_mail_links.mail_link_id%TYPE
 )
 is
 begin
     delete from acs_mail_queue_messages
         where message_id = acs_mail_queue_message.del.message_id;
     acs_mail_link.del(message_id);
 end;

end acs_mail_queue_message;
/
show errors


-- Needs:
--   Incoming:
--     A way to say "okay, I've accepted this one, go ahead and delete"
--   Outgoing:
--     A way to say "send this message to this person from this person"
--     A way to say "send this message to these people from this person"
