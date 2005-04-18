--
-- packages/acs-mail/sql/acs-mail-queue-create.sql
--
-- @author John Prevost <jmp@arsdigita.com>
-- @creation-date 2001-01-08
-- @cvs-id $Id$
--

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


--
-- packages/acs-mail/sql/acs-mail-create-packages.sql
--
-- @author John Prevost <jmp@arsdigita.com>
-- @creation-date 2001-01-08
-- @cvs-id $Id$
--

-- Package Interfaces --------------------------------------------------

create or replace package acs_mail_gc_object
as

 function new (
  gc_object_id  in acs_objects.object_id%TYPE     default null,
  object_type   in acs_objects.object_type%TYPE   default 'acs_mail_gc_object',
  creation_date in acs_objects.creation_date%TYPE default sysdate,
  creation_user in acs_objects.creation_user%TYPE default null,
  creation_ip   in acs_objects.creation_ip%TYPE   default null,
  context_id    in acs_objects.context_id%TYPE    default null
 ) return acs_objects.object_id%TYPE;

 procedure del (
  gc_object_id in acs_mail_gc_objects.gc_object_id%TYPE
 );

end;
/
show errors

create or replace package acs_mail_body
as

 function new (
  body_id           in acs_mail_bodies.body_id%TYPE           default null,
  body_reply_to     in acs_mail_bodies.body_reply_to%TYPE     default null,
  body_from         in acs_mail_bodies.body_from%TYPE         default null,
  body_date         in acs_mail_bodies.body_date%TYPE         default null,
  header_message_id in acs_mail_bodies.header_message_id%TYPE default null,
  header_reply_to   in acs_mail_bodies.header_reply_to%TYPE   default null,
  header_subject    in acs_mail_bodies.header_subject%TYPE    default null,
  header_from       in acs_mail_bodies.header_from%TYPE       default null,
  header_to         in acs_mail_bodies.header_to%TYPE         default null,
  content_item_id	in acs_mail_bodies.content_item_id%TYPE default null,

  object_type       in acs_objects.object_type%TYPE default 'acs_mail_body',
  creation_date     in acs_objects.creation_date%TYPE default sysdate,
  creation_user     in acs_objects.creation_user%TYPE default null,
  creation_ip       in acs_objects.creation_ip%TYPE   default null,
  context_id        in acs_objects.context_id%TYPE    default null
 ) return acs_objects.object_id%TYPE;

 procedure del (
  body_id in acs_mail_bodies.body_id%TYPE
 );

 function body_p (
  object_id in acs_objects.object_id%TYPE
 ) return char;

 -- duplicate a mail body to make changes safely

 function clone (
  old_body_id   in acs_mail_bodies.body_id%TYPE,
  body_id       in acs_mail_bodies.body_id%TYPE default null,
  object_type   in acs_objects.object_type%TYPE    default 'acs_mail_body',
  creation_date in acs_objects.creation_date%TYPE  default sysdate,
  creation_user in acs_objects.creation_user%TYPE  default null,
  creation_ip   in acs_objects.creation_user%TYPE  default null,
  context_id    in acs_objects.context_id%TYPE     default null
 ) return acs_objects.object_id%TYPE;

 -- set the main content object of a mail body

 procedure set_content_object (
  body_id           in acs_mail_bodies.body_id%TYPE,
  content_item_id	in acs_mail_bodies.content_item_id%TYPE
 );

end;
/
show errors

create or replace package acs_mail_multipart
as

 function new (
  multipart_id   in acs_mail_multiparts.multipart_id%TYPE   default null,
  multipart_kind in acs_mail_multiparts.multipart_kind%TYPE,

  object_type    in acs_objects.object_type%TYPE
                                               default 'acs_mail_multipart',
  creation_date  in acs_objects.creation_date%TYPE             default sysdate,
  creation_user  in acs_objects.creation_user%TYPE             default null,
  creation_ip    in acs_objects.creation_ip%TYPE               default null,
  context_id     in acs_objects.context_id%TYPE                default null
 ) return acs_objects.object_id%TYPE;

 procedure del (
  multipart_id in acs_mail_multiparts.multipart_id%TYPE
 );

 function multipart_p (
  object_id in acs_objects.object_id%TYPE
 ) return char;

 -- Add content at a specific index.  If the sequence number is null,
 -- below one, or higher than the highest item already available,
 -- adds at the end.  Otherwise, inserts and renumbers others.

 function add_content (
  multipart_id      in acs_mail_multipart_parts.multipart_id%TYPE,
  content_item_id	in acs_mail_multipart_parts.content_item_id%TYPE
 ) return integer;

end acs_mail_multipart;
/
show errors

create or replace package acs_mail_link
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
  mail_link_id in acs_mail_links.mail_link_id%TYPE
 );

 function link_p (
  object_id in acs_objects.object_id%TYPE
 ) return char;

end acs_mail_link;
/
show errors

-- Package Implementations ---------------------------------------------

create or replace package body acs_mail_gc_object
as
 function new (
  gc_object_id  in acs_objects.object_id%TYPE     default null,
  object_type   in acs_objects.object_type%TYPE   default 'acs_mail_gc_object',
  creation_date in acs_objects.creation_date%TYPE default sysdate,
  creation_user in acs_objects.creation_user%TYPE default null,
  creation_ip   in acs_objects.creation_ip%TYPE   default null,
  context_id    in acs_objects.context_id%TYPE    default null
 ) return acs_objects.object_id%TYPE
 is
     v_object_id acs_objects.object_id%TYPE;
 begin
     v_object_id := acs_object.new (
         object_id => gc_object_id,
         object_type => object_type,
         creation_date => creation_date,
         creation_user => creation_user,
         creation_ip => creation_ip,
         context_id => context_id
     );
     insert into acs_mail_gc_objects values ( v_object_id );
     return v_object_id;
 end new;

 procedure del (
  gc_object_id in acs_mail_gc_objects.gc_object_id%TYPE
 )
 is
 begin
     delete from acs_mail_gc_objects
         where gc_object_id = acs_mail_gc_object.del.gc_object_id;
     acs_object.del(gc_object_id);
 end del;

end acs_mail_gc_object;
/
show errors

create or replace package body acs_mail_body
as

 function new (
  body_id           in acs_mail_bodies.body_id%TYPE           default null,
  body_reply_to     in acs_mail_bodies.body_reply_to%TYPE     default null,
  body_from         in acs_mail_bodies.body_from%TYPE         default null,
  body_date         in acs_mail_bodies.body_date%TYPE         default null,
  header_message_id in acs_mail_bodies.header_message_id%TYPE default null,
  header_reply_to   in acs_mail_bodies.header_reply_to%TYPE   default null,
  header_subject    in acs_mail_bodies.header_subject%TYPE    default null,
  header_from       in acs_mail_bodies.header_from%TYPE       default null,
  header_to         in acs_mail_bodies.header_to%TYPE         default null,
  content_item_id	in acs_mail_bodies.content_item_id%TYPE	  default null,

  object_type       in acs_objects.object_type%TYPE default 'acs_mail_body',
  creation_date     in acs_objects.creation_date%TYPE default sysdate,
  creation_user     in acs_objects.creation_user%TYPE default null,
  creation_ip       in acs_objects.creation_ip%TYPE   default null,
  context_id        in acs_objects.context_id%TYPE    default null
 ) return acs_objects.object_id%TYPE
 is
     v_object_id         acs_objects.object_id%TYPE;
     v_header_message_id acs_mail_bodies.header_message_id%TYPE;
 begin
     v_object_id := acs_mail_gc_object.new (
         gc_object_id => body_id,
         object_type => object_type,
         creation_date => creation_date,
         creation_user => creation_user,
         creation_ip => creation_ip,
         context_id => context_id
     );
     v_header_message_id :=
         nvl(header_message_id,
             sysdate || '.' || v_object_id || '@' ||
                 utl_inaddr.get_host_name || '.sddd');
     insert into acs_mail_bodies
         (body_id, body_reply_to, body_from, body_date, header_message_id,
          header_reply_to, header_subject, header_from, header_to,
          content_item_id)
     values
         (v_object_id, body_reply_to, body_from, body_date,
          v_header_message_id, header_reply_to, header_subject, header_from,
          header_to, content_item_id);
     return v_object_id;
 end new;

 procedure del (
  body_id in acs_mail_bodies.body_id%TYPE
 )
 is
 begin
     acs_mail_gc_object.del(body_id);
 end del;

 function body_p (
  object_id in acs_objects.object_id%TYPE
 ) return char
 is
     v_check_body_id integer;
 begin
     select decode(count(body_id),0,0,1) into v_check_body_id
         from acs_mail_bodies
         where body_id = object_id;
     if v_check_body_id <> 0 then
         return 't';
     else
         return 'f';
     end if;
 end body_p;

 function clone (
  old_body_id   in acs_mail_bodies.body_id%TYPE,
  body_id       in acs_mail_bodies.body_id%TYPE  default null,
  object_type   in acs_objects.object_type%TYPE   default 'acs_mail_body',
  creation_date in acs_objects.creation_date%TYPE default sysdate,
  creation_user in acs_objects.creation_user%TYPE default null,
  creation_ip   in acs_objects.creation_user%TYPE default null,
  context_id    in acs_objects.context_id%TYPE    default null
 ) return acs_objects.object_id%TYPE
 is
     v_object_id       acs_objects.object_id%TYPE;
     body_reply_to     acs_mail_bodies.body_reply_to%TYPE;
     body_from         acs_mail_bodies.body_from%TYPE;
     body_date         acs_mail_bodies.body_date%TYPE;
     header_message_id acs_mail_bodies.header_message_id%TYPE;
     header_reply_to   acs_mail_bodies.header_reply_to%TYPE;
     header_subject    acs_mail_bodies.header_subject%TYPE;
     header_from       acs_mail_bodies.header_from%TYPE;
     header_to         acs_mail_bodies.header_to%TYPE;
     content_item_id   acs_mail_bodies.content_item_id%TYPE;
 begin
     select body_reply_to, body_from, body_date,
            header_reply_to, header_subject, header_from, header_to,
            content_item_id
         into body_reply_to, body_from, body_date,
            header_reply_to, header_subject, header_from, header_to,
            content_item_id
         from acs_mail_bodies
         where body_id = old_body_id;
     v_object_id := acs_mail_body.new (
         body_id => body_id,
         body_reply_to => body_reply_to,
         body_from => body_from,
         body_date => body_date,
         header_reply_to => header_reply_to,
         header_subject => header_subject,
         header_from => header_from,
         header_to => header_to,
         content_item_id => content_item_id,
         object_type => object_type,
         creation_date => creation_date,
         creation_user => creation_user,
         creation_ip => creation_ip,
         context_id => context_id
     );
     return v_object_id;
 end clone;

 procedure set_content_object (
  body_id           in acs_mail_bodies.body_id%TYPE,
  content_item_id in acs_mail_bodies.content_item_id%TYPE
 )
 is
 begin
     update acs_mail_bodies
         set content_item_id = set_content_object.content_item_id
         where body_id = set_content_object.body_id;
 end set_content_object;

end acs_mail_body;
/
show errors

create or replace package body acs_mail_multipart
as

 function new (
  multipart_id   in acs_mail_multiparts.multipart_id%TYPE   default null,
  multipart_kind in acs_mail_multiparts.multipart_kind%TYPE,

  object_type    in acs_objects.object_type%TYPE
                                               default 'acs_mail_multipart',
  creation_date  in acs_objects.creation_date%TYPE             default sysdate,
  creation_user  in acs_objects.creation_user%TYPE             default null,
  creation_ip    in acs_objects.creation_ip%TYPE               default null,
  context_id     in acs_objects.context_id%TYPE                default null
 ) return acs_objects.object_id%TYPE
 is
     v_object_id acs_objects.object_id%TYPE;
 begin
     v_object_id := acs_mail_gc_object.new (
         gc_object_id => multipart_id,
         object_type => object_type,
         creation_date => creation_date,
         creation_user => creation_user,
         creation_ip => creation_ip,
         context_id => context_id
     );
     insert into acs_mail_multiparts (multipart_id, multipart_kind)
         values (v_object_id, multipart_kind);
     return v_object_id;
 end new;

 procedure del (
  multipart_id in acs_mail_multiparts.multipart_id%TYPE
 )
 is
 begin
     acs_mail_gc_object.del(multipart_id);
 end del;

 function multipart_p (
  object_id in acs_objects.object_id%TYPE
 ) return char
 is
     v_check_multipart_id integer;
 begin
     select decode(count(multipart_id),0,0,1) into v_check_multipart_id
         from acs_mail_multiparts
         where multipart_id = object_id;
     if v_check_multipart_id <> 0 then
         return 't';
     else
         return 'f';
     end if;
 end multipart_p;

 -- Add content at a specific index.  If the sequence number is null,
 -- below one, or higher than the highest item already available,
 -- adds at the end.  Otherwise, inserts and renumbers others.

 function add_content (
  multipart_id      in acs_mail_multipart_parts.multipart_id%TYPE,
  content_item_id	in acs_mail_multipart_parts.content_item_id%TYPE
 ) return integer
 is
     v_multipart_id acs_mail_multiparts.multipart_id%TYPE;
     v_max_num integer;
 begin
     -- get a row lock on the multipart item
     select multipart_id into v_multipart_id from acs_mail_multiparts
         where multipart_id = add_content.multipart_id for update;
     select nvl(max(sequence_number),0) into v_max_num
         from acs_mail_multipart_parts
         where multipart_id = add_content.multipart_id;
     insert into acs_mail_multipart_parts
         (multipart_id, sequence_number, content_item_id)
     values
         (multipart_id, v_max_num + 1, content_item_id);

	 return v_max_num + 1;
 end add_content;

end acs_mail_multipart;
/
show errors

create or replace package body acs_mail_link
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
     v_object_id := acs_object.new (
         object_id => mail_link_id,
         context_id => context_id,
         creation_date => creation_date,
         creation_user => creation_user,
         creation_ip => creation_ip,
         object_type => object_type
     );
     insert into acs_mail_links ( mail_link_id, body_id )
         values ( v_object_id, body_id );
     return v_object_id;
 end;

 procedure del (
  mail_link_id in acs_mail_links.mail_link_id%TYPE
 )
 is
 begin
     delete from acs_mail_links
         where mail_link_id = acs_mail_link.del.mail_link_id;
     acs_object.del(mail_link_id);
 end;

 function link_p (
  object_id in acs_objects.object_id%TYPE
 ) return char
 is
     v_check_link_id integer;
 begin
     select decode(count(mail_link_id),0,0,1) into v_check_link_id
         from acs_mail_links
         where mail_link_id = object_id;
     if v_check_link_id <> 0 then
         return 't';
     else
         return 'f';
     end if;
 end link_p;

end acs_mail_link;
/
show errors
