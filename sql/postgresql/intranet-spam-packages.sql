-- bodies of spam package
-- 


create or replace function spam__new (integer,varchar,timestamptz,text,varchar,text,varchar,varchar,integer,timestamptz,integer,varchar,varchar,boolean,varchar,timestamptz)
returns integer as '
declare
        p_spam_id         alias for $1;     -- default null
        reply_to        alias for $2;     -- default null
        sent_date       alias for $3;     -- default sysdate
        sender          alias for $4;     -- default null
        rfc822_id       alias for $5;     -- default null
        title           alias for $6;     -- default null
        html_text       alias for $7;     -- default null
        plain_text      alias for $8;     -- default null
        context_id      alias for $9;
        creation_date   alias for $10;    -- default sysdate
        creation_user   alias for $11;    -- default null
        creation_ip     alias for $12;    -- default null
        object_type     alias for $13;    -- default acs_mail_body
	p_approved_p      alias for $14;    -- default f
	p_sql_query       alias for $15;
	p_send_date       alias for $16;

	v_link_id       acs_objects.object_id%TYPE;
	v_body_id	acs_objects.object_id%TYPE;
	v_content_obj   acs_mail_bodies.content_item_id%TYPE;
	v_html_id 	acs_mail_bodies.content_item_id%TYPE;
	v_text_id       acs_mail_bodies.content_item_id%TYPE;
begin
	select acs_mail_body__new (
		null,           -- p_body_id
                null,           -- p_body_reply_to
                null,           -- p_body_from
       		sent_date,      -- p_body_date
		rfc822_id,      -- p_header_message_id
		reply_to,       -- p_header_reply_to
		title,          -- p_header_subject
                null,           -- p_header_from
                null,           -- p_header_to
                null,           -- p_content_item_id
		''acs_mail_body'', -- p_object_type
		to_date(to_char(creation_date,  ''YYYY-MM-DD''), ''YYYY-MM-DD''),  -- p_creation_date
		creation_user,  -- p_creation_user
		creation_ip,    -- p_creation_ip
		context_id      -- p_context_id
	) into v_body_id;

	if plain_text is not null then
		 select spam__new_content(
			context_id,     -- context_id
			creation_date,  -- creation_date
			creation_user,  -- creation_user
			creation_ip,    -- creation_ip
			null,           -- object_type
			''text/plain'', -- mime_type
			plain_text,     -- text
                        v_body_id       -- body_id
		) into v_text_id;
	end if;

	if html_text is not null then
		select spam__new_content(
			context_id,     -- context_id
			creation_date,  -- creation_date
			creation_user,  -- creation_user
			creation_ip,    -- creation_ip
			null,           -- object_type
			''text/html'',  -- mime_type
			html_text,      -- text
                        v_body_id       -- body_id
		) into v_html_id;
	end if;


	-- now we have the message header set up.  now see what type
	-- of content we create.  We create a straight text/* content
	-- object if we only have either html_text or plain_text set,
	-- but we create a multipart/alternative if we have both.

	if html_text IS NOT NULL and plain_text IS NOT NULL then 
		-- we have both html and plain
		select acs_mail_multipart__new(
                        null,                   -- p_multipart_id
			''alternative'',        -- p_multipart_kind
			''acs_mail_multipart'', -- p_object_type
			creation_date,          -- p_creation_date
			creation_user,          -- p_creation_user
			creation_ip,            -- p_creation_ip
			context_id              -- p_context_id

		) into v_content_obj;
		perform acs_mail_multipart__add_content(v_content_obj, v_text_id);
		perform acs_mail_multipart__add_content(v_content_obj, v_html_id);
	else if plain_text is not null then
		v_content_obj := v_text_id;
             else if html_text is not null then
		v_content_obj := v_html_id;
                  end if;
             end if;
	end if;

        perform	acs_mail_body__set_content_object(v_body_id, v_content_obj);

	select acs_mail_link__new(
		p_spam_id,                -- p_mail_link_id
		v_body_id,              -- p_body_id
		context_id,             -- p_context_id
		creation_date,          -- p_creation_date
		creation_user,          -- p_creation_user
		creation_ip,            -- p_creation_ip
                ''acs_mail_link''       -- p_object_type (default)
	) into v_link_id;


	insert into spam_messages (spam_id, sql_query, approved_p, send_date) values (v_link_id, p_sql_query, p_approved_p, p_send_date);

	return v_link_id;
end;
' language 'plpgsql';

-- end spam__new



-- procedure edit
create or replace function spam__edit (integer,text,varchar,varchar,varchar,timestamptz) returns integer as '
declare
        p_spam_id       alias for $1;     -- spam_messages.spam_id%TYPE,
        p_title         alias for $2;     -- acs_mail_bodies.header_subject%TYPE default null
        p_html_text     alias for $3;     -- default null
        p_plain_text    alias for $4;     -- default null
	p_sql_query     alias for $5;
 	p_send_date     alias for $6;

	v_context_id	acs_objects.context_id%TYPE;
      	v_creation_user	acs_objects.creation_user%TYPE;
	v_creation_ip	acs_objects.creation_ip%TYPE;
	v_creation_date	acs_objects.creation_date%TYPE;
	v_body_id	acs_objects.object_id%TYPE;
	v_content_obj   acs_mail_bodies.content_item_id%TYPE;
	v_rec    	record;
	v_html_id 	acs_mail_bodies.content_item_id%TYPE;
	v_text_id       acs_mail_bodies.content_item_id%TYPE;

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
	and 	spam_id = p_spam_id
	and 	object_id = p_spam_id;

	select content_item_id into v_content_obj 
		from acs_mail_bodies
		where body_id = v_body_id;

	update acs_mail_bodies
		set content_item_id = null,
		header_subject = p_title
	where body_id = v_body_id;


	-- now we have the body id of the spam message.
	-- nuke any content associated with it.

	if (select acs_mail_multipart__multipart_p(v_content_obj)) then
		-- we have a multipart
		-- and thus have to nuke the components.
                
                for v_rec in
                        select content_item_id from acs_mail_multipart_parts
                                where multipart_id=v_content_obj
                loop
                        perform content_item__delete(v_rec.content_item_id);
                end loop;
		perform acs_mail_multipart__delete(v_content_obj);

	else 
		perform content_item__delete(v_content_obj);
	end if;

	if p_plain_text is not null then
		select spam__new_content(
			v_context_id,           -- context_id
			v_creation_date,        -- creation_date
			v_creation_user,        -- creation_user
			v_creation_ip,          -- creation_ip
                        null,                   -- object_type
			''text/plain'',         -- mime_type
			p_plain_text,           -- text
                        v_body_id               -- body_id
		) into v_text_id;
	end if;

	if p_html_text is not null then
		select spam__new_content(
			v_context_id,           -- context_id
			v_creation_date,        -- creation_date
			v_creation_user,        -- creation_user
			v_creation_ip,          -- creation_ip
                        null,                   -- object_type
			''text/html'',          -- mime_type
			p_html_text,            -- text
                        v_body_id               -- body_id
		) into v_html_id;
	end if;


    	-- now we have the message header set up.  now see what type
    	-- of content we create.  We create a straight text/* content
    	-- object if we only have either html_text or plain_text set,
    	-- but we create a multipart/alternative if we have both.

	if p_html_text IS NOT NULL and p_plain_text IS NOT NULL then 
		-- we have both html and plain
		select acs_mail_multipart__new(
                        null,                   -- p_multipart_id
			''alternative'',        -- p_multipart_kind
			''acs_mail_multipart'', -- p_object_type
			v_creation_date,        -- p_creation_date
			v_creation_user,        -- p_creation_user
			v_creation_ip,          -- p_creation_ip
			v_context_id            -- p_context_id

		) into v_content_obj;
		perform acs_mail_multipart__add_content(v_content_obj, v_text_id);
		perform acs_mail_multipart__add_content(v_content_obj, v_html_id);
	else if p_plain_text is not null then
		v_content_obj := v_text_id;
	     else if p_html_text is not null then
                   v_content_obj := v_html_id;
                  end if;
             end if;
	end if;
	perform acs_mail_body__set_content_object(v_body_id, v_content_obj);

        return 0; 

end;
' language 'plpgsql';

-- end spam__edit



create or replace function spam__new_content (integer,timestamptz,integer,varchar,varchar,varchar,varchar,integer)
returns integer as '
declare
        context_id    alias for $1;      -- acs_objects.context_id%TYPE
        creation_date alias for $2;      -- acs_objects.creation_date%TYPE default sysdate
        creation_user alias for $3;      -- acs_objects.creation_user%TYPE default null
        creation_ip   alias for $4;      -- acs_objects.creation_ip%TYPE default null
        object_type   alias for $5;      -- acs_objects.object_type%TYPE default content_item
	mime_type     alias for $6;      -- acs_contents.mime_type%TYPE default text/plain

	p_text	      alias for $7;	-- default null

        -- TilmannS: the body_id of the spam message that this content 
        -- item will be associated with. Added to provide unique name 
        -- for the cr
        p_body_id     alias for $8;     

	v_id          integer;
        v_rev_id      integer;

begin

	select content_item__new (
		(''spam_message body_id-'' || p_body_id || '' '' || mime_type)::varchar, -- name
                null,                   -- item_id
                null,                   -- parent_id
                null,                   -- new_locale
		creation_date,          -- creation_date,
		creation_user,          -- creation_user,
                null,                   -- context_id
		creation_ip,            -- creation_ip
                ''content_item'', --  new__item_subtype     default ''content_item''
                ''content_revision'', -- new__content_type default ''content_revision''
                null, --   new__title                  default null
                null, --   new__description            default null
		mime_type,               -- mime_type
                null,                   -- nls_language
                p_text,                 -- text 
                ''text''::varchar       -- storage_type
	) into v_id;

        -- set the new revision live
        select content_item__get_latest_revision(v_id) into v_rev_id;
        perform content_item__set_live_revision(v_rev_id);

	return v_id;
end;
' language 'plpgsql';

-- end spam__new_content



--  procedure approve (
create or replace function spam__approve (integer)
returns integer as '
declare
   p_spam_id      alias for $1            -- spam_messages.spam_id%TYPE)
begin
   update spam_messages
      set approved_p = ''t''
      where spam_id = p_spam_id;

   return 0; 
end;
' language 'plpgsql';

