-- bodies of spam package
-- 

create or replace package spam 
as 
    function new (
        spam_id       in spam_messages.spam_id%TYPE   default null,
        reply_to      in acs_mail_bodies.header_reply_to%TYPE     default null,
        sent_date     in acs_mail_bodies.body_date%TYPE    default sysdate,
        sender        in acs_mail_bodies.header_from%TYPE       default null,
        rfc822_id     in acs_mail_bodies.header_message_id%TYPE    default null,
        title         in acs_mail_bodies.header_subject%TYPE        default null,
        html_text     in varchar2                       default null,
        plain_text    in varchar2                       default null,
        context_id    in acs_objects.context_id%TYPE,
        creation_date in acs_objects.creation_date%TYPE default sysdate,
        creation_user in acs_objects.creation_user%TYPE default null,
        creation_ip   in acs_objects.creation_ip%TYPE   default null,
        object_type   in acs_objects.object_type%TYPE   default 'acs_message',
	approved_p    in char				default 'f',
	sql_query     in varchar2,
	send_date     in date
    ) return acs_objects.object_id%TYPE;


    procedure edit (
        spam_id       in spam_messages.spam_id%TYPE,
        title         in acs_mail_bodies.header_subject%TYPE        default null,
        html_text     in varchar2                       default null,
        plain_text    in varchar2                       default null,
	sql_query     in varchar2,
 	send_date     in date
    );


    function new_content (
        context_id    in acs_objects.context_id%TYPE,
        creation_date in acs_objects.creation_date%TYPE default sysdate,
        creation_user in acs_objects.creation_user%TYPE default null,
        creation_ip   in acs_objects.creation_ip%TYPE   default null,
        object_type   in acs_objects.object_type%TYPE   default 'acs_content',
	mime_type     in cr_revisions.mime_type%TYPE    default 'text/plain',
	p_text	      in varchar2			default null,

        -- TilmannS: the body_id of the spam message that this content 
        -- item will be associated with. Added to provide unique name 
        -- for the cr
        p_body_id     in acs_mail_bodies.body_id%TYPE

    ) return acs_objects.object_id%TYPE;
 
    procedure approve (
	spam_id    in spam_messages.spam_id%TYPE
    );

end spam;
/
show errors

create or replace package body spam 
as 
    function new (
        spam_id       in spam_messages.spam_id%TYPE   default null,        
        reply_to      in acs_mail_bodies.header_reply_to%TYPE     default null,
        sent_date     in acs_mail_bodies.body_date%TYPE    default sysdate,
        sender        in acs_mail_bodies.header_from%TYPE       default null,
        rfc822_id     in acs_mail_bodies.header_message_id%TYPE    default null,
        title         in acs_mail_bodies.header_subject%TYPE        default null,
        html_text     in varchar2                       default null,
        plain_text    in varchar2                       default null,
        context_id    in acs_objects.context_id%TYPE,
        creation_date in acs_objects.creation_date%TYPE default sysdate,
        creation_user in acs_objects.creation_user%TYPE default null,
        creation_ip   in acs_objects.creation_ip%TYPE   default null,
        object_type   in acs_objects.object_type%TYPE   default 'acs_message',
	approved_p    in char				default 'f',
	sql_query     in varchar2,
 	send_date     in date
    ) return acs_objects.object_id%TYPE
    IS
	v_link_id	acs_objects.object_id%TYPE;
	v_body_id	acs_objects.object_id%TYPE;
	v_content_obj   acs_mail_bodies.content_item_id%TYPE;
	v_html_id 	acs_mail_bodies.content_item_id%TYPE;
	v_text_id       acs_mail_bodies.content_item_id%TYPE;
        v_dummy         integer;
    begin
	v_body_id := acs_mail_body.new (
		body_id => null,
		header_reply_to => reply_to,
		body_date => sent_date,
		header_message_id => rfc822_id,
		header_subject => title,
		context_id => context_id,
		creation_date => creation_date,
		creation_user => creation_user,
		creation_ip => creation_ip, 
		object_type => 'acs_mail_body'
	);

	if plain_text is not null then
		v_text_id := spam.new_content(
			context_id => context_id,
			creation_date => creation_date,
			creation_user => creation_user,
			creation_ip => creation_ip, 
			object_type => object_type,
			mime_type => 'text/plain',
			p_text => plain_text,
                        p_body_id => v_body_id
		);
	end if;

	if html_text is not null then
		v_html_id := spam.new_content(
			context_id => context_id,
			creation_date => creation_date,
			creation_user => creation_user,
			creation_ip => creation_ip, 
			object_type => object_type,
			mime_type => 'text/html',
			p_text => html_text,
                        p_body_id => v_body_id
		);
	end if;

	-- now we have the message header set up.  now see what type
	-- of content we create.  We create a straight text/* content
	-- object if we only have either html_text or plain_text set,
	-- but we create a multipart/alternative if we have both.

	if html_text IS NOT NULL and plain_text IS NOT NULL then 
		-- we have both html and plain
		v_content_obj := acs_mail_multipart.new(
			multipart_kind => 'alternative',
			context_id => context_id,
			creation_date => creation_date,
			creation_user => creation_user,
			creation_ip => creation_ip, 
			object_type => object_type
		);
                v_dummy := acs_mail_multipart.add_content(v_content_obj, v_text_id);
		v_dummy := acs_mail_multipart.add_content(v_content_obj, v_html_id);
	elsif plain_text is not null then
		v_content_obj := v_text_id;
	elsif html_text is not null then
		v_content_obj := v_html_id;
	end if;
	acs_mail_body.set_content_object(v_body_id, v_content_obj);
	v_link_id := acs_mail_link.new(
		mail_link_id => spam_id,
		body_id => v_body_id,
		context_id => context_id,
		creation_date => creation_date,
		creation_user => creation_user,
		creation_ip => creation_ip
	);

	insert into spam_messages
		(spam_id, sql_query, approved_p, send_date)
	values
		(v_link_id, sql_query, approved_p, send_date);

	return v_link_id;
    end new;

    procedure edit (
        spam_id       in spam_messages.spam_id%TYPE,
        title         in acs_mail_bodies.header_subject%TYPE        default null,
        html_text     in varchar2                       default null,
        plain_text    in varchar2                       default null,
	sql_query     in varchar2,
 	send_date     in date
    ) 
    IS
	v_context_id	acs_objects.context_id%TYPE;
	v_creation_user	acs_objects.creation_user%TYPE;
	v_creation_ip	acs_objects.creation_ip%TYPE;
	v_creation_date	acs_objects.creation_date%TYPE;
	v_body_id	acs_objects.object_id%TYPE;
	v_content_obj   acs_mail_bodies.content_item_id%TYPE;
	v_html_id 	acs_mail_bodies.content_item_id%TYPE;
	v_text_id       acs_mail_bodies.content_item_id%TYPE;
        v_dummy         integer;

        v_parts_row     acs_mail_multipart_parts%ROWTYPE;

    begin
	select 
		body_id, context_id, creation_user, creation_date, creation_ip 
	into
		v_body_id, v_context_id, v_creation_user, v_creation_date, 
		v_creation_ip 
	from 
		acs_mail_links, spam_messages, acs_objects
	where 
		spam_id = mail_link_id 
	and 	spam_id = edit.spam_id
	and 	object_id = edit.spam_id;

	select content_item_id into v_content_obj 
		from acs_mail_bodies
		where body_id = v_body_id;

	update acs_mail_bodies
		set content_item_id = null,
		header_subject = edit.title
	where body_id = v_body_id;

	-- now we have the body id of the spam message.
	-- nuke any content associated with it.

	if acs_mail_multipart.multipart_p(v_content_obj) = 't' then
		-- we have a multipart
		-- and thus have to nuke the components.

                for v_parts_row in (select content_item_id from acs_mail_multipart_parts where multipart_id=v_content_obj) loop

                        -- cannot delete content_item as long as 
                        -- acs_mail_multipart_parts references it, so 
                        -- we set it null here. There's propably a more
                        -- elegant way to do this though. (TilmannS)
                        update acs_mail_multipart_parts set content_item_id=null where multipart_id=v_content_obj;

                        content_item.del(v_parts_row.content_item_id);
                end loop;

     		acs_mail_multipart.del(v_content_obj);

	else 
		content_item.del(v_content_obj);
	end if;

	if plain_text is not null then
		v_text_id := spam.new_content(
			context_id => v_context_id,
			creation_date => v_creation_date,
			creation_user => v_creation_user,
			creation_ip => v_creation_ip, 
			mime_type => 'text/plain',
			p_text => plain_text,
                        p_body_id => v_body_id
		);
	end if;

	if html_text is not null then
		v_html_id := spam.new_content(
			context_id => v_context_id,
			creation_date => v_creation_date,
			creation_user => v_creation_user,
			creation_ip => v_creation_ip, 
			mime_type => 'text/html',
			p_text => html_text,
                        p_body_id => v_body_id
		);
	end if;

	-- now we have the message header set up.  now see what type
	-- of content we create.  We create a straight text/* content
	-- object if we only have either html_text or plain_text set,
	-- but we create a multipart/alternative if we have both.

	if html_text IS NOT NULL and plain_text IS NOT NULL then 
		-- we have both html and plain
		v_content_obj := acs_mail_multipart.new(
			multipart_kind => 'alternative',
			context_id => v_context_id,
			creation_date => v_creation_date,
			creation_user => v_creation_user,
			creation_ip => v_creation_ip
		);
		v_dummy := acs_mail_multipart.add_content(v_content_obj, v_text_id);
		v_dummy := acs_mail_multipart.add_content(v_content_obj, v_html_id);
	elsif plain_text is not null then
		v_content_obj := v_text_id;
	elsif html_text is not null then
		v_content_obj := v_html_id;
	end if;
	acs_mail_body.set_content_object(v_body_id, v_content_obj);
	
	update spam_messages	
		set sql_query = edit.sql_query,
		    send_date = edit.send_date
		where spam_id = edit.spam_id;

    end edit;

    function new_content (
        context_id    in acs_objects.context_id%TYPE,
        creation_date in acs_objects.creation_date%TYPE default sysdate,
        creation_user in acs_objects.creation_user%TYPE default null,
        creation_ip   in acs_objects.creation_ip%TYPE   default null,
        object_type   in acs_objects.object_type%TYPE   default 'acs_content',
	mime_type     in cr_revisions.mime_type%TYPE    default 'text/plain',
	p_text	      in varchar2			default null,
        p_body_id     in acs_mail_bodies.body_id%TYPE

    ) return acs_objects.object_id%TYPE
    is 
	v_id            integer;
        v_rev_id        integer;
    begin
	v_id := content_item.new (
       		name => ('spam_message body_id-' || p_body_id || ' ' || mime_type),
                creation_date   => creation_date,
                creation_user   => creation_user,
                creation_ip     => creation_ip,
		mime_type       => mime_type,
                text            => p_text,
                storage_type    => 'text'
	);

        -- set the new revision live
        v_rev_id := content_item.get_latest_revision(v_id);
        content_item.set_live_revision(v_rev_id);

	return v_id;

    end new_content;

   procedure approve(spam_id IN spam_messages.spam_id%TYPE)
   is
   begin
	update spam_messages
 	  set approved_p = 't'
	where spam_id = approve.spam_id;
   end approve;

end spam;
/ 
show errors
