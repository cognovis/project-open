--
-- packages/acs-mail/sql/postgresql/acs-mail-drop.sql
--
-- @author Vinod Kurup <vkurup@massmed.org>
-- @creation-date 2001-07-05
-- @cvs-id $Id: acs-mail-drop.sql,v 1.2 2006/04/07 22:47:06 cvs Exp $
--

-- FIXME: This script has NOT been tested! - vinodk

\i acs-mail-nt-drop.sql

drop function acs_mail_queue_message__new (integer,integer,
	 integer,timestamptz,integer,varchar,varchar);
drop function acs_mail_queue_message__delete (integer);

drop table acs_mail_queue_incoming;
drop table acs_mail_queue_outgoing;
drop table acs_mail_queue_messages;

select acs_object_type__drop_type (
	'acs_mail_queue_message',
	't'
);


drop function acs_mail_gc_object__new (integer,varchar,timestamptz,integer,
	 varchar,integer);
drop function acs_mail_gc_object__delete(integer);
drop function acs_mail_body__new (integer,integer,integer,timestamptz,varchar,
	 varchar,text,text,text,integer,varchar,date,integer,varchar,integer);
drop function acs_mail_body__delete(integer);
drop function acs_mail_body__body_p(integer);
drop function acs_mail_body__clone (integer,integer,varchar,timestamptz,
	 integer,varchar,integer);
drop function acs_mail_body__set_content_object (integer,integer);
drop function acs_mail_multipart__new (integer,varchar,varchar,
	 timestamptz,integer,varchar,integer);
drop function acs_mail_multipart__delete (integer);
drop function acs_mail_multipart__multipart_p (integer);
drop function acs_mail_multipart__add_content (integer,integer);
drop function acs_mail_link__new (integer,integer,integer,timestamptz,
	 integer,varchar,varchar);
drop function acs_mail_link__delete (integer);
drop function acs_mail_link__link_p (integer);


drop index acs_mail_body_hdrs_body_id_idx;

create function inline_0 ()
returns integer as '
declare
	v_rec		acs_objects%ROWTYPE;
begin
	for v_rec in select object_id from acs_objects where object_type in (''acs_mail_multipart'',''acs_mail_link'',''acs_mail_body'',''acs_mail_gc_object'') order by object_id desc
	loop
		perform acs_object__delete( v_rec.object_id );
	end loop;

	return 0;
end;' language 'plpgsql';

select inline_0 ();

drop function inline_0 ();


drop table acs_mail_body_headers;
drop table acs_mail_multipart_parts;
drop table acs_mail_multiparts;
drop table acs_mail_links;
drop table acs_mail_bodies;
drop table acs_mail_gc_objects;

select acs_object_type__drop_type (
	'acs_mail_multipart',
	't'
);

select acs_object_type__drop_type (
	'acs_mail_link',
	't'
);


select acs_object_type__drop_type (
	'acs_mail_body',
	't'
);

select acs_object_type__drop_type (
	'acs_mail_gc_object',
	't'
);

