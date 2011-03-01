--
-- packages/acs-mail/sql/postgresql/acs-mail-drop.sql
--
-- @author Vinod Kurup <vkurup@massmed.org>
-- @creation-date 2001-07-05
-- @cvs-id $Id: acs-mail-drop.sql,v 1.2 2006/04/07 22:47:06 cvs Exp $
--

-- FIXME: This script has NOT been tested! - vinodk

@@ acs-mail-nt-drop

drop package acs_mail_queue_message;

drop table acs_mail_queue_incoming;
drop table acs_mail_queue_outgoing;
drop table acs_mail_queue_messages;

begin
	acs_object_type.drop_type (
		'acs_mail_queue_message',
		't'
	);
end;
/
show errors

drop package acs_mail_gc_object;
drop package acs_mail_body;
drop package acs_mail_multipart;
drop package acs_mail_link;

drop index acs_mail_body_hdrs_body_id_idx;

-- drop all acs-mail objects
begin
    for v_rec in (select object_id from acs_objects where object_type in ('acs_mail_multipart', 'acs_mail_link', 'acs_mail_body','acs_mail_gc_object') order by object_id desc)
    loop
        acs_object.del(v_rec.object_id);
    end loop;
end;
/
show errors

drop table acs_mail_body_headers;
drop table acs_mail_multipart_parts;
drop table acs_mail_multiparts;
drop table acs_mail_links;
drop table acs_mail_bodies;
drop table acs_mail_gc_objects;

begin
	acs_object_type.drop_type (
	   'acs_mail_multipart',
	   't'
	);

	acs_object_type.drop_type (
		'acs_mail_link',
		't'
	);

	acs_object_type.drop_type (
		'acs_mail_body',
		't'
	);

	acs_object_type.drop_type (
		'acs_mail_gc_object',
		't'
	);
end;
/
show errors
